#!/usr/bin/env bash
# Docker installation script

# --------------------------------------------------------------------------
# Docker CE install
# https://docs.docker.com/engine/installation/linux/ubuntu/#install-using-the-repository
# --------------------------------------------------------------------------

#----------------------
# SET UP THE REPOSITORY
#----------------------

# 1 Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install \
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
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

#----------------------
# INSTALL DOCKER 
#----------------------
sudo apt-get update
sudo apt-get install docker-ce
sudo docker run hello-world

#----------------------
# Manage Docker as a non-root user 
#----------------------

sudo groupadd docker
sudo usermod -aG docker $USER

#----------------------
# Ubuntu distributions 
#----------------------
# Install nvidia-docker and nvidia-docker-plugin
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb

# Test nvidia-smi
sudo nvidia-docker run --rm nvidia/cuda nvidia-smi
