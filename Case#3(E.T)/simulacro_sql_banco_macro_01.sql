-- ============================================================================
-- SIMULACRO TÉCNICO SQL #1 — Preparación entrevista Banco Macro
-- Banco ficticio: "Banco Río Paraná"
-- Fecha de referencia (hoy): 2026-07-01
-- ============================================================================
--
-- CONTEXTO:
-- 30-40 minutos, 5 preguntas de negocio sobre 3 datasets.
-- La técnica evalúa 3 cosas al mismo nivel:
--   1) Interpretación de la pregunta antes de escribir código
--   2) Razonamiento en voz alta mientras tipeás
--   3) Comunicación del resultado en términos de negocio
--
-- ============================================================================


-- ============================================================================
-- ESQUEMA DE DATOS
-- ============================================================================

/*
TABLA: clientes
---------------
cliente_id    INT           PK
nombre        VARCHAR       Nombre del cliente
fecha_alta    DATE          Fecha en que se hizo cliente
segmento      VARCHAR       'Individuo', 'PyME', 'Corporativo'
provincia     VARCHAR       Provincia de residencia
edad          INT           Edad del cliente (NULL para PyME/Corporativo)


TABLA: productos
----------------
producto_id       INT           PK
nombre_producto   VARCHAR       'Caja de Ahorro', 'Cuenta Corriente',
                                'Tarjeta Crédito', 'Préstamo Personal',
                                'Plazo Fijo', 'Fondo Común'
categoria         VARCHAR       'Transaccional', 'Crédito', 'Inversión'
comision_mensual  DECIMAL       Comisión que paga el cliente por tenerlo activo


TABLA: transacciones
--------------------
transaccion_id  INT           PK
cliente_id      INT           FK a clientes
producto_id     INT           FK a productos
fecha           DATE          Fecha de la transacción
monto           DECIMAL       Positivo = ingreso al banco / consumo
                              Negativo = egreso
canal           VARCHAR       'App', 'Web', 'Sucursal', 'Cajero'
*/


-- ============================================================================
-- PATRONES MENTALES CLAVE (repasar antes de la técnica real)
-- ============================================================================

/*
ORDEN LÓGICO DE EJECUCIÓN DE SQL (memorizar):
  1. FROM       → de qué tablas saco datos
  2. JOIN       → cómo las combino
  3. WHERE      → qué filas descarto antes de agrupar
  4. GROUP BY   → cómo agrupo
  5. HAVING     → qué grupos descarto después de agrupar
  6. SELECT     → qué muestro
  7. ORDER BY   → cómo ordeno
  8. LIMIT      → cuántas filas devuelvo

WHERE vs HAVING:
  - WHERE  = filtra filas ANTES de agrupar (columnas crudas)
  - HAVING = filtra grupos DESPUÉS de agregar (funciones de agregación)

FECHAS (opción más segura):
  - Columna DATE:     WHERE fecha BETWEEN '2026-01-01' AND '2026-06-30'
  - Columna DATETIME: WHERE fecha >= '2026-01-01' AND fecha < '2026-07-01'
  - Si dudás del tipo, preguntá al entrevistador. Es actitud senior.

REGLA DE ORO en GROUP BY:
  - Toda columna en SELECT que NO esté en una función de agregación
    (SUM, COUNT, AVG, MIN, MAX) TIENE que estar en el GROUP BY.

CHECKLIST ANTES DE DAR UNA QUERY POR TERMINADA:
  ✓ ¿Puse el filtro temporal si la pregunta lo pide?
  ✓ ¿Puse la columna de agrupación en el SELECT?
  ✓ ¿Necesito DISTINCT? (típico en "clientes únicos", "productos únicos")
  ✓ ¿El ORDER BY refleja lo que pidieron?
  ✓ ¿Los alias están sin comillas simples? (usar sin comillas o dobles)

TIPS DE COMUNICACIÓN (tanto o más importantes que el código):
  1. Antes de escribir: repetí en voz alta cómo interpretaste la pregunta.
  2. Mientras tipeás: narrá qué estás haciendo ("primero uno estas tablas por
     cliente_id, después filtro por fecha, después agrupo...").
  3. Al terminar: interpretá el resultado en términos de negocio, no solo
     "acá está el output".
  4. Si no sabés una sintaxis puntual: decilo. "El concepto lo tengo claro,
     no me acuerdo la función exacta en este dialecto." Eso es actitud senior.
*/


