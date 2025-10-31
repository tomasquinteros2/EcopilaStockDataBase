#!/bin/sh
set -e

DB_HOST="postgres-db"
DB_PORT="5432"
DB_USER="admin"
DB_NAME="ecopila_db_online"
export PGPASSWORD="password"

echo "=========================================="
echo "SymmetricDS Master - Inicialización"
echo "=========================================="
echo "--> [$(date)] Host: ${DB_HOST}:${DB_PORT}"
echo "--> [$(date)] Base de datos: ${DB_NAME}"
echo ""

echo "--> [$(date)] Esperando a PostgreSQL..."

MAX_TRIES=30
COUNTER=0

while ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c '\q' 2>/dev/null; do
  COUNTER=$((COUNTER + 1))
  if [ $COUNTER -ge $MAX_TRIES ]; then
    echo "❌ ERROR: PostgreSQL no disponible después de $MAX_TRIES intentos"
    exit 1
  fi
  echo "⏳ Esperando PostgreSQL... (intento $COUNTER/$MAX_TRIES)"
  sleep 2
done

echo "✅ PostgreSQL está listo"
echo ""

# Verificar si ya existe configuración previa
echo "--> [$(date)] Verificando configuración existente..."
EXISTING_CONFIG=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='sym_node';" 2>/dev/null | tr -d ' ')

echo "Tablas SymmetricDS encontradas: ${EXISTING_CONFIG:-0}"

if [ "$EXISTING_CONFIG" = "0" ] || [ -z "$EXISTING_CONFIG" ]; then
  echo ""
  echo "=========================================="
  echo "Primera inicialización detectada"
  echo "=========================================="

  echo "--> [$(date)] Iniciando instancia temporal para crear esquema..."
  /app/symmetric-ds-3.14.0/bin/sym --port 31415 --server &
  SYMMETRIC_PID=$!

  echo "⏳ Esperando creación de esquema (60 segundos)..."
  sleep 60

  echo "--> [$(date)] Deteniendo instancia temporal (PID: $SYMMETRIC_PID)..."
  kill $SYMMETRIC_PID 2>/dev/null || true
  sleep 5

  echo ""
  echo "--> [$(date)] Insertando configuración personalizada..."
  if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f /app/insert_config.sql; then
    echo "✅ Configuración insertada exitosamente"
  else
    echo "❌ ERROR: Falló la inserción de configuración"
    exit 1
  fi
else
  echo "ℹ️  Esquema existente detectado. Saltando inicialización."
fi

echo ""
echo "=========================================="
echo "Verificación de Nodos Registrados"
echo "=========================================="
# Corrección del error SQL: Cast explícito a boolean
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT
  node_id,
  node_group_id,
  external_id,
  CASE WHEN sync_enabled::boolean THEN 'Sí' ELSE 'No' END as sincronizacion
FROM sym_node
ORDER BY created_at_node_id;
" 2>/dev/null || echo "No hay nodos registrados aún"

echo ""
echo "=========================================="
echo "Configuración de Canales"
echo "=========================================="
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT channel_id, processing_order, max_batch_size,
       CASE WHEN enabled::boolean THEN 'Sí' ELSE 'No' END as habilitado
FROM sym_channel
ORDER BY processing_order;
" 2>/dev/null || echo "No hay canales configurados aún"

echo ""
echo "=========================================="
echo "Iniciando SymmetricDS Master"
echo "=========================================="
echo "--> Puerto: 31415"
echo "--> Grupo: master_group"
echo "--> External ID: master_node"
echo "--> Registration URL: http://symmetricds-master:31415/sync/master"
echo ""

exec /app/symmetric-ds-3.14.0/bin/sym --port 31415 --server
