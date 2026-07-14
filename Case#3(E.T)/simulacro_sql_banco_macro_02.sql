-- ============================================================================
-- SIMULACRO TÉCNICO SQL #2 — Preparación entrevista Banco Macro
-- Dominio: Tarjetas de Crédito
-- Fecha de referencia (hoy): 2026-07-01
-- ============================================================================


-- ============================================================================
-- ESQUEMA
-- ============================================================================

/*
TABLA: tarjetas
---------------
tarjeta_id      INT       PK
cliente_id      INT       Titular
tipo_tarjeta    VARCHAR   'Classic', 'Gold', 'Platinum', 'Black'
limite_credito  DECIMAL   Límite asignado en pesos
fecha_emision   DATE      Fecha de alta
estado          VARCHAR   'Activa', 'Bloqueada', 'Cerrada'
sucursal_id     INT       FK a sucursales


TABLA: sucursales
-----------------
sucursal_id      INT       PK
nombre_sucursal  VARCHAR
provincia        VARCHAR
region           VARCHAR   'AMBA', 'Centro', 'Norte', 'Sur', 'Cuyo'


TABLA: consumos
---------------
consumo_id     INT       PK
tarjeta_id     INT       FK a tarjetas
fecha_consumo  DATE      Fecha del consumo
monto          DECIMAL   Siempre positivo
rubro          VARCHAR   'Supermercado', 'Combustible', 'Indumentaria',
                         'Gastronomía', 'Viajes', 'Electro'
cuotas         INT       1 = un pago
*/


-- ============================================================================
-- REGLAS DE ORO (las que fallaron en este simulacro)
-- ============================================================================

/*
COMILLAS:
  - Comillas SIMPLES → valores/strings:  WHERE estado = 'Activa'
  - Sin comillas o dobles → alias:       AS cantidad_tarjetas
  (Nunca comillas dobles para un string. Nunca comillas simples para un alias.)

ALIAS: ¿dónde se pueden usar?
  Orden de ejecución: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY

  - En el mismo SELECT  → NO (el alias todavía no existe)
  - En HAVING           → NO (se ejecuta antes del SELECT) → repetir la expresión
  - En ORDER BY         → SÍ (se ejecuta después del SELECT)

  Ejemplo:
    HAVING SUM(monto) > 50000000     ✓ correcto
    HAVING monto_total > 50000000    ✗ falla en Postgres/SQL Server

COUNT DESPUÉS DE UN JOIN:
  Al joinear una tabla "1" (tarjetas) con una "muchos" (consumos), las filas
  de la primera se DUPLICAN. Preguntarse siempre:
      ¿estoy contando ENTIDADES o FILAS?
  Si son entidades → COUNT(DISTINCT columna)

DIVISIÓN:
  Si ambos operandos son enteros, algunos motores hacen división ENTERA
  (5/2 = 2, no 2.5). Hábito preventivo: multiplicar por 1.0
      SUM(monto) * 1.0 / COUNT(DISTINCT tarjeta_id)
  Y ojo con división por cero.

DOS FILTROS ≠ UN FILTRO:
  Cuando la pregunta tiene filtro de estado Y filtro de fecha, van los dos.
  Ojo: pueden vivir en tablas distintas.
      WHERE t.estado = 'Activa'
        AND c.fecha_consumo BETWEEN '2026-01-01' AND '2026-06-30'

HACER EXACTAMENTE LO QUE PIDEN:
  Si piden ORDER BY por una columna, no ordenes por tres. Agregar de más
  sugiere que no leíste con atención.
*/


-- ============================================================================
-- PREGUNTA 1 — Warm-up
-- ============================================================================
-- Cantidad de tarjetas y límite promedio por tipo de tarjeta,
-- solo tarjetas 'Activa'. Ordenar por límite promedio DESC.

SELECT
    tipo_tarjeta,
    COUNT(tarjeta_id) AS cantidad_tarjetas,
    AVG(limite_credito) AS promedio_limite_credito
FROM tarjetas
WHERE estado = 'Activa'
GROUP BY tipo_tarjeta
ORDER BY promedio_limite_credito DESC;

