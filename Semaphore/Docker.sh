#!/usr/bin/env bash

# Declaring variables.
DISTRO=$(lsb_release -ds)
VERSION=$(lsb_release -cs)

# Sanity checking.
if [[ ${USERID} -ne "0" ]]; then
    echo -e "\e[32;1;3;5m[❌] You must be root, exiting\e[m"
    exit 1
fi

# Docker installation.
install() {
    echo -e "\e[96;1;3m[INFO] Distribution: ${DISTRO}\e[m"
    echo
    echo -e "\e[32;1;3m[INFO] Updating system\e[m"
    apt update
    echo -e "\e[32;1;3m[INFO] Adding repository\e[m"
    apt install apt-transport-https ca-certificates software-properties-common curl -qy
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${VERSION} stable" -y
    echo -e "\e[32;1;3m[INFO] Installing Docker\e[m"
    apt install docker-ce docker-ce-cli docker-compose containerd.io -qy
    usermod -aG docker ${USER}
    chmod a=rw /var/run/docker.sock
    echo -e "\e[32;1;3m[INFO] Creating volume\e[m"
    mkdir -pv /container
    docker volume create bindmount
}

# Enabling service.
service() {
    echo -e "\e[32;1;3m[INFO] Testing Docker\e[m"
    docker pull docker/whalesay:latest
    docker run docker/whalesay:latest cowsay "Docker is functional."
    echo -e "\e[32;1;3m[INFO] Starting service\e[m"
    echo "
  ____             _             
 |  _ \  ___   ___| | _____ _ __ 
 | | | |/ _ \ / __| |/ / _ \ '__|
 | |_| | (_) | (__|   <  __/ |   
 |____/ \___/ \___|_|\_\___|_|  
                                 "
    systemctl start docker
    systemctl enable docker
}

# Docker Compose.
compose() {
    echo -e "\e[32;1;3m[INFO] Executing file up\e[m"
    docker-compose -f docker-compose.yml up -d
    echo -e "\e[33;1;3;5m[✅] Finished, Docker installed.\e[m"
    exit
}

# Defining function.
main() {
    install
    service
    compose
}

# Calling function.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[38;5;208;1;3;5m[OK] Ubuntu detected, proceeding...\e[m"
    main
fi
