## SCD2 - Procesamiento retroactivo de dimensiones

Laboratorio práctico en SQL Server enfocado en el tratamiento de cambios históricos y retroactivos en una dimensión de clientes de tipo SCD2.

El objetivo es implementar un ETL incremental capaz de identificar registros nuevos, corregir versiones históricas existentes y procesar cambios que llegan fuera de orden, conservando correctamente el historial de cada cliente.

**El proceso contempla:**

- Extracción incremental mediante Watermark.
- Limpieza de datos y generación de Hash Keys.
- Actualización de versiones históricas mediante `INNER JOIN + UPDATE`.
- Inserción de nuevas versiones mediante `LEFT JOIN + INSERT`.
- Recálculo de fechas de vigencia y versiones activas mediante `LEAD()`.

Se trabajan casos como cambios de ciudad, correcciones históricas, versiones atrasadas y clientes que regresan a una ubicación anterior, priorizando un procesamiento eficiente de los registros afectados.
