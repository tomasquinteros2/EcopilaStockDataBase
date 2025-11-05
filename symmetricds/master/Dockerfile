FROM eclipse-temurin:21-jdk-alpine

# Instala dependencias necesarias usando apk (Alpine package manager)
RUN apk add --no-cache \
    postgresql-client \
    bash \
    sed \
    curl

WORKDIR /app

# Copia SymmetricDS
COPY symmetricds/symmetric-ds-3.14.0/ ./symmetric-ds-3.14.0/

# IMPORTANTE: Asegúrate de copiar el archivo correcto
COPY symmetricds/master/engines/master.properties ./symmetric-ds-3.14.0/engines/master.properties

# Verificar que la configuración fue copiada correctamente
RUN echo "=== Verificando master.properties ===" && \
    cat ./symmetric-ds-3.14.0/engines/master.properties | grep -E "(registration\.url|sync\.url|engine\.name)" || \
    (echo "ERROR: master.properties no contiene las propiedades necesarias" && exit 1)

# Copia scripts
COPY symmetricds/master/init-symmetric-master.sh /app/init-symmetric-master.sh
COPY symmetricds/insert_config.sql /app/insert_config.sql

# Permisos de ejecución
RUN sed -i 's/\r$//' /app/init-symmetric-master.sh && \
    chmod +x /app/init-symmetric-master.sh && \
    chmod +x /app/symmetric-ds-3.14.0/bin/sym

# Variables de entorno
ENV JAVA_OPTS="-Xmx512m"

EXPOSE 31415

CMD ["/app/init-symmetric-master.sh"]
