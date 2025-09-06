#!/bin/sh

init-symmetric-master.sh (Versión Mejorada)
set -e

--- Variables ---
SYM_ADMIN="/app/symmetric-ds-3.14.0/bin/symadmin"
DB_SQL="/app/symmetric-ds-3.14.0/bin/dbsql"
SYM_ENGINE="master"
CONFIG_SQL_FILE="/app/symmetric-ds-3.14.0/conf/insert_config.sql"
PG_HOST="postgres-db"
PG_USER="admin"
PG_DB="ecopila_db_online"
INIT_FLAG_FILE="/app/symmetric-ds-3.14.0/data/.initialized"

Las opciones de la JVM que solucionan el error de Cgroup
JVM_OPTIONS="-XX:+UnlockDiagnosticVMOptions -XX:-UseContainerSupport -Djava.net.preferIPv4Stack=true"

--- Iniciar directamente si ya está inicializado ---
if [ -f "$INIT_FLAG_FILE" ]; then
echo "SymmetricDS Master ya está inicializado. Iniciando servidor..."
exec /app/symmetric-ds-3.14.0/bin/sym --port 31415 --server $JVM_OPTIONS
fi

--- Esperar a que PostgreSQL esté listo ---
echo "--> Esperando a PostgreSQL en $PG_HOST:5432..."
export PGPASSWORD=password
until pg_isready -h "$PG_HOST" -U "$PG_USER" -d "$PG_DB" -q; do
sleep 2
done
echo "✅ PostgreSQL está listo."

--- Inicializar SymmetricDS y crear el esquema ---
echo "--> Iniciando instancia temporal de SymmetricDS para crear el esquema..."
$SYM_ADMIN --engine "$SYM_ENGINE" --host $PG_HOST --port 5432 create-sym-tables $JVM_OPTIONS

Esperamos un poco para asegurarnos de que el comando se complete
sleep 15

--- Insertar la configuración ---
echo "--> Insertando configuración personalizada en la base de datos..."
$DB_SQL --engine "$SYM_ENGINE" --host $PG_HOST --port 5432 < "$CONFIG_SQL_FILE"

--- Crear el flag y limpiar ---
echo "✅ Inicialización completada. Se creó el flag en $INIT_FLAG_FILE."
touch "$INIT_FLAG_FILE"

--- Iniciar el servidor final ---
echo "--> Iniciando instancia final de SymmetricDS..."
exec /app/symmetric-ds-3.14.0/bin/sym --port 31415 --server $JVM_OPTIONS
