#!/bin/bash 

. ./vars.txt
. ./cleanup.sh

echo "****** Deploying Apps *****"
echo ""

echo "Creating Bucket"
gsutil mb gs://${BUCKET_NAME}/
gsutil cp -r startup-scripts/* gs://${BUCKET_NAME}/startup-scripts/
gsutil ls -al gs://${BUCKET_NAME}/

echo "Creating Instances"
gcloud deployment-manager deployments create cities-instances-templates --config instance-templates.yml




gcloud deployment-manager deployments create cities-instances --config instances.yml
#gcloud compute instances tail-serial-port-output cities-service
echo "Sleeping while instance initialises, monitor output using console or: gcloud compute instances tail-serial-port-output cities-service"
sleep 120
gcloud compute instances get-serial-port-output cities-service --zone=${SERVICE_ZONE}
sleep 5
gcloud compute instances get-serial-port-output cities-ui --zone=${UI_ZONE}

echo "Creating Firewall Rules"
gcloud deployment-manager deployments create cities-firewall --config firewall-rules.yml

echo "Launching Browser"
URL=`gcloud compute instances list | grep cities-ui | xargs | cut -d ' ' -f 5 `
open http://${URL}:8081/

echo "********** App Deployed **********"
