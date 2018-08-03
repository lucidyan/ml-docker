FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
LABEL maintainer "lucidyan"

#################################################################
# cuDNN manual install
#
# Replace previous section with this only if you need
# SPECIFIC cuDNN version!
#################################################################
# FROM nvidia/cuda:9.0-devel-ubuntu16.04
# ENV CUDNN_VERSION 7.1.4.18
# LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"
#
# RUN apt-get update && apt-get install -y --no-install-recommends \
#             libcudnn7=$CUDNN_VERSION-1+cuda9.0 && \
#    apt-mark hold libcudnn7 && \
#    rm -rf /var/lib/apt/lists/*

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
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py && \
    pip3 install --upgrade pip

RUN pip3 --no-cache-dir install \
        Pillow \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        pandas \
        scipy \
        sklearn \
        seaborn \
        plotly \
        opencv-python \
        statsmodels \
        tqdm \
        pydot \
        scikit-image \
        opencv-python \
        Cython \
    && \
    python3 -m ipykernel.kernelspec

# Install TensorFlow GPU version.
RUN pip3 --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.9.0-cp35-cp35m-linux_x86_64.whl

# Keras
RUN pip3 --no-cache-dir install git+git://github.com/fchollet/keras.git

# PyTorch
RUN pip3 install http://download.pytorch.org/whl/cu90/torch-0.4.0-cp35-cp35m-linux_x86_64.whl 
RUN pip3 install torchvision

# XGBoost
RUN apt-get update && apt-get -y install libboost-program-options-dev zlib1g-dev libboost-python-dev
RUN git clone --recursive https://github.com/dmlc/xgboost && \
    cd xgboost \
    && make -j$(nproc)

# XGBoost python wrapper
RUN cd xgboost/python-package; python3 setup.py install && cd ../..

# LightGBM
RUN apt-get -y install cmake 
RUN cd /usr/local/src && git clone --recursive --depth 1 https://github.com/Microsoft/LightGBM && \
    cd LightGBM && mkdir build && cd build && cmake .. && make -j$(nproc) 
RUN cd /usr/local/src/LightGBM/python-package && python3 setup.py install

#################################################################
# Setup container
#################################################################

# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# Copy sample notebooks.
COPY notebooks /notebooks

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

WORKDIR "/notebooks"

CMD ["/run_jupyter.sh", "--allow-root"]
