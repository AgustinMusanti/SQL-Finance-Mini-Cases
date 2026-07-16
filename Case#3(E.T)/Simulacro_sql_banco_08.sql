-- Producto quiere entender la mezcla de saldos. Mostrá, por tipo de cuenta y moneda,
-- cuántas cuentas hay y el saldo promedio. Ordená por saldo promedio descendente.

SELECT tipo_cuenta, moneda, COUNT(cuenta_id) AS cant_cuentas,
       ROUND(AVG(saldo_actual),2) AS saldo_promedio
FROM cuentas
GROUP BY 1,2
ORDER BY 2 DESC;

-- Marketing quiere saber la tasa de respuesta de cada tipo de campaña. Para cada 
-- tipo de campaña, mostrá cuántos clientes se contactaron, cuántos respondieron,
-- y qué porcentaje representan los que respondieron. Ordená por tasa de respuesta 
-- descendente.

WITH consulta1 AS(
SELECT ca.tipo, COUNT(cc.cliente_id) AS clientes_contactados,
       COUNT(CASE WHEN cc.respondio = TRUE THEN 1 END) AS clientes_que_respondieron
FROM campanias ca
JOIN clientes_campanias cc
ON ca.campania_id=cc.campania_id
GROUP BY ca.tipo)
SELECT tipo,
       clientes_contactados,
	   clientes_que_respondieron,
       ROUND(clientes_que_respondieron * 100.0 / clientes_contactados, 2) AS pct_respuesta
FROM consulta1
ORDER BY pct_respuesta DESC;

-- El equipo de fidelización quiere premiar a los clientes más activos con tarjeta. 
-- Mostrá los clientes que hicieron 3 o más movimientos de tipo 'Compra' en total, 
-- con la cantidad de compras que hicieron. Ordená de más a menos compras.

SELECT c.cliente_id, c.nombre, COUNT(m.movimiento_id) AS cant_compras
FROM clientes c
JOIN tarjetas t
ON c.cliente_id = t.cliente_id
JOIN movimientos m
ON t.tarjeta_id=m.tarjeta_id
WHERE m.tipo = 'Compra'
GROUP BY c.cliente_id, c.nombre
HAVING COUNT(m.movimiento_id) >= 3
ORDER BY cant_compras DESC;

-- (window function) Riesgo quiere ver, dentro de cada provincia, cuáles son los 
-- clientes con mayor saldo total en sus cuentas. Mostrá, para cada provincia, 
-- el top 2 de clientes por saldo total acumulado (sumando todas sus cuentas). 
-- Devolvé provincia, nombre del cliente, su saldo total, y la posición dentro 
-- de la provincia.

WITH consulta1 AS (
    SELECT 
        c.provincia,
        c.nombre,
        SUM(ca.saldo_actual) AS saldo_acumulado,
        ROW_NUMBER() OVER (
            PARTITION BY c.provincia 
            ORDER BY SUM(ca.saldo_actual) DESC
        ) AS rn
    FROM clientes c
    JOIN cuentas ca ON c.cliente_id = ca.cliente_id
    GROUP BY c.provincia, c.nombre
)
SELECT provincia, nombre, saldo_acumulado, rn
FROM consulta1
WHERE rn <= 2
ORDER BY provincia, rn;


-- Comercial quiere una lista de clientes de alto valor sin tarjeta de crédito, 
-- para ofrecerles una. Mostrá los clientes cuyo saldo total en cuentas supere 
-- los 3 millones y que no tengan ninguna tarjeta de crédito. Mostrá nombre y 
-- saldo total.

SELECT 
    c.cliente_id, 
    c.nombre, 
    SUM(ca.saldo_actual) AS saldo_total
FROM clientes c
JOIN cuentas ca ON c.cliente_id = ca.cliente_id
LEFT JOIN tarjetas t 
    ON c.cliente_id = t.cliente_id 
    AND t.tipo = 'Crédito'
WHERE t.tarjeta_id IS NULL
GROUP BY c.cliente_id, c.nombre
HAVING SUM(ca.saldo_actual) > 3000000
ORDER BY saldo_total DESC;
