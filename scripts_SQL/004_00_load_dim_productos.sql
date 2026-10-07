/*
=======================================
DIMPRODUCTO -> Tipo SCD1
=======================================
*/

DROP TABLE IF EXISTS #tmp_dim_producto

WITH tb_pre_productos AS (
	SELECT DISTINCT
		HASHBYTES(
			'SHA2_256',
			CodigoProducto
		) AS HashKeyProducto,
		CodigoProducto,
		NombreProducto,
		Categoria,
		Subcategoria,
		Marca,
		PrecioLista,
		EstadoProducto
	FROM 
		tmp_stg_Ventas_process
)

SELECT
	*
INTO #tmp_dim_producto
FROM
	tb_pre_productos;
