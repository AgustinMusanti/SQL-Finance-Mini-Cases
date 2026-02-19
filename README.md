<!-- README.html — SQL Finance/Business Mini-Cases -->
<div align="center">
  <h1>SQL Finance & Business Mini-Cases</h1>
  <p>
    Mini casos prácticos de <b>finanzas</b> y <b>negocio</b> resueltos con <b>SQL</b>.
    La idea es practicar de a un tema por vez (CTEs, window functions, cohortes, churn, cashflow, etc.)
    y construir un repositorio ordenado y escalable.
  </p>

  <p>
    <i>Objetivo:</i> mejorar habilidades técnicas y, al mismo tiempo, entrenar el enfoque analítico orientado a decisiones.
  </p>

  <hr style="width:70%;" />
</div>

<h2>¿Qué vas a encontrar acá?</h2>
<ul>
  <li><b>Casos cortos e independientes</b> (cada uno con su mini base de datos y solución).</li>
  <li><b>Enfoque realista</b>: métricas y preguntas típicas de finanzas/negocio.</li>
  <li><b>SQL “de trabajo”</b>: legible, comentado y pensado para explicar.</li>
  <li><b>Resultados</b> listos para mostrar (capturas/tablas) y compartir en LinkedIn.</li>
</ul>

<h2>Estructura del repositorio</h2>
<pre>
/cases
  /01-cashflow-diario-caja-acumulada
    README.md
    schema.sql
    seed.sql
    solution.sql
    output.png
  /02-...
README.html
</pre>

<h2>Mini-casos</h2>
<p>Checklist para ir agregando casos (se irán completando con el tiempo):</p>
<ul>
  <li>[x] <b>01 — Ingresos vs Egresos + Caja Acumulada</b> (CTE + Window Function)</li>
  <li>[ ] 02 — Pareto de gastos (80/20) por categoría</li>
  <li>[ ] 03 — MRR simple (SaaS) mensual</li>
  <li>[ ] 04 — Churn mensual de clientes</li>
  <li>[ ] 05 — Cohortes de retención</li>
  <li>[ ] 06 — LTV simple (aprox.)</li>
  <li>[ ] 07 — Detección de anomalías en gastos</li>
  <li>[ ] 08 — Forecast naive de caja (30 días)</li>
  <li>[ ] 09 — Cartera: costo promedio ponderado</li>
  <li>[ ] 10 — P&amp;L realizado vs no realizado</li>
</ul>

<h2>01 — Ingresos vs Egresos + Caja Acumulada</h2>
<p>
  <b>Problema:</b> dado un registro de movimientos (ingresos/egresos) por fecha, calcular:
</p>
<ul>
  <li>Total ingresado y total egresado por día</li>
  <li>Flujo neto diario (ingresos − egresos)</li>
  <li><b>Caja acumulada</b> (saldo) a lo largo del tiempo</li>
</ul>

<p>
  <b>Conceptos SQL:</b> CTE, agregaciones, <code>CASE WHEN</code>, y window function
  (<code>SUM() OVER (ORDER BY fecha ...)</code>).
</p>

<h3>Cómo ejecutarlo</h3>
<ol>
  <li>Crear tablas:</li>
</ol>
<pre><code>-- Ejecutar schema.sql
</code></pre>

<ol start="2">
  <li>Cargar datos de ejemplo:</li>
</ol>
<pre><code>-- Ejecutar seed.sql
</code></pre>

<ol start="3">
  <li>Ejecutar la solución:</li>
</ol>
<pre><code>-- Ejecutar solution.sql
</code></pre>

<p>
  <b>Salida esperada:</b> una tabla con <code>fecha</code>, <code>ingresos</code>, <code>egresos</code>,
  <code>flujo_neto</code> y <code>caja_acumulada</code>.
</p>

<h2>Convenciones</h2>
<ul>
  <li><b>SQL dialect:</b> indicar en cada caso (ej: SQL Server, MySQL, Postgres).</li>
  <li><b>Datos pequeños:</b> suficientes para probar lógica sin “mega bases”.</li>
  <li><b>Primero negocio, después SQL:</b> cada carpeta arranca con el contexto y preguntas.</li>
</ul>

<h2>Roadmap</h2>
<ul>
  <li>Agregar más mini-casos orientados a métricas financieras y de negocio.</li>
  <li>Incluir variantes: “versión simple” vs “versión pro” (más edge cases).</li>
  <li>Sumar tests básicos (validaciones) cuando aplique.</li>
</ul>

<h2>Contacto</h2>
<p>
  Si te interesa este tipo de casos o querés sugerir uno:
  <b>conectemos en LinkedIn</b> 😊
</p>
