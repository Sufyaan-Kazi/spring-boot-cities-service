#!/bin/bash

sudo apt-get update
sudo apt-get -y install default-jdk
sudo apt-get -y install git-core
git clone https://github.com/Sufyaan-Kazi/spring-boot-cities-service.git
cd spring-boot-cities-service/
./gradlew bootRun
