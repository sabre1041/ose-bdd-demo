#!/bin/bash


echo "creating organizational unit"

curl -i \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --user $BUSINESS_CENTRAL_USER:$BUSINESS_CENTRAL_PASSWORD \
    -X POST \
    -d '{"name":"coolstore","defaultGroupId":"coolstore", "owner":"redhat"}' \
    http://business-central:8080/business-central/rest/organizationalunits

#Sleeping to give time for organizational unit to be created since it is asyncronous

sleep 5s

echo "cloning coolstore repo from gogs"

curl -i \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --user $BUSINESS_CENTRAL_USER:$BUSINESS_CENTRAL_PASSWORD \
    -X POST \
    -d '{"name":"coolstore","description":"repo for coolstore rules","requestType":"clone","gitURL":"http://gogs:bddgogs@gogs:3000/gogs/CoolstoreRules.git","organizationalUnitName":"coolstore"}' \
    http://business-central:8080/business-central/rest/repositories