-- ============================================================================
-- PREGUNTA 1 — Warm-up
-- ============================================================================
-- ENUNCIADO:
-- ¿Cuántos clientes hay en total, discriminados por segmento?
-- Ordená del segmento con más clientes al que menos.

-- INTERPRETACIÓN:
-- Cuento clientes agrupados por segmento y ordeno el count descendente.
-- No hay filtros, no hay JOINs. Es solo GROUP BY + ORDER BY.

SELECT
    segmento,
    COUNT(*) AS cantidad_clientes
FROM clientes
GROUP BY segmento
ORDER BY cantidad_clientes DESC;

/*
ERRORES CLÁSICOS QUE COMETÍ ACÁ:
  - Olvidar poner `segmento` en el SELECT → resultado ilegible.
  - Alias entre comillas simples ('CantidadClientes') → no es un alias,
    es un string literal. Usar sin comillas o con comillas dobles.

APRENDIZAJE:
  - Regla: la columna del GROUP BY casi siempre va también en el SELECT.
  - COUNT(*) vs COUNT(columna): dan lo mismo si la columna es PK y no
    admite NULL. Distinto si la columna puede tener nulos.
*/


-- ============================================================================
-- PREGUNTA 2 — Filtros y agregación
-- ============================================================================
-- ENUNCIADO:
-- Para el primer semestre de 2026 (enero a junio inclusive), mostrame el
-- monto total transaccionado (suma en valor absoluto) por canal.
-- Digital quiere saber qué canales están traccionando más volumen.

-- INTERPRETACIÓN:
-- Filtro transacciones al primer semestre 2026, agrupo por canal,
-- sumo el valor absoluto del monto (porque negativos son egresos y
-- también cuentan como volumen).

SELECT
    canal,
    SUM(ABS(monto)) AS monto_total
FROM transacciones
WHERE fecha BETWEEN '2026-01-01' AND '2026-06-30'
GROUP BY canal
ORDER BY monto_total DESC;

/*
ERRORES CLÁSICOS QUE COMETÍ ACÁ:
  - Olvidar el WHERE de fecha (BUG #1 recurrente).
  - Poner `fecha` en el SELECT sin necesitarla (rompe GROUP BY además).
  - Sumar `monto` a secas: los negativos cancelan positivos y da neto,
    no volumen.

APRENDIZAJE:
  - Cuando la pregunta habla de "volumen" o "transaccionado" → ABS(monto).
  - Cuando habla de "balance" o "neto" → sin ABS.
  - El filtro temporal es LO PRIMERO que pienso, no lo último.
  - SELECT y WHERE son independientes: puedo filtrar por una columna
    sin mostrarla.
*/


-- ============================================================================
-- PREGUNTA 3 — Join múltiple + conteo único
-- ============================================================================
-- ENUNCIADO:
-- Para cada combinación de segmento y categoría de producto, mostrame la
-- cantidad de clientes únicos que tuvieron al menos una transacción en 2026.
-- Ordená por segmento y dentro de cada segmento por cantidad descendente.

-- INTERPRETACIÓN:
-- Necesito las 3 tablas (transacciones es el puente entre clientes y productos).
-- Agrupo por (segmento, categoría) y cuento clientes ÚNICOS.
-- "Al menos una transacción" ya lo garantiza el INNER JOIN, no necesito HAVING.

