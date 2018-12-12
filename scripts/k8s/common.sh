#!/bin/bash
set -e

getPodName() {
  if [ -z $1 ]
  then
    echo "No pod status supplied"
    exit 1
  fi

  kubectl get pods | grep $APPNAME | grep "${2}"
  COUNT=$(kubectl get pods | grep $APPNAME | grep "${2}" | wc -l)
  if [ $COUNT -eq 0 ]
  then
    PODNAME=$(kubectl get pods | grep -v NAME | grep $APPNAME | grep "${2}" | cut -d " " -f1)
  else
    #Posibly a new patched pod is about ot replace the old one
    PODNAME=$(kubectl get pods | grep -v NAME | grep $APPNAME | grep "${2}" | grep "0/" | cut -d " " -f1)
  fi

  echo "Podname is: $PODNAME"
}

waitForAppToStart() {
  if [ -z $1 ]
  then
    echo "No pod name supplied"
    exit 1
  fi

  PODNAME=$1

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
}

