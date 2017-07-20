#!/bin/sh 
. $APPNAME/ci/scripts/common.sh

main()
{
  oc_login
  if [ ! -z $CREATE_FRESH_PROJ ]
  then
    echo_msg "Creating Project"
    EXISTS=`oc projects | grep $APPNAME | wc -l | xargs`
    if [ $EXISTS -ne 0 ]
    then
      oc delete project $APPNAME
      sleep 5
    fi
    oc new-project $APPNAME
  fi

  EXISTS=`oc get dc | grep mysql | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    PLAN=`oc get template -n openshift | grep mysql- | grep ephemeral | wc -l | xargs`
    if [ $PLAN -eq 0 ]
    then
      PLAN=mysql-persistent
    else
      PLAN=mysql-ephemeral
    fi
    oc process openshift/$PLAN --param-file=src/main/resources/mysql.env -l name=${APPNAME} | oc create -f -
    sleep 3
    oc get logs dc/mysql
  fi
  oc get dc
  oc logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
