-- El equipo de canales quiere entender por dónde entra la gente. Mostrá cuántos 
-- clientes se captaron por cada canal, y qué edad promedio tiene cada grupo. 
-- Ordená del canal que más capta al que menos

SELECT canal_captacion, 
       COUNT(cliente_id) AS cantidad_clientes,
	   ROUND(AVG(edad),2) AS edad_promedio
FROM clientes
GROUP BY 1
ORDER BY 2 DESC;

-- Marketing quiere medir efectividad de campañas. Para cada campaña, mostrá 
-- cuántos clientes fueron contactados y cuántos respondieron. Incluí también 
-- las campañas que no contactaron a nadie todavía

SELECT 
    ca.nombre_campania,
    COUNT(cc.cliente_id) AS clientes_contactados,
    COUNT(CASE WHEN cc.respondio THEN 1 END) AS clientes_que_respondieron
FROM campanias ca
LEFT JOIN clientes_campanias cc ON ca.campania_id = cc.campania_id
GROUP BY ca.nombre_campania
ORDER BY clientes_contactados DESC;


-- Finanzas quiere ver el volumen transaccional de junio 2026. Mostrá el monto 
-- total operado por tipo de movimiento, pero solo los tipos que hayan superado 
-- el millón de pesos en total. Ordená de mayor a menor.

SELECT tipo,
       SUM(monto) AS monto_total_operado
FROM movimientos
WHERE EXTRACT(YEAR FROM fecha) = 2026
AND EXTRACT(MONTH FROM fecha) = 6
GROUP BY tipo
HAVING SUM(monto) > 1000000
ORDER BY monto_total_operado DESC;

-- El equipo de riesgo de tarjetas quiere revisar la cartera de crédito. Para cada 
-- cliente que tenga al menos una tarjeta de crédito, mostrá su nombre y la suma 
-- de los límites de crédito que tiene asignados. 
-- Ordená de mayor límite total a menor

SELECT c.cliente_id, c.nombre, SUM(t.limite) AS limite_asignado
FROM clientes c
JOIN tarjetas t
ON c.cliente_id=t.cliente_id
WHERE tipo = 'Crédito'
GROUP BY c.cliente_id, c.nombre
ORDER BY 3 DESC;


-- Comercial quiere detectar clientes para una campaña de activación: clientes que
-- tienen cuenta abierta pero no registraron ningún movimiento en junio 2026. 
-- Mostrá su nombre y provincia.

SELECT DISTINCT c.cliente_id, c.nombre, c.provincia
FROM clientes c
JOIN cuentas ca ON c.cliente_id = ca.cliente_id
LEFT JOIN movimientos m 
    ON ca.cuenta_id = m.cuenta_id
    AND EXTRACT(YEAR FROM m.fecha) = 2026 
    AND EXTRACT(MONTH FROM m.fecha) = 6
WHERE m.movimiento_id IS NULL;

-- Este es un combo que aparece seguido (clientes inactivos, 
-- cuentas dormidas, productos sin ventas en el mes). La receta:

FROM base b
JOIN intermedia i ON ...
LEFT JOIN evento e 
    ON i.id = e.id 
    AND e.fecha [en el período]      -- ← filtro temporal ACÁ
WHERE e.pk IS NULL                    -- ← los que no tuvieron el evento

-- Filtro del evento en el ON, ausencia con IS NULL en el WHERE.
-- Guardátelo, porque "detectar inactivos para reactivar" es una
-- pregunta clásica de banca comercial.


