#!/bin/sh
# init-symmetric-master.sh (Versión Más Robusta)

set -e

# --- Variables ---
SYM_ADMIN="/app/symmetric-ds-3.14.0/bin/symadmin"
DB_SQL="/app/symmetric-ds-3.14.0/bin/dbsql"
SYM_ENGINE="master"
CONFIG_SQL_FILE="/app/symmetric-ds-3.14.0/conf/insert_config.sql"
PG_HOST="postgres-db"
PG_USER="admin"
PG_DB="ecopila_db_online"
INIT_FLAG_FILE="/app/symmetric-ds-3.14.0/data/.initialized"

# Las opciones de la JVM que solucionan el error de Cgroup
# Se exportan como una variable de entorno para que sean globales.
JVM_OPTIONS="-XX:+UnlockDiagnosticVMOptions -XX:-UseContainerSupport -Djava.net.preferIPv4Stack=true"
export JAVA_OPTS="$JVM_OPTIONS"

# --- Iniciar directamente si ya está inicializado ---
# Iniciar directamente si ya está inicializado.
if [ -f "$INIT_FLAG_FILE" ]; then
    echo "SymmetricDS Master is already initialized. Starting server..."
    exec /app/symmetric-ds-3.14.0/bin/sym --port 31415 --server
fi

# --- Esperar a que PostgreSQL esté listo ---
# Esperar a que PostgreSQL esté listo.
echo "--> Waiting for PostgreSQL at $PG_HOST:5432..."
export PGPASSWORD=password
until pg_isready -h "$PG_HOST" -U "$PG_USER" -d "$PG_DB" -q; do
    sleep 2
done
echo "✅ PostgreSQL is ready."

# --- Inicializar SymmetricDS y crear el esquema ---
# Inicializar SymmetricDS y crear el esquema.
echo "--> Starting a temporary SymmetricDS instance to create the schema..."
$SYM_ADMIN --engine "$SYM_ENGINE" --host $PG_HOST --port 5432 create-sym-tables

# Esperamos un poco para asegurarnos de que el comando se complete.
sleep 15

# --- Insertar la configuración ---
# Insertar la configuración.
echo "--> Inserting custom configuration into the database..."
$DB_SQL --engine "$SYM_ENGINE" --host $PG_HOST --port 5432 < "$CONFIG_SQL_FILE"

# --- Create the flag and clean up ---
# Crear el flag y limpiar.
echo "✅ Initialization complete. Flag created at $INIT_FLAG_FILE."
touch "$INIT_FLAG_FILE"

# --- Start the final server instance ---
# Iniciar la instancia final del servidor.
echo "--> Starting the final SymmetricDS instance..."
exec /app/symmetric-ds-3.14.0/bin/sym --port 31415 --server
