## Automated Deployment of Microservice-Based App on Kubernetes 
---

### Prerequisite
Before you test out the scripts, please ensure you have done the following:
1. Create an account on Google Cloud Platform if you do not have one already. You can go [here](https://cloud.google.com/) to sign up.

2. Install [Cloud SDK](https://cloud.google.com/sdk/) on your local machine. This will enable you interact with GCP resources in your account from the command line.

    For instance, the automation scripts use the `gcloud` commands available in the SDK to create, start and make SSH connections to a web server instance.

3. Create a [project](https://medium.com/google-cloud/how-to-create-cloud-platform-projects-using-the-google-cloud-platform-console-e6f2cb95b467) from your GCP console for the test purpose.

4. Ensure you authentice the CLI by running the `gcloud auth login` command on your terminal, and that your demo project from **3.** is set to your current project.

    Below is a screenshot of what a successful CLI authentication looks like. Take note of the current project which in your case should be the name of your own project.

    ![alt text](../img/gcloud-auth.png?raw=true "kops server")

Once we have the above prerequisites sorted out, then we are good to run our script!

### Deploy your Cluster
---
1. Clone the repository and navigate to the `scripts` folder in your terminal.

2. Execute the script to set up your cluster by running `./provision_kops.sh <instance-name>`. `instance-name` should be any name of your choice to identify your web server that will be created.

    If all things go well, you should have your web server up and running in your project dashboard. Note that `kops` was the `instance-name` I chose while executing the script.

    ![alt text](../img/cluster-created.png?raw=true "cluster has been created")

    ![alt text](../img/kops-server.png?raw=true "kops server")

3. SSH into the kops server from the browser window
4. Execute the following commands to complete the cluster deployment:
    ```
    export KOPS_STATE_STORE=gs://k8s-demo-state/

    export KOPS_FEATURE_FLAGS=AlphaAllowGCE 

    kops update cluster cluster.k8s.local --yes
    ```

    **KOPS_STATE_STORE** is a storage bucket that was created while setting up the kops server. Kops needs this bucket to persist its state 


5. `kops update` creates the cluster servers (in this case a master and two nodes) and can be seen on your dashboard:
    
    ![alt text](../img/master_nodes.png?raw=true "master and node servers")

    After the servers have been created, it takes some time for them to join the cluster. I'll advise you wait for few minutes before running `kops validate cluster` to check if the nodes in your cluster are ready. If you get an error or message that suggests that they are not ready, give it some more minutes and try the command again.

    Once you have an output as seen below, then your cluster is set to be used:

    ![alt text](../img/cluster.png?raw=true "cluster")

    
    
### Deploy K8S Web UI
---
In order to view your cluster in a dashboard, you need to deploy the UI as it is not done by default. From the kops server, execute the following commands:
```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

kubectl create -f /home/dashboard-rolebinding.yml
```

You  access the UI directly via the Kubernetes master apiserver. Open a browser and navigate to `https://<master-ip>/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/`, where <master-ip> is public IP address of the Kubernetes master server.

To log in to the dashboard, you can run `kubectl config view` to retrieve the admin username and password. 

![alt text](../img/kubectl-config.png?raw=true "kubectl config view")


Please `skip` this step as it is not necessary for this demo:

![alt text](../img/skip_auth.png?raw=true "skip for demo")

After skipping the step above, you should be taken to your cluster dashboard:

![alt text](../img/cluster_dash.png?raw=true "cluster dashboard")


### Configure Jenkins Server
---
With our cluster up and running, we can now proceed to set up our Jenkins CI/CD server.

1. Still from the `scripts` directory on your local terminal, execute the Jenkins setup script by running `./provision_jenkins.sh`. If the execution completes successfully, the default Jenkins `admin` password will be printed on the terminal:

    ![alt text](../img/admin_password.png?raw=true "admin_password")

2. Open a browser and visit `<jenskins-server-public-ip>:8080`, where <jenskins-server-public-ip> is public IP address of the Jenkins server.
    
    ![alt text](../img/jenkins_server.png?raw=true "jenkins server")

    ![alt text](../img/setup.png?raw=true "jenkins setup page")

3. Enter your admin password from **1.** and click on `Install suggested plugins` as shown in the screenshot below:

    ![alt text](../img/install_plugins.png?raw=true "install plugins")

4. After the plugins installation, you will be required to create an Admin user to access Jenkins, after which you will finish up the setup:

    ![alt text](../img/create_admin.png?raw=true "create admin user")

5. If after "finishing" the setup you are redirected to a blank page, please restart Jenkins by appending `/restart` to the URL so that it looks like so: `<jenskins-server-public-ip>:8080/restart` on your browser.

    When Jenkins restarts should be taken to a login page where you can enter the details of the admin user you created in **4.** You can refresh the browser if that does not happen automatically and your browser still shows a "**This page isn’t working**" error page.
    
    ![alt text](../img/jenkins_login.png?raw=true "login page")

6. Once you're logged in, you should see the required CI/CD pipeline jobs already set up and ready to be taken on a ride:
    ![alt text](../img/dashboard.png?raw=true "jenkins dashboard")

    Each job will be responsible for deploying each microservice of the application.

7. Install the [Kubernetes CLI](https://wiki.jenkins.io/display/JENKINS/Kubernetes+CLI+Plugin) plugin to enable us interact with the cluster. You can follow the guide in the **Find plugins to install** section of this [tutorial](https://wilsonmar.github.io/jenkins-plugins/) if you are not familiar with installing plugins on Jenkins.

    From the **Available** tab of the plugins manager page, you should find the plugin via a search. Please choose the option to **Install without restart**.

      ![alt text](../img/k8s-cli.png?raw=true "jenkins dashboard")

### Add Environmental Variables as Jenkins Credentials
---
In order to run builds successfully, we need to add some variables in Jenkins credential:
1. **REGISTRY-URL**: The URL of the container registry associated to a specified project where you can store and retrieve docker images

    ```
    secret: gcr.io/<project-id>
    ```
    Substitute `<project-id>` with the id of the project you created in Prerequisite **3.** from where you are testing this work. In my case, it was `gcr.io/d1-d2-218406`

    ![alt text](../img/registry-url1.png?raw=true "registry url credential")

     ![alt text](../img/registry-url2.png?raw=true "project id")

  2. **GCLOUD-SERVICE-KEY**: Google service account key required to authenticate Jenkins to access your private GCR.

      Create a new service account key from the Google Cloud console and attach the following roles to the key:
      ```
      Storage -> Storage Admin & Storage Object Viewer
      ```

       You can find a guide in the **Create Service Account** section of this [post](https://blog.openbridge.com/the-missing-guide-to-setting-up-google-cloud-service-accounts-for-google-bigquery-6301e509b232).

        Download the key in `json` format and encode it with base 64. You can copy the `json` value and paste into this [tool](https://www.url-encode-decode.com/base64-encode-decode/) to quickly encode it. This encoded value becomes the credential value of 'GCLOUD-SERVICE-KEY'

        ```
        secret: <Base64 encoded value of service account key>
        ```

        ![alt text](../img/gcloud_cred.png?raw=true "registry url credential")

  3. **KUBERNETES**: Username and password needed to log in to kubernetes cluster. You can retrieve them by running `kubectl config view` from the kops server.

      *Refer to screenshot in **Deploy K8S Web UI** section above that shows the result of running `kubectl config view`.*

      ![alt text](../img/k8s-login-details.png?raw=true "k8s log in details")

  4. **CLUSTER-NAME**: Name of Kubernetes cluster. It can retrieve them by running `kubectl config view` from the kops server.

      *Refer to screenshot in **Deploy K8S Web UI** section above that shows the result of running `kubectl config view`.*

      ![alt text](../img/cluster-name-cred.png?raw=true "cluster name")

  5. **SERVER-URL**: URL of the Kubernetes cluster. It can retrieve them by running `kubectl config view` from the kops server.

      *Refer to screenshot in **Deploy K8S Web UI** section above that shows the result of running `kubectl config view`.*

      ![alt text](../img/server-url-cred.png?raw=true "server url credential")

**PLEASE ENDEAVOUR TO GET THE CREDENTIALS RIGHT AS THIS WILL DETERMINE HOW SUCCESSFUL THE BUILDS WILL BE.**

### DEPLOY SERVICES
--- 
With the credentials in place, you can go ahead to deploy the services by running each build in no particular order. For the application to work, all the services must be deployed, meaning that all the jobs must be run.

To run a build, click on any job of choice and find the **Build Now** link.

  ![alt text](../img/build-result1.png?raw=true "build result")
  *Sample job with build result*

  ![alt text](../img/build-result2.png?raw=true "build result")
  *All jobs after successful test builds*

  ![alt text](../img/build-result3.png?raw=true "build result")
  *Images pushed to the registry via the pipeline*

  ![alt text](../img/build-result4.png?raw=true "build result")
  *Cluster dashboard showing successful deployments of all services*


### Test Application
---
1. From the cluster dashboard, go to **Services**:

    ![alt text](../img/k8s-services.png?raw=true "build result")

2. `zipkin` and `frontend` services have external endpoints for interacting with them from the browser. The `frontend` endpoint takes you to the app itself, while `zipkin` takes you to a dashboard to view traces produced by other components while the app is in use. Feel free to try them out.

    ![alt text](../img/test1.png?raw=true "test result")
    *Application landing page. Log in with details as seen in the placeholders*

    ![alt text](../img/test2.png?raw=true "test result")
    *TODOs page with default todo items*

    ![alt text](../img/test3.png?raw=true "test result")
    *TODOs page with test todo items*

    ![alt text](../img/test4.png?raw=true "test result")
    *Zipkins dashboard showing traces of activities. Click on 'Find Traces' button to reveal them*

### Clean Up
---
When you are done with looking around, clean up all theresources by doing the following:
* From the **kops** server, run the command below to  delete all cluster associated resources:
  ```
  export KOPS_STATE_STORE=gs://k8s-demo-state/
  
  kops delete cluster --name=cluster.k8s.local --yes
  ```

  It will take a while for **kops** to clean up things. Once this is done, the master and node servers would be gone.

 * Delete all the images that were added to your Container Registry

 * Delete the storage bucket `k8s-demo-state` that was created when **kops** server was being configured. 

 * Then delete the `jenkins` and `kops` servers from the dashboard:

    ![alt text](../img/delete-server.png?raw=true "test result")