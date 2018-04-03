FROM nvidia/cuda:9.0-cudnn7-runtime-ubuntu16.04

LABEL maintainer="Craig Citro <craigcitro@google.com>"

# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python3.5 \
        python3.5-dev \
        rsync \
        software-properties-common \
        unzip \
        && \
    apt-get clean

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
        && \
    python3 -m ipykernel.kernelspec

# --- DO NOT EDIT OR DELETE BETWEEN THE LINES --- #
# These lines will be edited automatically by parameterized_docker_build.sh. #
# COPY _PIP_FILE_ /
# RUN pip3 --no-cache-dir install /_PIP_FILE_
# RUN rm -f /_PIP_FILE_

# Install TensorFlow GPU version.
RUN pip3 --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.7.0-cp35-cp35m-linux_x86_64.whl
# --- ~ DO NOT EDIT OR DELETE BETWEEN THE LINES --- #

#################################################################
# CUSTOM SECTION START
#################################################################
# Additional Software
RUN apt-get install -y \
	git

# Additional Python packages
RUN pip3 --no-cache-dir install \
        seaborn \
        plotly \
        opencv-python \
        statsmodels \
        tqdm \
        pydot \
	scikit-image \
	watermark \
	opencv-python \
    && python3 -m ipykernel.kernelspec

# Keras
RUN pip3 --no-cache-dir install git+git://github.com/fchollet/keras.git

# PyTorch
RUN pip3 install http://download.pytorch.org/whl/cu90/torch-0.3.1-cp35-cp35m-linux_x86_64.whl 
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

# LightGBM python wrapper
RUN cd /usr/local/src/LightGBM/python-package && python3 setup.py install

#################################################################
# CUSTOM SECTION END
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
