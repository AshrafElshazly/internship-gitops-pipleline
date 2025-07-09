FROM maven:3.8-openjdk-17 as build

EXPOSE 8080

COPY ./target/app.jar /usr/app/app.jar

WORKDIR /usr/app

ENTRYPOINT ["java", "-jar", "app.jar"]
