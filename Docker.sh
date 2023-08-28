#!/usr/bin/env bash

################################################################################
# The purpose of the script is to automate a Docker installation on Ubuntu.    #       
# The script installs Docker, creates a volume, and executes a Grafana script. #
################################################################################

# Declaring variables.
DISTRO=$(lsb_release -ds)
VERSION=$(lsb_release -cs)
USERID=$(id -u)

# Sanity checking.
if [[ ${USERID} -ne "0" ]]; then
    echo -e "\e[31;1;3m[✗] You must be root, exiting.\e[m"
    exit 1
fi

# Docker installation.
install() {
    echo -e "\e[96;1;3m[OK] Distribution: ${DISTRO}\e[m"
    echo -e "\e[32;1;3m[INFO] Updating system\e[m"
    apt update
    echo -e "\e[32;1;3mAdding repository\e[m"
    apt install apt-transport-https ca-certificates software-properties-common curl -qy
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${VERSION} stable" -y
    echo -e "\e[32;1;3m[INFO] Installing Docker\e[m"
    apt install docker-ce docker-ce-cli containerd.io -qy
    usermod -aG docker ${USER}
    chmod a=rw /var/run/docker.sock
}

# Docker configuration.
config() {
    echo -e "\e[32;1;3m[INFO] Testing Docker\e[m"
    docker pull docker/whalesay:latest
    docker run docker/whalesay:latest cowsay "Docker is functional."
    echo -e "\e[32;1;3m[INFO] Creating volume\e[m"
    mkdir -pv /container
    docker volume create bindmount
}

# Enabling service.
service() {
    echo -e "\e[32;1;3m[INFO] Starting Docker\e[m"
    systemctl start docker
    systemctl enable docker
}

# Grafana script.
script() {    
    echo -e "\e[33;1;3;5m[INFO] Executing Grafana script...\e[m"
    source /vagrant/Grafana.sh
}
      
# Defining function.
main() {
    install
    config
    service
    script
}

# Calling function.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[35;1;3;5m[OK] Ubuntu detected, proceeding...\e[m"
    main
fi
