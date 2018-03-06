#!/bin/bash 
. vars.txt

echo "********* Performing Cleanup *****"

gcloud deployment-manager deployments delete cities-instance-group -q
gcloud deployment-manager deployments delete cities-instance-template -q

gcloud deployment-manager deployments delete cities-firewall -q

gsutil rm -raf gs://${BUCKET_NAME}/*
gsutil rb -f gs://${BUCKET_NAME}/
echo "********* Cleanup Complete *****"

