#!/bin/bash

set -e

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# OSE Login
OSE_CLI_USER="admin"
OSE_CLI_PASSWORD="admin"
OSE_CLI_HOST="https://10.1.2.2:8443"

# OpenShift Projects
OSE_CI_PROJECT="ci"
OSE_BDD_DEV_PROJECT="coolstore-bdd-dev"
OSE_BDD_PROD_PROJECT="coolstore-bdd-prod"

#BRMS
KIE_SERVER_USER="kieserver"
KIE_SERVER_PASSWORD="bdddemo1!"

# Jenkins
JENKINS_USER="admin"
JENKINS_DSL_JOB="bdd-coolstore-dsl"
COOLSTORE_TEST_HARNESS_JOB="coolstore-test-harness-pipeline"
CRUMB_ISSUER_URL='crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'

# Gogs and PostgreSQL Credentials
GOGS_ADMIN_USER="gogs"
GOGS_ADMIN_PASSWORD="bddgogs"
POSTGRESQL_USER="postgresql"
POSTGRESQL_PASSWORD="password"
POSTGRESQL_DATABASE="gogs"

# Gogs Projects
COOLSTORE_APP_PROJECT="coolstore-app"
COOLSTORE_TEST_HARNESS_PROJECT="coolstore-test-harness"
COOLSTORE_RULES_PROJECT="coolstore-rules"
CI_PROJECT="ci"


function wait_for_running_build() {
    APP_NAME=$1
    NAMESPACE=$2
    BUILD_NUMBER=$3

    [ ! -z "$3" ] && BUILD_NUMBER="$3" || BUILD_NUMBER="1"

    set +e

    while true
    do
        BUILD_STATUS=$(oc get builds ${APP_NAME}-${BUILD_NUMBER} -n ${NAMESPACE} --template='{{ .status.phase }}')

        if [ "$BUILD_STATUS" == "Running" ] || [ "$BUILD_STATUS" == "Complete" ] || [ "$BUILD_STATUS" == "Failed" ]; then
           break
        fi
    done

    set -e

}

function wait_for_endpoint_registration() {
    ENDPOINT=$1
    NAMESPACE=$2
    
    set +e
    
    while true
    do
        oc get ep $ENDPOINT -n $NAMESPACE -o yaml | grep "\- addresses:" >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            break
        fi
        
        sleep 10
        
    done

    set -e
}

function execute_jenkins_job() {
    JENKINS_HOST=$1
    JENKINS_JOB=$2
    PARAMETER_BUILD=$3
    
    if [ -z $PARAMETER_BUILD ]; then
        PARAMETER_BUILD_CONTEXT="build"
    else
        PARAMETER_BUILD_CONTEXT="buildWithParameters"
    fi
    
    
    echo
    echo "Running Jenkins job ${JENKINS_JOB}..."
    echo
    
    curl -X POST http://${JENKINS_HOST}/job/${JENKINS_JOB}/${PARAMETER_BUILD_CONTEXT} --user "${JENKINS_USER}:${JENKINS_PASSWORD}"

    sleep 10
    
    echo "Waiting for ${JENKINS_JOB} job to complete..."
    echo

    while true
    do
        BUILD_STATUS=$(curl -s http://${JENKINS_HOST}/job/${JENKINS_JOB}/lastBuild/api/json?pretty=true --user "${JENKINS_USER}:${JENKINS_PASSWORD}" | grep \"result\" | awk '{print $3}'
    )
        if [[ $BUILD_STATUS == *"SUCCESS"* ]]
        then
            echo "Build completed successfully!"
            break
        elif [[ $BUILD_STATUS == *"FAILURE"* ]]
        then
            echo "Build Failed"
            exit 1
        fi

        sleep 5

    done
    
}


echo
echo "Beginning setup of demo environmnet..."
echo

# Login to OSE
oc login -u ${OSE_CLI_USER} -p ${OSE_CLI_PASSWORD} ${OSE_CLI_HOST} --insecure-skip-tls-verify=true

