#!/bin/bash 

. ./cleanup.sh

gcloud deployment-manager deployments create cities-service --config instances.yml
sleep 120
gcloud compute instances get-serial-port-output cities-service --zone=europe-west2-b
gcloud compute instances get-serial-port-output cities-ui --zone=europe-west3-b
