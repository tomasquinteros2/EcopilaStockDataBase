-- #####################################################################
-- Se Definen los Grupos de Nodos
-- #####################################################################
INSERT INTO sym_node_group (node_group_id, description) VALUES ('master_group', 'Master Node Group') ON CONFLICT (node_group_id) DO NOTHING;
INSERT INTO sym_node_group (node_group_id, description) VALUES ('client_group', 'Client Node Group') ON CONFLICT (node_group_id) DO NOTHING;

-- #####################################################################
-- Se Define cómo se comunican los grupos (Bidireccional)
-- #####################################################################
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action)
VALUES ('master_group', 'client_group', 'W')
    ON CONFLICT (source_node_group_id, target_node_group_id)
DO UPDATE SET data_event_action = 'W';

-- El Cliente ENVÍA (PUSH) sus datos al Master.
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action)
VALUES ('client_group', 'master_group', 'P')
    ON CONFLICT (source_node_group_id, target_node_group_id)
DO UPDATE SET data_event_action = 'P';
-- #####################################################################
-- Se Definen los Canales para categorizar los datos
-- #####################################################################
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('producto_channel', 1, 1000, 1, 'Producto data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('proveedor_channel', 1, 1000, 1, 'Proveedor data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('tipo_producto_channel', 1, 1000, 1, 'Tipo Producto data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('dolar_channel', 1, 1000, 1, 'Dolar data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('auth_channel', 1, 1000, 1, 'Auth data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('venta_channel', 2, 500, 1, 'Ventas del cliente al master') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('config_channel', 1, 1000, 1, 'Configuracion general') ON CONFLICT (channel_id) DO NOTHING;

-- #####################################################################
-- Se definen los Triggers: qué tablas observar para capturar cambios
-- #####################################################################
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('producto_trigger', 'public', 'producto', 'producto_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('proveedor_trigger', 'public', 'proveedor', 'proveedor_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('tipo_producto_trigger', 'public', 'tipo_producto', 'tipo_producto_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('dolar_trigger', 'public', 'dolar', 'dolar_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('usuario_trigger', 'public', 'usuario', 'auth_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('authority_trigger', 'public', 'authority', 'auth_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('usuario_authority_trigger', 'public', 'usuario_authority', 'auth_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('productos_relacionados_trigger', 'public', 'productos_relacionados', 'producto_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('nro_comprobante_trigger', 'public', 'nro_comprobante', 'config_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;

-- Unidireccionales Cliente -> Maestro (ventas)
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('venta_trigger', 'public', 'venta', 'venta_channel', 0, 1, 0, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_schema_name, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('venta_item_trigger', 'public', 'venta_item', 'venta_channel', 0, 1, 0, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;

-- #####################################################################
-- Se definen los Routers: a qué grupo de nodos se envían los datos
-- #####################################################################
INSERT INTO sym_router (router_id, source_node_group_id, target_node_group_id, create_time, last_update_time) VALUES ('master_to_client', 'master_group', 'client_group', now(), now()) ON CONFLICT (router_id) DO NOTHING;
INSERT INTO sym_router (router_id, source_node_group_id, target_node_group_id, create_time, last_update_time) VALUES ('client_to_master', 'client_group', 'master_group', now(), now()) ON CONFLICT (router_id) DO NOTHING;

-- ## Reglas: del MAESTRO (Online) hacia el CLIENTE (Offline) ##
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('producto_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('proveedor_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('tipo_producto_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('dolar_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('authority_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_authority_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('productos_relacionados_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('nro_comprobante_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;


-- ## Reglas: del CLIENTE (Offline) hacia el MAESTRO (Online) ##
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('producto_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('proveedor_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('tipo_producto_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('dolar_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('authority_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_authority_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('productos_relacionados_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('nro_comprobante_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;

-- Sincronización unidireccional de ventas (Cliente -> Maestro)
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('venta_trigger', 'client_to_master', 200, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('venta_item_trigger', 'client_to_master', 200, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;


INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_time)
VALUES ('ALL', 'master_group', 'db.quote.numbers.in.where.enabled', 'false', now(), now())
    ON CONFLICT (external_id, node_group_id, param_key) DO NOTHING;

INSERT INTO sym_conflict (
    conflict_id, source_node_group_id, target_node_group_id,
    target_channel_id, target_catalog_name, target_schema_name, target_table_name,
    detect_type, resolve_type, ping_back, resolve_changes_only, resolve_row_only,
    detect_expression, create_time, last_update_time
)
VALUES
    ('producto_conflict', 'client_group', 'master_group',
     'producto_channel', NULL, 'public', 'producto',
     'USE_TIMESTAMP', 'NEWER_WINS', 'SINGLE_ROW', 1, 1,
     NULL, now(), now()),
    ('productos_relacionados_conflict', 'client_group', 'master_group',
     'producto_channel', NULL, 'public', 'productos_relacionados',
     'USE_PK_DATA', 'FALLBACK', 'OFF', 1, 1,
     NULL, now(), now()),
    ('proveedor_conflict', 'client_group', 'master_group',
     'proveedor_channel', NULL, 'public', 'proveedor',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now()),
    ('tipo_producto_conflict', 'client_group', 'master_group',
     'tipo_producto_channel', NULL, 'public', 'tipo_producto',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now()),
    ('dolar_conflict', 'client_group', 'master_group',
     'dolar_channel', NULL, 'public', 'dolar',
     'USE_TIMESTAMP', 'NEWER_WINS', 'OFF', 1, 1,
     NULL, now(), now()),
    ('usuario_conflict', 'client_group', 'master_group',
     'auth_channel', NULL, 'public', 'usuario',
     'USE_PK_DATA', 'MANUAL', 'OFF', 1, 1,
     NULL, now(), now())
    ON CONFLICT (conflict_id)
DO UPDATE SET
    ping_back = EXCLUDED.ping_back,
           resolve_type = EXCLUDED.resolve_type,
           detect_type = EXCLUDED.detect_type,
           last_update_time = now();
INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_time)
VALUES
    ('ALL', 'ALL', 'job.pull.period.time.ms', '5000', now(), now()),
    ('ALL', 'ALL', 'job.push.period.time.ms', '5000', now(), now()),
    ('ALL', 'ALL', 'job.routing.period.time.ms', '3000', now(), now()),
    ('ALL', 'master_group', 'concurrent.workers', '5', now(), now()),
    ('ALL', 'client_group', 'concurrent.workers', '3', now(), now()),
    ('ALL', 'ALL', 'routing.max.batch.size', '10000', now(), now()),
    ('ALL', 'ALL', 'transport.max.bytes.to.sync', '2097152', now(), now())
    ON CONFLICT (external_id, node_group_id, param_key)
DO UPDATE SET
    param_value = EXCLUDED.param_value,
           last_update_time = now();

-- Habilitar initial load automático para nuevos clientes
INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_time)
VALUES
    ('ALL', 'client_group', 'initial.load.create.first', 'true', now(), now()),
    ('ALL', 'client_group', 'auto.registration', 'true', now(), now())
    ON CONFLICT (external_id, node_group_id, param_key)
DO UPDATE SET
    param_value = EXCLUDED.param_value,
           last_update_time = now();