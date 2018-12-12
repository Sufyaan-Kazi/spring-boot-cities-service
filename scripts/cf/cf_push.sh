SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

cd ../../
cf target
./gradlew build 
cf push -b java_buildpack_offline
cd $SCRIPTPATH
