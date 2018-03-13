#!/bin/bash 

# Author: Sufyaan Kazi
# Date: March 2018
# Purpose: Removes the cities-service and cities-ui deployments

# Load in cars
. vars.txt

##
# Removes bucket
#
deleteBucket() {
  COUNT=`gsutil ls | grep ${BUCKET_NAME} | wc -l`
  if [ $COUNT -ne 0 ]
  then
    echo "Deleting bucket"
    gsutil rm -raf gs://${BUCKET_NAME}/*
    gsutil rb -f gs://${BUCKET_NAME}/
  fi
}

##
# Wrapper method to delete a deployment.
#
# The method redirects all output to null and runs the command as nohup, so that even if the script is killed
# the delete action will then still try to complete cleanly in the background asynchronusly. If th escript isn't terminated,
# the method will not end till the background task completes, so that any other deployments being deleted won't fail because
# of parent/child depndency relationships between deployments.
###
deleteDeployment() {
  EXIST=`echo $DEPS | grep $1 | wc -l`

  if [ $EXIST -ne 0 ]
  then
    echo "Deleting Deployment: $1"
    nohup gcloud deployment-manager deployments delete -q $1 > /dev/null 2>&1 &
    wait
  fi
}

###
# Wrapper method to delete a deployment using the async flag.
#
# All output is sent to null and it the comand is executed as nohup
###
deleteDeploymentAsync() {
  EXIST=`echo $DEPS | grep $1 | wc -l`

  if [ $EXIST -ne 0 ]
  then
    echo "Deleting Deployment: $1"
    nohup gcloud deployment-manager deployments delete -q $1 --async > /dev/null 2>&1 &
  fi
}

###
# Deletes the cities-service microservice
###
deleteCitiesService() {
  COUNT=`gcloud deployment-manager deployments list | grep cities-service | wc -l`
  if [ $COUNT -ne 0 ]
  then
    DEPS=`gcloud deployment-manager deployments list`

    deleteDeploymentAsync cities-service-fw
    deleteDeployment cities-service-lb-fwd-rule
    deleteDeployment cities-service-lb
    deleteDeployment cities-service-ig-as
    deleteDeployment cities-service-ig
    deleteDeploymentAsync cities-service-lb-hc 
    deleteDeployment cities-service-it
  fi
}

###
# Deletes the cities-ui microservice
###
deleteCitiesUI() {
  COUNT=`gcloud deployment-manager deployments list | grep cities-ui | wc -l`
  if [ $COUNT -ne 0 ]
  then
    DEPS=`gcloud deployment-manager deployments list`

    deleteDeploymentAsync cities-ui-fw
    deleteDeployment cities-ui-ig-as 
    deleteDeployment cities-ui-fe
    deleteDeployment cities-ui-web-proxy
    deleteDeployment cities-ui-url-map
    deleteDeployment cities-ui-be
    deleteDeployment cities-ui-ig
    deleteDeploymentAsync cities-ui-hc
    deleteDeploymentAsync cities-ui-it
  fi
}

echo "********* Performing Cleanup if necessary *****"
deleteCitiesUI &
deleteCitiesService &
wait
gcloud deployment-manager deployments list
deleteBucket &
wait
echo "********* Cleanup Complete *****"
