#!/usr/bin/env bash

##############################################################################
# The purpose of the script is to automate a monitoring solution on Ubuntu.  #
# The script installs and configures Prometheus, Grafana, and Node Exporter. #
##############################################################################

# Declaring variables.
DISTRO=$(lsb_release -ds)
USERID=$(id -u)
IPADDR=192.168.33.55

# Sanity checking.
if [[ ${USERID} -ne "0" ]]; then
    echo -e "\e[1;3mYou must be root, exiting.\e[m"
    exit 1
fi

# Prometheus configuration.
config() {
    echo -e "\e[1;3mDistribution: ${DISTRO}\e[m"
    echo -e "\e[1;3mConfiguring Prometheus\e[m"
    mkdir -vp /opt/prometheus
    cd /opt/prometheus
    tee prometheus.yml << STOP
global:
  scrape_interval: 5s
  external_labels: 
    monitor: 'node'
# Linux servers
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['${IPADDR}:9090']
        labels:
          alias: localhost
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['${IPADDR}:9100']
        labels:
          alias: localhost
STOP
}

# Prometheus Docker.
prom() {
    echo -e "\e[1;3mCreating Prometheus\e[m"
    docker pull prom/prometheus:latest
    docker run -d \
    --name prometheus \
    -p 9090:9090 \
    -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:latest
}

# Node Exporter.
node() {
    echo -e "\e[1;3mCreating Node Exporter\e[m"
    docker pull quay.io/prometheus/node-exporter:latest
    docker run -d \
    --name node-exporter \
    -p 9100:9100 \
    quay.io/prometheus/node-exporter:latest
}

# Grafana Docker.
graf() {
    echo -e "\e[1;3mCreating Grafana\e[m"
    docker pull grafana/grafana:latest
    docker run -d \
    --name grafana \
    -p 3000:3000 grafana/grafana:latest
}

# Portainer agent.
agent() {
    echo -e "\e[1;3mDownloading agent\e[m"
    docker pull portainer/portainer/agent:latest
    docker run -d  \
    -p ${IPADDR}:9001:9001 \
    --name portainer_agent \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
    echo -e "\e[1;3mPortainer agent - http://${IPADDR}:9001/login\e[m"
    echo -e "\e[1;3mPrometheus access - http://${IPADDR}:9090/targets\e[m"
    echo -e "\e[1;3mNode Exporter - http://${IPADDR}:9100/metrics\e[m"
    echo -e "\e[1;3mGrafana access - http://${IPADDR}:3000/login\e[m"
    exit
}

# Calling functions.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[1;3;5mUbuntu detected, proceeding...\e[m"
    config
    prom
    node
    graf
    agent
fi
