#!/bin/bash
set -e


PORT=8443
BUILD_PHASE=""
COUNTER=0
DELAY=20
MAX_COUNTER=30
BUILD_NAME=


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
  -f|--file=<file>              : Location of a compressed file to use for a binary build type
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
    -f=*|--FILE=*)
      FILE="${i#*=}"
      shift;;
  esac
done


function end_trap() {

  if [ $? -eq 0 ]; then
	echo
	echo "====================================================="  
	echo "= ${APP} Build ${BUILD_NAME} Succeeded!        "
	echo "====================================================="  
	echo
  else
  	echo
  	echo "====================================================="  
  	echo "= ${APP} Build Failed!                              ="
  	echo "====================================================="  
  	echo
fi

}

# Validate file exists
if [ ! -f "$FILE" ]; then
    echo "Error: Binary File Input Does Not Exist"
    exit 1
fi


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

# Trigger a new build of application
echo "Triggering new build of ${APP}..."

if [ ! -z "${FILE}" ]; then

    NEW_BUILD_REQUEST=$(curl -s -f -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/octet-stream" -X POST --data-binary "@${FILE}" -k  https://${HOST}:${PORT}/oapi/v1/namespaces/${NAMESPACE}/buildconfigs/${APP}/instantiatebinary)

else

    NEW_BUILD_REQUEST=$(curl -s -f -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -X POST --data-binary "{\"kind\":\"BuildRequest\",\"apiVersion\":\"v1\",\"metadata\":{\"name\":\"$APP\"}}" --insecure  https://${HOST}:${PORT}/oapi/v1/namespaces/${NAMESPACE}/buildconfigs/${APP}/instantiate)

fi

BUILD_NAME=$(echo $NEW_BUILD_REQUEST | jq -r .metadata.name)

echo
echo "New build created: $BUILD_NAME"


# Allow build to progress through lifecycle (pending -> running). Give the build X amount of time to complete each phase resetting the counter
# when a new phase is entered

while [ $COUNTER -lt $MAX_COUNTER ]
do
	
	BUILD_STATUS_RESPONSE=$(curl -s -f -H "Authorization: Bearer ${TOKEN}" --insecure  https://${HOST}:${PORT}/oapi/v1/namespaces/${NAMESPACE}/builds/${BUILD_NAME})

	BUILD_STATUS=$(echo $BUILD_STATUS_RESPONSE | jq -r .status.phase)


	# Check if build succeeded or failed
	if [ "$BUILD_STATUS" == "Complete" ]; then
		echo
		break
	fi
	
	if [ "$BUILD_STATUS" == "Failed" ] || [ "$BUILD_STATUS" == "Failed" ]; then
		echo
		echo
		echo "Build ${BUILD_NAME} Failed with status \"${BUILD_STATUS}\""
		exit 1
	fi
	
	if [ "$BUILD_STATUS" == "Cancelled" ]; then
		echo
		echo
		echo "Build ${BUILD_NAME} was Cancelled"
		exit 1
	fi

	# Check build phase
	if [ "$BUILD_STATUS" != "$BUILD_PHASE" ]; then
		echo
		echo
		echo "Build Phase Changed. \"${BUILD_PHASE}\" -> \"${BUILD_STATUS}\""
		BUILD_PHASE=$BUILD_STATUS
		
		echo -n "Build Status: \"${BUILD_STATUS}\" "
		
		# Reset Counter
		COUNTER=0
	fi
	
	echo -n "."
	COUNTER=$(( $COUNTER + 1 ))
	
	sleep $DELAY

    if [ $COUNTER -eq $MAX_COUNTER ]; then
      echo "Max Validation Attempts Exceeded. Failed Verifying Application Build..."
      exit 1
    fi

done
