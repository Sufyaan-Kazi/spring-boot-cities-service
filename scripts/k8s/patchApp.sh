#!/bin/bash
set -e

. ./vars.txt
. ./common.sh

main() {
  kubectl patch deployment $APPNAME -p   "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"$DATE\"}}}}}"
  sleep 1.5
  getPodName Running
  waitForAppToStart $PODNAME
  echo "App External ip is: "
  kubectl get svc | grep lb-$APPNAME | xargs | cut -d " " -f4
}

# Run the script
trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=$(basename "$0")
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds at $DATE.\n"
trap : 0
