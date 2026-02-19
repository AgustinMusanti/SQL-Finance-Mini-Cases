<h2>Introducción</h2>

<p>
En cualquier negocio, entender cómo evoluciona la liquidez en el tiempo es clave para la toma de decisiones. 
No alcanza con saber cuánto se facturó o cuánto se gastó en total: lo importante es analizar 
<b>cuándo</b> ingresó y salió el dinero, y cómo eso impacta en la caja disponible día a día.
</p>

<p>
Este mini-caso aborda un problema básico pero fundamental en finanzas:
calcular el <b>flujo neto diario</b> (ingresos − egresos) y el <b>saldo acumulado de caja</b> 
a partir de una tabla simple de movimientos.
</p>

<p>
El objetivo es transformar datos transaccionales en una métrica operativa que permita responder preguntas como:
</p>

<ul>
  <li>¿La caja está creciendo o deteriorándose?</li>
  <li>¿En qué momentos hubo mayor presión de liquidez?</li>
  <li>¿El negocio genera efectivo de manera sostenible?</li>
</ul>

<p>
A nivel técnico, el caso demuestra cómo construir esta lógica utilizando 
<b>agregaciones, CTEs y window functions</b>, manteniendo el análisis directamente en SQL.
</p>
