FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

LABEL maintainer="lucidyan"

# debconf: delaying package configuration, since apt-utils is not installed
ENV DEBIAN_FRONTEND=noninteractive
#################################################################
# System packages
#################################################################
# Python
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
	# debconf: delaying package configuration, since apt-utils is not installed
        apt-utils \
        # add-apt-repository
        software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get install -y --no-install-recommends \
	python3.7 \
	python3.7-dev \
    && update-alternatives --install /usr/bin/python3 python3.7 /usr/bin/python3.7 0 \
    && python3 --version

# Neccessary system packages
RUN apt-get install -y --no-install-recommends \
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
    && apt-get clean

# CMake
RUN export CMAKE_FILENAME=cmake-3.15.0-Linux-x86_64.sh \
	&& wget https://cmake.org/files/v3.15/$CMAKE_FILENAME -O /tmp/$CMAKE_FILENAME -q \
	&& apt-get remove --purge --auto-remove cmake -y \
	&& mkdir /opt/cmake \
	&& sh /tmp/$CMAKE_FILENAME --prefix=/opt/cmake --skip-license && rm /tmp/$CMAKE_FILENAME \
	&& ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
	&& cmake --version

##################################################################
## Python packages
##################################################################
# PIP
RUN apt-get install -y --no-install-recommends \
	python3-pip \
    && curl -O https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py \
    && rm get-pip.py \
    && pip3 install --upgrade pip

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
    && python3 -m ipykernel.kernelspec \
    && jupyter nbextension enable --py widgetsnbextension


# XGBoost python wrapper
RUN cd /usr/local/src && git clone --recursive https://github.com/dmlc/xgboost \
    && cd xgboost \
    && mkdir build && cd build \
    && cmake .. -DUSE_CUDA=ON -DUSE_NCCL=ON -DNCCL_ROOT=/usr/local/nccl-{$NCCL_VERSION} \
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
RUN pip3 --no-cache-dir install \
	https://download.pytorch.org/whl/cu100/torch-1.1.0-cp37-cp37m-linux_x86_64.whl \
        https://download.pytorch.org/whl/cu100/torchvision-0.3.0-cp37-cp37m-linux_x86_64.whl

# Install TensorFlow GPU version with Keras
RUN pip3 --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.14.0-cp37-cp37m-linux_x86_64.whl \
    keras

RUN pip3 --no-cache-dir install \
    albumentations 

RUN git clone https://github.com/rflamary/POT && \
    cd POT && \
    python3 setup.py install

RUN pip3 --no-cache-dir install \
    # POT \
    pymanopt \
    autograd


RUN git clone https://github.com/cudamat/cudamat.git && \
    cd cudamat && \
    python3 setup.py install

RUN python3 -c 'import ot'

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

# ARG USER_ID
# ARG GROUP_ID

## Создать пользователя
#RUN USER_ID=1000 GROUP_ID=1000 \
#    OLD_GROUP_NAME="$(getent group ${GROUP_ID}| cut -d: -f1)" && \
#    OLD_GROUP_ID="$(getent group ${GROUP_ID}| cut -d: -f3)" && \
#    # Магическое число для GID, которое скорее всего не занято другими группами
#    NEW_GROUP_ID=10000 && \
#    if [ "$OLD_GROUP_NAME" ]; then \
#        # Перебиваем существующую группу
#        groupmod -g "$NEW_GROUP_ID" "$OLD_GROUP_NAME" ; \
#        find / -group "$OLD_GROUP_ID" -print 2>/dev/null \
#            | xargs --no-run-if-empty chgrp -h "$NEW_GROUP_ID" ; \
#    fi && \
#    # Создаем/меняем группу с освободившимся GROUP_ID
#    groupmod -g ${GROUP_ID} docker && \
#    usermod -o -u ${USER_ID} docker


USER docker

WORKDIR "/home/docker/"

ENV DEBIAN_FRONTEND=teletype
