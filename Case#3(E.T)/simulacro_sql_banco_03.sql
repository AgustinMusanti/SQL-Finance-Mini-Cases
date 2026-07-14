-- ============================================================================
-- SIMULACRO TÉCNICO SQL #3 — Preparación entrevista Banco
-- Dominio: Créditos y Mora
-- Fecha de referencia (hoy): 2026-07-01
-- ============================================================================


-- ============================================================================
-- ESQUEMA
-- ============================================================================

/*
TABLA: clientes
---------------
cliente_id          INT
nombre              VARCHAR
fecha_alta          DATE
segmento            VARCHAR    'Individuo', 'PyME', 'Corporativo'
sucursal_id         INT
ingreso_declarado   DECIMAL


TABLA: prestamos
----------------
prestamo_id         INT
cliente_id          INT
tipo_prestamo       VARCHAR    'Personal', 'Hipotecario', 'Prendario', 'PyME'
monto_otorgado      DECIMAL
fecha_otorgamiento  DATE
plazo_meses         INT
tasa_anual          DECIMAL
estado              VARCHAR    'Vigente', 'Cancelado', 'En Mora'


TABLA: pagos
------------
pago_id             INT
prestamo_id         INT
fecha_vencimiento   DATE
fecha_pago          DATE       NULL si la cuota no fue pagada todavía
monto_cuota         DECIMAL
monto_pagado        DECIMAL
*/


-- ============================================================================
-- PREGUNTA 1
-- ============================================================================
-- Por tipo de préstamo: cantidad de préstamos y monto total otorgado,
-- solo préstamos NO cancelados. Ordenar por monto total DESC.

SELECT
    tipo_prestamo,
    COUNT(prestamo_id) AS cantidad_prestamos,
    SUM(monto_otorgado) AS monto_total_otorgado
FROM prestamos
WHERE estado <> 'Cancelado'
GROUP BY tipo_prestamo
ORDER BY monto_total_otorgado DESC;

/*
MI ERROR:
  WHERE estado IN ['Vigente', 'En Mora']   ✗ corchetes NO existen en SQL
  WHERE estado IN ('Vigente', 'En Mora')   ✓ la lista del IN va con paréntesis

  (Los corchetes son de listas de Python. Se me mezclaron.)

INCLUIR vs EXCLUIR — dos formas válidas:
  IN ('Vigente', 'En Mora')   → enumero lo que SÍ quiero
  <> 'Cancelado'              → excluyo lo que NO quiero

  Ambas dan lo mismo hoy. La diferencia importa si mañana agregan un
  estado nuevo (ej. 'Refinanciado'):
    - el IN lo dejaría afuera silenciosamente
    - el <> lo incluiría automáticamente

  Frase para decir en voz alta y sumar un punto:
    "Uso <> 'Cancelado' para que sea robusto ante nuevos estados."
*/


-- ============================================================================
-- PREGUNTA 2
-- ============================================================================
-- Préstamos otorgados en 2025: monto promedio y tasa promedio por segmento.
-- Solo segmentos con más de 100 préstamos en ese período.

SELECT
    c.segmento,
    COUNT(p.prestamo_id) AS cantidad_prestamos,
    AVG(p.monto_otorgado) AS monto_prom_otorgado,
    AVG(p.tasa_anual) AS promedio_tasa
FROM clientes c
JOIN prestamos p ON c.cliente_id = p.cliente_id
WHERE EXTRACT(YEAR FROM p.fecha_otorgamiento) = 2025
GROUP BY c.segmento
HAVING COUNT(p.prestamo_id) > 100;

/*
MI ERROR:
  AVG(p.monto_total)      ✗ esa columna no existe
  AVG(p.monto_otorgado)   ✓ leer bien el esquema

LO QUE SALIÓ BIEN (y antes fallaba):
  ✓ HAVING con la expresión completa COUNT(...), no con el alias.
  ✓ Filtro temporal presente y bien construido.

HAVING vs SELECT — no hay relación obligatoria:
  Podés filtrar en el HAVING por algo que NO mostrás en el SELECT.
  El motor calcula el COUNT internamente aunque no lo devuelva.

  Lo que SÍ es obligatorio:
    SELECT → GROUP BY: toda columna no agregada debe estar en el GROUP BY.

  Criterio: si el enunciado pide columnas específicas, devolvé exactamente
  esas. Si no las especifica, mostrar la métrica por la que filtrás hace
  el resultado auditable.

¿POR QUÉ ACÁ NO HACE FALTA DISTINCT EN EL COUNT?
  Porque estoy contando préstamos (la tabla "muchos"), no clientes.
  Cada fila del JOIN es un préstamo distinto.
  Si contara CLIENTES, ahí sí necesitaría COUNT(DISTINCT c.cliente_id).
*/


