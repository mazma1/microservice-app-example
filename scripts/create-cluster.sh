#!/usr/bin/env bash

# script to install mysql-server and HAProxy on server

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

SERVICE_KEY=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/service_key -H "Metadata-Flavor: Google")


install_kubectl() {
  echo 'About to install kubectl......'

  sudo apt-get update && sudo apt-get install -y apt-transport-https
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubectl

  echo 'Successfully installed kubectl.'
}

install_kops() {
  echo 'About to install kops......'

  wget https://github.com/kubernetes/kops/releases/download/1.10.0/kops-linux-amd64
  sudo chmod +x kops-linux-amd64
  sudo mv kops-linux-amd64 /usr/local/bin/kops

  echo 'Successfully installed kops.'
}

create_bucket() {
  # echo $SERVICE_KEY | base64 --decode --ignore-garbage > /home/gcloud-service-key.json
  echo $SERVICE_KEY | base64 --decode --ignore-garbage | sudo tee -a /home/gcloud-service-key.json
  gcloud auth activate-service-account --key-file /home/gcloud-service-key.json

  gsutil mb -l europe-west3 gs://cluster.k8s.local-state/
}

set_vars() {
  # gossip based DNS cluster name
  export NAME=cluster.k8s.local

  # create storage bucket for kops
  gsutil mb -l europe-west3 gs://k8s-demo-state/
  export KOPS_STATE_STORE=gs://k8s-demo-state/

  PROJECT=`gcloud config get-value project`

  # to unlock the GCE features
  export KOPS_FEATURE_FLAGS=AlphaAllowGCE 
}

create_k8s_cluster() {
  kops create cluster \
  --name=${NAME} \
  --zones us-central1-a \
  --project=${PROJECT}
}


main() {
  install_kubectl
  install_kops
  set_vars
  create_k8s_cluster
}

main "$@"
