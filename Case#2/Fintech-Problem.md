## Introducción

En los productos **fintech**, entender cómo interactúan los usuarios con la plataforma es clave para mejorar la experiencia, aumentar el uso del producto y detectar posibles problemas de retención.

No alcanza con saber cuántas transacciones se realizaron en total: lo importante es analizar **cómo se comportan los usuarios**, qué tipo de operaciones realizan y si mantienen **actividad en el tiempo**.

Este mini-caso simula el funcionamiento de una **billetera digital**, utilizando un dataset ficticio de aproximadamente **10.000 transacciones realizadas por 750 usuarios durante el año 2025**.

El objetivo es transformar **datos transaccionales** en información útil que permita responder preguntas de negocio como:

- ¿Quiénes son los **usuarios más activos** de la plataforma?
- ¿Cuál es el **ticket promedio por tipo de operación**?
- ¿Qué **segmentos de usuarios** existen según su nivel de actividad?
- ¿Cómo evoluciona el **volumen de pagos mes a mes**?
- ¿Qué usuarios concentran el **mayor volumen transaccionado**?
- ¿Qué usuarios **dejaron de usar la app**?

Este tipo de análisis es común en fintechs y productos digitales, ya que permite **entender el comportamiento de los usuarios**, detectar **abandono de la plataforma** y diseñar **estrategias de crecimiento o reactivación**.

A nivel técnico, el caso demuestra cómo realizar este tipo de análisis utilizando **agregaciones, segmentación con `CASE` y consultas analíticas directamente en SQL**, trabajando sobre una base de datos generada completamente desde código.