-- ============================================================================
-- PREGUNTA 3 — LEFT JOIN
-- ============================================================================
-- Clientes 'Individuo' dados de alta antes del 2026-01-01, con la cantidad
-- de préstamos que tienen. Incluir a los que nunca tomaron uno (con 0).
-- Ordenar por cantidad de préstamos ASC.

SELECT
    c.cliente_id,
    c.nombre,
    COUNT(p.prestamo_id) AS cantidad_prestamos
FROM clientes c
LEFT JOIN prestamos p ON c.cliente_id = p.cliente_id
WHERE c.segmento = 'Individuo'
  AND c.fecha_alta < '2026-01-01'
GROUP BY c.cliente_id, c.nombre
ORDER BY cantidad_prestamos ASC;

/*
MIS ERRORES:
  1. fecha_alta <> 2026          ✗ comparás una DATE contra el número 2026
     c.fecha_alta < '2026-01-01' ✓

  2. GROUP BY c.nombre           ✗ dos clientes con el mismo nombre se fusionan
     GROUP BY c.cliente_id, c.nombre  ✓ agrupar siempre por la clave

  3. ORDER BY ... DESC           ✗ la consigna pedía ASC (buscan clientes SIN
                                   préstamos = las oportunidades comerciales)

NO HACÍA FALTA COALESCE (esto es importante):
  COUNT() ignora los NULL y devuelve 0, no NULL.
  Un cliente sin préstamos → p.prestamo_id es NULL → COUNT lo ignora → 0. ✓

  ⚠ TRAMPA CLÁSICA:
     COUNT(*)              → devuelve 1 para clientes sin préstamos
                             (cuenta la fila del LEFT JOIN, que existe con
                             NULLs adentro)
     COUNT(p.prestamo_id)  → devuelve 0 ✓

  REGLA: en un LEFT JOIN, contá SIEMPRE una columna de la tabla derecha,
         nunca COUNT(*).

  ¿CUÁNDO SÍ VA COALESCE? Con SUM(), que sí devuelve NULL si no hay filas:
     COALESCE(SUM(p.monto_otorgado), 0) AS monto_total


-- ---------------------------------------------------------------------------
-- LA TRAMPA MÁS IMPORTANTE DEL LEFT JOIN (memorizar esto)
-- ---------------------------------------------------------------------------

  Si ponés en el WHERE un filtro sobre la tabla DERECHA, el LEFT JOIN se
  convierte de facto en un INNER JOIN.

  ✗ ROMPE el LEFT JOIN:
      LEFT JOIN prestamos p ON c.cliente_id = p.cliente_id
      WHERE p.estado = 'Vigente'

      ¿Por qué? Los clientes sin préstamos tienen p.estado = NULL.
      NULL = 'Vigente' es falso → esas filas se descartan.
      Adiós clientes sin préstamos.

  ✓ CORRECTO — el filtro de la tabla derecha va en el ON:
      LEFT JOIN prestamos p
          ON c.cliente_id = p.cliente_id
          AND p.estado = 'Vigente'

  REGLA DE ORO:
      Filtro sobre tabla IZQUIERDA  → va en el WHERE
      Filtro sobre tabla DERECHA    → va en el ON

  (En esta pregunta zafé: mis filtros eran sobre `clientes`, la izquierda.)


-- ---------------------------------------------------------------------------
-- ¿CUÁNDO USAR LEFT JOIN? (la intuición)
-- ---------------------------------------------------------------------------

  INNER JOIN → "solo me interesan los que tienen match en ambas tablas"
               - "clientes que tomaron préstamos"
               - "productos que se vendieron"

  LEFT JOIN  → "quiero TODOS los de la tabla A, tengan o no match en B"
               - "todos los clientes, con sus préstamos si los tienen"
               - "todas las sucursales, incluso las que no vendieron nada"

  SEÑALES EN EL ENUNCIADO que gritan LEFT JOIN:
     "incluí también a los que no..."
     "todos los X, aunque..."
     "deben aparecer con 0"
     "clientes sin..."
     "que nunca..."


-- ---------------------------------------------------------------------------
-- PATRÓN "ANTI-JOIN" — los que NUNCA hicieron X
-- ---------------------------------------------------------------------------

  SELECT c.cliente_id, c.nombre
  FROM clientes c
  LEFT JOIN prestamos p ON c.cliente_id = p.cliente_id
  WHERE p.prestamo_id IS NULL;

  El WHERE ... IS NULL después de un LEFT JOIN te deja SOLO los que no
  matchearon. Aparece seguido en técnicas.
*/


