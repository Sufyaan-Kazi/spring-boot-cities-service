#!/bin/bash 
set -e

gcloud compute instances create cities-service --zone europe-west2-b --machine-type=g1-small --network=custom-network --subnet=subnet2 --tags=service --metadata=serial-port-enable=1 --metadata-from-file=startup-script=startup-script.service

#gcloud compute instances create cities-service --zone europe-west2-b --machine-type=n1-standard-1 --network=custom-network --subnet=subnet2 --tags=service --metadata=serial-port-enable=1 --metadata-from-file=startup-script=startup-script.service

sleep 120
gcloud compute instances get-serial-port-output cities-service --zone=europe-west2-b

gcloud compute instances create cities-ui --zone europe-west3-b --machine-type=g1-small --network=custom-network --subnet=subnet3 --tags=web --metadata=serial-port-enable=1 --metadata-from-file=startup-script=startup-script.ui

sleep 120
gcloud compute instances get-serial-port-output cities-ui --zone=europe-west3-b
