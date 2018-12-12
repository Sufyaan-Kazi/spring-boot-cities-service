#!/bin/sh 
. $APPNAME/ci/scripts/common.sh

addVersionEnv()
{
  cf set-env $APPNAME VERSION $VERSION
}

main()
{
  cf_login

  summaryOfApps
  createVarsBasedOnVersion
  addVersionEnv
  summaryOfApps

  cf logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=`basename "$0"`
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
