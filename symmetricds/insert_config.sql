-- #####################################################################
-- 1. GRUPOS DE NODOS
-- #####################################################################
INSERT INTO sym_node_group (node_group_id, description)
VALUES
    ('master_group', 'Master Node Group'),
    ('client_group', 'Client Node Group')
    ON CONFLICT (node_group_id) DO NOTHING;

-- #####################################################################
-- 2. ENLACES ENTRE GRUPOS (BIDIRECCIONAL)
-- #####################################################################
-- Master ESPERA (WAIT) datos de Clientes
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action)
VALUES ('master_group', 'client_group', 'W')
    ON CONFLICT (source_node_group_id, target_node_group_id)
DO UPDATE SET data_event_action = 'W';

-- Cliente ENVÍA (PUSH) datos al Master
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action)
VALUES ('client_group', 'master_group', 'P')
    ON CONFLICT (source_node_group_id, target_node_group_id)
DO UPDATE SET data_event_action = 'P';

-- #####################################################################
-- 3. CANALES (PRIORIZACIÓN Y THROUGHPUT)
-- #####################################################################
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description)
VALUES
    ('config_channel', 1, 1000, 1, 'Configuración general (máxima prioridad)'),
    ('auth_channel', 2, 1000, 1, 'Datos de autenticación'),
    ('proveedor_channel', 3, 1000, 1, 'Datos de proveedores'),
    ('tipo_producto_channel', 4, 1000, 1, 'Tipos de producto'),
    ('dolar_channel', 5, 1000, 1, 'Cotizaciones del dólar'),
    ('producto_channel', 6, 2000, 1, 'Productos (mayor batch por volumen)'),
    ('venta_channel', 7, 500, 1, 'Ventas (cliente → master unidireccional)')
    ON CONFLICT (channel_id) DO UPDATE SET
    processing_order = EXCLUDED.processing_order,
                                    max_batch_size = EXCLUDED.max_batch_size,
                                    enabled = EXCLUDED.enabled,
                                    description = EXCLUDED.description;

-- #####################################################################
-- 4. TRIGGERS (QUÉ TABLAS MONITOREAR)
-- #####################################################################

-- Triggers Bidireccionales (Master ↔ Clientes)
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id,
                         sync_on_update, sync_on_insert, sync_on_delete,
                         excluded_column_names,  -- Evita loops infinitos
                         last_update_time, create_time)
VALUES
    -- Configuración
    ('nro_comprobante_trigger', 'public', 'nro_comprobante', 'config_channel',
     1, 1, 1, 'last_sync_node', now(), now()),

    -- Autenticación
    ('usuario_trigger', 'public', 'usuario', 'auth_channel',
     1, 1, 1, 'last_sync_node', now(), now()),
    ('authority_trigger', 'public', 'authority', 'auth_channel',
     1, 1, 1, 'last_sync_node', now(), now()),
    ('usuario_authority_trigger', 'public', 'usuario_authority', 'auth_channel',
     1, 1, 1, 'last_sync_node', now(), now()),

    -- Datos Maestros
    ('proveedor_trigger', 'public', 'proveedor', 'proveedor_channel',
     1, 1, 1, 'last_sync_node', now(), now()),
    ('tipo_producto_trigger', 'public', 'tipo_producto', 'tipo_producto_channel',
     1, 1, 1, 'last_sync_node', now(), now()),
    ('dolar_trigger', 'public', 'dolar', 'dolar_channel',
     1, 1, 1, 'last_sync_node', now(), now()),

    -- Productos (Core de tu negocio)
    ('producto_trigger', 'public', 'producto', 'producto_channel',
     1, 1, 1, 'last_sync_node', now(), now()),
    ('productos_relacionados_trigger', 'public', 'productos_relacionados', 'producto_channel',
     1, 1, 1, 'last_sync_node', now(), now())
    ON CONFLICT (trigger_id) DO UPDATE SET
    excluded_column_names = EXCLUDED.excluded_column_names,
                                    last_update_time = now();

-- Triggers Unidireccionales (Cliente → Master SOLAMENTE)
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id,
                         sync_on_update, sync_on_insert, sync_on_delete,
                         last_update_time, create_time)
