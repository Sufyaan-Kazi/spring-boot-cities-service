#!/bin/bash 
. vars.txt

#gcloud deployment-manager deployments delete cities-service -q --async
gcloud deployment-manager deployments delete cities-instances -q
gcloud compute instances list

gcloud deployment-manager deployments delete cities-firewall -q
gcloud compute firewall-rules list --filter network=custom-network

gsutil rm -raf gs://${BUCKET_NAME}/*
gsutil rb -f gs://${BUCKET_NAME}/
