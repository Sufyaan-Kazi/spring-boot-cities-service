#!/bin/bash
APPNAME=cities-rest
PROJNAME=sufcloudnative
REPONAME=eu.gcr.io
DATE=$(date '+%Y%m%d%H%M%S')

main() {
  #Build, tag and push image
  echo "****************** Building $APPNAME"
  sudo ./gradlew build buildDocker
  echo -e "\n****************** Building Docker Image"
  sudo docker tag sufyaankazi/$APPNAME:1.0 $REPONAME/$PROJNAME/$APPNAME
  sudo docker images
  sudo docker push $REPONAME/$PROJNAME/$APPNAME:latest

  #Remove previous deployment
  echo -e "\n****************** Removing Previous Deploymet"
  kubectl get deployments
  kubectl delete deployment $APPNAME
  kubectl delete svc lb-$APPNAME

  #Change date label in yaml
  echo -e "\n*********************** Deploying $APPNAME"
  sed -e 's/DATE/'"$DATE"'/g' yml/$APPNAME.yml > yml/$APPNAME_$DATE.yml
  kubectl create -f yml/$APPNAME_$DATE.yml
  rm -f yml/$APPNAME_$DATE.yml
  gcloud container images list --repository $REPONAME/$PROJNAME

  #Check status
  echo -e "\n********************* $APPNAME deployed, checking status"
  PODNAME=$(kubectl get pods | grep $APPNAME | grep "ContainerCreating" | cut -d " " -f1)
  echo "Podname is: $PODNAME"
  STATUS=$(kubectl get pods $PODNAME | grep -v NAME | xargs | cut -d " " -f3)
  COUNTER=1
  while [ $STATUS != "Running" ]
  do
    sleep 1.5
    STATUS=$(kubectl get pods $PODNAME | grep -v NAME | xargs | cut -d " " -f3)
    COUNTER=$(($COUNTER+1))

    if [ "$COUNTER" -gt 5 ]
    then
      echo "Something went wrong .."
      break  # Skip entire rest of loop.
    fi
  done
  echo "Pod is now $STATUS, waiting for app to start"

  #Wait for logs to say started
  STARTED=$(kubectl logs $PODNAME | tail -n1 | grep Started | wc -l)
  while [ $STARTED -eq 0 ]
  do
    sleep 2
    STARTED=$(kubectl logs $PODNAME | tail -n1 | grep Started | wc -l)
  done
  kubectl logs $PODNAME

  # Deploy Service
  echo -e "\n**************************** Deploying Service"
  kubectl create -f yml/lb-cities-rest.yml 
  EXT_IP=$(kubectl get svc | grep lb-cities-rest | xargs | cut -d " " -f4)
  while [ $EXT_IP = "<pending>" ]
  do
    sleep 2
    EXT_IP=$(kubectl get svc | grep lb-cities-rest | xargs | cut -d " " -f4)
  done
  sleep 1
  echo "App is available at: $EXT_IP"
  curl http://$EXT_IP:8080/
}

# Run the script
trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=$(basename "$0")
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds at $DATE.\n"
trap : 0
