#!/usr/bin/env bash

# script to install mysql-server and HAProxy on server

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

PROJECT_NAME='jenkins'

provision_instance() {
  echo 'About to provision Jenkins instance......'

  gcloud compute instances create $PROJECT_NAME \
    --zone europe-west3-b \
    --machine-type g1-small \
    --scopes cloud-platform \
    --image ubuntu-1604-xenial-v20181114 \
    --image-project ubuntu-os-cloud

  gcloud compute instances add-tags $PROJECT_NAME \
    --tags jenkins

  # firewall rule to allow traffic into Jenkins default port
  gcloud compute firewall-rules create "jenkins-rule" --allow tcp:8080 \
      --source-ranges="0.0.0.0/0" \
      --target-tags="jenkins"
    
  echo 'Successfully provisioned Jenkins instance.'
}

copy_config_script() {
  echo 'About to copy local config scripts to Jenkins instance...'

  gcloud compute scp './configure-jenkins.sh' ${PROJECT_NAME}:/tmp/configure-jenkins.sh
  # gcloud compute scp --recurse $PROJECT_NAME:/tmp/jobs/* "../jobs"

  gcloud compute scp --recurse ../jobs ${PROJECT_NAME}:/tmp/jobs

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "sudo mv -v /tmp/configure-jenkins.sh /home/configure-jenkins.sh"

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "sudo mkdir -p /home/jenkins/jobs && sudo cp -r -v /tmp/jobs /home/jenkins"

  echo 'Successfully copied config script.'
}

execute_config_script() {
  echo 'About to configure Jenkins server...'

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "sudo chmod +x /home/configure-jenkins.sh"

  gcloud compute ssh $PROJECT_NAME --zone europe-west3-b \
    --command "/home/configure-jenkins.sh"
}


main() {
  provision_instance
  copy_config_script
  execute_config_script
}

main "$@"
