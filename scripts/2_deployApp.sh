#!/bin/sh 
. common.sh

createS2I()
{
  IS_EXIST=$(oc get is | grep s2i-java | wc -l | xargs)
  if [ $IS_EXIST -eq 0 ]
  then
    echo_msg "Creating image stream ${s2i}"
    oc create -f ${s2i}
    sleep 3
    oc get is
  fi

  APP_EXIST=$(oc get dc | grep ${APPNAME} | wc -l | xargs)
  if [ $APP_EXIST -eq 1 ]
  then
    oc delete bc ${APPNAME}
    oc delete dc ${APPNAME}
    oc delete svc ${APPNAME}
    oc delete is ${APPNAME}
    ROUTE_EXIST=$(oc get route ${APPVERSION} | wc -l | xargs)
    if [ ${ROUTE_EXIST} -ne 0 ]
    then
      oc delete routes ${APPVERSION}
    fi
    sleep 2
  fi
}

testSrc()
{
  cd ..
  ./gradlew test
  cd -
}

deployApp()
{
  testSrc

  echo_msg "Deploying $APPNAME from $gitproj"
  cat ${APP_ENV_FILE} ${MYSQL_ENV_FILE} | oc new-app s2i-java:latest\~${gitproj} -l name=${APPNAME} --env-file=-
  echo "Building app"
  oc logs -f bc/${APPNAME} --request-timeout=5m
  echo "Deploying app"
  oc logs -f dc/${APPNAME} --request-timeout=15m
  sleep 3
  oc logs dc/${APPNAME} 

  SBOOT_PROFILE=$(oc logs dc/${APPNAME} | grep "The following profiles are active" | wc -l | xargs)
  echo $SBOOT_PROFILE
}

main()
{
  # Login
  oc version
  oc_login

  oc project ${APPNAME}
  createS2I
  deployApp

  oc expose svc/${APPNAME} --name ${APPVERSION}
  echo_msg "App available at: http://$(oc get routes | grep ${APPNAME} | xargs | cut -d ' ' -f 2)/"

  oc logout
}

trap 'abort $LINENO' 0
SECONDS=0
SCRIPTNAME=$(basename "$0")
main
printf "\nExecuted $SCRIPTNAME in $SECONDS seconds.\n"
trap : 0