VALUES
    ('venta_trigger', 'public', 'venta', 'venta_channel',
     0, 1, 0, now(), now()),  -- Solo INSERT
    ('venta_item_trigger', 'public', 'venta_item', 'venta_channel',
     0, 1, 0, now(), now())   -- Solo INSERT
    ON CONFLICT (trigger_id) DO UPDATE SET
    sync_on_update = EXCLUDED.sync_on_update,
                                    sync_on_insert = EXCLUDED.sync_on_insert,
                                    sync_on_delete = EXCLUDED.sync_on_delete,
                                    last_update_time = now();

-- #####################################################################
-- 5. ROUTERS (A QUIÉN SE ENVÍA)
-- #####################################################################
INSERT INTO sym_router (router_id, source_node_group_id, target_node_group_id,
                        router_type, router_expression,
                        create_time, last_update_time)
VALUES
    -- Master distribuye a TODOS los clientes
    ('master_to_all_clients', 'master_group', 'client_group',
     'default', NULL, now(), now()),

    -- Cliente envía al Master
    ('client_to_master', 'client_group', 'master_group',
     'default', NULL, now(), now())
    ON CONFLICT (router_id) DO UPDATE SET
    router_expression = EXCLUDED.router_expression,
                                   last_update_time = now();

-- #####################################################################
-- 6. TRIGGER_ROUTERS (CONEXIÓN TRIGGER → ROUTER)
-- #####################################################################

-- ==================== MASTER → TODOS LOS CLIENTES ====================
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, enabled,
                                last_update_time, create_time)
VALUES
    -- Configuración (prioridad 1)
    ('nro_comprobante_trigger', 'master_to_all_clients', 10, 1, now(), now()),

    -- Autenticación (prioridad 2)
    ('usuario_trigger', 'master_to_all_clients', 20, 1, now(), now()),
    ('authority_trigger', 'master_to_all_clients', 21, 1, now(), now()),
    ('usuario_authority_trigger', 'master_to_all_clients', 22, 1, now(), now()),

    -- Datos Maestros (prioridad 3-5)
    ('proveedor_trigger', 'master_to_all_clients', 30, 1, now(), now()),
    ('tipo_producto_trigger', 'master_to_all_clients', 40, 1, now(), now()),
    ('dolar_trigger', 'master_to_all_clients', 50, 1, now(), now()),

    -- Productos (prioridad 6)
    ('producto_trigger', 'master_to_all_clients', 60, 1, now(), now()),
    ('productos_relacionados_trigger', 'master_to_all_clients', 61, 1, now(), now())
    ON CONFLICT (trigger_id, router_id) DO UPDATE SET
    initial_load_order = EXCLUDED.initial_load_order,
                                               enabled = 1,
                                               last_update_time = now();

-- ==================== CLIENTE → MASTER ====================
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, enabled,
                                last_update_time, create_time)
VALUES
    -- Configuración
    ('nro_comprobante_trigger', 'client_to_master', 10, 1, now(), now()),

    -- Autenticación
    ('usuario_trigger', 'client_to_master', 20, 1, now(), now()),
    ('authority_trigger', 'client_to_master', 21, 1, now(), now()),
    ('usuario_authority_trigger', 'client_to_master', 22, 1, now(), now()),

    -- Datos Maestros
    ('proveedor_trigger', 'client_to_master', 30, 1, now(), now()),
    ('tipo_producto_trigger', 'client_to_master', 40, 1, now(), now()),
    ('dolar_trigger', 'client_to_master', 50, 1, now(), now()),

    -- Productos
    ('producto_trigger', 'client_to_master', 60, 1, now(), now()),
    ('productos_relacionados_trigger', 'client_to_master', 61, 1, now(), now()),

    -- Ventas (SOLO Cliente → Master)
    ('venta_trigger', 'client_to_master', 100, 1, now(), now()),
    ('venta_item_trigger', 'client_to_master', 101, 1, now(), now())
    ON CONFLICT (trigger_id, router_id) DO UPDATE SET
    initial_load_order = EXCLUDED.initial_load_order,
                                               enabled = 1,
                                               last_update_time = now();

