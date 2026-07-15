-- El líder del equipo quiere un vistazo rápido de la cartera. ¿Cuántos clientes 
-- tiene el banco por segmento, y cuál es el ingreso declarado 
-- promedio de cada segmento?

SELECT segmento, COUNT(DISTINCT cliente_id) AS cantidad_clientes, ROUND(AVG(ingreso_declarado),2) AS ing_promedio
FROM clientes
GROUP BY segmento
ORDER BY cantidad_clientes DESC;

-- El Product Owner de préstamos personales pregunta: ¿cómo vino la colocación 
-- de préstamos en lo que va de 2026? Mostrale la cantidad de préstamos otorgados
-- y el monto total colocado por mes.

SELECT EXTRACT(MONTH FROM fecha_otorgamiento) AS mes,
       COUNT(prestamo_id) AS cantidad_prestamos, 
	   SUM(monto_otorgado) AS monto_total
FROM prestamos
WHERE fecha_otorgamiento >= '2026-01-01'
AND tipo_prestamo = 'Personal'
GROUP BY mes
ORDER BY mes ASC;


-- Riesgo está armando el comité mensual y necesita saber: ¿qué porcentaje de 
-- la cartera vigente de cada sucursal está en mora? Mostrá por sucursal el monto 
-- total otorgado en préstamos no cancelados, el monto en mora, y qué porcentaje 
-- representa la mora sobre ese total. Ordená para que se vean 
-- primero las sucursales más comprometidas.


WITH cartera_por_sucursal AS (
    SELECT 
        s.nombre_sucursal,
        SUM(p.monto_otorgado) AS monto_total,
        SUM(CASE WHEN p.estado = 'En Mora' THEN p.monto_otorgado ELSE 0 END) AS monto_mora
    FROM sucursales s
    JOIN clientes c ON c.sucursal_id = s.sucursal_id
    JOIN prestamos p ON p.cliente_id = c.cliente_id
    WHERE p.estado <> 'Cancelado'
    GROUP BY s.nombre_sucursal
)
SELECT 
    nombre_sucursal,
    monto_total,
    monto_mora,
    ROUND(monto_mora * 100.0 / monto_total, 2) AS pct_mora
FROM cartera_por_sucursal
ORDER BY pct_mora DESC;


-- El equipo comercial quiere hacer una campaña de cross-selling: buscar clientes
-- buenos sin deuda activa. Mostrá los clientes que no tienen ningún préstamo 
-- vigente ni en mora (pueden no tener préstamos, o tenerlos todos cancelados),
-- junto con su segmento y su ingreso declarado, ordenados por ingreso de 
-- mayor a menor.

SELECT 
    c.cliente_id,
    c.nombre,
    c.segmento,
    c.ingreso_declarado
FROM clientes c
WHERE c.cliente_id NOT IN (
    SELECT cliente_id 
    FROM prestamos 
    WHERE estado IN ('Vigente', 'En Mora')
)
ORDER BY c.ingreso_declarado DESC;

-- o de esta manera (left join)

SELECT 
    c.cliente_id,
    c.nombre,
    c.segmento,
    c.ingreso_declarado
FROM clientes c
LEFT JOIN prestamos p 
    ON c.cliente_id = p.cliente_id 
    AND p.estado IN ('Vigente', 'En Mora')
WHERE p.prestamo_id IS NULL
ORDER BY c.ingreso_declarado DESC;

-- La gerencia quiere reconocer a las sucursales estrella. Mostrá, para cada región,
-- la sucursal con mayor monto total otorgado en préstamos durante 2026. 
-- Devolvé la región, la sucursal, y el monto.

WITH ranking AS (
    SELECT 
        s.region, 
        s.nombre_sucursal, 
        SUM(p.monto_otorgado) AS monto_total,
        ROW_NUMBER() OVER (PARTITION BY s.region ORDER BY SUM(p.monto_otorgado) DESC) AS rn
    FROM prestamos p
    JOIN clientes c ON c.cliente_id = p.cliente_id
    JOIN sucursales s ON s.sucursal_id = c.sucursal_id
    WHERE EXTRACT(YEAR FROM p.fecha_otorgamiento) = 2026
    GROUP BY s.region, s.nombre_sucursal
)
SELECT region, nombre_sucursal, monto_total
FROM ranking
WHERE rn = 1
ORDER BY monto_total DESC;

