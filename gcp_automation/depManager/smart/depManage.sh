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
gcloud deployment-manager deployments create cities-instance-templates --config instance-template.yml
echo "Sleeping while instance initialises"
sleep 120

echo "Creating Firewall Rules"
gcloud deployment-manager deployments create cities-firewall --config firewall-rules.yml

echo "Launching Browser"
URL=`gcloud compute instances list | grep cities-ui | xargs | cut -d ' ' -f 5 `
open http://${URL}:8081/

echo "********** App Deployed **********"
