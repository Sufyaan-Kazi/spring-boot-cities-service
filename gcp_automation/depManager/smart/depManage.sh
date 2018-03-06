#!/bin/bash 

. ./vars.txt
. ./cleanup.sh

echo "****** Deploying Apps *****"
echo ""

echo "Creating Bucket"
gsutil mb gs://${BUCKET_NAME}/
gsutil cp -r startup-scripts/* gs://${BUCKET_NAME}/startup-scripts/
gsutil ls -al gs://${BUCKET_NAME}/

echo "Creating Instance Templates"
gcloud deployment-manager deployments create cities-instance-templates --config instance-template.yml

echo "Creating Instance Groups"
gcloud deployment-manager deployments create cities-instance-group --config instance-group.yml
gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION}
gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION}
INST=`gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION} | tail -n 1 | cut -d ' ' -f1 | xargs`
SERVICE_ZONE=`gcloud compute instance-groups managed list-instances cities-service-ig --region=${SERVICE_REGION} | tail -n 1 | xargs | cut -d ' ' -f2 | xargs`
echo $INST $SERVICE_ZONE
echo "Sleeping while instance initialises"
sleep 60
gcloud compute instances get-serial-port-output cities-service --zone=${SERVICE_ZONE}

# Define Autoscaling
echo "Autoscale"
cat autoscale.yml | sed s/REGION/europe-west2/g > autoscale_temp.yml
gcloud deployment-manager deployments create cities-service-as --config=autoscale_temp.yml
rm -f autoscale_temp.yml

echo "Creating Firewall Rules"
gcloud deployment-manager deployments create cities-firewall --config firewall-rules.yml

echo "Launching Browser"
URL=`gcloud compute instances list | grep cities-ui | xargs | cut -d ' ' -f 5 `
open http://${URL}:8081/

echo "********** App Deployed **********"
