-- #####################################################################
-- # 1. Definir los Grupos de Nodos
-- #####################################################################
INSERT INTO sym_node_group (node_group_id, description) VALUES ('master_group', 'Master Node Group') ON CONFLICT (node_group_id) DO NOTHING;
INSERT INTO sym_node_group (node_group_id, description) VALUES ('client_group', 'Client Node Group') ON CONFLICT (node_group_id) DO NOTHING;

-- #####################################################################
-- # 2. Definir cómo se comunican los grupos (Bidireccional)
-- #####################################################################
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action) VALUES ('master_group', 'client_group', 'P') ON CONFLICT (source_node_group_id, target_node_group_id) DO NOTHING;
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action) VALUES ('client_group', 'master_group', 'P') ON CONFLICT (source_node_group_id, target_node_group_id) DO NOTHING;

-- #####################################################################
-- # 3. Definir los Canales para categorizar los datos
-- #####################################################################
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('producto_channel', 1, 1000, 1, 'Producto data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('proveedor_channel', 1, 1000, 1, 'Proveedor data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('tipo_producto_channel', 1, 1000, 1, 'Tipo Producto data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('dolar_channel', 1, 1000, 1, 'Dolar data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('auth_channel', 1, 1000, 1, 'Auth data') ON CONFLICT (channel_id) DO NOTHING;
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, enabled, description) VALUES ('venta_channel', 2, 500, 1, 'Ventas del cliente al master') ON CONFLICT (channel_id) DO NOTHING;

-- #####################################################################
-- # 4. Definir los Triggers: qué tablas observar para capturar cambios
-- #####################################################################
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('producto_trigger', 'producto', 'producto_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('proveedor_trigger', 'proveedor', 'proveedor_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('tipo_producto_trigger', 'tipo_producto', 'tipo_producto_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('dolar_trigger', 'dolar', 'dolar_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('usuario_trigger', 'usuario', 'auth_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('authority_trigger', 'authority', 'auth_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
-- ✅ NUEVOS TRIGGERS PARA VENTAS
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('venta_trigger', 'venta', 'venta_channel', 0, 1, 0, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('venta_item_trigger', 'venta_item', 'venta_channel', 0, 1, 0, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, sync_on_update, sync_on_insert, sync_on_delete, last_update_time, create_time) VALUES ('usuario_authority_trigger', 'usuario_authority', 'auth_channel', 1, 1, 1, now(), now()) ON CONFLICT (trigger_id) DO NOTHING;

-- #####################################################################
-- # 5. Definir los Routers: a qué grupo de nodos se envían los datos
-- #####################################################################
INSERT INTO sym_router (router_id, source_node_group_id, target_node_group_id, create_time, last_update_time) VALUES ('master_to_client', 'master_group', 'client_group', now(), now()) ON CONFLICT (router_id) DO NOTHING;
INSERT INTO sym_router (router_id, source_node_group_id, target_node_group_id, create_time, last_update_time) VALUES ('client_to_master', 'client_group', 'master_group', now(), now()) ON CONFLICT (router_id) DO NOTHING;

-- #####################################################################
-- # 6. Vincular Triggers a Routers (CONFIGURACIÓN BIDIRECCIONAL)
-- #####################################################################

-- ## Reglas: del MAESTRO (Online) hacia el CLIENTE (Offline) ##
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('producto_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('proveedor_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('tipo_producto_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('dolar_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('authority_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_authority_trigger', 'master_to_client', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;

-- ## Reglas: del CLIENTE (Offline) hacia el MAESTRO (Online) ##
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('producto_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('proveedor_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('tipo_producto_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('dolar_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('authority_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('usuario_authority_trigger', 'client_to_master', 100, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
-- ✅ SINCRONIZACIÓN UNIDIRECCIONAL DE VENTAS (Cliente -> Maestro)
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('venta_trigger', 'client_to_master', 200, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('venta_item_trigger', 'client_to_master', 200, now(), now()) ON CONFLICT (trigger_id, router_id) DO NOTHING;


-- #####################################################################
-- # 7. Parámetros Adicionales (Corrección para PostgreSQL)
-- #####################################################################
INSERT INTO sym_parameter (external_id, node_group_id, param_key, param_value, create_time, last_update_time)
VALUES ('ALL', 'master_group', 'db.quote.numbers.in.where.enabled', 'false', now(), now())
    ON CONFLICT (external_id, node_group_id, param_key) DO NOTHING;
