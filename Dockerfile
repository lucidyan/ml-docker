FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
LABEL maintainer="lucidyan"

#################################################################
# System packages
#################################################################
RUN apt-get update && \
        apt-get install -y --no-install-recommends \
        apt-utils

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libncurses5-dev \
        libjpeg8 \
        libjpeg62-dev \
        libfreetype6 \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python3.5 \
        python3.5-dev \
        libpython3-dev \
        rsync \
        software-properties-common \
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
        Pillow \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy\
        pandas \
        scipy \
        sklearn \
        seaborn \
        plotly \
        opencv-python \
        tqdm \
        pydot \
        scikit-image \
        opencv-python \
        Cython \
    && \
    python3 -m ipykernel.kernelspec

# XGBoost python wrapper
RUN cd xgboost/python-package; python3 setup.py install && cd ../..

# LightGBM
RUN apt-get -y install cmake
RUN cd /usr/local/src && git clone --recursive --depth 1 https://github.com/Microsoft/LightGBM && \
    cd LightGBM && mkdir build && cd build && cmake .. && make -j$(nproc)
RUN cd /usr/local/src/LightGBM/python-package && python3 setup.py install

# Install TensorFlow GPU version.
RUN pip3 --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.9.0-cp35-cp35m-linux_x86_64.whl

# Keras
RUN pip3 --no-cache-dir install git+git://github.com/fchollet/keras.git

# PyTorch
RUN pip3 --no-cache-dir install http://download.pytorch.org/whl/cu90/torch-0.4.0-cp35-cp35m-linux_x86_64.whl
RUN pip3 --no-cache-dir install torchvision

#################################################################
# Setup container
#################################################################
# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

# Create user
RUN apt-get -y install sudo
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
USER docker

WORKDIR "/home/docker/"