/*
NOTAS:
  - No hay JOIN, así que COUNT(tarjeta_id) es seguro (no hay duplicación).
  - Convención: la dimensión de agrupación va primero en el SELECT,
    las métricas después. Se lee mejor.
*/


-- ============================================================================
-- PREGUNTA 2 — Filtro temporal + HAVING
-- ============================================================================
-- Monto total consumido por rubro en Q2 2026 (abr-jun),
-- solo rubros con consumo total > 50 millones. Ordenar DESC.

SELECT
    rubro,
    SUM(monto) AS monto_total
FROM consumos
WHERE fecha_consumo BETWEEN '2026-04-01' AND '2026-06-30'
GROUP BY rubro
HAVING SUM(monto) > 50000000
ORDER BY monto_total DESC;

/*
NOTAS:
  - HAVING repite la expresión SUM(monto), NO usa el alias.
  - ORDER BY sí puede usar el alias.
  - Sin ABS(): en esta tabla los montos son siempre positivos.
    Leer el esquema antes de aplicar ABS por reflejo.
*/


-- ============================================================================
-- PREGUNTA 3 — JOIN múltiple + promedio con denominador correcto
-- ============================================================================
-- Por región: cantidad de tarjetas activas, monto total consumido en
-- el primer semestre 2026, y consumo promedio por tarjeta activa.
-- Ordenar por monto total DESC.

/*
EL PROBLEMA CONCEPTUAL DE ESTA PREGUNTA:
  Las dos métricas viven en tablas distintas con granularidad distinta:
    - "cantidad de tarjetas activas" → vive en `tarjetas`
    - "monto consumido"              → vive en `consumos`

  Si joineás todo de una, una tarjeta activa SIN consumos en el período
  desaparece del INNER JOIN → el denominador queda mal.

  SOLUCIÓN: calcular cada métrica por separado en su propia CTE y unirlas
  después con LEFT JOIN.
*/

-- Versión correcta
WITH tarjetas_activas AS (
    SELECT
        s.region,
        COUNT(t.tarjeta_id) AS cantidad_tarjetas
    FROM tarjetas t
    JOIN sucursales s ON s.sucursal_id = t.sucursal_id
    WHERE t.estado = 'Activa'
    GROUP BY s.region
),
consumos_region AS (
    SELECT
        s.region,
        SUM(c.monto) AS monto_total
    FROM consumos c
    JOIN tarjetas t ON t.tarjeta_id = c.tarjeta_id
    JOIN sucursales s ON s.sucursal_id = t.sucursal_id
    WHERE t.estado = 'Activa'
      AND c.fecha_consumo BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY s.region
)
SELECT
    ta.region,
    ta.cantidad_tarjetas,
    COALESCE(cr.monto_total, 0) AS monto_total,
    COALESCE(cr.monto_total, 0) * 1.0 / ta.cantidad_tarjetas AS consumo_promedio
FROM tarjetas_activas ta
LEFT JOIN consumos_region cr ON ta.region = cr.region
ORDER BY monto_total DESC;


-- Versión simple (ACEPTABLE si la aclarás en voz alta)
SELECT
    s.region,
    COUNT(DISTINCT t.tarjeta_id) AS cantidad_tarjetas,
    SUM(c.monto) AS monto_total,
    SUM(c.monto) * 1.0 / COUNT(DISTINCT t.tarjeta_id) AS consumo_promedio
FROM consumos c
JOIN tarjetas t ON t.tarjeta_id = c.tarjeta_id
JOIN sucursales s ON s.sucursal_id = t.sucursal_id
WHERE t.estado = 'Activa'
  AND c.fecha_consumo BETWEEN '2026-01-01' AND '2026-06-30'
GROUP BY s.region
ORDER BY monto_total DESC;

/*
QUÉ DECIR EN VOZ ALTA SI VAS POR LA VERSIÓN SIMPLE:
  "Ojo que acá estoy contando tarjetas activas que tuvieron al menos un
   consumo en el período, no todas las tarjetas activas. Si el negocio
   quiere el denominador completo, habría que calcular el conteo por
   separado."

  Esa aclaración vale más que la query perfecta: muestra que entendés
  la trampa del dato.

APRENDIZAJES:
  - COUNT después de JOIN → siempre preguntarse si necesito DISTINCT.
  - Dos métricas de tablas distintas → CTEs separadas + LEFT JOIN.
  - COALESCE para convertir NULL en 0 cuando el LEFT JOIN no matchea.
*/