-- ============================================================================
-- PREGUNTA 4 — La que no salió
-- ============================================================================
-- Para cada préstamo 'Vigente': % de cuotas pagadas fuera de término
-- (fecha_pago > fecha_vencimiento) sobre el total de cuotas YA PAGADAS.
-- Devolver prestamo_id, tipo_prestamo, cuotas pagadas, cuotas tarde, %.
-- Solo los préstamos con % > 30. Ordenar por % DESC.

/*
CÓMO SE ENCARA — el truco es CASE WHEN dentro de un SUM:

  1. "Cuotas ya pagadas"  → las que tienen fecha_pago NOT NULL
                            → ese es el filtro del WHERE

  2. "Cuotas pagadas tarde" → de esas, las que cumplen
                              fecha_pago > fecha_vencimiento
                              → NO va en el WHERE (perderías el denominador)
                              → va en un CASE WHEN adentro de un SUM

  EL PATRÓN CLAVE (contar condicionalmente sin perder el total):

      SUM(CASE WHEN <condicion> THEN 1 ELSE 0 END)

  Esto cuenta SOLO las filas que cumplen la condición, pero sin filtrarlas
  de la query. Así podés tener el numerador (tarde) y el denominador
  (todas) en la misma pasada.

  Es EL patrón más útil de SQL de negocio. Aparece siempre:
     - % de transacciones aprobadas sobre el total
     - % de clientes activos sobre el total
     - % de cuotas en mora sobre el total
*/

WITH comportamiento_pago AS (
    SELECT
        p.prestamo_id,
        p.tipo_prestamo,
        COUNT(pg.pago_id) AS cuotas_pagadas,
        SUM(CASE WHEN pg.fecha_pago > pg.fecha_vencimiento THEN 1 ELSE 0 END) AS cuotas_tarde
    FROM prestamos p
    JOIN pagos pg ON pg.prestamo_id = p.prestamo_id
    WHERE p.estado = 'Vigente'
      AND pg.fecha_pago IS NOT NULL      -- solo cuotas YA pagadas
    GROUP BY p.prestamo_id, p.tipo_prestamo
)
SELECT
    prestamo_id,
    tipo_prestamo,
    cuotas_pagadas,
    cuotas_tarde,
    (cuotas_tarde * 100.0 / cuotas_pagadas) AS pct_fuera_termino
FROM comportamiento_pago
WHERE (cuotas_tarde * 100.0 / cuotas_pagadas) > 30
ORDER BY pct_fuera_termino DESC;

/*
DETALLES IMPORTANTES:

  - pg.fecha_pago IS NOT NULL va en el WHERE porque el enunciado dice
    "sobre el total de cuotas YA PAGADAS". Las no pagadas no entran ni al
    numerador ni al denominador.

  - La condición "pagó tarde" NO puede ir en el WHERE: si filtrás ahí,
    te quedás solo con las cuotas tarde y perdés el denominador.
    Por eso va en el CASE WHEN.

  - * 100.0 (con decimal) fuerza división decimal. Hábito preventivo.

  - No hay división por cero: el WHERE garantiza al menos una cuota pagada
    por préstamo, así que cuotas_pagadas >= 1 siempre.

  - En el WHERE final hay que repetir la expresión completa, no se puede
    usar el alias pct_fuera_termino. (Misma regla del HAVING.)

VARIANTE DEL PATRÓN — COUNT con CASE (equivalente):
    COUNT(CASE WHEN pg.fecha_pago > pg.fecha_vencimiento THEN 1 END)

  Ojo: sin ELSE. COUNT ignora los NULL, así que solo cuenta los que
  cumplen. Es equivalente al SUM(CASE ... THEN 1 ELSE 0 END).
  Usá la que te salga más natural.
*/


-- ============================================================================
-- PREGUNTA 5 — Top N por grupo
-- ============================================================================
-- Préstamos otorgados en el primer semestre 2026: los 2 clientes con mayor
-- monto total otorgado dentro de cada segmento.
-- Devolver segmento, cliente_id, nombre, monto total, posición.
-- Desempatar por nombre alfabéticamente.

WITH prestamos_2026 AS (
    SELECT
        c.cliente_id,
        c.nombre,
        c.segmento,
        ROUND(SUM(p.monto_otorgado), 2) AS monto_total
    FROM clientes c
    JOIN prestamos p ON c.cliente_id = p.cliente_id
    WHERE p.fecha_otorgamiento BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY c.cliente_id, c.nombre, c.segmento
),
ranking_clientes AS (
    SELECT
        cliente_id,
        nombre,
        segmento,
        monto_total,
        ROW_NUMBER() OVER (
            PARTITION BY segmento
            ORDER BY monto_total DESC, nombre ASC
        ) AS ranking
    FROM prestamos_2026
)
SELECT
    segmento,
    cliente_id,
    nombre,
    monto_total,
    ranking
