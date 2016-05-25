#!/bin/bash

# Performs an ImageStream tag

PORT="8443"
SOURCE_TAG="latest"
DESTINATION_TAG="latest"


# Validate JQ is installed
command -v jq -q >/dev/null 2>&1 || { echo >&2 "json parser jq is required but not installed yet... aborting."; exit 1; }

usage() {
  echo "
  Usage: $0 [options]

  Options:
  -h|--host=<host>                                        : OpenShift Master
  -p|--port=<port>                                        : OpenShift Master port (Default: 8443)
  -sn|--source-namespace=<source-project>                 : Source Project
  -sa|--source-application=<source-application>           : Source Application
  -st|--source-tag=<source-tag>                           : Source ImageStream Tag
  -dn|--destination-namespace=<destination-namespace>     : Destination Namespace
  -da|--destination-application=<destination-application> : Destination Application
  -dt|--destination-tag=<destination-tag>                 : Destination ImageStream Tag
  -t|--=<token>                                           : OpenShift API Token

  "
}


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
    -sn=*|--source-namespace=*)
      SOURCE_NAMESPACE="${i#*=}"
      shift;;
    -sa=*|--source-application=*)
      SOURCE_APPLICATION="${i#*=}"
      shift;;
    -st=*|--source-tag=*)
      SOURCE_TAG="${i#*=}"
      shift;;
    -dn=*|--destination-namespace=*)
      DESTINATION_NAMESPACE="${i#*=}"
      shift;;
    -da=*|--destination-application=*)
      DESTINATION_APPLICATION="${i#*=}"
      shift;;
    -dt=*|--destination-tag=*)
      DESTINATION_TAG="${i#*=}"
      shift;;
    -t=*|--token=*)
      TOKEN="${i#*=}"
      shift;;
  esac
done

# Validate Input Parameters
if [ -z "${HOST}" ] || [ -z "${PORT}" ] || [ -z "${SOURCE_NAMESPACE}" ] || [ -z "${SOURCE_APPLICATION}" ] || [ -z "${SOURCE_TAG}" ] || [ -z "${SOURCE_NAMESPACE}" ] || [ -z "${SOURCE_APPLICATION}" ] || [ -z "${SOURCE_TAG}" ] || [ -z "${TOKEN}" ]; then
  usage  
  exit 1
fi


# Get Source ImageStream
SOURCE_IS=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" https://$HOST:$PORT/oapi/v1/namespaces/$SOURCE_NAMESPACE/imagestreams/$SOURCE_APPLICATION) 


# Find Source Tag in Stream 
SOURCE_ORIGINAL_TAG=$(echo ${SOURCE_IS} | jq -r --arg tag $SOURCE_TAG '.status.tags[] | select(.tag==$tag) | .')


# Find the Image Name in the 
SOURCE_TAG_IMAGE=$(echo "$SOURCE_ORIGINAL_TAG" | jq -r '.items[0].image')

# Raw Source of Tag
SOURCE_NEW_TAG="{ \"name\": \"${SOURCE_TAG}\", \"from\": { \"kind\": \"ImageStreamImage\", \"namespace\": \"${SOURCE_NAMESPACE}\", \"name\": \"${SOURCE_APPLICATION}@${SOURCE_TAG_IMAGE}\" } }"

# Check for Empty Value
DESTINATION_IS=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" https://$HOST:$PORT/oapi/v1/namespaces/$DESTINATION_NAMESPACE/imagestreams/$DESTINATION_APPLICATION)

if [ $(echo $DESTINATION_IS | jq -c -r .spec.tags) = null ]; then
  DESTINATION_IS=$(echo $DESTINATION_IS | jq -r '.spec |= .+ { tags:[null] }') 
fi

# Remove the existing set of tags
EMPTY_IS=$(echo "$DESTINATION_IS" | jq  -r --arg tag $DESTINATION_TAG '.spec.tags |= map(if .name == "latest" then del(.) else . end)')

# Update with the tag pointer
UPDATED_IS=$(echo "$EMPTY_IS" | jq ".spec.tags[] |= .+ $SOURCE_NEW_TAG")

# Update the destination ImageStream
curl -s -k -H "Authorization: Bearer ${TOKEN}" -X PUT --data-binary "$UPDATED_IS" https://$HOST:$PORT/oapi/v1/namespaces/$DESTINATION_NAMESPACE/imagestreams/$DESTINATION_APPLICATION > /dev/null 2>&1


