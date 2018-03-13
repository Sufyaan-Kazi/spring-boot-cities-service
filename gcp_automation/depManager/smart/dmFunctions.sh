#!/bin/bash 

# Author: Sufyaan Kazi
# Date: March 2018

###
# Utility method to pretty print messages to the screen
###
echo_mesg() {
   echo ""
   echo "----- $1 ----"
}

###
# Utility method to extract a value from YAMl
###
getYAMLValue() {
  echo $1 | cut -d ':' | xargs -f2
}

###
# Wrapper to gcloud method to create a deployment.
#
# Method checks the right number of args were supplied then calls the create deployment method
###
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

###
# Method to Create an Instance Template
###
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

###
# Method which waits for a VM Instance to start.
#
# It loops until the status of the instances is "RUNNING"
###
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

###
#
# Method which grabs the console output for debugging.
#
###
getInstanceOutput() {
  local INST=$1
  local ZONE=`gcloud compute instances list | grep $INST | xargs | cut -d ' ' -f2`

  gcloud compute instances get-serial-port-output ${INST} --zone=${ZONE}
}

###
# A method to create Regional Instance Group
#
# The method creates the Instrance group and autoscaler. The function will override
# the region in the yamls supplied, but in the future we may use Jinja placeholders
###
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

###
#
# Method to wait for the IP of a forwarding rule to be created.
#
# This method will wait untilt he forwarding rule of an external load balancer has been provided with an external IP,
# and can be used to confirm the load balancer is ready to serve traffic
###
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

###
# Method to create an Internal Load Balancer
#
# The method:
#   - creates the internal load balancer and healthcheck
#   - links the two together
#   - Creates the Backend for the Load Balancer from the associated Instance Group
#   - Creates forwarding rules for the frontend
#   - Waits for the internal load balancer to be ready and then atleast one instance of the backends to be readyA
#
# The method assumes a commong naming theme for the yamls of all components and deployment names, for simplicity.
###
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

###
# Method to create an External HTTP Load Balancer
#
# This method creates a healthcheck, backend service, URL Map, Web Proxy and Web Frontend, i.e. components needed for an external HTTP load balancer.
# The mothod completes when the vm instances in the backend are have initialised and have begun to report their status. Note this does not necessarily
# mean the instances are ready and healthy, just that they are ALMOST ready
###
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

###
# A method to wait until a backend service is healthy
#
# When a backend for a HTTP load balancer is first created it does not immediately report status back.
# Once it does start to report status, it will initially (most likely) report unhealthy if it is performing apt-get updates
# and/or starting the app it's hosting. This method is used during this window to determine when the instance is actually healthy
# as per the rules defined in a healthcheck (e.g. a http request to specific path works)
###
waitForHealthyBackend() {  
  local COUNT=$(gcloud compute backend-services get-health $1-be --global | grep healthState | grep ': HEALTHY' | wc -l)
  while [ $COUNT -eq 0 ]
  do
    echo "Waiting for Healthy State of Backend Instances of the HTTP Load Balancer: $COUNT"
    sleep 10
    COUNT=$(gcloud compute backend-services get-health $1-be --global | grep healthState | grep ': HEALTHY' | wc -l)
  done
}

###
# A utiltiy wrapper method to create firewall rules.
#
###
createFirewall() {
  # Try to compensate for GCE Enforcer
  # Does the firewall rule exist?

  echo_mesg "Creating Firewall Rule: $1"
  createDeployment $1-fw $1-fw.yml
  echo "Waiting for firewall rule to take effect ...."
  #gcloud compute firewall-rules list | grep $1-http
  sleep 3
}

###
# Utility method to ensure a URL returns HTTP 200
#
# When a HTTP load balancer is defined, there is a period of time needed to ensure all netowrk paths are clear
# and the requests result in happy requests.
###
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