FROM ranking_clientes
WHERE ranking <= 2
ORDER BY segmento, ranking;

/*
MIS ERRORES (todos de alias/nombres, NINGUNO conceptual):

  1. JOIN prestamos c ON c.cliente_id = p.producto_id
     ✗ le puse alias `c` a prestamos, pero `c` ya era clientes
     ✗ usé `p.` sin haberlo definido
     ✗ p.producto_id no existe, es p.cliente_id
     ✓ JOIN prestamos p ON c.cliente_id = p.cliente_id

  2. Dentro de la 2da CTE usé c.nombre, c.segmento...
     ✗ estoy leyendo de la CTE, no de la tabla clientes.
       Los alias de adentro de una CTE NO salen afuera.
     ✓ nombre, segmento (sin prefijo)

  3. ORDER BY monto_total DESC, c.segmento ASC
     ✗ desempaté por segmento, pero ya particiono por segmento
       (dentro de cada partición el segmento es siempre el mismo,
        no desempata nada)
     ✓ ORDER BY monto_total DESC, nombre ASC

  4. FROM ranking
     ✗ la CTE se llama ranking_clientes; `ranking` es la COLUMNA

  5. Faltaba `ranking` en el SELECT final (el enunciado lo pedía)

LO QUE SALIÓ BIEN:
  ✓ Reconocí que era top-N por grupo → fui directo a ROW_NUMBER
  ✓ Dos CTEs: una para agregar, otra para rankear (la receta)
  ✓ PARTITION BY segmento — exacto
  ✓ Filtro del ranking en la query externa (entendí por qué hay que envolver)
  ✓ GROUP BY completo en la primera CTE
  ✓ WHERE ranking IN (1,2) funciona igual que <= 2

LOS 2 HÁBITOS QUE LIMPIAN EL 90% DE ESTOS ERRORES:
  1. Definí los alias UNA sola vez y respetalos: c=clientes, p=prestamos,
     pg=pagos. No los reuses nunca.
  2. Cuando salís de una CTE, los alias de adentro no existen.
     La CTE es una tabla nueva; sus columnas se llaman como las nombraste
     en su SELECT, sin prefijos.
*/


-- ============================================================================
-- LAS 3 RECETAS PARA LA TÉCNICA (con estas cubrís el 90%)
-- ============================================================================

/*
[A] TOP N POR GRUPO
    1. CTE con la métrica agregada por (grupo, entidad)
    2. CTE con ROW_NUMBER() OVER (PARTITION BY grupo ORDER BY métrica DESC)
    3. SELECT externo con WHERE ranking <= N

    ¿Por qué CTE? No se puede filtrar una window function en el WHERE de la
    misma query donde se calcula.


[B] CALCULAR UN RATIO Y FILTRAR POR ÉL
    1. CTE con las métricas agregadas
    2. SELECT externo que calcula el ratio y filtra
    (o HAVING repitiendo la expresión completa, sin CTE)

    Recordá el * 100.0 para forzar división decimal.


[C] CONTAR CONDICIONALMENTE SIN PERDER EL TOTAL
    SUM(CASE WHEN <condicion> THEN 1 ELSE 0 END) AS los_que_cumplen
    COUNT(*)                                     AS total

    Sirve para todo % de negocio: aprobadas/total, tarde/pagadas,
    activos/total. Si la condición fuera al WHERE, perderías el denominador.
*/


-- ============================================================================
-- CHECKLIST FINAL — correr mentalmente antes de entregar cada query
-- ============================================================================

/*
  ✓ ¿Están TODOS los filtros del enunciado? (a veces son 2 o 3)
  ✓ ¿El ORDER BY es exactamente el que pidieron? (ASC vs DESC — leer bien)
  ✓ ¿Devuelvo exactamente las columnas que pidieron?
  ✓ ¿Necesito DISTINCT en el COUNT? (¿cuento entidades o filas?)
  ✓ ¿Estoy usando un alias donde no se puede? (mismo SELECT, WHERE, HAVING)
  ✓ ¿El GROUP BY incluye la clave, no solo el nombre?
  ✓ ¿La división puede ser entera o dar cero?
  ✓ Si hay LEFT JOIN: ¿algún filtro de la tabla derecha se me coló al WHERE?
  ✓ Alias de tabla: ¿los definí una vez y los respeté?

RECORDATORIOS DE COMUNICACIÓN (valen tanto como el código):
  - Antes de escribir: reformulá la pregunta en tus palabras.
  - Si hay ambigüedad: preguntá. Es señal de senioridad, no de debilidad.
  - Mientras tipeás: narrá lo que hacés.
  - Al terminar: interpretá el resultado en términos de negocio.
  - Si no sabés una sintaxis: decilo y contá cómo lo resolverías igual.
*/
