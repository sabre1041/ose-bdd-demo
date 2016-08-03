Continuous Integration and Continuous Delivery
=================

One of the core components of this demonstration is to utilize the principles and tools emphasized by continuous integration and continuous delivery. This document explains how these tools and concepts are achieved.

## Jenkins

The Jenkins Continuous Integration Server is being used to orchestrate the building, deploying and promoting of applications to OpenShift. It builds upon the official [Jenkins xPaaS image] (https://docs.openshift.com/enterprise/latest/using_images/other_images/jenkins.html) by adding essential plugins and configurations to enable continuous integration and delivery functionality and behavior driven development. 

## Jenkins Agents

To offload the responsibility of executing build on the masters, Jenkins agents are used to provide distributed build functionality. Agents are dynamically created and managed by the Jenkins master through the [Kubernetes Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Kubernetes+Plugin). When new builds are started, the Jenkins master communicates with the OpenShift API to use or instantiate new pods. When the build completes, the pods are destroyed. Communication to the OpenShift API is made possible by utilizing service account tokens that are automatically injected into the running pods.

## Jenkins Pipelines

Jenkins [pipelines as code](https://wiki.jenkins-ci.org/display/JENKINS/2.0+Pipeline+as+Code) is a concept where the steps an application will take from build to deployment is packaged alongside the application code in a descriptive format. A new *pipeline* build type makes use of this domain specific language (DSL), typically stored in a file called *Jenkinsfile*, to illustrate these steps. Each of the [projects](../projects) contains one of these files to illustrate the processes that will occur during the job execution.

The following pipelines are configured in Jenkins

* coolstore-test-harness-pipeline - Builds the test harness for Behavior Driven Development. This job is automatically triggered at the conclusion of the [init.sh](../init.sh) script
* coolstore-app - Pipeline to build, test and deploy the web application
* coolstore-rules - Builds and deploys the business rules for the web application. Executes Behavior Driven Development scenarios

## Job Management

The Jenkins jobs that are used to execute the pipeline described earlier are created and managed using the [Jenkins Job DSL plugin](https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin). This allows the job configuration to be versioned as well as alleviating configuration drift that typically occurs in a Jenkins server. The DSL scripts are located in the [ci](../projects/ci) folder within this repository and initiated by a job that is built into the [Jenkins image](../infrastructure/jenkins). This job is automatically run at the conclusion of the [init.sh](../init.sh) script.
 

## Nexus

Nexus is an artifact repository. It is being used to act as a Maven and NPM proxy in the environment to accelerate build time and to store artifacts produced by Jenkins build processes. This server is preconfigured with the necessary repositories to build Red Hat middleware solutions

## Gogs

Gogs is a self contained git server used to provide distributed source code management for the environment. Three repositories are created based on the projects located in the [projects](../projects) folder as part of the provisioning process.

### Git Hooks

Git hooks play an integral component integrating several of the solutions to achieve true continuous delivery. Each of the repositories configured in the Gogs server in one form or another.

* coolstore-test-harness - Webhook to trigger the *coolstore-test-harness-pipeline* in Jenkins
* coolstore-app - Webhook to trigger the *coolstore-app-pipeline*
* coolstore-rules - *post-receive* hook to trigger the *coolstore-rules-pipeline* Jenkins job when changes occur on the *deployments* branch