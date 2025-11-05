FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

# Instalar herramientas necesarias
RUN apk add --no-cache \
    bash \
    net-tools \
    sed \
    curl \
    dos2unix

# Copiar SymmetricDS
COPY symmetricds/symmetric-ds-3.14.0/ ./

# Copiar configuración del cliente
COPY symmetricds/client/engines/client.properties ./engines/client.properties.template

# Copiar script de inicio
COPY symmetricds/client/start-client.sh /app/start-client.sh

# Convertir CRLF a LF y dar permisos
RUN dos2unix /app/start-client.sh && \
    chmod +x /app/start-client.sh && \
    chmod +x /app/bin/sym && \
    ls -lah /app/start-client.sh  # Verificar que existe

# Variables de entorno
ENV JAVA_OPTS="-Xmx512m"

EXPOSE 8081

CMD ["/bin/bash", "/app/start-client.sh"]
