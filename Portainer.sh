#!/usr/bin/env bash

#############################################################################
# The purpose of the script is to automate a Docker installation on Ubuntu. #
# The script installs Docker, downloads Portainer and creates an exception. #
#############################################################################

# Declaring variables.
DISTRO=$(lsb_release -ds)
USERID=$(id -u)
IPADDR=192.168.56.74

# Sanity checking.
if [[ ${USERID} -ne "0" ]]; then
    echo -e "\e[31;1;3m[❌] You must be root, exiting.\e[m"
    exit 1
fi

# Docker installation.
install() {
    echo -e "\e[96;1;3m[OK] Distribution: ${DISTRO}\e[m"
    echo
    cat << STOP
#--------------------#
# Welcome to Ubuntu. #
#--------------------#
                    ##        .            
              ## ## ##       ==            
           ## ## ## ##      ===            
       /""""""""""""""""\___/ ===        
  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
       \______ o          __/            
         \    \        __/             
          \____\______/                    
STOP
    echo
    echo -e "\e[32;1;3m[INFO] Updating system\e[m"
    apt update
    echo -e "\e[32;1;3m[INFO] Adding repository\e[m"
    apt install apt-transport-https ca-certificates software-properties-common curl -qy
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" -y
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
    echo -e "\e[32;1;3m[INFO] Starting service\e[m"
    systemctl start docker
    systemctl enable docker
}

# Firewall creation.
fwall() {
    echo -e "\e[32;1;3m[INFO] Adjusting firewall\e[m"
    ufw allow 80/tcp
    ufw allow 8080,9000/tcp
    echo "y" | ufw enable
    ufw reload
}

# Nginx container.
nginx() {
    echo -e "\e[32;1;3m[INFO] Downloading Nginx\e[m"
    docker pull nginx:latest
    docker run -d                                   \
    -p ${IPADDR}:80:80                              \
    --name nginx                                    \
    --restart=always                                \
    -v /usr/share/nginx/html:/usr/share/nginx/html  \
    nginx:latest
}

# Portainer container.
portainer() {
    echo -e "\e[32;1;3m[INFO] Downloading Portainer\e[m"
    docker pull portainer/portainer-ce:latest
    docker run -d                                \
    -p ${IPADDR}:9000:9000                       \
    --name portainer                             \
    --restart=always                             \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /container:/data portainer/portainer-ce:latest
}

# cAdvisor container.
cadvisor() {
    echo -e "\e[32;1;3m[INFO] Downloading cAdvisor\e[m"
    docker pull gcr.io/cadvisor/cadvisor:latest
    docker run -d                                \
    -p ${IPADDR}:8080:8080                       \
    --name cadvisor                              \
    --restart=always                             \
    -v /:/rootfs:ro                              \
    -v /var/run:/var/run:rw                      \
    -v /sys:/sys:ro                              \
    -v /var/lib/docker/:/var/lib/docker:ro       \
    gcr.io/cadvisor/cadvisor:latest
    echo -e "\e[33;1;3;5m[INFO] Finished, Docker installed.\e[m"
 
# Defining function.
main() {
    install
    config
    service
    fwall
    nginx
    portainer
    cadvisor
}

# Calling function.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[35;1;3;5m[OK] Ubuntu detected, proceeding...\e[m"
    main
    exit
fi
