OpenShift Behavior Driven Development Demo 
==========================================

Demonstration of how behavior driven development can be applied in a containerized environment

Please look at the README in docker/business-central/support and follow the instructions to aquire the BRMS deployable


## Persistent Volume Requirements

To ensure state is stored within various components of the infrastructure, OpenShift persistent volumes will be utilized. The Red Hat CDK contains 3 persistent volumes out of the box, but at least 5 are required. Perform the following steps to ensure at least 5 persistent volumes are available.

Login to the Red Hat CDK and sudo up to root

```
vagrant ssh
sudo su -
```
 
Login to OpenShift using the admin account

    oc login -u admin -p admin --insecure-skip-tls-verify=true localhost:8443

Check the number of persistent volumes available

    oc get pv
    
Use the following section to create a persistent volume in order to satisfy the minimum requirements

### Create additional persistent storage

Creating additional persistent storage requires first adding a new export to the NFS share and then adding a persistent volume to OpenShift referencing the newly created share

#### Creating a new NFS Export

The CDK stores NFS shares in the `/nfsvolumes` directory in folders `pvXX` where XX indicates the number. In this scenario, persistent volume 04 will be created.

Execute the following commands to configure the NFS server with the additional share

```
mkdir /nfsvolumes/pv04
chmod -R 777 /nfsvolumes/pv04
chown -R nfsnobody:nfsnobody /nfsvolumes/pv04
echo "/nfsvolumes/pv04 *(rw,root_squash)" >> /etc/exports
exportfs -r
```

#### Create the new Persistent Volume

Execute the following command to create the new Persistent Volume

```
oc create -f- <<PV
apiVersion: v1
kind: PersistentVolume
metadata:
  creationTimestamp: null
  name: pv04
spec:
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  capacity:
    storage: 2Gi
  nfs:
    path: /nfsvolumes/pv04
    server: localhost
  persistentVolumeReclaimPolicy: Recycle
PV
```