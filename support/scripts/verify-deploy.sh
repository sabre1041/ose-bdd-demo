#!/bin/bash
set -e


PORT=8443
RC_PHASE=""
COUNTER=0
DELAY=10
MAX_COUNTER=30
RC_NAME=


# Validate JQ is installed
command -v jq -q >/dev/null 2>&1 || { echo >&2 "json parser jq is required but not installed yet... aborting."; exit 1; }

usage() {
  echo "
  Usage: $0 [options]

  Options:
  -h|--host=<host>              : OpenShift Master
  -p|--port=<port>              : OpenShift Master port (Default: 8443)
  -t|--token=<token>            : OAuth Token to authenticate as
  -u|--user=<username>          : Username to authenticate as (Instead of Token)
  -w|--password=<password>      : Password to authenticate as (Instead of Token)
  -n|--namespace=<namespace>    : OpenShift Project
  -a|--app=<app>                : OpenShift Application
  "
}

# Set Trap
trap end_trap EXIT


# Process Input
for i in "$@"
do
  case $i in
    -h=*|--host=*)
      HOST="${i#*=}"
      shift;;
    -p=*|--port=*)
      PORT="${i#*=}"
      shift;;
    -u=*|--user=*)
      USER="${i#*=}"
      shift;;
    -w=*|--password=*)
      PASSWORD="${i#*=}"
      shift;;
    -n=*|--namespace=*)
      NAMESPACE="${i#*=}"
      shift;;
    -a=*|--app=*)
      APP="${i#*=}"
      shift;;
    -t=*|--token=*)
      TOKEN="${i#*=}"
      shift;;
  esac
done


function end_trap() {

  if [ $? -eq 0 ]; then
	echo
	echo "====================================================="  
	echo "= ${APP} Deployment ${RC_NAME} Succeeded!            "
	echo "====================================================="  
	echo
  else
  	echo
  	echo "====================================================="  
  	echo "= ${APP} Deploymnet Failed!                         ="
  	echo "====================================================="  
  	echo
fi

}


# Get token if not present
if [ -z $TOKEN ]; then
	
	# Validate user and password are present
	if [ -z $PASSWORD ] && [ -z $USER ]; then
		echo "Username and Password must be provided"
		usage
		exit 1
	fi

	# Get auth token
	CHALLENGE_RESPONSE=$(curl -s  -I --insecure -f  "https://${HOST}:8443/oauth/authorize?response_type=token&client_id=openshift-challenging-client" --user ${USER}:${PASSWORD} -H "X-CSRF-Token: 1")

	if [ $? -ne 0 ]; then
	    echo "Error: Unauthorized Access Attempt"
	    exit 1
	fi


	TOKEN=$(echo "$CHALLENGE_RESPONSE" | grep -oP "access_token=\K[^&]*")

	if [ -z "$TOKEN" ]; then
    	echo "Token is blank!"
    	exit 1
	fi
fi


LATEST_DC_VERSION=$(curl -s -f -H "Authorization: Bearer ${TOKEN}" --insecure  https://${HOST}:${PORT}/oapi/v1/namespaces/${NAMESPACE}/deploymentconfigs/${APP} | jq -r .status.latestVersion)


# Cycle Through Status to see if we have hit our deployment target
while [ $COUNTER -lt $MAX_COUNTER ]
do
    
    RC_NAME=${APP}-${LATEST_DC_VERSION}
    
    RC=$(curl -s -f -H "Authorization: Bearer ${TOKEN}" --insecure  https://${HOST}:${PORT}/api/v1/namespaces/${NAMESPACE}/replicationcontrollers/${RC_NAME})
    
    RC_STATUS=$(echo "$RC" | jq -r '.metadata.annotations["openshift.io/deployment.phase"]')
    
	# Check if build succeeded or failed
	if [ "$RC_STATUS" == "Complete" ]; then
		echo
		break
	fi
	
	if [ "$RC_STATUS" == "Failed" ] || [ "$RC_STATUS" == "Failed" ]; then
		echo
		echo
		echo "Deployment ${APP}-${LATEST_DC_VERSION} Failed with status \"${RC_STATUS}\""
		exit 1
	fi
	
	if [ "$RC_STATUS" == "Cancelled" ]; then
		echo
		echo
		echo "Deployment ${RC_NAME} was Cancelled"
		exit 1
	fi

	# Check build phase
	if [ "$RC_STATUS" != "$RC_PHASE" ]; then
		echo
		echo
		echo "Deployment Phase Changed. \"${RC_PHASE}\" -> \"${RC_STATUS}\""
		RC_PHASE=$RC_STATUS
		
		echo -n "Deployment Status: \"${RC_STATUS}\" "
		
		# Reset Counter
		COUNTER=0
	fi
	
	echo -n "."
	COUNTER=$(( $COUNTER + 1 ))
    
    if [ $COUNTER -eq $MAX_COUNTER ]; then
      echo "Max Validation Attempts Exceeded. Failed Verifying Application Deployment..."
      exit 1
    fi

	sleep $DELAY

done