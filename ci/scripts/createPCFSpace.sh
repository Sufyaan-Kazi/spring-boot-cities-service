#!/bin/sh 
. $APPNAME/ci/scripts/common.sh

main()
{
  if [ ! -z $CREATE_FRESH_SPACE ]
  then
    echo_msg "Creating space"
    cf_login
    cf delete-space $space -f
    cf create-space $space
    cf logout
  fi
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
