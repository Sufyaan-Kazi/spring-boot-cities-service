#!/bin/sh 
set -e

abort()
{
    if [ "$?" = "0" ]
    then
        return
    else
      echo >&2 '
      ***************
      *** ABORTED ***
      ***************
      '
      echo "An error occurred on line $1. Exiting..." >&2
      exit 1
    fi
}

echo_msg()
{
  echo ""
  echo "************** ${1} **************"
}

oc_login()
{
  oc login $uri -u $username -p $password --insecure-skip-tls-verify=true
}

exitIfNull()
{
  if [ -z "${1}" ]
  then
    echo ${2}
    exit 1
  fi
}

checkSpringBootApp()
{
  echo_msg "Checking Spring Boot Actuator health endpoint: $1/health"
  running=`curl -s $1/health | grep '"status" : "UP"'`
  curl -s $1/health
  echo ""
  exitIfNull $running
}

setVars()
{
  . params-oshift.yml
}

setVars