-- ============================================================================
-- PREGUNTA 4 — CTE + porcentaje de utilización
-- ============================================================================
-- Para cada tarjeta ACTIVA: pct_utilizacion = (consumo semestre / límite) * 100
-- Devolver tarjeta_id, tipo_tarjeta, limite_credito, consumo_total,
-- pct_utilizacion. Solo utilización > 80%. Ordenar por pct DESC.

/*
CÓMO SE ENCARA (simple):
  1. CTE: calculo el consumo total por tarjeta en el semestre.
     Necesito el JOIN con tarjetas para traer tipo y límite, y filtrar activas.
  2. SELECT externo: calculo el porcentaje y filtro > 80.

  ¿Por qué CTE? Porque no puedo filtrar por pct_utilizacion en el WHERE
  de la misma query donde lo calculo (el alias no existe todavía).
  Alternativa sin CTE: repetir la expresión completa en el HAVING.
*/

WITH consumo_por_tarjeta AS (
    SELECT
        t.tarjeta_id,
        t.tipo_tarjeta,
        t.limite_credito,
        SUM(c.monto) AS consumo_total
    FROM tarjetas t
    JOIN consumos c ON c.tarjeta_id = t.tarjeta_id
    WHERE t.estado = 'Activa'
      AND c.fecha_consumo BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY t.tarjeta_id, t.tipo_tarjeta, t.limite_credito
)
SELECT
    tarjeta_id,
    tipo_tarjeta,
    limite_credito,
    consumo_total,
    (consumo_total * 100.0 / limite_credito) AS pct_utilizacion
FROM consumo_por_tarjeta
WHERE (consumo_total * 100.0 / limite_credito) > 80
ORDER BY pct_utilizacion DESC;

/*
NOTAS:
  - `* 100.0` (con decimal) fuerza división decimal. Hábito preventivo.
  - En el WHERE hay que repetir la expresión completa, no se puede usar
    el alias pct_utilizacion. (Misma regla que el HAVING.)
  - Si limite_credito pudiera ser 0 → división por cero. En un caso real
    agregarías: AND limite_credito > 0
  - GROUP BY incluye tipo_tarjeta y limite_credito porque están en el SELECT
    y no son agregaciones. Regla de oro del GROUP BY.

ALTERNATIVA SIN CTE (con HAVING):
    SELECT t.tarjeta_id, t.tipo_tarjeta, t.limite_credito,
           SUM(c.monto) AS consumo_total,
           SUM(c.monto) * 100.0 / t.limite_credito AS pct_utilizacion
    FROM tarjetas t
    JOIN consumos c ON c.tarjeta_id = t.tarjeta_id
    WHERE t.estado = 'Activa'
      AND c.fecha_consumo BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY t.tarjeta_id, t.tipo_tarjeta, t.limite_credito
    HAVING SUM(c.monto) * 100.0 / t.limite_credito > 80
    ORDER BY pct_utilizacion DESC;

  Funciona igual. La CTE es más legible; el HAVING es más corto.
  Usá la que te salga más natural en el momento.
*/


-- ============================================================================
-- PREGUNTA 5 — Window function: Top 1 por grupo
-- ============================================================================
-- Rubro de mayor consumo de cada tipo de tarjeta, primer semestre 2026,
-- solo tarjetas activas. Devolver tipo_tarjeta, rubro, monto_total, ranking.
-- Solo el #1 de cada tipo. Desempate alfabético por rubro.

/*
LA RECETA (siempre igual, memorizala):

  PASO 1 → CTE con la métrica agregada por las dos dimensiones
           (el grupo + la cosa que rankeás)
  PASO 2 → ROW_NUMBER() OVER (PARTITION BY grupo ORDER BY métrica DESC)
  PASO 3 → SELECT externo con WHERE ranking <= N

  PARTITION BY = dentro de qué grupo rankeo
  ORDER BY (dentro del OVER) = según qué criterio rankeo

  ¿Por qué siempre CTE? Porque NO se puede filtrar una window function
  en el WHERE de la misma query donde se calcula. Hay que envolverla.
*/

