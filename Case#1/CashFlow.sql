-- MINI CASO #1: Ingresos vs Egresos + Caja Acumulada
-- Con 1 tabla: cashflow diario + saldo acumulado en SQL Server

-- 1. CREACIÓN DE TABLA

CREATE TABLE movimientos (
    id        INT IDENTITY(1,1) PRIMARY KEY,
    fecha     DATE          NOT NULL,
    tipo      VARCHAR(10)   NOT NULL CHECK (tipo IN ('INGRESO', 'EGRESO')),
    categoria VARCHAR(50)   NOT NULL,
    monto     INT           NOT NULL  -- sin decimales
);


-- 2. DATOS

INSERT INTO movimientos (fecha, tipo, categoria, monto) VALUES
('2025-01-02', 'INGRESO', 'Cobranza clientes',      1250000),
('2025-01-02', 'EGRESO',  'Sueldos',                 980000),
('2025-01-06', 'INGRESO', 'Venta contado',            430000),
('2025-01-07', 'EGRESO',  'Proveedores',              310000),
('2025-01-10', 'INGRESO', 'Cobranza clientes',        870000),
('2025-01-12', 'EGRESO',  'Alquiler',                 220000),
('2025-01-15', 'INGRESO', 'Venta contado',            560000),
('2025-01-18', 'EGRESO',  'Servicios',                 85000),
('2025-01-20', 'INGRESO', 'Cobranza clientes',        340000),
('2025-01-22', 'EGRESO',  'Gastos administrativos',   120000),
('2025-01-25', 'INGRESO', 'Anticipo proyecto',       1800000),
('2025-01-28', 'EGRESO',  'Impuestos',                450000),
('2025-01-30', 'INGRESO', 'Venta contado',            290000),
('2025-02-03', 'INGRESO', 'Cobranza clientes',       1100000),
('2025-02-03', 'EGRESO',  'Sueldos',                  980000),
('2025-02-06', 'EGRESO',  'Proveedores',              275000),
('2025-02-10', 'INGRESO', 'Venta contado',            510000),
('2025-02-12', 'EGRESO',  'Alquiler',                 220000),
('2025-02-14', 'INGRESO', 'Cobranza clientes',        720000),
('2025-02-18', 'EGRESO',  'Servicios',                 90000),
('2025-02-21', 'EGRESO',  'Mantenimiento',            175000),
('2025-02-24', 'INGRESO', 'Cobranza clientes',        630000),
('2025-02-28', 'INGRESO', 'Venta contado',            210000),
('2025-03-03', 'EGRESO',  'Sueldos',                  980000),
('2025-03-03', 'INGRESO', 'Cobranza clientes',        950000),
('2025-03-05', 'INGRESO', 'Anticipo proyecto',       2200000),
('2025-03-07', 'EGRESO',  'Proveedores',              420000),
('2025-03-12', 'EGRESO',  'Alquiler',                 220000),
('2025-03-14', 'INGRESO', 'Cobranza clientes',        810000),
('2025-03-17', 'EGRESO',  'Impuestos',                510000),
('2025-03-21', 'EGRESO',  'Servicios',                 95000),
('2025-03-26', 'INGRESO', 'Cobranza clientes',        670000),
('2025-03-31', 'INGRESO', 'Venta contado',            410000);


-- 3. QUERY PRINCIPAL: cashflow diario + saldo acumulado

;WITH cashflow_diario AS (

    -- Agrupo por fecha: total ingresado, total egresado y flujo neto del día
    SELECT
        fecha,
        SUM(CASE WHEN tipo = 'INGRESO' THEN monto ELSE 0 END) AS ingresos,
        SUM(CASE WHEN tipo = 'EGRESO'  THEN monto ELSE 0 END) AS egresos,
        SUM(CASE WHEN tipo = 'INGRESO' THEN monto ELSE -monto END) AS flujo_neto
    FROM movimientos
    GROUP BY fecha

)
SELECT
    fecha,
    FORMAT(ingresos,   'N0', 'es-AR') AS ingresos,
    FORMAT(egresos,    'N0', 'es-AR') AS egresos,
    FORMAT(flujo_neto, 'N0', 'es-AR') AS flujo_neto,
    /* SUM() OVER: acumula el flujo neto desde la primera hasta la fila actual.
       Equivale a un "saldo de caja" que crece o decrece cada día. */
    FORMAT(
        SUM(flujo_neto) OVER (ORDER BY fecha ROWS UNBOUNDED PRECEDING),
        'N0', 'es-AR'
    ) AS caja_acumulada

FROM cashflow_diario
ORDER BY fecha;
