#!/usr/bin/env bash

# script to install mysql-server and HAProxy on server

# exit when a command fails
set -o errexit

# exit if previous command returns a non 0 status
set -o pipefail

USER=$(whoami)


install_java() {
  echo 'About to install Java on Jenkins server......'

  sudo apt update -y
  sudo apt install openjdk-8-jdk -y

  echo 'Successfully installed Java'
}

install_jenkins() {
  echo 'About to install Jenkins......'

  wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
  echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee -a /etc/apt/sources.list.d/jenkins.list

  sudo apt update -y
  sudo apt install jenkins -y

  echo 'Successfully installed Jenkins.'
}

copy_jenkins_jobs() {
  echo 'About to copy jobs config files to Jenkins......'

  JOBS_DIR='/var/lib/jenkins/jobs'

  gcloud compute ssh jenkins --zone europe-west3-b \
    --command "sudo cp -r -v /tmp/jobs /var/lib/jenkins"

  # change the owner and group of each job dir from root to jenkins
  sudo chown jenkins:jenkins \
    ${JOBS_DIR}/users-api/ \
    ${JOBS_DIR}/auth-api/ \
    ${JOBS_DIR}/frontend/ \
    ${JOBS_DIR}/todos-api/ \
    ${JOBS_DIR}/misc-services/ \
    ${JOBS_DIR}/log-message-processor/ 

  echo 'Successfully copied jobs config files.'
}

install_docker() {
  echo 'About to install Docker......'

  sudo apt-get update

  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install docker-ce -y

  # add jenkins user to docker group
  sudo usermod -aG docker jenkins
  sudo service jenkins restart

  echo 'Successfully installed Docker.'
}


install_kubectl() {
  echo 'About to install kubectl......'

  sudo apt-get update && sudo apt-get install -y apt-transport-https
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update -y
  sudo apt-get install -y kubectl

  echo 'Successfully installed kubectl.'
}


get_admin_password() {
  echo 'Your default admin password:'
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
}


main() {
  install_java
  install_jenkins
  copy_jenkins_jobs
  install_docker
  install_kubectl
  get_admin_password
}

main "$@"
