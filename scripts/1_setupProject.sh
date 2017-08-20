#!/bin/sh 
. common.sh

createProj()
{
  echo_msg "Creating Project"
  EXISTS=$(oc projects | grep $APPNAME | wc -l | xargs)
  if [ $EXISTS -eq 0 ]
  then
    oc new-project $APPNAME
  fi
}

addMYSQL()
{
  # Create MariaDB
  EXISTS=$(oc get dc | grep maridb | wc -l | xargs)
  if [ $EXISTS -eq 0 ]
  then

    echo_msg "Creating MariaDB"
    PLAN=$(oc get template -n openshift | grep mariadb- | grep ephemeral | wc -l | xargs)
    if [ $PLAN -eq 0 ]
    then
      PLAN=mariadb-persistent
    else
      PLAN=mariadb-ephemeral
    fi

    oc process openshift//$PLAN --param-file=${MYSQL_ENV_FILE} -l name=${APPNAME} | oc create -f - --request-timeout=5m
    sleep 3
    oc logs -f dc/mariadb --request-timeout=15m
  fi

  oc get po | grep mariadb | grep -v deploy

  STATUS=0
  while [ $STATUS -ge 1 ]
  do
    sleep 3
    echo "Waiting for db to start ..."
    STATUS=$(oc logs dc/mariadb | grep "/var/lib/mysql/mysql.sock" | wc -l | xargs)
  done
  oc logs dc/mariadb
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
SCRIPTNAME=$(basename "$0")
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
