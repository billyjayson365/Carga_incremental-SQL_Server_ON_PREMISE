/*
=======================================
DIMPRODUCTO -> Tipo SCD1
=======================================
*/

--INTENTO DE ELIMINAR LA TABLA TEMPORAL EN CASO EXISTA
DROP TABLE IF EXISTS #tmp_dim_producto;

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


--IDENTIFICACIÓN DE PRODUCTOS YA EXISTENTES PERO CON MODIFICACIONES
SELECT 
	*
FROM 
	#tmp_dim_producto AS tmp
INNER JOIN 
	DimProducto AS dim
ON
	tmp.HashKeyProducto = dim.ProductoHashKey
WHERE
	tmp.NombreProducto <> dim.NombreProducto OR 
	tmp.Categoria <> dim.Categoria OR
	tmp.Subcategoria <> dim.Subcategoria OR
	tmp.Marca <> dim.Marca OR
	tmp.PrecioLista <> dim.PrecioLista OR
	tmp.EstadoProducto <> dim.EstadoProducto;


--IDENTIFICACIÓN DE PRODUCTOS NUEVOS
SELECT 
	*
FROM 
	#tmp_dim_producto AS tmp	
LEFT JOIN 
	DimProducto AS dim
ON
	tmp.HashKeyProducto = dim.ProductoHashKey
WHERE
	dim.Categoria IS NULL;

--ELIMINAR LA TABLA TEMPORAL
DROP TABLE IF EXISTS #tmp_dim_producto;