#!/bin/sh 
. common.sh

createProj()
{
  # Create new Project
  if [ $CREATE_FRESH_PROJ = "y" ]
  then
    EXISTS=`oc projects | grep $APPNAME | wc -l | xargs`
    if [ $EXISTS -ne 0 ]
    then
      MYSQL_EXISTS=`oc get dc | grep mysql | wc -l | xargs`
      oc delete project $APPNAME
      if [ $MYSQL_EXISTS -eq 1 ]
      then
        echo "Sleeping while MySQL service is removed ...."
        sleep 60
      fi
    fi
  fi

  echo_msg "Creating Project"
  EXISTS=`oc projects | grep $APPNAME | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then
    oc new-project $APPNAME
  fi
}

addMYSQL()
{
  # Create MySQL
  EXISTS=`oc get dc | grep mysql | wc -l | xargs`
  if [ $EXISTS -eq 0 ]
  then

    echo_msg "Creating MySQL"
    PLAN=`oc get template -n openshift | grep mysql- | grep ephemeral | wc -l | xargs`
    if [ $PLAN -eq 0 ]
    then
      PLAN=mysql-persistent
    else
      PLAN=mysql-ephemeral
    fi

    oc process openshift//$PLAN --param-file=${MYSQL_ENV_FILE} -l name=${APPNAME} | oc create -f -
    sleep 3
    echo ""

    COUNTER=0
    STATUS=`oc get po | grep mysql | grep -v deploy | xargs | cut -d ' ' -f 3`
    while [ $STATUS != "Running" ]
    do
       if [ $COUNTER -eq 40 ]
       then
         break
       fi

       sleep 15
       oc get po | grep mysql
       let COUNTER=COUNTER+1
       STATUS=`oc get po | grep mysql | grep -v deploy | xargs | cut -d ' ' -f 3`
    done
  fi
  oc get dc/mysql

  STATUS=`oc logs dc/mysql | tail -n 1 | grep "ySQL Community Server" | wc -l | xargs`
  while [ $STATUS -ne 1 ]
  do
    sleep 3
    STATUS=`oc logs dc/mysql | tail -n 1 | grep "ySQL Community Server" | wc -l | xargs`
  done
  oc logs dc/mysql
}

main()
{
  # Login
  oc version
  oc_login
  createProj
  addMYSQL
  oc logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
