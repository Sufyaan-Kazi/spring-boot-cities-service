#!/bin/bash 

echo_mesg() {
   echo ""
   echo "----- $1 ----"
}

getYAMLValue() {
  echo $1 | cut -d ':' | xargs -f2
}

createDeployment() {
  if [ $# -ne 2 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> <yaml_file>"
    exit 1
  fi

  NAME=$1
  YAML=$2
  gcloud deployment-manager deployments create $NAME --config $YAML > /dev/null
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
  createDeployment $IT $IT.yml
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
  createDeployment $IG $IG.yml

  # Define Autoscaling for Instance Group
  # Grab the "template" autoscale definition and replace REGION with actual region desired
  echo_mesg "Setting up Autoscale for: $IG"
  local TEMP_FILE=$IG-as_temp_$$.yml
  cat $IG-as.yml | sed s/REGION/$2/g > ${TEMP_FILE}
  createDeployment $IG-as $TEMP_FILE
  rm -f ${TEMP_FILE}
}

waitForFWDIP() {
  # Get the IP of the TCP Forwarding Rule once it's been assigned
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
  createDeployment $LB-hc $LB-hc.yml

  echo_mesg "Creating Internal load balancer: $LB"
  createDeployment $LB $LB.yml

  echo_mesg "Defining Backend service (Instance Group) for Internal Load Balancer: $LB"
  gcloud compute backend-services add-backend $LB --instance-group=$1-ig --instance-group-region=$2 --region=$2

  echo_mesg "Defining Forwarding Rule for Internal Load Balancer: $LB"
  createDeployment $LB-fwd-rule $LB-fwd-rule.yml

  waitForFWDIP

  local INSTANCE_NAME=`gcloud compute instances list | grep $1-ig | cut -d ' ' -f1 | head -n 1`
  waitForInstanceToStart $INSTANCE_NAME
}

# Create Ext HTTP Load Balancer
createExtLB() {
  if [ $# -ne 1 ]
  then
    echo "Not enough arguments supplied, please supply <deploymentName> "
    exit 1
  fi

  echo_mesg "Creating Healthcheck: $1"
  createDeployment $1-hc $1-hc.yml

  echo_mesg "Creating Backend Service: $1"
  createDeployment $1-be $1-be.yml

  echo_mesg "Creating URL Map: $1"
  createDeployment $1-url-map $1-url-map.yml

  echo_mesg "Creating Web Proxy: $1"
  createDeployment $1-web-proxy $1-web-proxy.yml

  echo_mesg "Creating Web FE: $1"
  createDeployment $1-fe $1-fe.yml
  sleep 5

  echo_mesg "Checking health of backends"
  local ALMOST_READY=$(gcloud compute backend-services get-health $1-be --global | grep healthState | grep HEALTHY)
  while [ -n "$ALMOST_READY" ]
  do
    echo "Waiting for backends to register with Load Balancer"
    sleep 10
    ALMOST_READY=$(gcloud compute backend-services get-health $1-be --global | grep healthState | grep HEALTHY)
  done
}

waitForHealthyBackend() {  
  local COUNT=$(gcloud compute backend-services get-health $1-be --global | grep healthState | grep ': HEALTHY' | wc -l)
  while [ $COUNT -eq 0 ]
  do
    echo "Waiting for Healthy State of Backend Instances of the HTTP Load Balancer: $COUNT"
    sleep 10
    COUNT=$(gcloud compute backend-services get-health $1-be --global | grep healthState | grep ': HEALTHY' | wc -l)
  done
}

createFirewall() {
  # Try to compensate for GCE Enforcer
  # Does the firewall rule exist?

  echo_mesg "Creating Firewall Rule: $1"
  createDeployment $1-fw $1-fw.yml
  echo "Waiting for firewall rule to take effect ...."
  #gcloud compute firewall-rules list | grep $1-http
  sleep 3
}

checkAppIsReady() {
  #Check app is ready
  URL=$1
  HTTP_CODE=$(curl -Is http://${URL}/ | grep HTTP | cut -d ' ' -f2)
  while [ $HTTP_CODE -ne 200 ]
  do
    echo "Waiting for app to become ready: $HTTP_CODE"
    sleep 10
    HTTP_CODE=$(curl -Is http://${URL}/ | grep HTTP | cut -d ' ' -f2)
  done
}
