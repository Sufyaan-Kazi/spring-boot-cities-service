#!/bin/bash 

. ./vars.txt
. ./dmFunctions.sh
. ./cleanup.sh

echo "****** Deploying Apps *****"
echo ""

######### Create Bucket
echo_mesg "Creating Bucket"
gsutil mb gs://${BUCKET_NAME}/

######### Copye Startup Script for cities-service
gsutil cp -r startup-scripts/cities-service.sh gs://${BUCKET_NAME}/startup-scripts/cities-service.sh

######### Create Instance Group for cities service
createRegionalInstanceGroup cities-service ${APP_REGION}

######### Define Internal Load Balancer for cities-service
createIntLB cities-service ${APP_REGION} 

######### Get IP of Internal Load Balancer
echo_mesg "Storing IP of Internal Load Balancer in the instance template for web layer"
FWD_IP=`gcloud compute forwarding-rules list | grep cities-service | xargs | cut -d ' ' -f 3`

######### Amend the startup script of cities-ui and insert IP of Load Balancer and copy to bucket
TEMP_FILE=cities_ui_$$.sh
cat startup-scripts/cities-ui.sh | sed s/LB_IP/$FWD_IP/g > startup-scripts/${TEMP_FILE}
gsutil cp -r startup-scripts/$TEMP_FILE gs://${BUCKET_NAME}/startup-scripts/cities-ui.sh
rm -f startup-scripts/${TEMP_FILE}

######### Create Instance Groups for cities ui
createRegionalInstanceGroup cities-ui ${APP_REGION}
echo "Waiting for apt-get updates to complete and then applications to start for cities-ui"
sleep 120

######### Create External Load Balancer
createExtLB cities-ui

######### Launching Browser
echo_mesg "Launching Browser"
URL=`gcloud compute forwarding-rules list | grep cities-ui-fe | xargs | cut -d ' ' -f 2`
open http://${URL}/

echo_mesg "********** App Deployed **********"
