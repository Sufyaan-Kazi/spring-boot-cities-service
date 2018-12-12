https://twitter.com/Sufyaan_Kazi

- [spring-boot-cities-service](#spring-boot-cities-service)
  * [Running the app locally or connecting directly to a db](#running-the-app-locally-or-connecting-directly-to-a-database)
  * [Running the app on Cloud Foundry](#running-the-app-on-cloud-foundry)
  * [Running the app directly on AWS](#running-the-app-directly-on-aws)
  * [Usage!](#usage)
  * [Wait, I want a GUI!](#wait-i-want-a-gui)
  * [What about Netflix OSS and Spring Cloud Services?](#what-about-netflix-oss-and-spring-cloud-services)
  * [Can I get some metrics?](#can-i-get-some-metrics)
  * [This app is too simple](#this-app-is-too-simple)
  * [How is data loaded?](#how-is-data-loaded)
  * [Achitecture](#achitecture)
  * [Tell me more](#tell-me-more)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


# spring-boot-cities-service
This is a very simple Spring Boot project which demonstrates, that with only small a footprint of code its possible to a create a complex webservice which exposes CRUD operations as restful endpoints. It uses Spring Data (JPA) and spring web. This microservice runs on a local machine or on Cloud Foundry, or AWS (or anywhere you can run a Spring Boot app). To see how to package a war rather than a "fat" jar, look in the AppD branch.

![Cities](/docs/Arch.png)

Note: This is a FORK of https://github.com/cf-platform-eng/spring-boot-cities! Thanks to help and tips from my team, as well as Dave Syer and Scott Frederick in this and other branches :) The SCS branch includes updates to work with Spring Cloud Services.

## Running the app locally or connecting directly to a database
You don't need to have a database running, this app will automatically spin up H2 in memory for you, because of Spring Boot. However, if you have one you want to use, such as MySQL, then a) comment/uncomment the relevant lines in build.gradle to get Spring Boot to automatically load the mySQL jdbc drivers and b) amend the application.yml file with url, username etc settings for your database. 

To run outside of Eclipse just run 
```./gradlew bootRun ```
on your command line. You don't need to have gradle installed.

## Running the app on Cloud Foundry
To run this on Cloud Foundry, simply run the script:
```./first_time_push.sh ```

This script creates the required Cloud Foundry services, tidies up previous installations, pushes the app and binds the app to the service. Once the env is setup correctly, feel free to use the other script which will both build and push the app to cloud foundry:

```./push.sh ```

Alternately to build the application yourself, simply run:

``` ./gradlew clean assemble ```

Because Spring Boot is opinionated, it automatically connects this app to the correct datasources within your Cloud Foundry space using Spring Cloud Connectors - no code is needed in the application itself to read the credentials supplied by Cloud Foundry. The app will auto-populate data in the table of the db schema provisioned by Cloud Foundry in the SI - see below. Please note, when you first deploy this app it will take a long time to start because several SQL inserts are executing.

If you've never heard of Cloud Foundry - use it! This app is very simple to construct, as soon as you deploy it to Cloud Foundry your entire support infrastructure, app server, libraries etc are configured loaded and deployed within 2 minutes - push this application to our trial instance of cloud foundry at run.pivotal.io. This si classic DevOps separation of concerns yet both in harmony together.

## Running the app directly on AWS
Running the app on AWS using Elastic Beanstalk is a bit more involved. To simplify things I created banches of this project called elbeanstalk. Fundamentally to get this to work you need to overcome the problem that NGinX always assumes the tomcat server is running on port 5000. You can overcome this by directly changing the port in the application props file of the app, but then you would need to use spring boot params/profiles to manage properties for running on your local machine vs AWS. You could then use some form of config service to help. An alternate method is to use ELB software config in your app environment to inject the ports into the AWS environment. More info can be found here:
https://aws.amazon.com/blogs/devops/deploying-a-spring-boot-application-on-aws-using-aws-elastic-beanstalk/

In addition, use the env params to inject the credentials for your RDS instance (or a.n.other) to allow this app to talk to a database.

Either way, building the right cd pipeline should overcome these issues. This project was originally written with concourse in mind, but the pipelines for this haven't been updated to work with AWS. If using AWS, you may consider using these: https://aws.amazon.com/products/developer-tools/

Finaly, one other option is to just create EC2 instances in your VPC and deploy this app as a war directly to your own tomcat. Creating a war rather than jar is easy (but an odd thing to do ... as Josh Long would say .. make jar not war). Anyway, if you really want to, have a look at what's necessary, look at the build.gradle in the AppD branch of this project.

## Usage!
When you run this app you can access its features using several RESTful endpoints. Note - this is only a SMALL sample of the endpoints available, this app exposes HATEOS endpoints. e.g. when running locally:
* <a href="http://localhost:8080/cities" target="_blank">http://localhost:8080/cities</a> - returns a single page JSON listing cities (20 cities in a page)
* <a href="http://localhost:8080/cities?page=2&size=5" target="_blank">http://localhost:8080/cities?page=2&size=5</a> - returns only FIVE results from the SECOND page
* <a href="http://localhost:8080/cities/search/name?q=London" target="_blank">http://localhost:8080/cities/search/name?q=London</a> - returns a list of cities with London in their name.
* <a href="http://localhost:8080/cities/search/nameContains?q=Lon&size=3" target="_blank">http://localhost:8080/cities/search/nameContains?q=Lon&size=3</a> - returns the first three results of the search to find any cities with a name containing the word "Lon" (case insensitive search)
* <a href="http://localhost:8080/health" target="_blank">http://localhost:8080/health</a> - This returns the current health of the app, it is provided by Spring Boot Actuator. This and all other actuator endpoints that actuator provides are available immediately.

## Wait, I want a GUI!
There is a separate application which can be used as a GUI to consume the data delivered by this Microservice here: https://github.com/skazi-pivotal/spring-boot-cities-ui or feel free to write your own, using that as a guide.

![Cities](/docs/Cities-ui.png)

## What about Netflix OSS and Spring Cloud Services?
Netflix OSS is a great way of managing distributed Microservices. There is another branch of this project which takes advantgaes of Spring Cloud Services in Pivotal Cloud Foundry, therfore automatically including several Netflix OSS features. To see this switch to the SCS branch.

## Can I get some metrics?
Spring Boot Actuator automatically exposes endpoints which allow you to consume useful information such as health, configprops, for more info check this out: http://docs.spring.io/autorepo/docs/spring-boot/1.2.0.M2/reference/htmlsingle/#production-ready. Alternately if you want to use AppDynamics, check out the AppD branch where I package the app as a war to deploy to tomcat (which you can instrument wth AppDynamics). AppD will then automatically identify and discover the application architecture.

## This app is too simple
Yes it is, but ok then if you want a more advanced Microservice based application you should really check out this Repo: https://github.com/pivotal-bank/cf-SpringBootTrader. This is several microservices tied together using some great Netflix OSS features delivered via Spring and Cloud Foundry to create a stock trading app.

## How is data loaded?
With Spring and Spring Boot there are several ways to get an applicaton to initialise and load data automatically into a database on startup. This application uses flyway, but can also use Hibernate instead. For more info check out this page: https://docs.spring.io/spring-boot/docs/current/reference/html/howto-database-initialization.html

This application will use Flyway by default to load data into the database. To do this I simply added the flyway maven repo dependency in my build.gradle and Spring Boot makes sure flyway is loaded and launched for me.  Using flyway (or hibernate) eliminates any ugly initialisation java code within my app that needs to be maintained. 

Flyyway is pretty simple, it looks for sql files in the resources sub-folder, and executes them in order based on he name of the file. It creates a table in your database to track which files it has already executed. If you change the db structure or want to load more data to an existing implementation, simply create new sql files with higher numbers in the name. Flyway will detect and execute them just once the next time the app starts. Flyway calls these files "migrations

e.g. file V1.sql will run before V1.1. If you later add V1.2, only this file will be executed.

By default, only cities from Hampshire, Surrey and the West Midlands are loaded (for performance reasons) in this app. To load all cities, rename the db/migrations/....txt file and delete your local copy of the three sql files for these counties.

If you don't want to use Flyway and use hibernate instead, simply comment it out from the dependencies section in the buld.gradle (and Spring Boot will not activate it). You can then simple uncomment the following lines in [src/main/resources/application.properties] (src/main/resources/application.properties) file:

```
spring.jpa.hibernate.ddl-auto = create
spring.jpa.hibernate.naming-strategy = org.hibernate.cfg.ImprovedNamingStrategy
spring.jpa.properties.hibernate.dialect = org.hibernate.dialect.MySQL5Dialect
```

## Achitecture
![Cities](/docs/Classes.png)

This app is very simple, it is ultimately driven by three classes and some properties and that is it.
* SBootCitiesAplication.java - simple class which alows you to run this class as a regular java app. Spring Boot will automaticaly configure and deploy tomcat even though you launch a regular java app. 
* City.java - This class uses JPA to bind to a database table called uktowns. The table is where city data is held, this class maps java fields to the column names and enables Spring Data to dynamically construct instances of the class when it fetches data from the database. (Data is loaded in automatically - see the section below)
* CityRepository.java - This "interface" declares both restful endpoints as well as defines SQL operations required. Spring Boot and Spring Web automatically register typical DB endpoints for CRUD operations without the need to edit a web.xml or any other configuration files. Spring also "automagically" builds the right SQL queries to search, update, insert and retirve data from the database by automatically interpreting method names into real logic. This class also returns results as pages (i.e. 20 results at a time, but this can be tweaked using paramters to RESTFUL calls.
* WebController.java (optional) - This class isn't necessary, however it exposes a new REST endpoint 'cities_all' which lists all cities with no paging or size control options
* DataSourceConfig.java (optional) - This class isn't necessary, however it allows you to run this application locally on your Mac, desktop etc - it will bound your app to a local MySQL Server. You can use hibernate very easily instead, see the original project this is forked from.

## Tell me more
Spring Boot is designed to get you up and running quickly and it is opinionated, so:

* I have not needed to define a long list of libraries, in my build.gradle I add a dependency on Spring Boot and then dependencies on specific spring-boot starter projects. Spring Boot does the rest, it makes opinions for you
* I have not needed to configure endpoints in my web.xml or configure more detail about which endpoints exists, my CityRepository class automatically exposes these as endpoints because of the @RestRepository endpoints
* I do not need to install Tomcat,  configure it or write a dpoyment script to put it in the correct location in Tomcat etc, Spring Boot decides I need Tomcat and installs and deploys my app to it for me. I could even tell Spring Boot to use Jetty instead is I wanted to, or to use a different port.
* I have not needed to define any SQL queries, the methods I list in the repository class are automatically interpreted into queires because of the way I define them -> findByNameIgnoreCase (findBy<field in my entityy><type of find>)
* I have not needed to build a mapping config file between java and the db - this is handled by a few simple annotations e.g. @Entity
* I have not needed to hard code db parameters. When running locally, these are "injected" at runtime using the DataSourceConfig class (it is labelled with a specific @Profile), or just injected by Boot immediatelty when running in Pivotal Cloud Foundry. This can be tweaked to add db pooling etc (https://spring.io/blog/2015/04/27/binding-to-data-services-with-spring-boot-in-cloud-foundry)
* I have not needed to write any code to locate or parse properties files, Spring Boot just knows where to read them and how. (https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-profiles.html)
* I did not need to add the flyway plugin or flyway db params to my build.gradle. Spring Boot automaticaly coonfigures and triggers flyway for me when it finds flyway in my classpath.

Do Check out the following URLs:
* https://spring.io/guides
* https://spring.io/guides/gs/rest-service/
* https://spring.io/guides/gs/accessing-data-jpa/
* http://cloud.spring.io/spring-cloud-connectors/spring-cloud-spring-service-connector.html
* http://cloud.spring.io/spring-cloud-connectors/spring-cloud-connectors.html
* https://spring.io/blog/2015/04/27/binding-to-data-services-with-spring-boot-in-cloud-foundry
* http://docs.spring.io/spring-data/data-commons/docs/1.6.1.RELEASE/reference/html/repositories.html
* https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-profiles.html
