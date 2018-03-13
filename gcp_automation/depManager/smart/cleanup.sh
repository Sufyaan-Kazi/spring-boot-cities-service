#!/bin/bash 
. vars.txt

deleteBucket() {
  COUNT=`gsutil ls | grep ${BUCKET_NAME} | wc -l`
  if [ $COUNT -ne 0 ]
  then
    echo "Deleting bucket"
    gsutil rm -raf gs://${BUCKET_NAME}/*
    gsutil rb -f gs://${BUCKET_NAME}/
  fi
}

deleteDeployment() {
  EXIST=`echo $DEPS | grep $1 | wc -l`

  if [ $EXIST -ne 0 ]
  then
    echo "Deleting Deployment: $1"
    nohup gcloud deployment-manager deployments delete -q $1 > /dev/null 2>&1 &
    wait
  fi
}

deleteDeploymentAsync() {
  EXIST=`echo $DEPS | grep $1 | wc -l`

  if [ $EXIST -ne 0 ]
  then
    echo "Deleting Deployment: $1"
    nohup gcloud deployment-manager deployments delete -q $1 --async > /dev/null 2>&1 &
  fi
}

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
gcloud deployment-manager deployments list
wait
deleteBucket &
wait
echo "********* Cleanup Complete *****"