-- #####################################################################
-- 7. RESOLUCIÓN DE CONFLICTOS
-- #####################################################################
INSERT INTO sym_conflict (
    conflict_id, source_node_group_id, target_node_group_id,
    target_channel_id, target_catalog_name, target_schema_name, target_table_name,
    detect_type, resolve_type, ping_back, resolve_changes_only, resolve_row_only,
    detect_expression, create_time, last_update_time
)
VALUES
    -- Productos: El más reciente gana (TIMESTAMP)
    ('producto_conflict', 'client_group', 'master_group',
     'producto_channel', NULL, 'public', 'producto',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now()),

    -- Productos Relacionados: Usa PK, fallback manual
    ('productos_relacionados_conflict', 'client_group', 'master_group',
     'producto_channel', NULL, 'public', 'productos_relacionados',
     'USE_PK_DATA', 'FALLBACK', 'OFF', 1, 1,
     NULL, now(), now()),

    -- Proveedores: El más reciente gana
    ('proveedor_conflict', 'client_group', 'master_group',
     'proveedor_channel', NULL, 'public', 'proveedor',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now()),

    -- Tipos de Producto: El más reciente gana
    ('tipo_producto_conflict', 'client_group', 'master_group',
     'tipo_producto_channel', NULL, 'public', 'tipo_producto',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now()),

    -- Dólar: El más reciente gana
    ('dolar_conflict', 'client_group', 'master_group',
     'dolar_channel', NULL, 'public', 'dolar',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now()),

    -- Usuarios: Resolución manual (seguridad)
    ('usuario_conflict', 'client_group', 'master_group',
     'auth_channel', NULL, 'public', 'usuario',
     'USE_PK_DATA', 'MANUAL', 'OFF', 1, 1,
     NULL, now(), now()),

    -- Nro Comprobante: El más reciente gana
    ('nro_comprobante_conflict', 'client_group', 'master_group',
     'config_channel', NULL, 'public', 'nro_comprobante',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now())
    ON CONFLICT (conflict_id) DO UPDATE SET
    detect_type = EXCLUDED.detect_type,
                                     resolve_type = EXCLUDED.resolve_type,
                                     ping_back = EXCLUDED.ping_back,
                                     last_update_time = now();

-- #####################################################################
-- 8. PARÁMETROS DE RENDIMIENTO
-- #####################################################################
INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_time)
VALUES
    -- Prevención de Loops Infinitos
    ('ALL', 'ALL', 'routing.data.gap.detection.enabled', 'true', now(), now()),
    ('ALL', 'ALL', 'sync.table.level.preview.enabled', 'true', now(), now()),

    -- Intervalos de Sincronización Optimizados
    ('ALL', 'ALL', 'job.pull.period.time.ms', '5000', now(), now()),
    ('ALL', 'ALL', 'job.push.period.time.ms', '5000', now(), now()),
    ('ALL', 'ALL', 'job.routing.period.time.ms', '3000', now(), now()),
    ('ALL', 'ALL', 'job.heartbeat.period.time.ms', '10000', now(), now()),

    -- Workers Concurrentes
    ('ALL', 'master_group', 'concurrent.workers', '5', now(), now()),
    ('ALL', 'client_group', 'concurrent.workers', '3', now(), now()),

    -- Tamaño de Batch
    ('ALL', 'ALL', 'routing.max.batch.size', '10000', now(), now()),
    ('ALL', 'ALL', 'transport.max.bytes.to.sync', '2097152', now(), now()),

    -- Números en WHERE (PostgreSQL)
    ('ALL', 'ALL', 'db.quote.numbers.in.where.enabled', 'false', now(), now()),

    -- Auto-registro y Carga Inicial
    ('ALL', 'client_group', 'auto.registration', 'true', now(), now()),
    ('ALL', 'client_group', 'initial.load.create.first', 'true', now(), now()),
    ('ALL', 'client_group', 'initial.load.delete.first', 'true', now(), now()),

    -- Logging Detallado
    ('ALL', 'ALL', 'log.conflict.resolution', 'true', now(), now()),
    ('ALL', 'ALL', 'routing.log.stats.on.batch.error', 'true', now(), now()),
    ('ALL', 'ALL', 'db.log.sql', 'false', now(), now()),  -- Activar solo para debug

    -- Timeouts
    ('ALL', 'ALL', 'http.timeout.ms', '300000', now(), now()),
    ('ALL', 'ALL', 'http.connection.timeout.ms', '30000', now(), now())
    ON CONFLICT (external_id, node_group_id, param_key) DO UPDATE SET
    param_value = EXCLUDED.param_value,
                                                               last_update_time = now();