WITH consumo_por_tipo_rubro AS (
    SELECT
        t.tipo_tarjeta,
        c.rubro,
        SUM(c.monto) AS monto_total
    FROM tarjetas t
    JOIN consumos c ON c.tarjeta_id = t.tarjeta_id
    WHERE t.estado = 'Activa'
      AND c.fecha_consumo BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY t.tipo_tarjeta, c.rubro
),
ranking_rubros AS (
    SELECT
        tipo_tarjeta,
        rubro,
        monto_total,
        ROW_NUMBER() OVER (
            PARTITION BY tipo_tarjeta
            ORDER BY monto_total DESC, rubro ASC
        ) AS ranking
    FROM consumo_por_tipo_rubro
)
SELECT
    tipo_tarjeta,
    rubro,
    monto_total,
    ranking
FROM ranking_rubros
WHERE ranking = 1
ORDER BY tipo_tarjeta;

/*
LAS 3 FUNCIONES DE RANKING (cuándo usar cada una):

  ROW_NUMBER()  → 1,2,3,4   Siempre únicos. USAR ESTA por defecto,
                            sobre todo cuando el enunciado dice cómo
                            desempatar.
  RANK()        → 1,1,3,4   Empates comparten posición, salta números.
  DENSE_RANK()  → 1,1,2,3   Empates comparten posición, no salta.

QUÉ DECIR EN VOZ ALTA:
  "Es un top 1 por grupo. Uso ROW_NUMBER particionando por tipo_tarjeta
   y ordenando por monto DESC, con desempate alfabético por rubro.
   Como no puedo filtrar la window function en el WHERE, la envuelvo
   en una CTE y filtro afuera."

  Con solo decir eso ya demostraste que entendés el patrón, aunque
  después la sintaxis te trabe.
*/


-- ============================================================================
-- RESUMEN DEL SIMULACRO 2
-- ============================================================================

/*
LO QUE MEJORÓ RESPECTO DEL SIMULACRO 1:
  ✓ Filtro temporal: ya sale casi automático (falló solo en la P3, donde
    había DOS filtros y te enfocaste en uno).
  ✓ Columna de agrupación en el SELECT: corregido.
  ✓ Alias sin comillas: corregido.
  ✓ HAVING usado donde corresponde (P2): perfecto.
  ✓ JOINs: siguen siendo tu punto fuerte. No hace falta practicarlos más.

LO QUE FALTA PULIR:
  ✗ COUNT sin DISTINCT después de un JOIN que multiplica filas.
  ✗ Uso de alias donde no se puede (mismo SELECT, HAVING).
  ✗ Cuando la pregunta tiene 2 filtros, chequear que estén los 2.
  ✗ Comillas dobles en strings (van simples).

LAS 2 RECETAS PARA MEMORIZAR:

  [A] "X supera al agregado de X" o "calcular un ratio y filtrar por él":
      1. CTE con la métrica por entidad
      2. SELECT externo que calcula el ratio y filtra
      (o HAVING repitiendo la expresión completa)

  [B] "Top N por grupo":
      1. CTE con la métrica agregada por (grupo, entidad)
      2. CTE con ROW_NUMBER() OVER (PARTITION BY grupo ORDER BY métrica DESC)
      3. SELECT externo con WHERE ranking <= N

  Con estas dos recetas cubrís el 90% de las preguntas difíciles
  de una técnica de Data Analyst.

CHECKLIST FINAL ANTES DE ENTREGAR CADA QUERY:
  ✓ ¿Están TODOS los filtros que pide el enunciado?
  ✓ ¿Necesito DISTINCT en el COUNT?
  ✓ ¿Estoy usando un alias donde no se puede?
  ✓ ¿La división puede ser entera o dar cero?
  ✓ ¿El ORDER BY es exactamente el que pidieron (ni más ni menos)?
*/
