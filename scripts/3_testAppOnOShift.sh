#!/bin/sh 
. common.sh

getRouteForVersion()
{
  URL=$(oc get route | grep 0.05 | xargs | cut -d " " -f 2)
  exitIfNull $URL
}

searchForCity()
{
  echo_msg "Checking for specific city"
  running=$(curl -s $URL/cities/search/name?q=Aldermoor | grep "SU3915")
  curl -s $URL/cities/search/name?q=Aldermoor
  echo ""
  exitIfNull $running
}

main()
{
  oc_login

  getRouteForVersion
  checkSpringBootApp $URL
  searchForCity

  oc logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=$(basename "$0")
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
