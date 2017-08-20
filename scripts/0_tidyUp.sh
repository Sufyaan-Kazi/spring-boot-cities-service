#!/bin/sh 
. common.sh

oc_login
oc delete all -l app=${APPNAME}
oc delete project ${APPNAME}
echo "Sleeping while db is deleted ...."
sleep 30
oc logout
