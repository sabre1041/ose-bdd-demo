#!/bin/bash

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


OSE_CI_PROJECT="ci"
OSE_BDD_DEV_PROJECT="coolstore-bdd-dev"
OSE_BDD_PROD_PROJECT="coolstore-bdd-prod"
OSE_CLI_USER="admin"
OSE_CLI_PASSWORD="admin"
OSE_CLI_HOST="https://10.1.2.2:8443"
GIT_REF="master"
KIE_SERVER_USER="kieserver"
KIE_SERVER_PASSWORD="bdddemo1!"
KIE_CONTAINER="default=com.redhat:coolstore:2.0.0"



function wait_for_running_first_build() {
    APP_NAME=$1
    NAMESPACE=$2

    while true
    do
        BUILD_STATUS=$(oc get builds ${APP_NAME}-1 -n ${NAMESPACE} --template='{{ .status.phase }}')

        if [ "$BUILD_STATUS" == "Running" ] || [ "$BUILD_STATUS" == "Complete" ] || [ "$BUILD_STATUS" == "Failed" ]; then
           break
        fi
    done

}



oc login -u ${OSE_CLI_USER} -p ${OSE_CLI_PASSWORD} ${OSE_CLI_HOST} --insecure-skip-tls-verify=true

echo
echo "Creating new CI Project (${OSE_CI_PROJECT})..."
echo

# Create New Project
oc new-project ${OSE_CI_PROJECT}

echo
echo "Creating Jenkins Service Account and Adding Permissions..."
echo

# Create New Service Account
oc process -v NAME=jenkins -f "${SCRIPT_BASE_DIR}/support/templates/create-sa.json" | oc create -f -

# Create Jenkins Service Account
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:jenkins

# Process RHEL Template
oc create -f"${SCRIPT_BASE_DIR}/support/templates/rhel7-is.json"

# Import Upstream Image
oc import-image rhel7

# Process Jenkins Template
oc process -v APPLICATION_NAME=jenkins,GIT_REF=${GIT_REF} -f "${SCRIPT_BASE_DIR}/support/templates/jenkins-template.json" | oc create -f -


# Update Jenkins with Environment Variables
echo
echo "Adding environment variables to Jenkins..."
echo
oc env dc/jenkins KIE_SERVER_USER=${KIE_SERVER_USER} KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -n $OSE_CI_PROJECT

echo
echo "Waiting for Jenkins build to begin..."
echo
wait_for_running_first_build "jenkins" "${OSE_CI_PROJECT}"

oc build-logs -f jenkins-1

# Process Nexus Template
oc process -v APPLICATION_NAME=nexus,GIT_REF=${GIT_REF} -f "${SCRIPT_BASE_DIR}/support/templates/nexus-template.json" | oc create -f -

echo
echo "Waiting for Nexus build to begin..."
echo
wait_for_running_first_build "jenkins" "${OSE_CI_PROJECT}"

oc build-logs -f nexus-1

echo
echo "Creating new BDD Dev Project (${OSE_BDD_DEV_PROJECT})..."
echo

# Create new Dev Project
oc new-project ${OSE_BDD_DEV_PROJECT}

# Grant Jenkins Service Account Access to Dev Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:jenkins -n ${OSE_BDD_DEV_PROJECT}

echo
echo "Creating Coolstore App in ${OSE_BDD_DEV_PROJECT}..."
echo
# Process app-store template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-app.json" | oc create -f -

echo
echo "Waiting for App build to begin..."
echo
wait_for_running_first_build "coolstore-app" "${OSE_BDD_DEV_PROJECT}"

# Cancel initial build since this is a binary build
oc cancel-build coolstore-app-1

echo
echo "Creating Coolstore Rules in ${OSE_BDD_DEV_PROJECT}..."
echo
# Process rules template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-rules.json" | oc create -f -

echo
echo "Waiting for Rules build to begin..."
echo
wait_for_running_first_build "coolstore-rules" "${OSE_BDD_DEV_PROJECT}"

# Cancel initial build since this is a binary build
oc cancel-build coolstore-rules-1

echo
echo "Creating new BDD Prod Project (${OSE_BDD_PROD_PROJECT})..."
echo
# Create new Dev Project
oc new-project ${OSE_BDD_PROD_PROJECT}

# Grant Jenkins Service Account Access to Dev Project
oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:jenkins -n ${OSE_BDD_PROD_PROJECT}

echo
echo "Creating Coolstore App in ${OSE_BDD_PROD_PROJECT}..."
echo
# Process app-store template
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-app-deploy.json" | oc create -f -

echo
echo "Creating Coolstore Prod in ${OSE_BDD_PROD_PROJECT}..."
echo
oc process -v KIE_SERVER_USER=${KIE_SERVER_USER},KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -f "${SCRIPT_BASE_DIR}/support/templates/coolstore-bdd-rules-deploy.json" | oc create -f -


oc policy add-role-to-user edit system:serviceaccount:${OSE_BDD_PROD_PROJECT}:default -n ${OSE_BDD_DEV_PROJECT}

echo
echo "Setup Complete"
echo

echo "Jenkins: http://$(oc get route jenkins -n $OSE_CI_PROJECT --template='{{ .spec.host }}')"
echo "Nexus: http://$(oc get route nexus -n $OSE_CI_PROJECT --template='{{ .spec.host }}')"