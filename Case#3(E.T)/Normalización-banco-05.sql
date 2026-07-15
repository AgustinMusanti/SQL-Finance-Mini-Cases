-- Normalizás al vuelo: mayúsculas + sacar espacios
SELECT
    UPPER(TRIM(segmento)) AS segmento_limpio, 
    COUNT(*)
FROM clientes
GROUP BY UPPER(TRIM(segmento));

/* TRIM() → saca espacios al principio y al final.
   UPPER() / LOWER() → unifica mayúsculas. */

-- NULLS

WHERE fecha_pago IS NULL        -- cuota impaga
WHERE fecha_pago IS NOT NULL    -- cuota pagada
  
Nunca = NULL. NULL no es igual a nada, ni a sí mismo. Siempre IS NULL.

-- Reemplazar por un valor (para que no te rompa una suma o un promedio):
  
COALESCE(monto_pagado, 0)       -- si es NULL, usá 0
  
COALESCE devuelve el primer valor no-nulo. Clave cuando sumás una columna que tiene huecos: 
SUM(monto_pagado) ya ignora nulos, pero en restas y ratios te conviene forzar el 0.
  
-- Nulos disfrazados (texto que parece nulo pero no lo es):
-- '', 'N/A', 'NULL' como string
  
NULLIF(TRIM(segmento), '')      -- convierte '' en NULL real
CASE WHEN segmento IN ('N/A','NULL','') THEN NULL ELSE segmento END

-- Si la fecha entró como string, no podés compararla ni extraer partes hasta castearla:
  
CAST(fecha_pago AS DATE)
-- o la sintaxis corta de Postgres:
  
fecha_pago::DATE
  
Si viene en formato raro ('01/07/2025', dd/mm/yyyy), en Postgres:
  
TO_DATE(fecha_pago, 'DD/MM/YYYY')

-- Números sucios
-- Datos argentinos: "1.500.000,50" (punto de miles, coma decimal) no es un número para SQL.
-- Postgres: saco puntos, cambio coma por punto, casteo
  
CAST(REPLACE(REPLACE(monto, '.', ''), ',', '.') AS DECIMAL)

REPLACE(texto, buscar, reemplazar) → dos pasadas: primero saco los puntos, después convierto la coma decimal en punto.

-- Duplicados
-- Detectar filas repetidas:
  
SELECT cliente_id, COUNT(*)
FROM clientes
GROUP BY cliente_id
HAVING COUNT(*) > 1;      -- los que aparecen más de una vez

-- Antes de responder cualquier pregunta de negocio, tirá 2-3 queries de reconocimiento:
  
SELECT DISTINCT segmento FROM clientes;              -- categorías sucias
SELECT COUNT(*) FROM pagos WHERE fecha_pago IS NULL; -- volumen de nulos
SELECT cliente_id, COUNT(*) FROM clientes 
GROUP BY cliente_id HAVING COUNT(*) > 1;             -- duplicados

