#!/bin/sh 
. $APPNAME/ci/scripts/common.sh

main()
{
  if [ ! -z $CREATE_FRESH_PROJ ]
  then
    echo_msg "Creating Project"
    oc_login
    #oc delete project $APPNAME
    oc new-project $APPNAME
    oc logout
  fi
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
