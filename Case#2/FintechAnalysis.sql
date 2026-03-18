--  Mini Caso #2 FINTECH / BILLETERA DIGITAL  |  Dataset ficticio
--  ~10.000 transacciones | ~750 usuarios | Año 2025

USE master;
GO

-- Crear la base de datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FintechDB')
    CREATE DATABASE FintechDB;
GO

USE FintechDB;
GO

--  LIMPIEZA
IF OBJECT_ID('transacciones', 'U') IS NOT NULL DROP TABLE transacciones;
IF OBJECT_ID('usuarios',      'U') IS NOT NULL DROP TABLE usuarios;
GO

--  TABLA: usuarios
CREATE TABLE usuarios (
    usuario_id      INT         NOT NULL PRIMARY KEY,
    edad            INT         NOT NULL,
    ciudad          NVARCHAR(50) NOT NULL,
    fecha_registro  DATE        NOT NULL
);
GO

--  TABLA: transacciones
CREATE TABLE transacciones (
    transaccion_id  INT         NOT NULL PRIMARY KEY,
    usuario_id      INT         NOT NULL REFERENCES usuarios(usuario_id),
    monto           INT         NOT NULL,
    tipo_operacion  NVARCHAR(20) NOT NULL,
    fecha           DATE        NOT NULL
);
GO

--  GENERACIÓN DE DATOS FICTICIOS
/* Se usa una CTE recursiva + funciones de hash para obtener
   valores pseudo-aleatorios sin depender de RAND() */

--  USUARIOS  (750 registros)
;WITH nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 750
)
INSERT INTO usuarios (usuario_id, edad, ciudad, fecha_registro)
SELECT
    n AS usuario_id,

    -- edad entre 18 y 65
    18 + ABS(CHECKSUM(NEWID(), n)) % 48  AS edad,

    -- ciudad (6 opciones)
    CASE ABS(CHECKSUM(NEWID(), n, 1)) % 6
        WHEN 0 THEN 'Buenos Aires'
        WHEN 1 THEN 'Córdoba'
        WHEN 2 THEN 'Rosario'
        WHEN 3 THEN 'Mendoza'
        WHEN 4 THEN 'La Plata'
        ELSE        'Mar del Plata'
    END AS ciudad,

    -- fecha_registro: entre 2024-01-01 y 2024-12-31 (registrados antes de las transacciones)
    DATEADD(DAY, ABS(CHECKSUM(NEWID(), n, 2)) % 365, '2024-01-01') AS fecha_registro

FROM nums
OPTION (MAXRECURSION 1000);
GO

--  TRANSACCIONES  (10 000 registros)
;WITH nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 10000
)
INSERT INTO transacciones (transaccion_id, usuario_id, monto, tipo_operacion, fecha)
SELECT
    n AS transaccion_id,

    -- usuario_id: entre 1 y 750
    1 + ABS(CHECKSUM(NEWID(), n)) % 750 AS usuario_id,

    -- monto: entre 500 y 50000
    500 + ABS(CHECKSUM(NEWID(), n, 1)) % 49501 AS monto,

    -- tipo_operacion (4 opciones con distribución aproximada 40/25/20/15)
    CASE ABS(CHECKSUM(NEWID(), n, 2)) % 20
        WHEN 0  THEN 'transferencia'
        WHEN 1  THEN 'transferencia'
        WHEN 2  THEN 'transferencia'
        WHEN 3  THEN 'transferencia'
        WHEN 4  THEN 'transferencia'
        WHEN 5  THEN 'retiro'
        WHEN 6  THEN 'retiro'
        WHEN 7  THEN 'retiro'
        WHEN 8  THEN 'retiro'
        WHEN 9  THEN 'deposito'
        WHEN 10 THEN 'deposito'
        WHEN 11 THEN 'deposito'
        WHEN 12 THEN 'deposito'
        WHEN 13 THEN 'deposito'
        ELSE         'pago'          -- 7/20 = 35 %  +  los restantes ELSE ~ 40 %
    END AS tipo_operacion,

    -- fecha: entre 2025-01-01 y 2025-12-31
    DATEADD(DAY, ABS(CHECKSUM(NEWID(), n, 3)) % 365, '2025-01-01') AS fecha

FROM nums
OPTION (MAXRECURSION 11000);
GO

--  VERIFICACIÓN RÁPIDA
SELECT 'usuarios'      AS tabla, COUNT(*) AS registros FROM usuarios
UNION ALL
SELECT 'transacciones' AS tabla, COUNT(*) AS registros FROM transacciones;
GO

-- ============================================================
--  CONSULTAS DE ANÁLISIS
-- ============================================================

-- ------------------------------------------------------------
--  1. Usuarios más activos
-- ------------------------------------------------------------
SELECT
    usuario_id,
    COUNT(*) AS total_transacciones
FROM transacciones
GROUP BY usuario_id
ORDER BY total_transacciones DESC;
GO

-- ------------------------------------------------------------
--  2. Ticket promedio por tipo de operación
-- ------------------------------------------------------------
SELECT
    tipo_operacion,
    AVG(monto) AS ticket_promedio
FROM transacciones
GROUP BY tipo_operacion;
GO

-- ------------------------------------------------------------
--  3. Segmentación de usuarios según actividad
-- ------------------------------------------------------------
DECLARE @fecha_corte DATE = '2025-12-31';

SELECT
    u.usuario_id,
    COUNT(t.transaccion_id) AS cantidad_transacciones_90d,
    CASE
        WHEN COUNT(t.transaccion_id) >= 20 THEN 'Actividad alta'
        WHEN COUNT(t.transaccion_id) >= 10 THEN 'Actividad media'
        WHEN COUNT(t.transaccion_id) > 0  THEN 'Actividad baja'
        ELSE                                   'Sin actividad reciente'
    END AS segmento_usuario
FROM usuarios u
LEFT JOIN transacciones t
    ON u.usuario_id = t.usuario_id
    AND t.fecha >= DATEADD(DAY, -90, @fecha_corte)
GROUP BY u.usuario_id;
GO

-- ------------------------------------------------------------
--  4. Volumen mensual de pagos
-- ------------------------------------------------------------
SELECT
    YEAR(fecha)  AS anio,
    MONTH(fecha) AS mes,
    SUM(monto)   AS volumen_pagos
FROM transacciones
WHERE tipo_operacion = 'pago'
GROUP BY YEAR(fecha), MONTH(fecha)
ORDER BY anio, mes;
GO

-- ------------------------------------------------------------
--  5. Usuarios con mayor volumen transaccionado
-- ------------------------------------------------------------
SELECT
    usuario_id,
    SUM(monto) AS volumen_total
FROM transacciones
GROUP BY usuario_id
ORDER BY volumen_total DESC;
GO

-- ------------------------------------------------------------
--  6. Usuarios que dejaron de usar la app
--     (sin transacciones en los últimos 30 días)
-- ------------------------------------------------------------
SELECT
    usuario_id,
    MAX(fecha) AS ultima_transaccion
FROM transacciones
GROUP BY usuario_id
HAVING MAX(fecha) < DATEADD(DAY, -30, GETDATE());
GO