SELECT
    c.segmento,
    p.categoria,
    COUNT(DISTINCT c.cliente_id) AS cantidad_clientes
FROM clientes c
JOIN transacciones t ON c.cliente_id = t.cliente_id
JOIN productos p ON p.producto_id = t.producto_id
WHERE t.fecha BETWEEN '2026-01-01' AND '2026-12-31'
GROUP BY c.segmento, p.categoria
ORDER BY c.segmento, cantidad_clientes DESC;

/*
ERRORES CLÁSICOS QUE COMETÍ ACÁ:
  - Olvidar DISTINCT en COUNT: cuento filas (transacciones), no clientes.
    Si un cliente hizo 30 transacciones lo contaba 30 veces.
  - Sintaxis: c.COUNT(cliente_id) NO existe. Es COUNT(c.cliente_id).
    El alias de tabla va DENTRO del COUNT, no delante.
  - HAVING innecesario: "al menos una transacción" lo da el INNER JOIN solo.
  - Dos ORDER BY: se pone UNO SOLO con columnas separadas por coma.

APRENDIZAJE:
  - "Clientes únicos", "productos únicos", "sucursales únicas" → DISTINCT
    en el COUNT. Reflejo automático.
  - Los JOINs los tengo bien: transacciones es el puente y las claves son
    cliente_id y producto_id. Ya no lo tengo que ensayar.
*/


-- ============================================================================
-- PREGUNTA 4 — Subquery / CTE + comparación con agregado global
-- ============================================================================
-- ENUNCIADO:
-- Clientes "premium potenciales": clientes Individuo cuyo monto total
-- transaccionado en el primer semestre 2026 supere el DOBLE del promedio
-- de monto total transaccionado por cliente Individuo en ese mismo período.
-- Devolver cliente_id, nombre, monto_total. Ordenar por monto_total DESC.

-- INTERPRETACIÓN:
-- Es el patrón clásico "X supera al promedio de X":
--   1) Calculo el total por cliente Individuo.
--   2) Calculo el umbral (promedio de esos totales × 2).
--   3) Filtro los que superan el umbral.
-- CUIDADO: el promedio es POR CLIENTE, no por transacción. Primero agrego
--   por cliente y DESPUÉS promedio esos agregados.


-- Versión recomendada: CTE + subquery escalar (la más legible)
WITH totales_individuo AS (
    SELECT
        c.cliente_id,
        c.nombre,
        SUM(ABS(t.monto)) AS monto_total
    FROM clientes c
    JOIN transacciones t ON c.cliente_id = t.cliente_id
    WHERE c.segmento = 'Individuo'
      AND t.fecha BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY c.cliente_id, c.nombre
)
SELECT
    cliente_id,
    nombre,
    monto_total
FROM totales_individuo
WHERE monto_total > (SELECT AVG(monto_total) * 2 FROM totales_individuo)
ORDER BY monto_total DESC;


-- Versión alternativa: subquery pura (sin CTE)
-- Menos legible, más verbosa, pero funciona igual.
SELECT
    c.cliente_id,
    c.nombre,
    SUM(ABS(t.monto)) AS monto_total
FROM clientes c
JOIN transacciones t ON c.cliente_id = t.cliente_id
WHERE c.segmento = 'Individuo'
  AND t.fecha BETWEEN '2026-01-01' AND '2026-06-30'
GROUP BY c.cliente_id, c.nombre
HAVING SUM(ABS(t.monto)) > (
    SELECT AVG(monto_total_cliente) * 2
    FROM (
        SELECT SUM(ABS(t2.monto)) AS monto_total_cliente
        FROM clientes c2
        JOIN transacciones t2 ON c2.cliente_id = t2.cliente_id
        WHERE c2.segmento = 'Individuo'
          AND t2.fecha BETWEEN '2026-01-01' AND '2026-06-30'
        GROUP BY c2.cliente_id
    ) AS totales_por_cliente
)
ORDER BY monto_total DESC;

