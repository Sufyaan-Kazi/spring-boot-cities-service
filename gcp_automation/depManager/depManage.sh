#!/bin/bash 

gcloud deployment-manager deployments delete cities-service -q

gcloud deployment-manager deployments create cities-service --config cities-service-vm.yml
ZONE=`gcloud compute instances describe cities-service| grep "zone:" | cut -d '/' -f9`
sleep 120
gcloud compute instances get-serial-port-output cities-service --zone=${ZONE}
