node {
  stage('git checkout') {
    git branch: 'deploy-k8s', url: 'https://github.com/mazma1/microservice-app-example'
  }

  stage('archive') {
    archiveArtifacts artifacts: '*, **/'
  }
}