-- #####################################################################
-- 9. AGREGAR COLUMNA DE CONTROL (OPCIONAL PERO RECOMENDADO)
-- #####################################################################
-- Esto ayuda a prevenir loops infinitos rastreando el nodo de origen

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'producto'
          AND column_name = 'last_sync_node'
    ) THEN
ALTER TABLE producto ADD COLUMN last_sync_node VARCHAR(50);
END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'proveedor'
          AND column_name = 'last_sync_node'
    ) THEN
ALTER TABLE proveedor ADD COLUMN last_sync_node VARCHAR(50);
END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'tipo_producto'
          AND column_name = 'last_sync_node'
    ) THEN
ALTER TABLE tipo_producto ADD COLUMN last_sync_node VARCHAR(50);
END IF;
END $$;

-- #####################################################################
-- 10. VERIFICACIÓN DE CONFIGURACIÓN
-- #####################################################################
-- Ejecuta estas queries para verificar que todo está OK

-- Verificar Triggers
SELECT trigger_id, source_table_name, channel_id, sync_on_insert, sync_on_update, sync_on_delete
FROM sym_trigger
ORDER BY channel_id, trigger_id;

-- Verificar Routers
SELECT tr.trigger_id, tr.router_id, t.source_table_name, r.source_node_group_id, r.target_node_group_id
FROM sym_trigger_router tr
         JOIN sym_trigger t ON tr.trigger_id = t.trigger_id
         JOIN sym_router r ON tr.router_id = r.router_id
ORDER BY tr.initial_load_order;

-- Verificar Conflictos
SELECT conflict_id, target_table_name, detect_type, resolve_type, ping_back
FROM sym_conflict
ORDER BY conflict_id;

-- Verificar Parámetros Críticos
SELECT param_key, node_group_id, param_value
FROM sym_parameter
WHERE param_key IN (
                    'routing.data.gap.detection.enabled',
                    'job.push.period.time.ms',
                    'job.pull.period.time.ms',
                    'concurrent.workers'
    )
ORDER BY node_group_id, param_key;

-- Actualizar sync_url del nodo master a IP pública
UPDATE sym_node
SET sync_url = 'http://31.97.240.232:31415/sync/master'
WHERE node_id = 'master_node';

INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_by, last_update_time)
VALUES ('GLOBAL', 'master_group', 'sync.url', 'http://31.97.240.232:31415/sync/master', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP)
    ON CONFLICT (external_id, node_group_id, param_key) DO UPDATE
                                                               SET param_value = EXCLUDED.param_value,
                                                               last_update_time = CURRENT_TIMESTAMP;

-- Configurar registration.url global
INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_by, last_update_time)
VALUES ('GLOBAL', 'ALL', 'registration.url', 'http://31.97.240.232:31415/sync/master', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP)
    ON CONFLICT (external_id, node_group_id, param_key) DO UPDATE
                                                               SET param_value = EXCLUDED.param_value,
                                                               last_update_time = CURRENT_TIMESTAMP;

-- #####################################################################
-- 11. CONFIGURACIÓN PARA REDISTRIBUCIÓN DE CAMBIOS
-- #####################################################################

-- Permitir que el master re-dispare triggers cuando reciba datos
-- Esto permite que los cambios de un cliente se redistribuyan a otros clientes
INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_time)
VALUES
    ('MASTER', 'master_group', 'sync.triggers.fire.on.load', 'true', now(), now()),

    -- Asegurar que los triggers se evalúen durante el proceso de carga
    ('MASTER', 'master_group', 'trigger.create.before.initial.load', 'true', now(), now()),

    -- Habilitar el enrutamiento después de aplicar cambios recibidos
    ('MASTER', 'master_group', 'routing.trigger.enabled', 'true', now(), now())
    ON CONFLICT (external_id, node_group_id, param_key) DO UPDATE SET
    param_value = EXCLUDED.param_value,
                                                               last_update_time = now();