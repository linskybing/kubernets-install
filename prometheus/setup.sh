#! /bin/bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update


kubectl create namespace monitoring

helm show values prometheus-community/kube-prometheus-stack > prometheus/value.yaml

helm install -f prometheus/value.yaml prometheus prometheus-community/kube-prometheus-stack -n prometheus-stack --create-namespace

# kube-prometheus-stack has been installed. Check its status by running:
#   kubectl --namespace prometheus-stack get pods -l "release=prometheus"

# Get Grafana 'admin' user password by running:

#   kubectl --namespace prometheus-stack get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

# Access Grafana local instance:

#   export POD_NAME=$(kubectl --namespace prometheus-stack get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=prometheus" -oname)
#   kubectl --namespace prometheus-stack port-forward $POD_NAME 3000

# Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.

# Setting up DCGM
# https://docs.nvidia.com/datacenter/cloud-native/gpu-telemetry/latest/kube-prometheus.html

helm repo add gpu-helm-charts \
   https://nvidia.github.io/dcgm-exporter/helm-charts
helm repo update

helm install \
   -n dcgm-exporter --create-namespace \
   dcgm-exporter gpu-helm-charts/dcgm-exporter


# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods -n dcgm-exporter -l "app.kubernetes.io/name=dcgm-exporter,app.kubernetes.io/instance=dcgm-exporter" -o jsonpath="{.items[0].metadata.name}")
#   kubectl -n dcgm-exporter port-forward $POD_NAME 8080:9400 &
#   echo "Visit http://127.0.0.1:8080/metrics to use your application"