# Create CI Project
echo
echo "Creating new CI Project (${OSE_CI_PROJECT})..."
echo
oc new-project ${OSE_CI_PROJECT}


echo
echo "Creating Jenkins Service Account and Adding Permissions..."
echo

# Create New Service Account
oc process -v NAME=jenkins -f "${SCRIPT_BASE_DIR}/support/templates/infrastructure/create-sa.json" | oc create -n ${OSE_CI_PROJECT} -f -


# Configure Security
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:default -n ${OSE_CI_PROJECT}


# Process RHEL Template
oc create -f"${SCRIPT_BASE_DIR}/support/templates/infrastructure/rhel7-is.json" -n ${OSE_CI_PROJECT}

# Import Upstream Image
oc import-image rhel7

# Process Jenkins Agent Template
echo
echo "Processing Jenkins Agent Template..."
echo
oc process -v APPLICATION_NAME=jenkins-agent -f "${SCRIPT_BASE_DIR}/support/templates/infrastructure/jenkins-agent-template.json" | oc -n ${OSE_CI_PROJECT} create -f - 

echo
echo "Starting Jenkins Agent binary build..."
echo
oc start-build -n ${OSE_CI_PROJECT} jenkins-agent --from-dir="${SCRIPT_BASE_DIR}/infrastructure/jenkins-agent"

wait_for_running_build "jenkins-agent" "${OSE_CI_PROJECT}"

oc build-logs -n ${OSE_CI_PROJECT} -f jenkins-agent-1

# Process Jenkins Template
echo
echo "Processing Jenkins Template..."
echo
oc process -v APPLICATION_NAME=jenkins -f "${SCRIPT_BASE_DIR}/support/templates/infrastructure/jenkins-template.json" | oc -n ${OSE_CI_PROJECT} create -f -

echo
echo "Updating Jenkins Credentials..."
echo
if [ $(uname -s) == "Darwin" ]; then
	# Mac detected, uses this sed command.
	sed -i "" "s:<username>.*</username>:<username>$KIE_SERVER_USER</username>:" $SCRIPT_BASE_DIR/infrastructure/jenkins/configuration/credentials.xml.tpl
	sed -i "" "s:<password>.*</password>:<password>$KIE_SERVER_PASSWORD</password>:" $SCRIPT_BASE_DIR/infrastructure/jenkins/configuration/credentials.xml.tpl 
else
	# All other OS's use this sed command.
	sed -i "s:<username>.*</username>:<username>$KIE_SERVER_USER</username>:" $SCRIPT_BASE_DIR/infrastructure/jenkins/configuration/credentials.xml.tpl
	sed -i "s:<password>.*</password>:<password>$KIE_SERVER_PASSWORD</password>:" $SCRIPT_BASE_DIR/infrastructure/jenkins/configuration/credentials.xml.tpl
fi

echo
echo "Starting Jenkins binary build..."
echo
oc start-build -n ${OSE_CI_PROJECT} jenkins --from-dir="${SCRIPT_BASE_DIR}/infrastructure/jenkins"

wait_for_running_build "jenkins" "${OSE_CI_PROJECT}"

oc build-logs -n ${OSE_CI_PROJECT} -f jenkins-1

# Process Nexus Template
echo
echo "Processing Nexus Template..."
echo
oc process -v APPLICATION_NAME=nexus -f "${SCRIPT_BASE_DIR}/support/templates/infrastructure/nexus-template.json" | oc -n ${OSE_CI_PROJECT} create -f -

echo
echo "Starting Nexus binary build..."
echo
oc start-build -n ${OSE_CI_PROJECT} nexus --from-dir="${SCRIPT_BASE_DIR}/infrastructure/nexus"

wait_for_running_build "nexus" "${OSE_CI_PROJECT}"

oc build-logs -n ${OSE_CI_PROJECT} -f nexus-1


