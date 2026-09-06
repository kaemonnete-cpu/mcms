# ===== Stage 1: Build the WAR with Maven =====
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -q dependency:go-offline || true
COPY src ./src
RUN mvn -q clean package -DskipTests

# ===== Stage 2: Runtime - Payara 6 + WAR =====
FROM payara/server-full:6.2025.11-jdk17

USER root

# Deploy the WAR built in stage 1 (bundles the PostgreSQL JDBC driver in WEB-INF/lib)
COPY --from=build /build/target/mcms.war ${DEPLOY_DIR}/mcms.war

# Configure the datasource via Payara post-boot commands (runs before app deploy).
# Setting is resolved with ${ENV=...} references so Render database credentials drive it.
COPY docker/post-boot-commands.asadmin $POSTBOOT_COMMANDS

# Add an init script that waits for the database before the server starts
COPY docker/init_2_wait_for_db.sh ${SCRIPT_DIR}/init.d/init_2_wait_for_db.sh
RUN chmod +x ${SCRIPT_DIR}/init.d/init_2_wait_for_db.sh && \
    chown payara:payara $POSTBOOT_COMMANDS

# Switch back to the non-root payara user
USER payara

EXPOSE 8080 4848
