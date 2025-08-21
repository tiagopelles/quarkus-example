# Use a Maven image with JDK 17
FROM maven:3.9.4-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Clone the Quarkus quickstart repo
RUN git clone https://github.com/quarkusio/quarkus-quickstarts.git

# Build the getting-started project
WORKDIR /app/quarkus-quickstarts/getting-started
RUN mvn -e -B package -DskipTests

# Use a lightweight JDK image to run the app
FROM eclipse-temurin:17-jdk-alpine

# Set working directory
WORKDIR /app

# Copy the built app from the builder stage
COPY --from=builder /app/quarkus-quickstarts/getting-started/target/quarkus-app /app

# Expose Quarkus default port
EXPOSE 8082

# Run the application
CMD ["java", "-jar", "quarkus-run.jar"]