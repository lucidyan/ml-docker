#!/usr/bin/env bash
# NVIDIA-Docker installation script

# --------------------------------------------------------------------------
# Docker CE install
# https://docs.docker.com/engine/installation/linux/ubuntu/#install-using-the-repository
# --------------------------------------------------------------------------

#----------------------
# SET UP THE REPOSITORY
#----------------------

# 1 Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# 2 Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 3 Verify that the key fingerprint is 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88
sudo apt-key fingerprint 0EBFCD88

# 4 Use the following command to set up the stable repository. You always 
# need the stable repository, even if you want to install edge builds as well.
sudo add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

#----------------------
# INSTALL DOCKER 
#----------------------
sudo apt-get update
sudo apt-get install -y docker-ce
sudo docker run hello-world

#----------------------
# Manage Docker as a non-root user 
#----------------------

sudo groupadd docker
sudo usermod -aG docker $USER

# --------------------------------------------------------------------------
# NVIDIA-Docker install
# https://github.com/NVIDIA/nvidia-docker#ubuntu-140416041804-debian-jessiestretch
# --------------------------------------------------------------------------

# If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
sudo apt-get purge -y nvidia-docker

# Add the package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-docker2 and reload the Docker daemon configuration
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Test nvidia-smi with the latest official CUDA image
sudo docker run --gpus all nvidia/cuda:10.0-base nvidia-smi
