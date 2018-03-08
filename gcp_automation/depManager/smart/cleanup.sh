#!/bin/bash 
. vars.txt

echo "********* Performing Cleanup if necessary *****"
COUNT=`gcloud deployment-manager deployments list | grep cities-service | wc -l`
if [ $COUNT -ne 0 ]
then
  gcloud deployment-manager deployments list
  gcloud deployment-manager deployments delete -q cities-service-int-lb
  gcloud deployment-manager deployments delete -q cities-service-ig
  gcloud deployment-manager deployments delete -q cities-service-as
  gcloud deployment-manager deployments delete -q cities-service-hc
  gcloud deployment-manager deployments delete -q cities-service-it
  gcloud deployment-manager deployments delete -q cities-firewall
  gcloud deployment-manager deployments list

  gsutil rm -raf gs://${BUCKET_NAME}/*
  gsutil rb -f gs://${BUCKET_NAME}/
fi

COUNT=`gsutil ls | grep ${BUCKET_NAME} | wc -l`
if [ $COUNT -ne 0 ]
then
  gsutil rm -raf gs://${BUCKET_NAME}/*
  gsutil rb -f gs://${BUCKET_NAME}/
fi

echo "********* Cleanup Complete *****"
