# NVIDIA DL Docker
Container for Deep Learning with built-in Jupyter/Tensorboard and latest DL Frameworks

# Specification
- Ubuntu 16.04
- Python 3.5
- CUDA 9.0
- CuDNN 7.x
- Tensorflow 1.9.0
- PyTorch 0.4.0
- Keras (latest)
- Tensorboard
- Jupyter
- ...other useful packages

# Quickstart
- Clone this repository
<br/>`git clone https://github.com/lucidyan/ml-docker`

- Install NVIDIA-Docker
<br/>`cd ml-docker; sudo chmod a+x nvidia_docker_install.sh; sudo ./nvidia_docker_install.sh`

- Reboot system after Docker installation (neccessary for running Docker without sudo rights)

- Build the image
<br/>`docker build -t "lucidyan/ml-docker:1.3" .`

- Run it with command
<br/>`python3 run_docker_jupyter.py -pj 8888 -pt 6006`
<br/> where `8888` and `6006` your local unoccupied ports for Jupyter and Tensorboard respectively
