-- Agregar columnas con valores por defecto para registros existentes
ALTER TABLE proveedor
    ADD COLUMN created_at TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP;

-- Actualizar registros existentes con valores por defecto
UPDATE proveedor
SET created_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE created_at IS NULL;

-- Hacer las columnas NOT NULL después de poblarlas
ALTER TABLE proveedor
    ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL;

-- Opcional: Agregar índices para mejorar consultas por fecha
CREATE INDEX idx_proveedor_updated_at ON proveedor(updated_at);
CREATE INDEX idx_proveedor_created_at ON proveedor(created_at);
