#!/bin/bash
set -e

. ./vars.txt

main() {
  #Build, tag and push image
  echo "****************** Building $APPNAME"
  cd ../..
  sudo ./gradlew build buildDocker
  cd $SCRIPTPATH
  echo -e "\n****************** Building Docker Image"
  sudo docker tag sufyaankazi/$APPNAME:1.0 $REPONAME/$PROJNAME/$APPNAME
  sudo docker images
  sudo docker push $REPONAME/$PROJNAME/$APPNAME:latest

  #Remove previous deployment
  echo -e "\n****************** Removing Previous Deploymet"
  EXISTS=$(kubectl get deployments | grep $APPNAME | wc -l)
  if [ $EXISTS -ne 0 ]
  then
    kubectl delete deployment $APPNAME
  fi
  EXISTS=$(kubectl get svc | grep lb-$APPNAME | wc -l)
  if [ $EXISTS -ne 0 ]
  then
    kubectl delete svc lb-$APPNAME
  fi

  #Change date label in yaml
  echo -e "\n*********************** Deploying $APPNAME"
  sed -e 's/DATE/'"$DATE"'/g' $YML_DIR/$APPNAME.yml > /tmp/$APPNAME_$DATE.yml
  kubectl create -f /tmp/$APPNAME_$DATE.yml
  rm -f /tmp/$APPNAME_$DATE.yml
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
  STARTED=$(kubectl logs $PODNAME | grep ": Started " | wc -l)
  while [ $STARTED -eq 0 ]
  do
    sleep 2
    STARTED=$(kubectl logs $PODNAME | grep ": Started " | wc -l)
  done
  kubectl logs $PODNAME

  # Deploy Service
  echo -e "\n**************************** Deploying Service"
  kubectl create -f $YML_DIR/lb-cities-rest.yml 
  echo "Waiting for external ip address ......."
  EXT_IP=$(kubectl get svc | grep lb-cities-rest | xargs | cut -d " " -f4)
  while [ $EXT_IP = "<pending>" ]
  do
    sleep 2
    EXT_IP=$(kubectl get svc | grep lb-cities-rest | xargs | cut -d " " -f4)
  done
  sleep 1
  echo "App is now available."
  curl http://$EXT_IP:8080/
}

# Run the script
trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=$(basename "$0")
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds at $DATE.\n"
trap : 0