/*
CONCEPTOS CLAVE DE ESTA PREGUNTA:
  - No se puede filtrar una agregación en el WHERE → va en HAVING
    (o en el WHERE de la query externa después de una CTE).
  - Promedio "por cliente" vs promedio "de transacciones" son DISTINTOS.
    Cuando el promedio es por cliente, primero agrego por cliente,
    después promedio esos agregados.
  - Cuando repito la misma lógica dos veces → CTE. Más limpio y evita bugs.

PATRÓN MENTAL "X SUPERA AL AGREGADO DE X" (memorizar):
  1. CTE con la métrica por entidad (SUM/COUNT/AVG por cliente/producto/etc.)
  2. Subquery escalar con el umbral (AVG, MEDIAN, MAX, etc. sobre la CTE).
  3. Filtrar la CTE por el umbral.

  Aparece en: "clientes que compran más que el promedio", "productos
  con rentabilidad sobre la media", "sucursales sobre la mediana", etc.
*/


-- ============================================================================
-- PREGUNTA 5 — Window function / Top N por grupo
-- ============================================================================
-- ENUNCIADO:
-- Para el primer semestre 2026, mostrar el TOP 3 de productos por monto
-- total transaccionado dentro de cada categoría de producto.
-- Devolver: categoria, nombre_producto, monto_total, ranking (1,2,3).
-- Desempate: nombre de producto alfabéticamente.

-- INTERPRETACIÓN:
-- Es un "top N por grupo", patrón universal:
--   1) Calculo el monto total por producto (JOIN + GROUP BY).
--   2) Aplico ROW_NUMBER() particionando por categoría, ordenando
--      por monto DESC y desempatando por nombre ASC.
--   3) Filtro ranking <= 3.
-- CUIDADO: no se puede filtrar la window function en el WHERE de la misma
--   query donde se calcula. Hay que envolver en CTE.


-- Versión recomendada: dos CTEs (razonamiento explícito, más legible)
WITH montos_por_producto AS (
    SELECT
        p.categoria,
        p.nombre_producto,
        SUM(ABS(t.monto)) AS monto_total
    FROM productos p
    JOIN transacciones t ON p.producto_id = t.producto_id
    WHERE t.fecha BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY p.categoria, p.nombre_producto
),
ranking_por_categoria AS (
    SELECT
        categoria,
        nombre_producto,
        monto_total,
        ROW_NUMBER() OVER (
            PARTITION BY categoria
            ORDER BY monto_total DESC, nombre_producto ASC
        ) AS ranking
    FROM montos_por_producto
)
SELECT
    categoria,
    nombre_producto,
    monto_total,
    ranking
FROM ranking_por_categoria
WHERE ranking <= 3
ORDER BY categoria, ranking;


-- Versión alternativa: una sola CTE (más compacta)
-- Válida pero mezcla agregación y window function en el mismo SELECT.
WITH ranking_productos AS (
    SELECT
        p.categoria,
        p.nombre_producto,
        SUM(ABS(t.monto)) AS monto_total,
        ROW_NUMBER() OVER (
            PARTITION BY p.categoria
            ORDER BY SUM(ABS(t.monto)) DESC, p.nombre_producto ASC
        ) AS ranking
    FROM productos p
    JOIN transacciones t ON p.producto_id = t.producto_id
    WHERE t.fecha BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY p.categoria, p.nombre_producto
)
SELECT categoria, nombre_producto, monto_total, ranking
FROM ranking_productos
WHERE ranking <= 3
ORDER BY categoria, ranking;

