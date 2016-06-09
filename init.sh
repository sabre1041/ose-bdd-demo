#!/bin/bash

set -e

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


OSE_CI_PROJECT="ci"
OSE_BDD_DEV_PROJECT="coolstore-bdd-dev"
OSE_BDD_PROD_PROJECT="coolstore-bdd-prod"
OSE_CLI_USER="admin"
OSE_CLI_PASSWORD="admin"
OSE_CLI_HOST="https://10.1.2.2:8443"
KIE_SERVER_USER="kieserver"
KIE_SERVER_PASSWORD="bdddemo1!"
KIE_CONTAINER="default=com.redhat:coolstore:2.0.0"
JENKINS_USER="admin"
JENKINS_DSL_JOB="bdd-coolstore-dsl"
CRUMB_ISSUER_URL='crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'



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
oc process -v APPLICATION_NAME=jenkins -f "${SCRIPT_BASE_DIR}/support/templates/jenkins-template.json" | oc create -f -


# Update Jenkins with Environment Variables
echo
echo "Adding environment variables to Jenkins..."
echo
oc env dc/jenkins KIE_SERVER_USER=${KIE_SERVER_USER} KIE_SERVER_PASSWORD=${KIE_SERVER_PASSWORD} -n $OSE_CI_PROJECT

echo
echo "Waiting for Jenkins build to begin..."
echo
wait_for_running_build "jenkins" "${OSE_CI_PROJECT}"

# Cancel initial build since this is a binary build with no content
oc cancel-build jenkins-1

oc start-build jenkins --from-dir="${SCRIPT_BASE_DIR}/docker/jenkins"

wait_for_running_build "jenkins" "${OSE_CI_PROJECT}" "2"

oc build-logs -f jenkins-2

# Process Nexus Template
oc process -v APPLICATION_NAME=nexus -f "${SCRIPT_BASE_DIR}/support/templates/nexus-template.json" | oc create -f -

echo
echo "Waiting for Nexus build to begin..."
echo
wait_for_running_build "nexus" "${OSE_CI_PROJECT}"

# Cancel initial build since this is a binary build with no content
oc cancel-build nexus-1

oc start-build nexus --from-dir="${SCRIPT_BASE_DIR}/docker/nexus"

wait_for_running_build "nexus" "${OSE_CI_PROJECT}" "2"

oc build-logs -f nexus-2

# Process Business-Central Template
oc process -v APPLICATION_NAME=business-central -f "${SCRIPT_BASE_DIR}/support/templates/business-central-template.json" | oc create -f -

echo
echo "Waiting for Business Central build to begin..."
echo
wait_for_running_build "business-central" "${OSE_CI_PROJECT}"

# Cancel initial build since this is a binary build with no content
oc cancel-build business-central-1

oc start-build business-central --from-dir="${SCRIPT_BASE_DIR}/docker/business-central"

wait_for_running_build "business-central" "${OSE_CI_PROJECT}" "2"

oc build-logs -f business-central-2


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
wait_for_running_build "coolstore-app" "${OSE_BDD_DEV_PROJECT}"

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
wait_for_running_build "coolstore-rules" "${OSE_BDD_DEV_PROJECT}"

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


# Trigger Jenkins DSL Build
echo
echo "Triggering Jenkins DSL Seed Job..."
echo

JENKINS_PASSWORD=$(oc env dc/jenkins -n $OSE_CI_PROJECT --list | grep JENKINS_PASSWORD | cut -d'=' -f2)
JENKINS_HOST=$(oc get route jenkins -n $OSE_CI_PROJECT --template='{{ .spec.host }}')
JENKINS_CRUMB=$(curl --user ${JENKINS_USER}:${JENKINS_PASSWORD} http://${JENKINS_HOST}/${CRUMB_ISSUER_URL} 2>/dev/null)
curl -X POST http://${JENKINS_HOST}/job/${JENKINS_DSL_JOB}/build -H "${JENKINS_CRUMB}" --user "${JENKINS_USER}:${JENKINS_PASSWORD}"

sleep 10

LAST_BUILD_NUMBER=$(curl -s http://${JENKINS_HOST}/job/${JENKINS_DSL_JOB}/lastBuild/buildNumber --header "${JENKINS_CRUMB}" --user "${JENKINS_USER}:${JENKINS_PASSWORD}")

while true
do
    BUILD_STATUS=$(curl -s http://${JENKINS_HOST}/job/${JENKINS_DSL_JOB}/lastBuild/api/json?pretty=true  --header "${JENKINS_CRUMB}" --user "${JENKINS_USER}:${JENKINS_PASSWORD}" | grep \"result\" | awk '{print $3}'
)
    if [[ $BUILD_STATUS == *"SUCCESS"* ]]
    then
        break
    elif [[ $BUILD_STATUS == *"FAILED"* ]]
    then
        echo "Build Failed"
        exit 1
    fi

done


echo
echo "Setup Complete"
echo

echo "Jenkins: http://$(oc get route jenkins -n $OSE_CI_PROJECT --template='{{ .spec.host }}')"
echo "Nexus: http://$(oc get route nexus -n $OSE_CI_PROJECT --template='{{ .spec.host }}')"
