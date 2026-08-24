# syntax=docker/dockerfile:1.7
# Build stage
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml docker-maven-retry.sh ./
RUN chmod +x docker-maven-retry.sh \
    && ./docker-maven-retry.sh -DskipTests dependency:go-offline

COPY src ./src

RUN ./docker-maven-retry.sh clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
