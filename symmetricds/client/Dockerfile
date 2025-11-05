FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

RUN apk add --no-cache bash net-tools sed curl

COPY symmetricds/symmetric-ds-3.14.0/ ./
COPY symmetricds/client/engines/client.properties ./engines/client.properties.template
COPY symmetricds/client/start-client.sh /app/start-client.sh

RUN chmod +x /app/start-client.sh && \
    chmod +x /app/bin/sym

ENV JAVA_OPTS="-Dh2.baseDir=/app -Xmx512m"

EXPOSE 8081

CMD ["/app/start-client.sh"]
