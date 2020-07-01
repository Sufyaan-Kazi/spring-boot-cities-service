# Dockerfile for use with Cloud Run

##
# Build app
##
FROM gradle:jdk11 as builder
ENV APP_HOME=/app/
WORKDIR $APP_HOME
COPY build.gradle $APP_HOME
RUN gradle wrapper --no-daemon
COPY gradle $APP_HOME/gradle
#RUN ls -al $APP_HOME/gradle/wrapper
RUN ./gradlew build -x test --no-daemon || return 0 
COPY . .
RUN ./gradlew build -x test --no-daemon
#COPY src ./src
#RUN gradle buildDocker -x test --no-daemon
#RUN ls -al $APP_HOME/build/libs/

##
# Stage 2 - Run app
##
FROM adoptopenjdk/openjdk11:jdk-11.0.7_10-alpine-slim
COPY --from=builder /app/build/libs/*.jar /app.jar
#RUN sh -c 'touch /app.jar'
EXPOSE 8080
ENTRYPOINT [ "java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar" ]
