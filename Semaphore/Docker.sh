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
    mkdir -p /container
    docker volume create bindmount
}

# Enabling service.
service() {
    echo -e "\e[32;1;3m[INFO] Testing Docker\e[m"
    docker pull mbentley/cowsay
    docker run -it --rm mbentley/cowsay "Docker is functional."
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
    echo -e "\e[32;1;3m[INFO] Creating file up\e[m"
    tee /opt/docker-compose.yml << STOP > /dev/null
version: "3"

services:
  mysql:
    restart: unless-stopped
    image: mysql:8.0
    hostname: mysql
    volumes:
      - semaphore-mysql:/var/lib/mysql
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"
      MYSQL_DATABASE: semaphore
      MYSQL_USER: semaphore
      MYSQL_PASSWORD: semaphore
  semaphore:
    restart: unless-stopped
    ports:
      - 3000:3000
    image: semaphoreui/semaphore:latest
    environment:
      SEMAPHORE_ACCESS_KEY_ENCRYPTION: QfWtJhFYtIcAOFDbbZjpk9hFMobxY0WZf4o1PKnRQKI=
      SEMAPHORE_ADMIN: osadmin
      SEMAPHORE_ADMIN_EMAIL: admin@semaphore.local
      SEMAPHORE_ADMIN_NAME: osadmin
      SEMAPHORE_ADMIN_PASSWORD: BOPZ3GQ=
      SEMAPHORE_DB: semaphore
      SEMAPHORE_DB_DIALECT: mysql
      SEMAPHORE_DB_HOST: mysql
      SEMAPHORE_DB_PASS: semaphore
      SEMAPHORE_DB_PORT: 3306
      SEMAPHORE_DB_USER: semaphore
      SEMAPHORE_LDAP_ACTIVATED: "no"
      SEMAPHORE_LDAP_DN_SEARCH: "uid=bind_user,cn=users,cn=accounts,dc=local,dc=shiftsystems,dc=net"
      SEMAPHORE_LDAP_HOST: dc01.local.example.com
      SEMAPHORE_LDAP_NEEDTLS: "yes"
      SEMAPHORE_LDAP_PASSWORD: "<ldap_bind_password>"
      SEMAPHORE_LDAP_PORT: "636"
      SEMAPHORE_LDAP_SEARCH_FILTER: "(\u0026(uid=%s)(memberOf=cn=ipausers,cn=groups,cn=accounts,dc=local,dc=example,dc=com))"
      SEMAPHORE_PLAYBOOK_PATH: /tmp/semaphore/
      ANSIBLE_HOST_KEY_CHECKING: "False"
    depends_on:
      - mysql
volumes:
  semaphore-mysql:
STOP
    echo -e "\e[32;1;3m[INFO] Executing file\e[m"
    docker-compose -f /opt/docker-compose.yml up -d
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
