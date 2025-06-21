#! /bin/bash

# install Kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# install kubeflow

git clone https://github.com/kubeflow/manifests.git
cd manifests
# cd model-registry/manifests/kustomize

# install all Kubeflow official components

# cert-manager
kustomize build common/cert-manager/base | kubectl apply -f -
kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -
echo "Waiting for cert-manager to be ready ..."
kubectl wait --for=condition=Ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kubectl wait --for=jsonpath='{.subsets[0].addresses[0].targetRef.kind}'=Pod endpoints -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager

# Istio

echo "Installing Istio CNI configured with external authorization..."
kustomize build common/istio/istio-crds/base | kubectl apply -f -
kustomize build common/istio/istio-namespace/base | kubectl apply -f -

# For most platforms (Kind, Minikube, AKS, EKS, etc.)
kustomize build common/istio/istio-install/overlays/oauth2-proxy | kubectl apply -f -

# For Google Kubernetes Engine (GKE), use:
# kustomize build common/istio/istio-install/overlays/gke | kubectl apply -f -

echo "Waiting for all Istio Pods to become ready..."
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout 300s

# Oauth2-proxy

echo "Installing oauth2-proxy..."

kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl apply -f -
kubectl wait --for=condition=Ready pod -l 'app.kubernetes.io/name=oauth2-proxy' --timeout=180s -n oauth2-proxy

# Dex

echo "Installing Dex..."
kustomize build common/dex/overlays/oauth2-proxy | kubectl apply -f -
kubectl wait --for=condition=Ready pods --all --timeout=180s -n auth

# Knative

kustomize build common/knative/knative-serving/overlays/gateways | kubectl apply -f -
kustomize build common/istio/cluster-local-gateway/base | kubectl apply -f -

# Kubeflow Namespace

kustomize build common/kubeflow-namespace/base | kubectl apply -f -

# Network policiese

kustomize build common/networkpolicies/base | kubectl apply -f -

# Kubeflow Roles

kustomize build common/kubeflow-roles/base | kubectl apply -f -

# Kubeflow Istio Resources

kustomize build common/istio/kubeflow-istio-resources/base | kubectl apply -f -

# Kubeflow Pipelines

kustomize build apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl apply -f -

# KServe

kustomize build apps/kserve/kserve | kubectl apply --server-side --force-conflicts -f -

# Katib

kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -

# Central Dashboard

kustomize build apps/centraldashboard/overlays/oauth2-proxy | kubectl apply -f -

# Admission Webhook

kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

# Notebooks 1.0

kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -

# Jupyter Web Application

kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -

# PVC Viewer Controller

kustomize build apps/pvcviewer-controller/upstream/base | kubectl apply -f -

# Profiles + KFAM

kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -

# Volumes Web Application

kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -

# Tensorboard
kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -

# Traning Operator
kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply --server-side --force-conflicts -f -

# Spark

kustomize build apps/spark/spark-operator/overlays/kubeflow | kubectl apply -f -

# User

kustomize build common/user-namespace/base | kubectl apply -f -

# Model registrey

git clone --depth 1 -b v0.2.19 https://github.com/kubeflow/model-registry.git
cd model-registry/manifests/kustomize

PROFILE_NAME=kubeflow-user-example-com
for DIR in options/istio overlays/db ; do (cd $DIR; kustomize edit set namespace $PROFILE_NAME); done

kubectl apply -k overlays/db
kubectl apply -k options/istio
kubectl apply -k options/ui/overlays/istio

kubectl port-forward svc/model-registry-service -n $PROFILE_NAME 8081:8080