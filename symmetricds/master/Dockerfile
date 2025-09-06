# symmetricds/master/Dockerfile

# Utiliza una imagen base de OpenJDK 17
FROM openjdk:11-jdk-slim

# Instala dependencias necesarias (cliente de postgres y sed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    sed \
    && rm -rf /var/lib/apt/lists/*

# Establece el directorio de trabajo
WORKDIR /app

# --- Copia y da permisos a los archivos ---
# 1. Copia la aplicación SymmetricDS a la imagen.
#    Esta ruta es relativa a la raíz de tu proyecto (el 'build context').
COPY symmetricds/symmetric-ds-3.14.0/ ./symmetric-ds-3.14.0/

# 2. Copia el script de inicialización a la imagen.
COPY symmetricds/master/init-symmetric-master.sh /app/init-symmetric-master.sh

# 3. Copia el script de configuración SQL a la imagen.
COPY symmetricds/insert_config.sql /app/insert_config.sql

# 4. Corrige finales de línea (si vienes de Windows) y da permisos de ejecución al script.
RUN sed -i 's/\r$//' /app/init-symmetric-master.sh && \
    chmod +x /app/init-symmetric-master.sh

# 5. Corrige el error de permisos. Le da permisos de ejecución al binario 'sym'.
#    
RUN chmod +x /app/symmetric-ds-3.14.0/bin/sym

# El comando de inicio se especificará en docker-compose.online.yml
