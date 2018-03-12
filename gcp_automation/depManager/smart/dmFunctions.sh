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
  if [ $# -ne 1 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName>"
    exit 1
  fi

  local IT=$1-it

  echo_mesg "Creating Instance Template: $IT"
  gcloud deployment-manager deployments create $IT --config $IT.yml
}

waitForInstanceToStart(){
  local INSTANCE_NAME=$1
  local ZONE=`gcloud compute instances list | grep $INSTANCE_NAME | xargs | cut -d ' ' -f2`
  local STATUS=`gcloud compute instances describe $INSTANCE_NAME --zone=${ZONE} | grep "status:" | cut -d ' ' -f2`

  while [[ "$STATUS" != "RUNNING" ]]
  do
    echo "Sleeping while instance starts ...."
    sleep 10
    STATUS=`gcloud compute instances describe $INSTANCE_NAME --zone=${ZONE} | grep "status:" | cut -d ' ' -f2`
  done
}

getInstanceOutput() {
  local INST=$1
  local ZONE=`gcloud compute instances list | grep $INST | xargs | cut -d ' ' -f2`

  gcloud compute instances get-serial-port-output ${INST} --zone=${ZONE}
}

# Create Regional Instance Groups
createRegionalInstanceGroup() {
  if [ $# -ne 2 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> <region>"
    exit 1
  fi
  
  createInstanceTemplate $1

  local IG=$1-ig

  echo_mesg "Creating Instance Group: $IG"
  gcloud deployment-manager deployments create $IG --config $IG.yml

  # Define Autoscaling for Instance Group
  # Grab the "template" autoscale definition and replace REGION with actual region desired
  echo_mesg "Setting up Autoscale for: $IG"
  local TEMP_FILE=$IG-as_temp_$$.yml
  cat $IG-as.yml | sed s/REGION/$2/g > ${TEMP_FILE}
  gcloud deployment-manager deployments create $IG-as --config=$TEMP_FILE
  rm -f ${TEMP_FILE}

  # Creating Healthcheck for Instance Group
  #echo_mesg "Creating HealthCheck for the Instance Group"
  #gcloud deployment-manager deployments create $1-hc --config=$5
  #HC=`gcloud compute http-health-checks list | grep cities-service | xargs | cut -d ' ' -f1`
  #gcloud beta compute instance-groups managed set-autohealing ${INSTANCEG} --http-health-check=${HC} --initial-delay=90 --region=$REGION

  #INSTANCE_NAME=`gcloud compute instances list | grep $IG | cut -d ' ' -f1 | head -n 1`
  #waitForInstanceToStart $IG
}

# Define Internal Load Balancer
createIntLB() {
  if [ $# -ne 2 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> <targetregion>"
    exit 1
  fi

  local LB=$1-lb

  echo_mesg "Creating HealthCheck for the Internal Load Balancer: $LB"
  gcloud deployment-manager deployments create $LB-hc --config=$LB-hc.yml

  echo_mesg "Creating Internal load balancer: $LB"
  gcloud deployment-manager deployments create $LB --config=$LB.yml

  echo_mesg "Defining Backend service (Instance Group) for Internal Load Balancer: $LB"
  gcloud compute backend-services add-backend $LB --instance-group=$1-ig --instance-group-region=$2 --region=$2

  echo_mesg "Defining Forwarding Rule for Internal Load Balancer"
  gcloud deployment-manager deployments create $LB-fwd-rule --config=$LB-fwd-rule.yml

  # Get the IP of the Forwarding Rule once it's been assigned
  local FWD_IP=`gcloud compute forwarding-rules list | grep $LB-fwd-rule | xargs | cut -d ' ' -f 3`
  local FWD_LIST=""
  while [ -z $FWD_IP ]
  do
    echo "Waiting for IP of forwarding rule: $1-fwd-rule"
    sleep 10
    FWD_LIST=`gcloud compute forwarding-rules list | grep $LB-fwd-rule | wc -l`
    if [ $FWD_LIST -eq 1 ]
    then
      # Grab the ip
      FWD_IP=`gcloud compute forwarding-rules list | grep $LB-fwd-rule | xargs | cut -d ' ' -f 3`
    fi
  done
  echo "IP of Internal Load Balancer is: $FWD_IP"

  local INSTANCE_NAME=`gcloud compute instances list | grep $1-ig | cut -d ' ' -f1 | head -n 1`
  waitForInstanceToStart $INSTANCE_NAME

  echo_mesg "Creating Firewall Rule: $1"
  gcloud deployment-manager deployments create $1-fw --config $1-fw.yml
  echo "Waiting for firewall rule to take effect ...."
  gcloud compute firewall-rules list | grep $1-http
  sleep 10
}

# Create Ext HTTP Load Balancer
createExtLB() {
if [ $# -ne 1 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> "
    exit 1
  fi

  echo_mesg "Creating Healthcheck: $1"
  gcloud deployment-manager deployments create $1-hc --config=$1-hc.yml

  echo_mesg "Creating Backend Service: $1"
  gcloud deployment-manager deployments create $1-be --config=$1-be.yml

  echo_mesg "Creating URL Map: $1"
  gcloud deployment-manager deployments create $1-url-map --config=$1-url-map.yml

  echo_mesg "Creating Web Proxy: $1"
  gcloud deployment-manager deployments create $1-web-proxy --config=$1-web-proxy.yml

  echo_mesg "Creating Web FE: $1"
  gcloud deployment-manager deployments create $1-fe --config=$1-fe.yml

  sleep 5

  echo_mesg "Creating Firewall Rule: $1"
  gcloud deployment-manager deployments create $1-fw --config $1-fw.yml
  echo "Waiting for firewall rule to take effect ...."
  gcloud compute firewall-rules list | grep $1-http
  sleep 10
}
