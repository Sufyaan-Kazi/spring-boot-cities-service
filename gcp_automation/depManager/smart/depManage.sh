#!/bin/bash 

. ./vars.txt
. ./common.sh
. ./cleanup.sh

echo "****** Deploying Apps *****"
echo ""

#
#
# Create Bucket
#
#
echo_mesg "Creating Bucket"
gsutil mb gs://${BUCKET_NAME}/
gsutil cp -r startup-scripts/* gs://${BUCKET_NAME}/startup-scripts/
gsutil ls -al gs://${BUCKET_NAME}/

#
#
# Create Instance Templates
#
#
echo_mesg "Creating Instance Templates"
gcloud deployment-manager deployments create cities-service-it --config instance-template.yml

#
#
# Create Instance Groups for cities service
#
#
echo_mesg "Creating Instance Groups for cities_service"
gcloud deployment-manager deployments create cities-service-ig --config instance-group.yml
gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION}
gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION}
INST=`gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION} | tail -n 1 | cut -d ' ' -f1 | xargs`
SERVICE_ZONE=`gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION} | tail -n 1 | xargs | cut -d ' ' -f2 | xargs`
echo_mesg "Sleeping while instance initialises"
sleep 120
gcloud compute instances get-serial-port-output ${INST} --zone=${SERVICE_ZONE}

#
#
# Define Autoscaling for Instance Group
#
#
echo_mesg "Setting up Autoscale"
cat autoscale.yml | sed s/REGION/europe-west2/g > autoscale_temp_$$.yml
gcloud deployment-manager deployments create cities-service-as --config=autoscale_temp_$$.yml
rm -f autoscale_temp.yml

#
#
# Creating Healthcheck for Instance Group
#
#
echo_mesg "Linking HealthCheck to the Instance Group"
gcloud deployment-manager deployments create cities-service-hc --config=healthchecks.yml
gcloud beta compute instance-groups managed set-autohealing cities-service-ig --http-health-check=cities-service-hc --initial-delay=90 --region=europe-west2

#
#
# Define Internal Load Balancer
#
#
echo_mesg "Creating Internal Backend Service and internal load balancer"
gcloud deployment-manager deployments create cities-service-int-lb --config=lb.yml
echo_mesg "Defining Backend service to ILB"
gcloud compute backend-services add-backend cities-service-int-lb --instance-group=cities-service-ig --instance-group-region=${SERVICE_REGION} --region=${SERVICE_REGION}
echo_mesg "Defining Forwarding Rule for ILB"
gcloud deployment-manager deployments create cities-service-fwd-rule --config=fwd-rules.yml

#
#
# Create cities-ui
#
#
gcloud deployment-manager deployments create cities-instances --config instances.yml --async

#
#
# Creating External Firewall Rules for App
#
#
echo_mesg "Creating External HTTP Firewall Rules"
gcloud deployment-manager deployments create cities-firewall --config firewall-rules.yml

#
#
# Launching Browser
#
#
echo_mesg "Launching Browser"
URL=`gcloud compute instances list | grep cities-ui | xargs | cut -d ' ' -f 5 `
open http://${URL}:8081/

echo_mesg "********** App Deployed **********"
