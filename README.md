# Carga incremental - SQL Server ON PREMISE

## Descripción del laboratorio

Este proyecto simula un proceso ETL incremental en SQL Server para un modelo de ventas compuesto por las dimensiones Cliente, Producto y Tienda, además de una tabla de hechos de ventas.

El laboratorio parte de datos históricos ya cargados y una tabla `stg_Ventas` que contiene nuevos registros y modificaciones provenientes del sistema origen. El objetivo es aplicar una estrategia de carga incremental usando una marca de agua (`watermark`) para determinar qué registros deben procesarse.

Durante el proceso se generan `HashKey` con `SHA2_256` para identificar de forma única clientes, productos, tiendas y líneas de venta. Los cambios se detectan comparando directamente los atributos de cada registro, sin utilizar `HashDiff`.

La casuística incluye:

- Registros existentes sin cambios.
- Registros existentes con modificaciones.
- Nuevos clientes, productos y tiendas.
- Nuevas ventas.
- Modificaciones sobre líneas de venta existentes.
- Registros fuera de la ventana definida por la marca de agua.
- Actualización de fechas de inserción y modificación dentro del Data Warehouse.

El flujo general del proyecto es:

`Stage → Watermark → Dimensiones → FactVentas → Actualización de control`