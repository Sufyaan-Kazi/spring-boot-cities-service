#!/bin/bash 

. ./vars.txt
. ./dmFunctions.sh

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

createFirewallRules() {
  echo_mesg "Creating Firewall Rules"

  ######### Create Firewalls
  # Do this late because of GCE Enforcer
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
checkAppIsReady $URL
# GCE Enforcer is a bit of a bully sometimes, and separately the app needs to stabilise a bit
sleep 5
echo_mesg "Launching Browser: $URL"
open http://${URL}/

echo_mesg "********** App Deployed **********"

echo_mesg "Deployment Complete in $SECONDS seconds."
