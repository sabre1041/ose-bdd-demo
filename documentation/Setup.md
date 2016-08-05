OpenShift Behavior Driven Development Demo - Setup 
====================================================


# Overview

This document provides information on the steps necessary for running the demonstration in an OpenShift Container Platform environment

# Prerequisites

A OpenShift Container Platform environment is required to utilize this demonstration. The target environment is the Red Hat Container Development Kit (CDK), though, any OpenShift Container Platform version 3.1.1+ can be utilized

## Hardware Requirements

Due to the number of components found within this demonstration, the following hardware resources are required:

* RAM: 6GB

## Obtaining JBoss BRMS

To build the JBoss BRMS container, the JBoss BRMS 6.3 deployable for JBoss Enterprise Application Platform (*jboss-brms-6.3.0.GA-deployable-eap6.x*) must be available. The software can be obtained from the Red Hat Customer Portal and placed in the `infrastructure/business-central/support` folder. Additional information can be found in the [README](../infrastructure/business-central/support/README.md) within this folder.

## Installing and Configuring the CDK

Instructions on how to install and configure the CDK for general use is beyond the scope of this document. Please refer to the installation and configuration instructions on the Red Hat Customer portal for details. Additional instructions for running the demonstration in the CDK will be provided in subsequent sections. The CDK must be active prior to initiating the setup script. 

## Confirming Access to the Environment

Access to the OpenShift Container Platform is dependent on the type of environment. In most cases, the [OpenShift Command Line Tool (CLI)](https://docs.openshift.com/enterprise/latest/cli_reference/get_started_cli.html) can be used to communicate with the platform. When performing administrative functions, as described in sections of this preparation guide, direct access to the platform may be required.

By default, the CDK exposes the public address `10.1.2.2` for remote access from the host. Access can be achieved using the aforementioned `oc` tool, or by direct accessing the environment using `vagrant ssh`. 

To login to the environment using the `oc` tool, execute the following command:

```
# oc login 10.1.2.2
Authentication required for https://10.1.2.2:8443 (openshift)
Username: admin
Password: 
Login successful.

```

Two accounts are preconfigured within the CDK. Please refer to the on screen text displayed after provisioning the CDK environment using the `vagrant up` command

The CDK can be accessed directly through an `ssh` session facilitated by vagrant. Navigate to the location of the `Vagrantfile` used to launch the environment and run `vagrant ssh`. This will start a terminal session within the CDK using the `vagrant` user. You can gain access to the root account by "sudo'ing" up. The `oc` tool is available within the CDK and can be used in a similar fashion as external access

## Persistent Storage

To allow for a stable, consistent and reusable environment, certain components require persistent storage in order to save state in the event a running container is removed. Four (4) [persistent volumes](https://docs.openshift.com/enterprise/latest/dev_guide/persistent_volumes.html) are required.

### Configuring Persistent Storage in the CDK

 Three (3) persistent volumes are preallocated for use by deployed components and backed by NFS. Additional persistent volumes are required in order to meet the prerequisites. Adding a persistent volume involves the following steps
 
* Adding an additional mount point to the NFS server
* Creating a persistent volume making use of the newly created storage

#### Creating the NFS Mount Point

NFS shares in the CDK are located at `/nfsvolumes` and named `pv0{1-3}`.  Additional mounts should be called `pv0{X}`. Repeat the following steps to create the required NFS mount points. Replace the X with the persistent volume being created
	
* Login to the CDK using the steps previously described
* Execute the following commands to create the folder and assign the correct permissions

```
mkdir /nfsvolumes/pv0X
chmod -R 777 /nfsvolumes/pv0X
clown -R nfsnobody:nfsnobody /nfsvolumes/pv0X
```

* Modify the NFS exports file at `/etc/exports` by adding the following to include the newly created folder

```
/nfsvolumes/pv0X *(rw,root_squash)
``` 

* Reload the NFS configuration

```
exportsfs -r
```

#### Configure the Persistent Volumes

*Note: You must be a cluster administrator to perform the actions described in this section*

With the NFS storage component complete, persistent volumes can be created referencing the previously created storage.

 Create the following JSON file for each of the persistent volumes that need to be created. 

For example, create a file called pv0X.json with the following contents. As illustrated earlier, replace X with the persistent volume number.

```
{
    "kind": "PersistentVolume",
    "apiVersion": "v1",
    "metadata": {
        "name": "pv0X",
        "creationTimestamp": null
    },
    "spec": {
        "capacity": {
            "storage": "1Gi"
        },
        "nfs": {
            "server": "localhost",
            "path": "/nfsvolumes/pv0X"
        },
        "accessModes": [
            "ReadWriteOnce",
            "ReadWriteMany"
        ],
        "persistentVolumeReclaimPolicy": "Recycle"
    },
    "status": {}
}
```

Add the persistent volume to OpenShift by executing the following command:

```
oc create -f pv0X.json
```

Confirm the expected number of persistent volumes are available:

```
oc get pv
```

#### Automated CDK Provisioning script

A script is available in `support/vagrant/createPV.sh` that performs the steps described above by adding a 4th and 5th persistent volume to OpenShift and the NFS server.

Login to the CDK and sudo up to the *root* user from the folder containing the *Vagrantfile*

```
vagrant ssh
sudo su -
```

Create a file called `createPV.sh` in the home directory with the contents of the script from the *support* folder. Make the file executable and run the script.

```
chmod +x createPV.sh
./createPV.sh
```

# Setup

The entire demonstration environment can be configured by simply running the `init.sh` script at the root of the repository. This script will perform the following actions:

* Create OpenShift Infrastructure Components
	* Projects
	* Authentication and authorization
	* ImageStreams
	* Templates
* Build required images
* Deploy and configure CI Infrastructure
* Deploy BRMS
* Instantiate application templates

## Connectivity Details

In order for the environment to be set up appropriately, the `init.sh` script must be told the location and credentials for the OpenShift environment. The following variables can be tailored to meet the specific configuration of the environment

```
OSE_CLI_USER="admin" 
OSE_CLI_PASSWORD="admin"
OSE_CLI_HOST="https://10.1.2.2:8443"
``` 

*Note: The above values are preconfigured to support the CDK*

## Running the script

To provision the environment, ensure OpenShift is available and execute the following command from the root of the repository:

```
./init.sh
```

## Validation

To validate the environment was successfully provisioned, complete the following actions.

Validate the infrastructure components are running. Executing the following command:

```
# oc get pods -n ci | grep Running
```

A result similar of the following should be returned:

```
business-central-1-kbm21       1/1       Running     0          20m
gogs-2-8hlwr                   1/1       Running     0          34m
jenkins-1-4bi9n                1/1       Running     0          43m
nexus-1-ysudy                  1/1       Running     0          12m
postgresql-1-01t9w             1/1       Running     0          38m
```

Ensure Business Central (BRMS), Jenkins, Nexus, Gogs and the supporting PostgreSQL database are running.

Now, validate the Jenkins Agent was built successfully. This image will be dynamically provisioned by Jenkins as new builds are initiated 

```
# oc get builds -n ci | grep jenkins-agent
jenkins-agent-1          Docker    Binary@f43a8e3   Complete   About an hour ago   4m55s
```

# Next Steps

Once the environment has been successfully provisioned, please see the user guide on how to execute the demonstration
