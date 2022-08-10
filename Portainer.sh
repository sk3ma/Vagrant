#!/usr/bin/env bash

############################################################################
# The purpose of the script is to automate a Docker installation on Ubuntu #
# The script installs Docker, Portainer server and creates the containers. #
############################################################################

# Declaring variables.
DISTRO=$(lsb_release -ds)
USERID=$(id -u)

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
    usermod -aG docker ${USER} && chmod a=rw /var/run/docker.sock
    echo -e "\e[32;1;3mInstalling Compose\e[m"
    curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}

# Docker configuration.
config() {
    echo -e "\e[32;1;3mTesting Docker\e[m"
    docker pull docker/whalesay:latest
    docker run docker/whalesay:latest cowsay "Docker is functional."
    echo -e "\e[32;1;3mCreating volume\e[m"
    docker volume create container
    echo -e "\e[32;1;3mStarting service\e[m"
    systemctl start docker && systemctl enable docker
}

# Firewall creation.
#firewall() {
#    echo -e "\e[32;1;3mAdjusting firewall\e[m"
#    ufw allow 8000/tcp
#    ufw allow 9443/tcp
#    echo "y" | ufw enable
#    ufw reload
#}

# Portainer server.
server() {
    echo -e "\e[32;1;3mDownloading Portainer\e[m"
    docker pull portainer/portainer-ce:latest
    docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name=portainer \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v container:/data \
    portainer/portainer-ce:latest \
    --restart=unless-stopped
    docker start portainer
}

# Portainer agent.
agent() {
    echo -e "\e[32;1;3mDownloading agent\e[m"
    docker pull portainer/agent:latest
    docker run -d \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes \
    -v /:/host \
    -v container:/data \
    --restart=always \
    -e EDGE=1 \
    -e EDGE_ID=f28a53ea-2fe3-4ddc-b30a-1687d9f12ae4 \
    -e EDGE_KEY=aHR0cDovLzE5Mi4xNjguNTYuNzQ6OTAwMHwxOTIuMTY4LjU2Ljc0OjgwMDB8MzU6NjA6Yjk6MTk6MjM6Njg6MjA6ODc6NzE6N2Y6MjM6OGE6NWE6YzM6NTc6YWZ8Mw \
    -e EDGE_INSECURE_POLL=1 \
    --name=portainer_agent \
    portainer/agent:latest
    docker container ls -a
    echo -e "\e[33;1;3;5mFinished, configure webUI.\e[m"
    exit
}

# Calling functions.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[35;1;3;5mUbuntu detected, proceeding...\e[m"
    install
    config
#    firewall
    server
    agent
fi
