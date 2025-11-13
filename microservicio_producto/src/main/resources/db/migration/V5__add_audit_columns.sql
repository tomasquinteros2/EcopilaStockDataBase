-- Agregar columnas con valores por defecto para registros existentes
ALTER TABLE producto
    ADD COLUMN created_at TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP;

-- Inicializar con fecha_ingreso o fecha actual para registros existentes
UPDATE producto
SET created_at = COALESCE(fecha_ingreso::timestamp, CURRENT_TIMESTAMP),
    updated_at = COALESCE(fecha_ingreso::timestamp, CURRENT_TIMESTAMP)
WHERE created_at IS NULL;

-- Hacer las columnas NOT NULL después de inicializarlas
ALTER TABLE producto
    ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL;
