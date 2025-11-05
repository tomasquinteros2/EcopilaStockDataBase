FROM openjdk:17-jdk-slim

WORKDIR /app

# Instalar net-tools para obtener MAC address
RUN apt-get update && apt-get install -y --no-install-recommends net-tools && \
    rm -rf /var/lib/apt/lists/*

COPY symmetricds/symmetric-ds-3.14.0/ ./
COPY symmetricds/client/engines/client.properties ./engines/client.properties.template

# Script que genera ID único basado en MAC address del contenedor
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Obtener MAC address única del contenedor (elimina ":")\n\
MAC_ADDRESS=$(cat /sys/class/net/eth0/address | tr -d ":")\n\
EXTERNAL_ID="client_node_${MAC_ADDRESS}"\n\
\n\
echo "================================="\n\
echo "Cliente SymmetricDS - Inicialización"\n\
echo "================================="\n\
echo "MAC Address: ${MAC_ADDRESS}"\n\
echo "External ID: ${EXTERNAL_ID}"\n\
echo ""\n\
\n\
# Reemplaza el placeholder\n\
sed "s/{{EXTERNAL_ID}}/${EXTERNAL_ID}/g" /app/engines/client.properties.template > /app/engines/client.properties\n\
\n\
echo "Configuración aplicada:"\n\
cat /app/engines/client.properties | grep -E "(external.id|registration.url)"\n\
echo ""\n\
\n\
# Inicia SymmetricDS\n\
exec /app/bin/sym --port 8081 --server\n\
' > /app/start-client.sh && chmod +x /app/start-client.sh

ENV JAVA_OPTS="-Dh2.baseDir=/app -Xmx512m"

RUN chmod +x bin/sym

EXPOSE 8081

CMD ["/app/start-client.sh"]
