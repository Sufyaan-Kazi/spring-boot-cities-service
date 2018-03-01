#!/bin/bash 

. ./cleanup.sh

gcloud deployment-manager deployments create cities-instances --config instances.yml

#gcloud compute instances tail-serial-port-output cities-service

sleep 120
gcloud compute instances get-serial-port-output cities-service --zone=europe-west2-b
sleep 5
gcloud compute instances get-serial-port-output cities-ui --zone=europe-west3-b

gcloud deployment-manager deployments create cities-firewall --config firewall-rules.yml

URL=`gcloud compute instances list | grep cities-ui | xargs | cut -d ' ' -f 5 `
open http://${URL}:8081/
