-- ============================================================================
-- GUÍA RÁPIDA PARA LA TÉCNICA SQL — Cómo encarar cada pregunta
-- Leer antes de empezar. No reemplaza practicar: recuerda hacia dónde ir.
-- ============================================================================


-- ============================================================================
-- 1. LO PRIMERO: ¿LISTADO O RESUMEN?
-- ============================================================================
/*
Antes de escribir NADA, decidí qué forma tiene la respuesta:

  LISTADO → una fila por registro. "mostrame los préstamos que...", 
            "listame los clientes con..."
            → SELECT + WHERE + ORDER BY. NADA de GROUP BY.

  RESUMEN → una fila por grupo. "cuántos por...", "total por...", 
            "promedio por..."
            → GROUP BY.

Meter GROUP BY en un listado es el error más común. Si no hay una
palabra de agregación (cuántos/total/promedio/máximo), NO va GROUP BY.
*/


-- ============================================================================
-- 2. LA PALABRA "POR X" → GROUP BY X
-- ============================================================================
/*
"por región"        → GROUP BY region
"por segmento"      → GROUP BY segmento
"por mes"           → GROUP BY (mes extraído de la fecha)
"por tipo y estado" → GROUP BY tipo, estado   (dos dimensiones)

REGLA: en el GROUP BY va EXACTAMENTE lo que pide desglosar, ni una más.
  - "por región" → solo region. (NO agregar sucursal_id: parte de más)

REGLA DE ORO DEL SELECT:
  Toda columna del SELECT que NO esté en una función de agregación
  (SUM/COUNT/AVG/MAX/MIN) DEBE estar en el GROUP BY.

Agrupar por entidad → agrupá por su CLAVE, no solo por el nombre:
  GROUP BY c.cliente_id, c.nombre   (dos "Juan Pérez" no se fusionan)
*/


-- ============================================================================
-- 3. WHERE vs HAVING
-- ============================================================================
/*
  WHERE  → filtra filas ANTES de agrupar. Sobre columnas crudas.
           (fecha, estado, monto individual)
  HAVING → filtra grupos DESPUÉS de agregar. Sobre agregaciones.
           (SUM(...) > X, COUNT(*) > X)

TEST: ¿el filtro tiene un SUM/COUNT/AVG adentro?
        Sí → HAVING     No → WHERE
*/


-- ============================================================================
-- 4. ¿DÓNDE PUEDO USAR UN ALIAS?
-- ============================================================================
/*
Orden real de ejecución:
  FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY

  En el mismo SELECT → NO (todavía no existe)
  En WHERE           → NO
  En HAVING          → NO → repetir la expresión: HAVING SUM(x) > 100
  En GROUP BY        → depende del motor → repetir la expresión o GROUP BY 1
  En ORDER BY        → SÍ (se ejecuta al final)

Si un motor no toma alias en GROUP BY → usar GROUP BY 1 (por posición),
funciona casi en todos.
*/


-- ============================================================================
-- 5. ¿VA CTE / SUBCONSULTA, O ES PLANO?
-- ============================================================================
/*
PREGUNTA CLAVE: ¿esto tiene UN paso o DOS?

  UN PASO (plano) → filtrar + agrupar una vez responde todo.
    → NO necesita CTE. No te compliques.

  DOS PASOS → calculás algo y DESPUÉS operás sobre ese resultado:
    - "el máximo/top de un total agrupado"  (calculo total → saco top)
    - "comparar cada fila contra un promedio/total global"
    - "filtrar por un valor que primero hay que calcular"
    → ahí SÍ CTE o subconsulta.

TRUCO MENTAL: si ya escribiste un GROUP BY y la consigna pide
"el máximo / el top / comparar eso contra algo" → NO reescribas:
envolvé tu query en  WITH x AS ( ...tu query... )  y operá sobre x.
La CTE es tu query + un nombre para hacerle una segunda pregunta.
*/


-- ============================================================================
-- 6. PATRONES DE PORCENTAJE (3 tipos)
-- ============================================================================
/*
SIEMPRE: identificá NUMERADOR (la parte) y DENOMINADOR (el todo).
Fórmula: parte * 100.0 / todo    (el 100.0 con decimal SIEMPRE)

TIPO 1 — parte vs todo, misma fila y misma tabla:
  (ej: % de mora de cada sucursal sobre su propio total)
    SUM(CASE WHEN <cond parte> THEN monto ELSE 0 END) * 100.0 / SUM(monto)
  → filtro que aplica a TODO va en WHERE
  → condición que define la PARTE va en el CASE (NO en WHERE, perderías el total)

TIPO 2 — dos métricas de tablas distintas / granularidad distinta:
  (ej: consumo total / cantidad de tarjetas activas)
  → dos CTEs, una por métrica, y las unís (LEFT JOIN)

TIPO 3 — parte de cada grupo vs TOTAL GLOBAL:
  (ej: % que representa cada segmento sobre el total del banco)
    SUM(monto) * 100.0 / (SELECT SUM(monto) FROM tabla WHERE ...)
  → el denominador es una subconsulta escalar (un solo número, igual
    para todas las filas)

CHECK: si es "% de cada X sobre el total", los % deben sumar ~100.
*/


