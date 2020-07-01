#!/bin/bash

set -e

PROJECTID=$(gcloud config get-value project)
#APIS="iam compute"
APIS="cloudbuild run"
REGION="europe-west1"
#Get app name - assume it is current directory name
APPNAME=${PWD##*/}

main() {
  ## Make sure code builds and tests pass
  ./gradlew build

  #Build the container using Cloud Build
  gcloud builds submit --tag gcr.io/${PROJECTID}/${APPNAME}

  #Deploy it to Cloud Run
  gcloud run deploy ${APPNAME}-service --image gcr.io/${PROJECTID}/${APPNAME} --platform managed --memory 512M --allow-unauthenticated
}

trap 'abort' 0
SECONDS=0
main
trap : 0
printf "\nComplete in ${SECONDS} seconds.\n"
