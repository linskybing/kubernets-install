#! /bin/bash

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

#helm show values grafana/grafana > grafana.values.yaml
helm install grafana grafana/grafana -n monitoring -f grafana/values.yaml

kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 3000