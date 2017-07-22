#!/bin/sh
./gradlew build
cd scripts
./1_setupProject.sh
./2_deployApp.sh
./3_testAppOnOShift.sh
cd --