echo
echo "Deploying PostgreSQL for Gogs..."
echo
oc process -f $SCRIPT_BASE_DIR/support/templates/infrastructure/postgresql-persistent.json -v=POSTGRESQL_DATABASE=$POSTGRESQL_DATABASE POSTGRESQL_USER=$POSTGRESQL_USER POSTGRESQL_PASSWORD=$POSTGRESQL_PASSWORD  | oc create -n $OSE_CI_PROJECT -f- >/dev/null 2>&1

wait_for_endpoint_registration "postgresql" "$OSE_CI_PROJECT"

echo
echo "Deploying Gogs Server..."
echo
oc process -f $SCRIPT_BASE_DIR/support/templates/infrastructure/gogs-persistent-template.json | oc create -n $OSE_CI_PROJECT -f-

wait_for_endpoint_registration "gogs" "$OSE_CI_PROJECT"

# Determine Running Pod
GOGS_POD=$(oc get pods -n $OSE_CI_PROJECT -l=deploymentconfig=gogs --no-headers | awk '{ print $1 }')

GOGS_ROUTE=$(oc get routes -n $OSE_CI_PROJECT gogs --template='{{ .spec.host }}')

# Sleep before setting up gogs server
echo
echo "Pausing a Moment..."
echo
sleep 10


echo
echo "Setting up Gogs Server..."
echo
# Setup Server
HTTP_RESPONSE=$(curl -o /dev/null -sL -w "%{http_code}" http://$GOGS_ROUTE/install \
--form db_type=PostgreSQL \
--form db_host=postgresql:5432 \
--form db_user=$POSTGRESQL_USER \
--form db_passwd=$POSTGRESQL_PASSWORD \
--form db_name=$POSTGRESQL_DATABASE \
--form ssl_mode=disable \
--form db_path=data/gogs.db \
--form "app_name=Gogs: Go Git Service" \
--form repo_root_path=/home/gogs/gogs-repositories \
--form run_user=gogs \
--form domain=localhost \
--form ssh_port=22 \
--form http_port=3000 \
--form app_url=http://$GOGS_ROUTE/ \
--form log_root_path=/opt/gogs/log \
--form admin_name=$GOGS_ADMIN_USER \
--form admin_passwd=$GOGS_ADMIN_PASSWORD \
--form admin_confirm_passwd=$GOGS_ADMIN_PASSWORD \
--form admin_email=gogs@redhat.com)

if [ $HTTP_RESPONSE != "200" ]
then
    echo "Error occurred when installing Gogs Service. HTTP Response $HTTP_RESPONSE"
    exit 1
fi

echo
echo "Initialized Gogs Server.... Pausing..."
echo

sleep 10

echo
echo "Setting up Coolstore App Project git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $SCRIPT_BASE_DIR/projects/$COOLSTORE_APP_PROJECT $GOGS_POD:/tmp/ 
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$COOLSTORE_APP_PROJECT && git init && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit'"
curl -H "Content-Type: application/json" -X POST -d "{\"clone_addr\": \"/tmp/$COOLSTORE_APP_PROJECT\",\"uid\": 1,\"repo_name\": \"$COOLSTORE_APP_PROJECT\"}" --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate
curl -H "Content-Type: application/json" -X POST -d '{"type": "gogs","config": { "url": "http://admin:password@jenkins:8080/job/coolstore-app-pipeline/buildWithParameters?delay=0", "content_type": "json" }, "active": true }' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/gogs/$COOLSTORE_APP_PROJECT/hooks

echo
echo "Setting up Coolstore Test Harness Project git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $SCRIPT_BASE_DIR/projects/$COOLSTORE_TEST_HARNESS_PROJECT $GOGS_POD:/tmp/
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$COOLSTORE_TEST_HARNESS_PROJECT && git init && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit'"
curl -H "Content-Type: application/json" -X POST -d "{\"clone_addr\": \"/tmp/$COOLSTORE_TEST_HARNESS_PROJECT\",\"uid\": 1,\"repo_name\": \"$COOLSTORE_TEST_HARNESS_PROJECT\"}" --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"type": "gogs","config": { "url": "http://admin:password@jenkins:8080/job/coolstore-test-harness-pipeline/buildWithParameters?delay=0", "content_type": "json" }, "active": true }' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/gogs/$COOLSTORE_TEST_HARNESS_PROJECT/hooks

