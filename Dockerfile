FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

LABEL maintainer="lucidyan"

#################################################################
# System packages
#################################################################
RUN apt-get update && \
        apt-get install -y --no-install-recommends \
        apt-utils \
        build-essential \
        software-properties-common \
	# Libraries
        libncurses5-dev \
        libjpeg8 \
        libjpeg62-dev \
        libfreetype6 \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
	libboost-dev \
	libboost-system-dev \
	libboost-filesystem-dev \
	# Python
        pkg-config \
        python3.5 \
        python3.5-dev \
        libpython3-dev \
	# Utils
        cmake \
        rsync \
        curl \
        unzip \
        zip \
        git \
        wget \
        htop \
        wget \
        nano \
        vim \
    && \
    apt-get clean

#################################################################
# Python packages
#################################################################
# PIP
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py && \
    pip3 install --upgrade pip

# PIP packages
RUN pip3 --no-cache-dir install \
	# ML
	bayesian-optimization \
        numpy\
        pandas \
        scipy \
        sklearn \
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
        opencv-python \
        scikit-image \
    && \
    python3 -m ipykernel.kernelspec \
    && \
    jupyter nbextension enable --py widgetsnbextension

# CMake
ADD https://cmake.org/files/LatestRelease/cmake-3.14.0-Linux-x86_64.sh /cmake-3.14.0-Linux-x86_64.sh
RUN apt remove --purge --auto-remove cmake -y && \
	mkdir /opt/cmake && \
	sh /cmake-3.14.0-Linux-x86_64.sh --prefix=/opt/cmake --skip-license && \
	ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake && \
	cmake --version

# XGBoost python wrapper
RUN cd /usr/local/src && git clone --recursive https://github.com/dmlc/xgboost && \
    cd xgboost && \
    mkdir build && cd build && \
    cmake .. -DUSE_CUDA=ON -DUSE_NCCL=ON -DNCCL_ROOT=/usr/local/nccl-{$NCCL_VERSION} && \
    make -j$(nproc) && \
    cd .. && \
    cd /usr/local/src/xgboost/python-package && python3 setup.py install

# LightGBM
RUN cd /usr/local/src && git clone --recursive https://github.com/Microsoft/LightGBM && \
    cd LightGBM && \
    mkdir build && cd build && \
    cmake .. -DUSE_GPU=1 -DOpenCL_LIBRARY=/usr/local/cuda/lib64/libOpenCL.so -DOpenCL_INCLUDE_DIR=/usr/local/cuda/include/ && \
    make -j$(nproc) && \
    cd .. && \
    cd /usr/local/src/LightGBM/python-package && python3 setup.py install

# CatBoost
RUN pip3 install catboost

# PyTorch
RUN pip3 --no-cache-dir install \
	https://download.pytorch.org/whl/cu90/torch-1.1.0-cp35-cp35m-linux_x86_64.whl \
        torchvision==0.3.0

# Install TensorFlow GPU version.
RUN pip3 --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.14.0-cp35-cp35m-linux_x86_64.whl

# Keras
RUN pip3 install keras

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

# Create user
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get -y install sudo
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
USER docker

WORKDIR "/home/docker/"