-- ============================================================================
-- 7. CASE WHEN — dos usos
-- ============================================================================
/*
A) CLASIFICAR fila por fila (una columna nueva):
     CASE WHEN tasa > 75 THEN 'Alta'
          WHEN tasa BETWEEN 60 AND 75 THEN 'Media'
          ELSE 'Baja' END AS categoria
   - Evalúa de arriba a abajo, corta en el primer match. El orden importa.
   - Cuidado con los bordes (¿75 va en Alta o Media?). Decilo en voz alta.

B) CONTAR/SUMAR CONDICIONAL (pivot: conteos en columnas):
     COUNT(CASE WHEN estado='Vigente' THEN 1 END)          -- cuenta
     SUM(CASE WHEN estado='En Mora' THEN monto ELSE 0 END) -- suma plata
   - Lo que va después del THEN = cuánto aporta la fila que cumple.
     1 para contar, el monto para sumar plata.
   - Las que no cumplen: NULL (COUNT las ignora) o 0 (para SUM).
*/


-- ============================================================================
-- 8. JOINS — qué tipo y desde dónde
-- ============================================================================
/*
INNER JOIN → solo los que tienen match en ambas tablas.
  "clientes que tomaron préstamos", "productos vendidos"

LEFT JOIN → TODOS los de una tabla, tengan o no match en la otra.
  Señales: "incluí también los que no...", "todos los X aunque...",
           "deben aparecer con 0", "clientes sin...", "que nunca..."

  → La tabla que querés ENTERA va en el FROM (la base).
    "todas las sucursales aunque no tengan..." → FROM sucursales
    Empezar por la tabla equivocada = faltan filas y no te das cuenta.

  → Filtro sobre tabla IZQUIERDA  → WHERE
    Filtro sobre tabla DERECHA    → va en el ON
    (si el filtro de la derecha va al WHERE, el LEFT se vuelve INNER)

JOIN correcto: unir por la COLUMNA COMPARTIDA REAL.
  ON c.cliente_id = p.cliente_id   (NO = p.prestamo_id)
  Un JOIN mal emparejado CORRE igual pero devuelve basura. Chequealo.
*/


-- ============================================================================
-- 9. ANTI-JOIN — "los que NO tienen / NUNCA hicieron X"
-- ============================================================================
/*
Dos formas:

A) NOT IN:
     WHERE id NOT IN (SELECT id FROM otra_tabla WHERE <cond>)

B) LEFT JOIN + IS NULL (anti-join clásico):
     FROM base b
     LEFT JOIN otra o ON b.id = o.id [AND <cond de la derecha>]
     WHERE o.id IS NULL     -- ← usar la CLAVE de la derecha, nunca falla

OJO: "no aparece ninguna fila" (anti-join, clave IS NULL)
     ≠ "hay fila pero con valor NULL adentro" (columna IS NULL)
     Son preguntas distintas.

Espejo — "los que SÍ tienen al menos uno":
     WHERE id IN (SELECT id FROM otra WHERE <cond>)
*/


-- ============================================================================
-- 10. "EL MÁXIMO/TOP POR GRUPO" (traer la fila entera, no solo el número)
-- ============================================================================
/*
MAX() te da el número, pero PIERDE qué fila era. Para traer la fila:

A) Subconsulta de máximos + emparejar (sin window functions):
     WITH totales AS ( SELECT grupo, SUM(x) AS total ... GROUP BY grupo )
     SELECT * FROM totales t
     WHERE total = (SELECT MAX(total) FROM totales t2 WHERE t2.grupo = t.grupo)

B) Window function (más corta, es la canónica para top-N):
     WITH r AS (
       SELECT ...,
         ROW_NUMBER() OVER (PARTITION BY grupo ORDER BY metrica DESC) AS rn
       FROM ... GROUP BY ...
     )
     SELECT * FROM r WHERE rn <= N
   - PARTITION BY = dentro de qué grupo rankeo
   - ORDER BY dentro del OVER = según qué criterio
   - No se puede filtrar rn en el WHERE de la misma query → envolver en CTE
   - ROW_NUMBER (1,2,3 únicos) para top-N con desempate definido
*/


