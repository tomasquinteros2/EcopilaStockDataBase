FROM openjdk:17-jdk-slim

WORKDIR /app

# Copia la distribución de SymmetricDS
COPY symmetricds/symmetric-ds-3.14.0/ ./

# Copia el archivo de configuración como template
COPY symmetricds/client/engines/client.properties ./engines/client.properties.template

# Script de inicio que genera external.id único
RUN echo '#!/bin/bash\n\
set -e\n\
# Genera un ID único basado en hostname y timestamp\n\
HOSTNAME=$(hostname)\n\
TIMESTAMP=$(date +%s)\n\
RANDOM_NUM=$((RANDOM % 10000))\n\
EXTERNAL_ID="client_node_${HOSTNAME}_${TIMESTAMP}_${RANDOM_NUM}"\n\
\n\
echo "Generando configuración con external.id: ${EXTERNAL_ID}"\n\
\n\
# Reemplaza el placeholder en el template\n\
sed "s/{{EXTERNAL_ID}}/${EXTERNAL_ID}/g" /app/engines/client.properties.template > /app/engines/client.properties\n\
\n\
# Muestra la configuración generada\n\
echo "Configuración del cliente:"\n\
cat /app/engines/client.properties\n\
\n\
# Inicia SymmetricDS\n\
exec /app/bin/sym --port 8081 --server\n\
' > /app/start-client.sh && chmod +x /app/start-client.sh

ENV JAVA_OPTS="-Dh2.baseDir=/app -Xmx512m"

RUN chmod +x bin/sym

EXPOSE 8081

CMD ["/app/start-client.sh"]
