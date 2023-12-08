#!/usr/bin/env bash

#######################################################################
# This script automates the installation of Minikube on Ubuntu 22.04. #
# It sets up a single-node cluster and deploys AWX pods within it.    #
# To access the AWX web frontend, forward pod traffic to localhost.   #
# Use the provided password, and use 'admin' as the username.         #
# Access the AWX web frontend at `http://<HOST_IP>:<NODE_PORT>`.      #
#######################################################################

# Operator version.
AWX_OP_VSN="2.7.0"

# Install Minikube.
install_minikube() {
    echo -e "\e[32;1;3m[INFO] Installing Minikube\e[m"
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    minikube start --cpus=2 --memory=4g --addons=ingress
}

# AWX operator.
awx_operator() {
    echo -e "\e[32;1;3m[INFO] Playbook path\e[m"
    sudo mkdir -vp /var/lib/awx/projects
    cd /tmp
    cat << STOP > /tmp/kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=${AWX_OP_VSN}
images:
  - name: quay.io/ansible/awx-operator
    newTag: ${AWX_OP_VSN}
namespace: awx
STOP
    echo -e "\e[32;1;3m[INFO] Applying configuration\e[m"
    minikube kubectl -- apply -k .
    minikube kubectl -- config set-context --current --namespace=awx
}

# AWX deployment.
configure_awx() {
    echo -e "\e[32;1;3m[INFO] AWX deployment\e[m"
    cat << STOP > awx-server.yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-server
spec:
  service_type: nodeport
STOP
    echo -e "\e[32;1;3m[INFO] Creating configuration\e[m"
    rm kustomization.yaml
    cat << STOP > kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=${AWX_OP_VSN}
  - awx-server.yaml
images:
  - name: quay.io/ansible/awx-operator
    newTag: ${AWX_OP_VSN}
namespace: awx
STOP
    echo -e "\e[32;1;3m[INFO] Updating configuration\e[m"
    minikube kubectl -- apply -k .
    echo -e "\e[32;1;3m[INFO] Initializing pods\e[m"
    while [[ $(minikube kubectl -- get po -n awx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' | tr ' ' '\n' | sort | uniq) != "True" ]]; do
        sleep 30
    done
}

# Show progress.
show_status() {
    echo -e "\e[32;1;3m[INFO] Minikube status\e[m"
    echo "
   __  ________  ________ ____  _____  ____
  /  |/  /  _/ |/ /  _/ //_/ / / / _ )/ __/
 / /|_/ // //    // // ,< / /_/ / _  / _/  
/_/  /_/___/_/|_/___/_/|_|\____/____/___/  
                                          "
    minikube status | grep -i running
    echo -e "\e[32;1;3m[INFO] Cluster status\e[m"
    minikube kubectl -- cluster-info
    echo -e "\e[32;1;3m[INFO] Deployment status\e[m"
    minikube kubectl -- get deploy
    echo -e "\e[32;1;3m[INFO] Pods status\e[m"
    minikube kubectl -- get ns | egrep 'awx|ingress'
    minikube kubectl -- get no
    minikube kubectl -- get po -n awx
    echo -e "\e[32;1;3m[INFO] AWX service\e[m"
    minikube kubectl -- get svc | grep awx-server-service
}

# Post steps.
post_steps() {
    trap 'echo -e "\e[33;1;3;5m[INFO] Please execute the below commands once the script ends:\e[m"; \
          echo "[INFO] node_port=$(minikube kubectl -- get svc awx-server-service -o jsonpath="{.spec.ports[0].nodePort}")"; \
          echo "$ minikube kubectl -- get secret awx-server-admin-password -o jsonpath="{.data.password}" | base64 --decode; echo"; \
          echo "$ minikube kubectl -- port-forward service/awx-server-service --address 0.0.0.0 \$node_port:80";' EXIT
}

# Execute functions.
install_minikube
awx_operator
configure_awx
show_status
post_steps

# End script.
exit
