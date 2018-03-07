#!/bin/bash 
. vars.txt

echo "********* Performing Cleanup *****"
gcloud deployment-manager deployments list
gcloud deployment-manager deployments delete -q cities-service-as \
    cities-service-ig cities-service-it cities-service-hc cities-firewall
gcloud deployment-manager deployments list

gsutil rm -raf gs://${BUCKET_NAME}/*
gsutil rb -f gs://${BUCKET_NAME}/
echo "********* Cleanup Complete *****"

