#!/bin/bash

set -e

PROJECTID=$(gcloud config get-value project)
#APIS="iam compute"
APIS="cloudbuild run"
REGION="europe-west1"
#Get app name - assume it is current directory name
APPNAME=${PWD##*/}

main() {
  enableAPIS

  gcloud config set run/platform managed
  gcloud config set run/region $REGION

  ## Make sure code builds and tests pass
  ./gradlew build

  #Build the container using Cloud Build
  gcloud builds submit --tag gcr.io/${PROJECTID}/${APPNAME}

  #Deploy it to Cloud Run
  gcloud run deploy ${APPNAME}-service --image gcr.io/${PROJECTID}/${APPNAME} --platform managed --memory 512M --allow-unauthenticated
}

## Enable GCloud APIS
# This functions does the following
#  - Grab the list of currently enabled API's in the project
#  - Loop through the list of API's required in vars.txt
#  - For each API
#    - Check if it has been enabled already
#    - Assuming it hasn't, then enable it
#
enableAPIS() {
  ENABLED_APIS=$(gcloud services list --enabled | grep -v NAME | sort | cut -d " " -f1)
  #echo "Current APIs enabled are: ${ENABLED_APIS}"

  declare -a REQ_APIS=(${APIS})
  for api in "${REQ_APIS[@]}"
  do
    EXISTS=$(echo ${ENABLED_APIS} | grep ${api} | wc -l)
    if [ ${EXISTS} -eq 0 ]
    then
      echo "*** Enabling ${api} API"
      gcloud services enable "${api}.googleapis.com"
      sleep 2
    fi
  done
}

trap 'abort' 0
SECONDS=0
main
trap : 0
printf "\nComplete in ${SECONDS} seconds.\n"
