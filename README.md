# NVIDIA DL Docker
Image for Deep Learning with built-in Jupyter/Tensorboard and latest DL Frameworks

# Requirements
- Ubuntu 18.04

# Environment
- CUDA Toolkit 10.0
- CuDNN 7.x
- NCCL 2
- Docker
- NVIDIA-Docker 2

# Packages
- Python 3.7
- Tensorflow 1.14.0
- PyTorch 1.1.0
- Keras
- Tensorboard
- Jupyter
- ...other useful packages

# Quickstart
- Clone this repository
<br/>`git clone https://github.com/lucidyan/ml-docker`

- Install CUDA-10
<br/>
- Old instruction: https://gist.github.com/bogdan-kulynych/f64eb148eeef9696c70d485a76e42c3a
- New instruction: https://gist.github.com/Mahedi-61/2a2f1579d4271717d421065168ce6a73

- Install NVIDIA-Docker
<br/>`cd ml-docker; sudo chmod a+x nvidia_docker_install.sh; sudo ./nvidia_docker_install.sh`

- Reboot system after Docker installation (necessary for running Docker without sudo rights)

- Build the image
<br/>`docker build --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) --tag "lucidyan/ml-docker:20.02.1" ." .`

- Run it with command
<br/>`python3 run_docker_jupyter.py -pj 8888 -pt 6006`
<br/> where `8888` and `6006` your local unoccupied ports for Jupyter and Tensorboard respectively
