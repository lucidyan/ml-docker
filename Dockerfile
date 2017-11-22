# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.gpu
FROM nvidia/cuda:8.0-cudnn6-runtime-ubuntu16.04

MAINTAINER Craig Citro <craigcitro@google.com>

# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
	    apt-utils \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python3.5 \
        python3.5-dev \
        python-distribute \
        rsync \
        software-properties-common \
        unzip \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

RUN pip3 --no-cache-dir install \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        scipy \
        scikit-learn \
        pandas \
        Pillow \

        seaborn \
        plotly \
        opencv-python \
        statsmodels \
        tqdm \
        pydot \
    && python3 -m ipykernel.kernelspec

# Facebook Prophet
RUN pip3 --no-cache-dir install \
        pystan \
        Cython \
        fbprophet

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

# LightGBM python wrapper
RUN cd /usr/local/src/LightGBM/python-package && python3 setup.py install

# Install TensorFlow GPU version.
#RUN pip3 --no-cache-dir install tensorflow_gpu-1.4.0-cp35-cp35m-manylinux1_x86_64.whl
RUN pip3 install tensorflow-gpu==1.4.0

# Set up our notebook config.
COPY jupyter_notebook_config.py /root/.jupyter/

# Copy sample notebooks.
COPY notebooks /notebooks

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /
RUN chmod a+x run_jupyter.sh

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

#pytorch
RUN echo `nvcc --version`
RUN ls /usr/local/cuda/
ENV CUDA_TOOLKIT_ROOT_DIR /usr/local/cuda
RUN git clone --recursive https://github.com/pytorch/pytorch
# RUN cd pytorch && git rm -r --cached * && git checkout 0b92e5c9ed1b62e695b10167f87621bbbcf0fc86 && python3 setup.py install
RUN cd pytorch && python3 setup.py install

# Final setup: directories, permissions, ssh login, symlinks, etc
RUN mkdir -p /home/user
WORKDIR "/home/user"
# WORKDIR "/notebooks"

CMD ["/run_jupyter.sh", "--allow-root"]
