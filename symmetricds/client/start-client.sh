#!/bin/bash
set -e

# Obtener MAC address única del contenedor
MAC_ADDRESS=$(cat /sys/class/net/eth0/address | tr -d ":")
EXTERNAL_ID="client_node_${MAC_ADDRESS}"

echo "================================="
echo "Cliente SymmetricDS - Inicialización"
echo "================================="
echo "MAC Address: ${MAC_ADDRESS}"
echo "External ID: ${EXTERNAL_ID}"
echo ""

# Reemplaza el placeholder
sed "s/{{EXTERNAL_ID}}/${EXTERNAL_ID}/g" /app/engines/client.properties.template > /app/engines/client.properties

echo "✅ Configuración aplicada:"
cat /app/engines/client.properties | grep -E "(external.id|registration.url|sync.url)"
echo ""

echo "🚀 Iniciando SymmetricDS Client..."
# Inicia SymmetricDS
exec /app/bin/sym --port 8081 --server
