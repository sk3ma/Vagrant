#!/usr/bin/env bash

##############################################################################
# The purpose of the script is to automate a monitoring solution on Ubuntu.  #
# The script installs and configures Prometheus, Grafana, and Node Exporter. #
##############################################################################

# Declaring variables.
USERID=$(id -u)
IPADDR=192.168.56.55

# Sanity checking.
if [[ ${USERID} -ne "0" ]]; then
    echo -e "\e[31;1;3m[✗] You must be root, exiting.\e[m"
    exit 1
fi

# Prometheus configuration.
config() {
    echo -e "\e[32;1;3m[INFO] Configuring Prometheus\e[m"
    mkdir -vp /opt/prometheus
    cd /opt/prometheus
    tee prometheus.yml << STOP > /dev/null
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
    echo -e "\e[32;1;3m[INFO] Container: Prometheus\e[m"
    docker pull prom/prometheus:latest
    docker run -d \
    --name prometheus \
    -p ${IPADDR}:9090:9090 \
    -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:latest
}

# Node Exporter.
node() {
    echo -e "\e[32;1;3m[INFO] Container: Node Exporter\e[m"
    docker pull quay.io/prometheus/node-exporter:latest
    docker run -d \
    --name node-exporter \
    -p ${IPADDR}:9100:9100 \
    quay.io/prometheus/node-exporter:latest
}

# Grafana Docker.
graf() {
    echo -e "\e[32;1;3m[INFO] Container: Grafana\e[m"
    docker pull grafana/grafana:latest
    docker run -d \
    --name grafana \
    -p ${IPADDR}:3000:3000 grafana/grafana:latest
}

# Portainer agent.
agent() {
    echo -e "\e[32;1;3m[INFO] Downloading agent\e[m"
    docker pull portainer/portainer/agent:latest
    docker run -d  \
    -p ${IPADDR}:9001:9001 \
    --name portainer_agent \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
    echo -e "\e[33;1;3m[INFO] Portainer agent - http://${IPADDR}:9001/login\e[m"
    echo -e "\e[33;1;3mP[INFO] Prometheus access - http://${IPADDR}:9090/targets\e[m"
    echo -e "\e[33;1;3m[INFO] Node exporter - http://${IPADDR}:9100/metrics\e[m"
    echo -e "\e[33;1;3m[INFO] Grafana access - http://${IPADDR}:3000/login\e[m"
    exit
}

# Defining function.
main() {
    config
    prom
    node
    graf
    agent
}

# Calling function.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[35;1;3;5m[OK] Ubuntu detected, proceeding...\e[m"
    main
fi