# Setup Git Hook in Rules Project
cp -f ${SCRIPT_BASE_DIR}/support/scripts/post-receive-coolstore-rules ${SCRIPT_BASE_DIR}/projects/$COOLSTORE_RULES_PROJECT/post-receive

echo
echo "Setting up Coolstore Rules Project git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $SCRIPT_BASE_DIR/projects/$COOLSTORE_RULES_PROJECT $GOGS_POD:/tmp/
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$COOLSTORE_RULES_PROJECT && git init && mv post-receive /tmp/ && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit' && git branch deployments"
curl -H "Content-Type: application/json" -X POST -d "{\"clone_addr\": \"/tmp/$COOLSTORE_RULES_PROJECT\",\"uid\": 1,\"repo_name\": \"$COOLSTORE_RULES_PROJECT\"}" --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate >/dev/null 2>&1
sleep 10
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "mv /tmp/post-receive /home/gogs/gogs-repositories/gogs/$COOLSTORE_RULES_PROJECT.git/hooks/ && chmod +x /home/gogs/gogs-repositories/gogs/$COOLSTORE_RULES_PROJECT.git/hooks/post-receive"

rm -f ${SCRIPT_BASE_DIR}/projects/$COOLSTORE_RULES_PROJECT/post-receive

echo
echo "Setting up ci git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $SCRIPT_BASE_DIR/projects/$CI_PROJECT $GOGS_POD:/tmp/
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$CI_PROJECT && git init && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit'"
curl -H "Content-Type: application/json" -X POST -d "{\"clone_addr\": \"/tmp/$CI_PROJECT\",\"uid\": 1,\"repo_name\": \"$CI_PROJECT\"}" --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"type": "gogs","config": { "url": "http://admin:password@jenkins:8080/job/bdd-coolstore-dsl/buildWithParameters?delay=0", "content_type": "json" }, "active": true }' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/gogs/$CI_PROJECT/hooks


echo
echo "Setting up persistent gogs configuration..."
echo

mkdir -p $SCRIPT_BASE_DIR/installgogs
oc rsync -n ${OSE_CI_PROJECT} $GOGS_POD:/etc/gogs installgogs/
oc secrets new gogs-config -n ${OSE_CI_PROJECT} $SCRIPT_BASE_DIR/installgogs/gogs/conf
oc volume dc/gogs -n ${OSE_CI_PROJECT} --add --overwrite --name=config-volume -m /etc/gogs/conf/ --type=secret --secret-name=gogs-config >/dev/null 2>&1
rm -rf $SCRIPT_BASE_DIR/installgogs

# Process eap-builder-with-git template
echo
echo "Processing eap with git builder image Template..."
echo
oc process -v APPLICATION_NAME=eap-builder-with-git -f "${SCRIPT_BASE_DIR}/support/templates/infrastructure/eap-builder-with-git-template.json" | oc create -n ${OSE_CI_PROJECT} -f -

echo
echo "Starting eap with git builder binary build..."
echo
oc start-build eap-builder-with-git --from-dir="${SCRIPT_BASE_DIR}/infrastructure/eap-builder-with-git"

wait_for_running_build "eap-builder-with-git" "${OSE_CI_PROJECT}"

oc build-logs -n ${OSE_CI_PROJECT} -f eap-builder-with-git-1


# Process Business-Central Template
echo
echo "Processing Business Central Template..."
echo
oc process -v APPLICATION_NAME=business-central -f "${SCRIPT_BASE_DIR}/support/templates/infrastructure/business-central-template.json" | oc create -n ${OSE_CI_PROJECT} -f -

echo
echo "Starting Business Central binary build..."
echo
oc start-build business-central --from-dir="${SCRIPT_BASE_DIR}/infrastructure/business-central"

wait_for_running_build "business-central" "${OSE_CI_PROJECT}"

