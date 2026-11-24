BEGIN;

-- ==================================================
-- SISTEMA DE RESERVAS DE RESTAURANTE
-- Base de datos PostgreSQL - Supabase
-- ==================================================


-- 1. Tabla de usuarios

CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rol VARCHAR(20) NOT NULL DEFAULT 'cliente',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT validar_rol
        CHECK (rol IN ('cliente', 'administrador')),

    CONSTRAINT validar_correo_minusculas
        CHECK (correo = LOWER(TRIM(correo)))
);


-- 2. Tabla de menus

CREATE TABLE menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    imagen_url TEXT,
    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT validar_precio
        CHECK (precio > 0)
);


-- 3. Tabla de mesas

CREATE TABLE mesas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero INTEGER UNIQUE NOT NULL,
    capacidad INTEGER NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT validar_numero_mesa
        CHECK (numero > 0),

    CONSTRAINT validar_capacidad
        CHECK (capacidad > 0)
);


-- 4. Tabla de reservas

CREATE TABLE reservas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL,
    mesa_id UUID NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    numero_personas INTEGER NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'confirmada',
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_reserva_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reserva_mesa
        FOREIGN KEY (mesa_id)
        REFERENCES mesas(id)
        ON DELETE RESTRICT,

    CONSTRAINT validar_numero_personas
        CHECK (numero_personas > 0),

    CONSTRAINT validar_estado_reserva
        CHECK (estado IN (
            'confirmada',
            'cancelada',
            'finalizada'
        )),

    CONSTRAINT validar_horario
        CHECK (
            hora_fin > hora_inicio
            AND hora_fin - hora_inicio = INTERVAL '1 hour'
            AND EXTRACT(MINUTE FROM hora_inicio) = 0
            AND EXTRACT(SECOND FROM hora_inicio) = 0
        )
);


-- 5. Tabla de notificaciones

CREATE TABLE notificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reserva_id UUID NOT NULL,
    mensaje TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_envio TIMESTAMPTZ,

    CONSTRAINT fk_notificacion_reserva
        FOREIGN KEY (reserva_id)
        REFERENCES reservas(id)
        ON DELETE RESTRICT,

    CONSTRAINT validar_estado_notificacion
        CHECK (estado IN (
            'pendiente',
            'enviada',
            'fallida'
        ))
);


-- ==================================================
-- PREVENCION DE RESERVAS DUPLICADAS
-- ==================================================

CREATE UNIQUE INDEX idx_reserva_unica
ON reservas (mesa_id, fecha, hora_inicio)
WHERE estado = 'confirmada';


-- ==================================================
-- INDICES PARA OPTIMIZAR CONSULTAS
-- ==================================================

CREATE INDEX idx_reservas_usuario
ON reservas (usuario_id);

CREATE INDEX idx_reservas_disponibilidad
ON reservas (fecha, hora_inicio, estado);

CREATE INDEX idx_reservas_mesa
ON reservas (mesa_id);

CREATE INDEX idx_menus_disponibles
ON menus (disponible);

CREATE INDEX idx_notificaciones_reserva
ON notificaciones (reserva_id);


-- ==================================================
-- SEGURIDAD RLS
-- ==================================================

ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE mesas ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;


-- Bloquear el acceso directo desde clientes publicos

REVOKE ALL ON TABLE
    usuarios,
    menus,
    mesas,
    reservas,
    notificaciones
FROM PUBLIC, anon, authenticated;


-- Permitir acceso al backend autorizado

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
    usuarios,
    menus,
    mesas,
    reservas,
    notificaciones
TO service_role;

COMMIT;