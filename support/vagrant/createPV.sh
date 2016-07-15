#!/bin/sh

oc login -u admin -p admin --insecure-skip-tls-verify=true localhost:8443

mkdir /nfsvolumes/pv04
chmod -R 777 /nfsvolumes/pv04
chown -R nfsnobody:nfsnobody /nfsvolumes/pv04
echo "/nfsvolumes/pv04 *(rw,root_squash)" >> /etc/exports
exportfs -r

mkdir /nfsvolumes/pv05
chmod -R 777 /nfsvolumes/pv05
chown -R nfsnobody:nfsnobody /nfsvolumes/pv05
echo "/nfsvolumes/pv05 *(rw,root_squash)" >> /etc/exports
exportfs -r

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

oc create -f- <<PV
apiVersion: v1
kind: PersistentVolume
metadata:
  creationTimestamp: null
  name: pv05
spec:
  accessModes:
  - ReadWriteOnce
  - ReadWriteMany
  capacity:
    storage: 2Gi
  nfs:
    path: /nfsvolumes/pv05
    server: localhost
  persistentVolumeReclaimPolicy: Recycle
PV