oc build-logs -n ${OSE_CI_PROJECT} -f business-central-1


echo
echo "Creating new BDD Dev Project (${OSE_BDD_DEV_PROJECT})..."
echo

# Create new Dev Project
oc new-project ${OSE_BDD_DEV_PROJECT}

# Grant Default Service Account Access to Dev Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_BDD_DEV_PROJECT:default -n ${OSE_BDD_DEV_PROJECT}

# Grant Jenkins Service Account Access to Dev Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:default -n ${OSE_BDD_DEV_PROJECT}

echo
echo "Creating nodejs ImageStream in ${OSE_BDD_DEV_PROJECT}..."
echo
oc create -f"${SCRIPT_BASE_DIR}/support/templates/infrastructure/nodejs-is.json" -n ${OSE_BDD_DEV_PROJECT}


echo
echo "Creating Coolstore App in ${OSE_BDD_DEV_PROJECT}..."
echo
# Process app-store template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER} KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/apps/coolstore-bdd-app.json" | oc create -n ${OSE_BDD_DEV_PROJECT} -f -

echo
echo "Waiting for App build to begin..."
echo
wait_for_running_build "coolstore-app" "${OSE_BDD_DEV_PROJECT}"

# Cancel initial build since this is a binary build
oc cancel-build -n ${OSE_BDD_DEV_PROJECT} coolstore-app-1

echo
echo "Creating Coolstore Rules in ${OSE_BDD_DEV_PROJECT}..."
echo
# Process rules template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER} KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/apps/coolstore-bdd-rules.json" | oc create -n ${OSE_BDD_DEV_PROJECT} -f -

echo
echo "Waiting for Rules build to begin..."
echo
wait_for_running_build "coolstore-rules" "${OSE_BDD_DEV_PROJECT}"

# Cancel initial build since this is a binary build
oc cancel-build -n ${OSE_BDD_DEV_PROJECT} coolstore-rules-1

echo
echo "Creating new BDD Prod Project (${OSE_BDD_PROD_PROJECT})..."
echo
# Create new Dev Project
oc new-project ${OSE_BDD_PROD_PROJECT}

# Grant Default Service Account Access to Dev Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_BDD_PROD_PROJECT:default -n ${OSE_BDD_PROD_PROJECT}

# Grant Jenkins Service Account Access to Prod Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:default -n ${OSE_BDD_PROD_PROJECT}

echo
echo "Creating Coolstore App in ${OSE_BDD_PROD_PROJECT}..."
echo
# Process app-store template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER} KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/apps/coolstore-bdd-app-deploy.json" | oc create -n ${OSE_BDD_PROD_PROJECT} -f -

echo
echo "Creating Coolstore Prod in ${OSE_BDD_PROD_PROJECT}..."
echo
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER} KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/apps/coolstore-bdd-rules-deploy.json" | oc create -n ${OSE_BDD_PROD_PROJECT} -f -


oc policy add-role-to-user edit system:serviceaccount:${OSE_BDD_PROD_PROJECT}:default -n ${OSE_BDD_DEV_PROJECT}


# Trigger Jenkins DSL Build
echo
echo "Triggering Jenkins DSL Seed Job..."
echo

JENKINS_PASSWORD=$(oc env dc/jenkins -n $OSE_CI_PROJECT --list | grep JENKINS_PASSWORD | cut -d'=' -f2)
JENKINS_HOST=$(oc get route jenkins -n $OSE_CI_PROJECT --template='{{ .spec.host }}')

sleep 10

execute_jenkins_job "${JENKINS_HOST}" "${JENKINS_DSL_JOB}"

execute_jenkins_job "${JENKINS_HOST}" "${COOLSTORE_TEST_HARNESS_JOB}" "true"

echo
echo "Setup Complete"
echo

echo "Jenkins: http://$(oc get route jenkins -n $OSE_CI_PROJECT --template='{{ .spec.host }}')"
echo "Nexus: http://$(oc get route nexus -n $OSE_CI_PROJECT --template='{{ .spec.host }}')"
