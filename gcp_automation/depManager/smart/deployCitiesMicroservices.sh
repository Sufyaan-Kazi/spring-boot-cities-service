#!/bin/bash 

# Author: Sufyaan Kazi
# Date: March 2018

#Load in vars and common functions
. ./vars.txt
. ./dmFunctions.sh

###
# Deploys the backend microservice - cities-service.
# This microservice reads city data from a database and exposes Restful endpoints for CRUD(ish) actions
#
# The function creates an instance template, instance group, autoscaling group, internal load balancer and healthcheck.
# The app spins up a basic in-mem db and loads in test data on first load. It can be configured ot use CloudSQL or a.n.other if needed.
###
deployCitiesService() {
  echo_mesg "Deploying cities-service"

  ######### Copy Startup Script for cities-service
  gsutil cp -r startup-scripts/cities-service.sh gs://${BUCKET_NAME}/startup-scripts/cities-service.sh 

  ######### Create Instance Group for cities service
  createRegionalInstanceGroup cities-service ${APP_REGION}

  ######### Define Internal Load Balancer for cities-service
  createIntLB cities-service ${APP_REGION}

  echo ""
}

###
# Deploys the cities-ui Microservice.
# This microservice calls the cities-service endpoints to display nice graphical representation of the cities data.
#
# The app reads the URL or ip address of the backing microservice from an ENVIRONMENT variable (set dynamically on startup)
###
deployCitiesUI() {
  echo_mesg "Deploying cities-ui"

  ######### Copy startup script for cities-ui
  gsutil cp -r startup-scripts/cities-ui.sh gs://${BUCKET_NAME}/startup-scripts/cities-ui.sh

  ######### Create Instance Groups for cities ui
  createRegionalInstanceGroup cities-ui ${APP_REGION}
  echo "  .... Waiting for apt-get updates to complete and then applications to start for cities-ui .... "
  sleep 120

  ######### Create External Load Balancer
  createExtLB cities-ui

  echo ""
}

###
# Utility function to define firewall rules.
# This function batches together firewall rules for both micorservices as GCE Enforcer may delete them while the
# deployment is runnning. 
#
# This should construct rules that:
#   - Enables traffic between the front-end HTTP load balancer (and healthchecks) to the cities-ui app (on port tcp:8080)
#   - Enables traffic between internal load balancer (and it's healthchecks) to the cities-service apps (on port tcp:8081)
#   - Enables traffic between the cities-ui layer and the cities-service layer (on port tcp:8081)
createFirewallRules() {
  echo_mesg "Creating Firewall Rules"
  createFirewall cities-service
  createFirewall cities-ui
  waitForHealthyBackend cities-ui

  echo ""
}

SECONDS=0

# Start
. ./cleanup.sh

echo_mesg "****** Deploying Microservices *****"

######### Create Bucket
echo_mesg "Creating Bucket"
gsutil mb gs://${BUCKET_NAME}/

deployCitiesService
deployCitiesUI

######### Launching Browser
echo_mesg "Determining external URL of application"
URL=`gcloud compute forwarding-rules list | grep cities-ui-fe | xargs | cut -d ' ' -f 2`
echo "  -> URL is $URL"
checkAppIsReady $URL
# GCE Enforcer is a bit of a bully sometimes and in addition the app needs to stabilise a bit
sleep 3
checkAppIsReady $URL
echo_mesg "Launching Browser: $URL"
open http://${URL}/

echo_mesg "********** App Deployed **********"

echo_mesg "Deployment Complete in $SECONDS seconds."
