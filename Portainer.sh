#!/usr/bin/env bash

#############################################################################
# The purpose of the script is to automate a Docker installation on Ubuntu. #          
# The script installs Docker, downloads Portainer and creates a container.  # 
#############################################################################

# Declaring variables.
DISTRO=$(lsb_release -ds)
USERID=$(id -u)
IPADDR=192.168.33.70

# Sanity checking.
if [[ ${USERID} -ne "0" ]]; then
    echo -e "\e[31;1;3mYou must be root, exiting.\e[m"
    exit 1
fi

# Docker installation.
install() {
    echo -e "\e[96;1;3mDistribution: ${DISTRO}\e[m"
    echo -e "\e[32;1;3mUpdating system\e[m"
    apt update
    echo -e "\e[32;1;3mAdding repository\e[m"
    apt install apt-transport-https ca-certificates software-properties-common curl -qy
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" -y
    echo -e "\e[32;1;3mInstalling Docker\e[m"
    apt install docker-ce docker-ce-cli containerd.io -qy
    usermod -aG docker ${USER}
}

# Docker configuration.
config() {
    echo -e "\e[32;1;3mTesting Docker\e[m"
    docker pull docker/whalesay:latest
    docker run docker/whalesay:latest cowsay "Docker is functional."
    echo -e "\e[32;1;3mCreating volume\e[m"
    mkdir -pv /container
    docker volume create bindmount
}

# Enabling service.
service() {
    echo -e "\e[32;1;3mStarting service\e[m"
    systemctl start docker
    systemctl enable docker
}

# Firewall creation.
firewall() {
    echo -e "\e[32;1;3mAdjusting firewall\e[m"
    ufw allow 9000/tcp
    echo "y" | ufw enable
    ufw reload
}

# Downloading Portainer.
portainer() {
    echo -e "\e[32;1;3mDownloading Portainer\e[m"
    docker pull portainer/portainer-ce:latest
    docker run -d \
    -p ${IPADDR}:9000:9000 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /container:/data portainer/portainer-ce:latest
    echo -e "\e[33;1;3;5mPortainer access - http://${IPADDR}:9000\e[m"
    exit
}
    
# Calling functions.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[33;1;3;5mUbuntu detected, proceeding...\e[m"
    install
    config
    service
    firewall
    portainer
fi
