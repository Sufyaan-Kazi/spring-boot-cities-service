#!/bin/bash 

. ./vars.txt
. ./depFunctions.sh
. ./cleanup.sh

echo "****** Deploying Apps *****"
echo ""

######### Create Bucket
echo_mesg "Creating Bucket"
gsutil mb gs://${BUCKET_NAME}/
gsutil cp -r startup-scripts/cities-service.sh gs://${BUCKET_NAME}/startup-scripts/cities-service.sh
gsutil ls -al gs://${BUCKET_NAME}/

######### Create Instance Templates
createInstanceTemplate cities-service-it instance-template.yml

######### Create Instance Groups for cities service
TEMP_FILE=cities-service-as_temp_$$.yml
cat cities-service-as.yml | sed s/REGION/$SERVICE_REGION/g > ${TEMP_FILE}
createRegionalInstanceGroup cities-service-ig ${SERVICE_REGION} cities-service-ig.yml  ${TEMP_FILE} healthchecks.yml
INST=`gcloud compute instances list | grep cities-service-ig | grep RUNNING | head -n 1`
#getInstanceOutput $INST ${SERVICE_REGION}
rm -f ${TEMP_FILE}

######### Define Internal Load Balancer
createIntLB cities-service-int-lb lb.yml cities-service-ig ${SERVICE_REGION} fwd-rules.yml

######### Amend startup for cities-ui
echo_mesg "Storing IP of Internal Load Balancer in the instance template for web layer"
FWD_IP=`gcloud compute forwarding-rules list | grep cities-service | xargs | cut -d ' ' -f 3`
TEMP_FILE=cities_ui_$$.sh
cat startup-scripts/cities-ui.sh | sed s/LB_IP/$FWD_IP/g > startup-scripts/${TEMP_FILE}
gsutil cp -r startup-scripts/$TEMP_FILE gs://${BUCKET_NAME}/startup-scripts/cities-ui.sh
rm -f startup-scripts/${TEMP_FILE}

######### Create Instance Groups for cities ui
TEMP_FILE=cities-ui-as_temp_$$.yml
cat cities-ui-as.yml | sed s/REGION/$SERVICE_REGION/g > ${TEMP_FILE}
createRegionalInstanceGroup cities-ui-ig ${SERVICE_REGION} cities-ui-ig.yml  ${TEMP_FILE} healthchecks.yml
INST=`gcloud compute instances list | grep cities-ui-ig | grep RUNNING | head -n 1`
#getInstanceOutput $INST ${SERVICE_REGION}
rm -f ${TEMP_FILE}
echo "Waiting for Instances to Start"
sleep 120

######### Create cities-ui
#echo_mesg "Creating cities-ui"
#gcloud deployment-manager deployments create cities-instances --config instances.yml 
#waitForInstanceToStart cities-ui
# Wait for App to start
#echo "Waiting for app to start ... "
#sleep 120

######### Creating External Firewall Rules for App
echo_mesg "Creating External HTTP Firewall Rules"
gcloud deployment-manager deployments create cities-firewall --config firewall-rules.yml
echo "Waiting for firewall rule to take effect ...."
gcloud compute firewall-rules list | grep 8081
sleep 10

######### Launching Browser
echo_mesg "Launching Browser"
URL=`gcloud compute instances list | grep cities-ui | xargs | cut -d ' ' -f 5 `
open http://${URL}:8081/

echo_mesg "********** App Deployed **********"
