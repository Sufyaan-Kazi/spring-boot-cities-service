#!/bin/bash 
set -e

abort()
{
    echo >&2 '
    ***************
    *** ABORTED ***
    ***************
    '
    echo "An error occurred. Exiting..." >&2
    exit 1
}

summary()
{
  echo_msg "Current Apps & Services in CF_SPACE"
  cf apps
  cf services
}

echo_msg()
{
  echo ""
  echo "************** ${1} **************"
}

build()
{
  echo_msg "Building application"
  ./gradlew build 
}

check_cli_installed()
{
  #Is the CF CLI installed?
  echo_msg "Targeting the following CF Environment, org and space"
  cf target
  if [ $? -ne 0 ]
  then
    echo_msg "!!!!!! ERROR: You either don't have the CF CLI installed or you are not connected to an Org or Space !!!!!!"
    exit $?
  fi
}

main()
{
  APPNAME=cities-service
  DBSERVICE=MyDB
  check_cli_installed
  build
  ./cleanup.sh

  echo_msg "Starting Deploy!"
  SERVICE=`cf marketplace | grep MySQL | head -n 1 | cut -d ' ' -f1 | xargs`
  PLAN=`cf marketplace -s ${SERVICE} | grep free | tail -n 1 | cut -d ' ' -f1 | xargs`
  if [ -z $PLAN ]
  then
    PLAN=`cf marketplace | grep MySQL | head -n 1 | cut -d ' ' -f1 | xargs`
  fi
  cf create-service $SERVICE $PLAN MyDB
  echo "About to push application, you can monitor this using the command: cf logs $APPNAME"
  BPACK=`cf buildpacks | grep java | grep true | head -n 1 | cut -d ' ' -f1 | xargs`
  cf push -b $BPACK
}

SECONDS=0
trap 'abort' 0
main
trap : 0
echo_msg "Deployment Complete in $SECONDS seconds."
