#!/bin/bash


echo "creating organizational unit"

curl -i \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --user brmsuser:redhat#1 \
    -X POST \
    -d '{"name":"coolstore","defaultGroupId":"coolstore","owner":"redhat"}' \
    http://business-central-ci.rhel-cdk.10.1.2.2.xip.io/business-central/rest/organizationalunits

sleep 2s

echo "cloning coolstore repo from gogs"

curl -i \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --user brmsuser:redhat#1 \
    -X POST \
    -d '{"name":"coolstore","description":"repo for coolstore rules","requestType":"clone","gitURL":"http://gogs:bddgogs@gogs:3000/gogs/CoolstoreRules.git","organizationalUnitName":"coolstore"}' \
    http://business-central-ci.rhel-cdk.10.1.2.2.xip.io/business-central/rest/repositories


echo "moving post-commit to hooks dir of repo"

#mkdir -p $HOME/gitrepo/.niogit/coolstore.git/hooks

#mv $HOME/post-commit $HOME/gitrepo/.niogit/coolstore.git/hooks/post-commit
 
