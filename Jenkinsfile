node {
  stage('git checkout') {
    git branch: 'deploy-k8s-gcp', url: 'https://github.com/mazma1/microservice-app-example'
  }

  stage('deploy to Kubernetes cluster') {
    withCredentials([
      string(credentialsId: 'REGISTRY-URL', variable: 'REGISTRY_URL'),
      string(credentialsId: 'CLUSTER-NAME', variable: 'CLUSTER_NAME'),
      string(credentialsId: 'SERVER-URL', variable: 'SERVER_URL')
    ]) {
      withKubeConfig(caCertificate: '', contextName: "${CLUSTER_NAME}", credentialsId: 'KUBERNETES', serverUrl: "${SERVER_URL}") {

        sh '''
          SERVICE1='zipkin'
          SERVICE2='redis-queue'

          DEPLOYMENTS=$(kubectl get deployment -o=jsonpath='{.items[*].metadata.name}')
          DEPLOYMENT_BASE_PATH="${WORKSPACE}/k8s"

          SERVICE1_FOUND=$(echo ${DEPLOYMENTS} | grep "${SERVICE1}") || :
          SERVICE2_FOUND=$(echo ${DEPLOYMENTS} | grep "${SERVICE2}") || :

          # deploy zipkin if it does not exist
          if [ -z "${SERVICE1_FOUND}" ]; then
              echo "${SERVICE1} does not exist, about to deploy service"
              
              kubectl create -f "${DEPLOYMENT_BASE_PATH}/${SERVICE1}/deployment.yaml"
              kubectl create -f "${DEPLOYMENT_BASE_PATH}/${SERVICE1}/service.yaml"
          fi

          # deploy redis-queue if it does not exist
          if [ -z "${SERVICE2_FOUND}" ]; then
              echo "${SERVICE2} does not exist, about to deploy service"
              
              kubectl create -f "${DEPLOYMENT_BASE_PATH}/${SERVICE2}/deployment.yaml"
              kubectl create -f "${DEPLOYMENT_BASE_PATH}/${SERVICE2}/service.yaml"
          fi
        '''
      }
    }
  }
}