/*
CONCEPTOS CLAVE DE WINDOW FUNCTIONS:

  Intuición: hacen un cálculo por grupo SIN colapsar filas (a diferencia
  de GROUP BY). Sirven para rankings, comparaciones con vecinos, acumulados.

  Sintaxis:
      FUNCION() OVER (PARTITION BY col_grupo ORDER BY col_orden)

  - PARTITION BY = reinicia el cálculo por cada valor (equivale a GROUP BY
    dentro de la ventana).
  - ORDER BY dentro del OVER = cómo se ordenan las filas dentro de la
    partición para asignar el ranking.

  Tres funciones de ranking (distintas ante empates):
    ROW_NUMBER() → 1,2,3,4  (todos únicos, desempate arbitrario o por
                             tu ORDER BY)
    RANK()       → 1,1,3,4  (empates comparten posición, salta números)
    DENSE_RANK() → 1,1,2,3  (empates comparten posición, NO salta)

  Regla importante:
    - No se puede filtrar una window function en el WHERE de la misma
      query donde se calcula → hay que envolver en CTE/subquery y filtrar
      afuera.

PATRÓN MENTAL "TOP N POR GRUPO" (memorizar):
  1. CTE 1: calculo la métrica por entidad (SUM/COUNT/AVG).
  2. CTE 2: aplico ROW_NUMBER() OVER (PARTITION BY grupo ORDER BY métrica DESC).
  3. SELECT externo: WHERE ranking <= N.
  4. ORDER BY final para presentar.

ERRORES A EVITAR:
  ✗ WHERE ROW_NUMBER() OVER (...) <= 3  → no se puede.
  ✗ Olvidar PARTITION BY → ranking global en lugar de por grupo.
  ✗ Confundir RANK con ROW_NUMBER → si hay que desempatar por otro
    criterio, siempre ROW_NUMBER.
  ✗ Olvidar ORDER BY dentro del OVER → ranking random.

QUÉ DECIR EN VOZ ALTA EN LA ENTREVISTA:
  "Es un top 3 por grupo, uso ROW_NUMBER particionando por categoría y
   ordenando por monto DESC con desempate por nombre ASC. Como no puedo
   filtrar la window function en el WHERE, la envuelvo en una CTE y filtro
   en la query externa."

  Con esa explicación sola, ya demostrás que entendés el patrón.
  Aunque la sintaxis después te trabe, el razonamiento vale muchísimo.
*/


-- ============================================================================
-- RESUMEN DE APRENDIZAJES DEL SIMULACRO
-- ============================================================================

/*
BUGS RECURRENTES A CORREGIR:
  1. Olvidar el filtro de fecha en el WHERE. (Ya empezó a corregirse en Q4.)
  2. Olvidar DISTINCT cuando la pregunta habla de "únicos".
  3. Aliases entre comillas simples.

FORTALEZAS DEMOSTRADAS:
  1. Modelado mental de las tablas y JOINs correctos (esto es lo más
     difícil, ya lo tengo).
  2. Buen instinto para arrancar por la tabla que tiene la métrica.
  3. Actitud de reconocer lo que no sé y preguntar (esto vale MUCHO
     en la técnica real).

PRÓXIMOS PASOS DE PRÁCTICA:
  - DataLemur:
    * Ejercicios de "Subqueries" y "Filter with aggregation" → refuerza Q4.
    * Ejercicios de "Top N per group" → refuerza Q5.
    * Ejercicios con filtros de fecha → refuerza el bug recurrente.
  - Hacer al menos 1 simulacro completo más (5 preguntas cronometradas).
  - Repetir hasta que el patrón "CTE → filtro" salga automático.

RECORDATORIOS PARA LA TÉCNICA REAL:
  - Antes de escribir código: 30 seg para explorar el esquema.
  - Antes de cada pregunta: leerla 2 veces, reformularla en tus palabras,
    preguntar si hay ambigüedad.
  - Pensar en voz alta mientras tipeás.
  - Cerrar cada pregunta interpretando el resultado en términos de negocio.
  - Si no sabés algo: decilo y contá cómo lo resolverías. Nunca fingir.
*/
