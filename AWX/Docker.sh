#!/usr/bin/env bash

# Declaring variables.
DISTRO=$(lsb_release -ds)
VERSION=$(lsb_release -cs)

# Docker installation.
install() {
    echo -e "\e[96;1;3m[INFO] Distribution: ${DISTRO}\e[m"
    echo
    echo -e "\e[32;1;3m[INFO] Adding repository\e[m"
    apt install apt-transport-https ca-certificates software-properties-common curl -qy
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${VERSION} stable" -y
    echo -e "\e[32;1;3m[INFO] Installing Docker\e[m"
    apt install docker-ce docker-ce-cli docker-compose containerd.io -qy
    usermod -aG docker ${USER}
    chmod a=rw /var/run/docker.sock
    echo -e "\e[32;1;3m[INFO] Creating volume\e[m"
    mkdir -vp /container
    docker volume create bindmount
}

# Enabling service.
service() {
    echo -e "\e[32;1;3m[INFO] Starting service\e[m"
    systemctl start docker
    systemctl enable docker
    echo -e "\e[36;1;3;5m[INFO] Executing Minikube script...\e[m"
}

# Defining function.
main() {
    install
    service
}

# Calling function.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[35;1;3;5m[OK] Ubuntu detected, proceeding...\e[m"
    main
fi