-- ============================================================================
-- 11. FECHAS — universal entre motores
-- ============================================================================
/*
Literales SIEMPRE en formato ISO:  '2026-07-01'  (nunca '01-07-2026')

Filtrar un rango (funciona en todos los motores):
     WHERE fecha >= '2026-01-01' AND fecha < '2027-01-01'
   - el "< primer día del período siguiente" es lo más seguro
     (no se rompe si la columna tiene hora)

BETWEEN es válido pero INCLUSIVO en ambos extremos:
     WHERE fecha BETWEEN '2026-01-01' AND '2026-06-30'
   - ok para columnas DATE; con fecha+hora puede perder el último día

EXTRACT es estándar SQL (mejor que YEAR()/MONTH(), que varían):
     EXTRACT(YEAR FROM fecha) = 2026
     EXTRACT(MONTH FROM fecha)
   - agrupar "por mes" de un solo año → GROUP BY EXTRACT(MONTH FROM fecha)
   - si el rango cruza años, agrupá por año Y mes para no mezclarlos

Restar fechas / antigüedad varía MUCHO entre motores → si podés,
filtrá por fecha cruda en lugar de calcular la diferencia:
   "más de 12 meses de antigüedad" → WHERE fecha_otorgamiento < '2025-07-01'
   (más simple y más portable que calcular meses)

NULL en fechas: comparar NULL con algo da siempre falso.
   fecha_pago > fecha_vencimiento  → ya excluye los NULL solo.
*/


-- ============================================================================
-- 12. NULL — recordatorios
-- ============================================================================
/*
  Comparar con NULL: usar IS NULL / IS NOT NULL. NUNCA = NULL (da vacío).
  AVG/SUM/COUNT(columna) IGNORAN los NULL.
  COUNT(*) cuenta filas (incluye NULLs); COUNT(col) ignora NULLs de col.
    → en LEFT JOIN, contá COUNT(tabla_derecha.col), NUNCA COUNT(*)
      (COUNT(*) daría 1 para los sin match, no 0)
  <> 'X' excluye los NULL. Si los querés: ... OR col IS NULL.
  Mostrar 0 en vez de NULL: COALESCE(SUM(x), 0)
*/


-- ============================================================================
-- 13. CONTEO ÚNICO
-- ============================================================================
/*
Después de un JOIN que multiplica filas (1 a muchos), la tabla "1"
se duplica. Si contás esa entidad → COUNT(DISTINCT id).

Preguntate SIEMPRE: ¿estoy contando ENTIDADES o FILAS?
  "cuántos clientes únicos" tras join con transacciones → DISTINCT
  "cuántas transacciones" → sin distinct
*/


-- ============================================================================
-- 14. HÁBITOS PARA LA TÉCNICA (valen tanto como el código)
-- ============================================================================
/*
  - Reformulá la pregunta en tus palabras antes de escribir.
  - Si hay ambigüedad, PREGUNTÁ. ("¿incluyo cancelados?") Es senioridad.
  - Pensá en voz alta mientras tipeás.
  - Al terminar, interpretá el resultado en términos de negocio.
  - Si no sabés una sintaxis, decilo y contá cómo lo harías igual.
  - Mostrá la columna por la que filtrás/clasificás mientras validás.
  - * 100.0 para forzar división decimal.
  - Prefijá columnas con alias de tabla cuando hay JOINs (p.monto).
  - Estrategia de examen: leé las 5 primero, arrancá por las claras,
    dejá la más difícil para el final. Mejor 4 perfectas + 1 peleada
    que trabarte en la 3.

CHECKLIST ANTES DE ENTREGAR CADA QUERY:
  [ ] ¿Están TODOS los filtros del enunciado? (a veces 2 o 3)
  [ ] ¿Es la agregación correcta? ¿Necesito DISTINCT?
  [ ] ¿El GROUP BY tiene lo justo (ni de más ni de menos)?
  [ ] ¿Uso algún alias donde no se puede?
  [ ] ¿ORDER BY exactamente como piden (ASC/DESC)?
  [ ] ¿Devuelvo las columnas pedidas?
  [ ] ¿El JOIN une por la columna correcta?
  [ ] Si hay LEFT JOIN: ¿algún filtro de la derecha se coló al WHERE?
  [ ] ¿La división puede dar entera o dividir por cero?
*/
