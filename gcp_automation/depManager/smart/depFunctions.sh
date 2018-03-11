#!/bin/bash 

echo_mesg() {
   echo ""
   echo "  ----- $1 ----  "
   echo ""
}

getYAMLValue() {
  echo $1 | cut -d ':' | xargs -f2
}

# Create Instance Template
createInstanceTemplate() {
  if [ $# -ne 2 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> <configFile.yml>"
    exit 1
  fi

  echo_mesg "Creating Instance Template: $1"
  gcloud deployment-manager deployments create $1 --config $2
}

waitForInstanceToStart(){
  INSTANCE_NAME=$1
  ZONE=`gcloud compute instances list | grep $INSTANCE_NAME | xargs | cut -d ' ' -f2`
  STATUS=`gcloud compute instances describe $INSTANCE_NAME --zone=${ZONE} | grep "status:" | cut -d ' ' -f2`
  while [[ "$STATUS" != "RUNNING" ]]
  do
    echo "Sleeping while instance starts ...."
    sleep 10
    STATUS=`gcloud compute instances describe $INSTANCE_NAME --zone=${ZONE} | grep "status:" | cut -d ' ' -f2`
  done
}

getInstanceOutput() {
  INST=$1
  ZONE=`gcloud compute instances list | grep $INST | xargs | cut -d ' ' -f2`
  gcloud compute instances get-serial-port-output ${INST} --zone=${ZONE}
}

# Create Regional Instance Groups
createRegionalInstanceGroup() {
  if [ $# -ne 5 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> <region> <ig_configFile.yml> <as_configFile.yml> <hc_configFile.yml>"
    exit 1
  fi

  INSTANCEG=$1
  REGION=$2

  echo_mesg "Creating Instance Group: $1 "
  gcloud deployment-manager deployments create $1 --config $3

  # Define Autoscaling for Instance Group
  echo_mesg "Setting up Autoscale"
  gcloud deployment-manager deployments create ${INSTANCEG}-as --config=$4

  # Creating Healthcheck for Instance Group
  echo_mesg "Linking HealthCheck to the Instance Group"
  gcloud deployment-manager deployments create ${INSTANCEG}-hc --config=$5
  #HC=`gcloud compute http-health-checks list | grep cities-service | xargs | cut -d ' ' -f1`
  #gcloud beta compute instance-groups managed set-autohealing ${INSTANCEG} --http-health-check=${HC} --initial-delay=90 --region=$REGION

  #INSTANCE_NAME=`gcloud compute instances list | grep $INSTANCEG | cut -d ' ' -f1 | head -n 1`
  #waitForInstanceToStart $INSTANCE_NAME
}

# Define Internal Load Balancer
createIntLB() {
  if [ $# -ne 5 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> <configFile.yml> <instancegroupname> <targetregion> <fwd_rule.yml>"
    exit 1
  fi

  echo_mesg "Creating Internal load balancer: $1"
  gcloud deployment-manager deployments create $1 --config=$2
  echo_mesg "Defining Backend service for Internal Load Balancer"
  gcloud compute backend-services add-backend $1 --instance-group=$3 --instance-group-region=$4 --region=$4
  echo_mesg "Defining Forwarding Rule for Internal Load Balancer"
  gcloud deployment-manager deployments create $3-fwd-rule --config=$5
  NAME=`cat $5 | grep "name: " | cut -d ':' -f2 | xargs`

  FWD_IP=`gcloud compute forwarding-rules list | grep $3 | xargs | cut -d ' ' -f 3`
  while [ -z $FWD_IP ]
  do
    echo "Waiting for IP of forwarding rule"
    sleep 10
    FWD_LIST=`gcloud compute forwarding-rules list | grep $NAME | wc -l`
    if [ $FWD_LIST -eq 1 ]
    then
      FWD_IP=`gcloud compute forwarding-rules list | grep $NAME | xargs | cut -d ' ' -f 3`
    fi
  done
  echo "IP of Internal Load Balancer is: $FWD_IP"

  INSTANCE_NAME=`gcloud compute instances list | grep $3 | cut -d ' ' -f1 | head -n 1`
  waitForInstanceToStart $INSTANCE_NAME
}

