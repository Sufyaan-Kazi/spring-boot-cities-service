#!/bin/sh 
. common.sh

main()
{
  # Login
  oc version
  oc_login

  IS_EXIST=`oc get is | grep s2i-java | wc -l | xargs`
  if [ $IS_EXIST -eq 0 ]
  then
    echo_msg "Creating image stream ${s2i}"
    oc create -f ${s2i}
    sleep 3
    oc get is
  fi

  APP_EXIST=`oc get dc | grep ${APPNAME} | wc -l | xargs`
  if [ $APP_EXIST -eq 1 ]
  then
    oc delete bc ${APPNAME}
    oc delete dc ${APPNAME}
    oc delete svc ${APPNAME}
    oc delete is ${APPNAME}
    sleep 2
  fi

  echo_msg "Deploying $APPNAME from $gitproj"
  oc new-app s2i-java:latest\~${gitproj} -l name=${APPNAME} --env-file=../src/main/resources/mysql.env
  echo ""
  oc logs -f bc/${APPNAME}
  echo_msg "Current Pods"
  oc get po
  echo ""
  oc logs -f dc/${APPNAME}
  echo ""

  echo_msg "Deploying ... "
  STARTED=`oc logs dc/${APPNAME} | tail -n 1 | grep ": Started " | wc -l | xargs`
  while [ ${STARTED} -ne 1 ]
  do
    oc get po -l name=spring-boot-cities-service
    sleep 3
    STARTED=`oc logs dc/${APPNAME} | tail -n 1 | grep ": Started " | wc -l | xargs`
  done
  echo ""

  SBOOT_PROFILE=`oc logs dc/${APPNAME} | grep "The following profiles are active" | wc -l | xargs`
  if [ ${SBOOT_PROFILE} -ne 0 ]
  then
    echo "......"
    oc logs dc/${APPNAME} | grep "The following profiles are active"
  fi

  echo "......"
  oc logs dc/${APPNAME} | tail -n 2
  echo ""

  echo status

  oc logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
