#! /bin/bash

# master

sudo apt update
sudo apt install -y nfs-kernel-server

sudo mkdir -p /export
sudo chmod -R 777 /export

# sudo nano /etc/exports
#/export 10.121.124.0/24(rw,async,no_root_squash,no_subtree_check)
sudo systemctl enable nfs-server
sudo systemctl restart nfs-server

# worker
sudo apt install nfs-common

#(edit /etc/fstab)
#10.121.124.21:/export    /export     nfs4 soft,intr,bg,timeo=600  0 0
sudo mkdir -p /export
sudo chmod -R 777 /export
sudo systemctl daemon-reload
sudo mount -a


# k8s

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

kubectl create ns nfs-storage

helm install nfs-client nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-storage \
  --set nfs.server=10.121.124.21 \
  --set nfs.path=/export \
  --set storageClass.name=nfs-sc \
  --set storageClass.defaultClass=true \
  --set storageClass.parameters.folderAnnotation=true