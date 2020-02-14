FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

LABEL maintainer="lucidyan"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHON_VERSION=3.7 \
    CMAKE_VERSION=3.16.4 \
    TORCH_VERSION=1.4.0 \
    TORCHVISION_VERSION=0.5.0 \
    TENSORFLOW_VERSION=2.1.0

#################################################################
# System packages
#################################################################
# Python
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        apt-utils \
        software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get install --yes --no-install-recommends \
	    python${PYTHON_VERSION}-dev \
    && update-alternatives --install /usr/bin/python3 python${PYTHON_VERSION} /usr/bin/python${PYTHON_VERSION} 0 \
    && python3 --version \
    && rm -rf /var/lib/apt/lists/*

# Neccessary system packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Libraries
        libncurses5-dev \
        libjpeg8 \
        libjpeg62-dev \
        libfreetype6 \
        libfreetype6-dev \
        libpng-dev \
        libzmq3-dev \
        libboost-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        # Utils
        sudo \
        build-essential \
        rsync \
        curl \
        unzip \
        zip \
        git \
        wget \
        htop \
        nano \
        vim \
    && rm -rf /var/lib/apt/lists/*

## CMake
RUN export CMAKE_VERSION_MINOR=$(echo $CMAKE_VERSION | cut -d "." -f 1-2) \
    && export CMAKE_FILENAME=cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
    && wget https://cmake.org/files/v${CMAKE_VERSION_MINOR}/${CMAKE_FILENAME} -O /tmp/${CMAKE_FILENAME} -q \
    && apt-get remove --purge --auto-remove cmake --yes \
    && mkdir /opt/cmake \
    && sh /tmp/${CMAKE_FILENAME} --prefix=/opt/cmake --skip-license && rm /tmp/${CMAKE_FILENAME} \
    && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
    && cmake --version

###################################################################
### Python packages
###################################################################
## PIP
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
	    python3-pip \
    && curl -O https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py \
    && rm get-pip.py \
    && pip3 --no-cache-dir install --upgrade pip \
    && rm -rf /var/lib/apt/lists/*

# PIP packages
RUN pip3 --no-cache-dir install \
        # ML
        bayesian-optimization \
        numpy \
        pandas \
        scipy \
        sklearn \
        numba \
        # Utils
        Cython \
        h5py \
        ipykernel \
        ipywidgets \
        nbdime \
        jupyter \
        tables \
        tqdm \
        # Visualization
        matplotlib \
        Pillow \
        plotly \
        pydot \
        seaborn \
        # Vision
        albumentations \
        opencv-python \
        scikit-image \
    && python3 -m ipykernel.kernelspec \
    && jupyter nbextension enable --py widgetsnbextension

# XGBoost python wrapper
RUN cd /usr/local/src && git clone --recursive https://github.com/dmlc/xgboost \
    && cd xgboost \
    && mkdir build && cd build \
    && cmake .. -DUSE_CUDA=ON -DUSE_NCCL=ON -DNCCL_ROOT=/usr/local/nccl-${NCCL_VERSION} \
    && make -j$(nproc) \
    && cd .. \
    && cd /usr/local/src/xgboost/python-package && python3 setup.py install

# LightGBM
RUN cd /usr/local/src && git clone --recursive https://github.com/Microsoft/LightGBM \
    && cd LightGBM \
    && mkdir build && cd build \
    && cmake .. -DUSE_GPU=1 -DOpenCL_LIBRARY=/usr/local/cuda/lib64/libOpenCL.so -DOpenCL_INCLUDE_DIR=/usr/local/cuda/include/ \
    && make -j$(nproc) \
    && cd .. \
    && cd /usr/local/src/LightGBM/python-package && python3 setup.py install

# CatBoost
RUN pip3 --no-cache-dir install catboost

# PyTorch
RUN export PYTHON_VERSION_SHORT=$(echo ${PYTHON_VERSION} | tr -d '.') \
    && pip3 --no-cache-dir install \
        https://download.pytorch.org/whl/cu101/torch-${TORCH_VERSION}-cp${PYTHON_VERSION_SHORT}-cp${PYTHON_VERSION_SHORT}m-linux_x86_64.whl \
            https://download.pytorch.org/whl/cu101/torchvision-${TORCHVISION_VERSION}-cp${PYTHON_VERSION_SHORT}-cp${PYTHON_VERSION_SHORT}m-linux_x86_64.whl \
        \
        # Catalyst
        && pip --no-cache-dir install catalyst

# Install TensorFlow GPU version with Keras
RUN export PYTHON_VERSION_SHORT=$(echo ${PYTHON_VERSION} | tr -d '.') \
    && pip3 --no-cache-dir install \
        https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-${TENSORFLOW_VERSION}-cp${PYTHON_VERSION_SHORT}-cp${PYTHON_VERSION_SHORT}m-manylinux2010_x86_64.whl \
        keras \
    \
    # PyMC
    && pip3 --no-cache-dir install \
        pymc3

# POT
RUN git clone https://github.com/rflamary/POT \
    && cd POT \
    && python3 setup.py install \
    && pip3 --no-cache-dir install \
        pymanopt \
        autograd

#################################################################
# Setup container
#################################################################
# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# TensorBoard
EXPOSE 6006

# IPython
EXPOSE 8888

ARG USER_ID
ARG GROUP_ID

# Volume mount workaround
RUN OLD_GROUP_NAME="$(getent group ${GROUP_ID}| cut -d: -f1)" && \
    OLD_GROUP_ID="$(getent group ${GROUP_ID}| cut -d: -f3)" && \
    # Big GID that very likely does not exist
    NEW_GROUP_ID=10000 && \
    if [ "$OLD_GROUP_NAME" ]; then \
        # Change current group name
        groupmod -g "$NEW_GROUP_ID" "$OLD_GROUP_NAME" ; \
        find / -group "$OLD_GROUP_ID" -print 2>/dev/null \
            | xargs --no-run-if-em;pty chgrp -h "$NEW_GROUP_ID" ; \
    fi && \
    # Create User and Group with our UID/GID
    groupadd --gid ${GROUP_ID} docker && \
    useradd --uid ${USER_ID} --gid ${GROUP_ID} docker \
    && \
    mkdir -p /home/docker/ && chown -R docker:docker /home/docker/

USER docker

WORKDIR "/home/docker/"
