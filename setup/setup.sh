#! /bin/bash

# close swap space
sudo swapoff -a

# install ssh
sudo apt-get install openssh-server

sudo apt-get update
sudo apt-get install -y docker.io

# cri-dockerd

wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.18/cri-dockerd-0.3.18.amd64.tgz
tar -xvf cri-dockerd-0.3.18.amd64.tgz 
cd cri-dockerd

sudo su
install -o root -g root -m 0755 cri-dockerd /usr/local/bin/cri-dockerd

sudo tee /etc/systemd/system/cri-docker.service > /dev/null << 'EOF'
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network.target docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/cri-dockerd --container-runtime-endpoint=unix:///var/run/dockershim.sock
Restart=always
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/cri-docker.socket > /dev/null << 'EOF'
[Unit]
Description=CRI Docker Socket for the API

[Socket]
ListenStream=/var/run/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

exit

# install kubeadm

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


# install helm

wget https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz
tar -xvf helm-v3.18.3-linux-amd64.tar.gz 
cd linux-amd64