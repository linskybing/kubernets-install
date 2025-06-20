#! /bin/bash

# nvidia 
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

helm install \
  -n gpu-operator \
  --generate-name \
  --create-namespace \
  --set devicePlugin.enabled=false \
  --set gfd.enabled=false \
  nvidia/gpu-operator

helm upgrade -i nvdp nvdp/nvidia-device-plugin \
    --version=0.17.1 \
    --namespace nvidia-device-plugin \
    --create-namespace \
    --set gfd.enabled=true \
    --set config.default=mps10 \
    --set-file config.map.mps10=/work/lin/kubernets-install/nvidia/mps.yaml

kubectl create ns demo

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  namespace: demo
  name: mps-env-test
spec:
  runtimeClassName: nvidia
  restartPolicy: OnFailure
  containers:
  - name: mps-env-test
    image: nvcr.io/nvidia/k8s/cuda-sample:nbody-cuda11.7.1-ubuntu18.04
    command: ["sleep", "9999"]
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

 kubectl exec -ti -n demo mps-env-test -- bash -c "echo get_default_active_thread_percentage | nvidia-cuda-mps-control"

