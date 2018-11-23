#!/usr/bin/env bash

# script to install mysql-server and HAProxy on server

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

PROJECT_NAME=$1

provision_instance() {
  echo 'About to provision KOPS instance......'

  gcloud compute instances create $PROJECT_NAME \
    --zone europe-west3-b \
    --machine-type f1-micro \
    --scopes cloud-platform


  gcloud compute instances add-tags $PROJECT_NAME \
    --tags kops-auto
    
  echo 'Successfully provisioned KOPS instance.'
}

copy_config_script() {
  echo 'About to copy local config script to new instance...'

  gcloud compute scp './create-cluster.sh' $PROJECT_NAME:/tmp/create-cluster.sh
  gcloud compute scp './dashboard-rolebinding.yml' $PROJECT_NAME:/tmp/dashboard-rolebinding.yml

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "sudo mv /tmp/create-cluster.sh /home/create-cluster.sh"

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "sudo mv /tmp/dashboard-rolebinding.yml /home/dashboard-rolebinding.yml"

  echo 'Successfully copied config script.'
}

execute_config_script() {
  echo 'About to begin cluster deployment...'

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "chmod +x /home/create-cluster.sh"

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "/home/create-cluster.sh"
}


main() {
  provision_instance
  copy_config_script
  execute_config_script
}

main "$@"
