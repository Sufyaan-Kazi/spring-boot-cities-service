#!/bin/bash 

gcloud deployment-manager deployments delete cities-service -q --async
gcloud deployment-manager deployments delete cities-ui -q
gcloud compute instances list
