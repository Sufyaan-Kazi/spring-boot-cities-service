#!/bin/bash 
. vars.txt

deleteDeployment() {
  EXIST=`echo $DEPS | grep $1 | wc -l`

  if [ $EXIST -ne 0 ]
  then
    echo "Deleting Deployment: $1"
    gcloud deployment-manager deployments delete -q $1
  fi
}

echo "********* Performing Cleanup if necessary *****"

#Temp Hack because can't used deployment manager for forwarding rules for some reason

COUNT=`gcloud deployment-manager deployments list | grep cities-service | wc -l`
if [ $COUNT -ne 0 ]
then
  DEPS=`gcloud deployment-manager deployments list`

  deleteDeployment cities-service-fwd-rule
  deleteDeployment cities-service-int-lb
  deleteDeployment cities-service-as
  deleteDeployment cities-service-ig
  deleteDeployment cities-service-hc
  deleteDeployment cities-service-it
  deleteDeployment cities-instances
  deleteDeployment cities-firewall
  gcloud deployment-manager deployments list
fi

COUNT=`gsutil ls | grep ${BUCKET_NAME} | wc -l`
if [ $COUNT -ne 0 ]
then
  echo "Deleting bucket"
  gsutil rm -raf gs://${BUCKET_NAME}/*
  gsutil rb -f gs://${BUCKET_NAME}/
fi

echo "********* Cleanup Complete *****"
