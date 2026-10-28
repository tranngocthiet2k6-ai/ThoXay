FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /build
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -B -ntp dependency:go-offline
COPY src/ src/
RUN ./mvnw -B -ntp verify

FROM eclipse-temurin:17-jre-jammy
RUN useradd --system --uid 10001 --create-home thoxay \
    && (getent group 1000 >/dev/null || groupadd --gid 1000 render-secrets) \
    && usermod -a -G 1000 thoxay
WORKDIR /app
COPY --from=build /build/target/tho-xay-1.0.0.jar app.jar
ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
USER 10001
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=65.0", "-Djava.awt.headless=true", "-jar", "/app/app.jar"]
