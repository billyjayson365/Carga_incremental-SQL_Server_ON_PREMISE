/*
=======================================
DIMPRODUCTO -> Tipo SCD1
=======================================
*/

--INTENTO DE ELIMINAR LA TABLA TEMPORAL EN CASO EXISTA
DROP TABLE IF EXISTS #tmp_dim_producto;

DECLARE @fechahora DATETIME = GETDATE();

WITH tb_pre_productos AS (
	SELECT DISTINCT
		HASHBYTES(
			'SHA2_256',
			UPPER(TRIM(CodigoProducto))
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
UPDATE
	dim
SET
	dim.NombreProducto = tmp.NombreProducto,
	dim.Categoria = tmp.Categoria,
	dim.Subcategoria = tmp.Subcategoria,
	dim.Marca = tmp.Marca,
	dim.PrecioLista = tmp.PrecioLista,
	dim.EstadoProducto = tmp.EstadoProducto,
	dim.FechaUltimaModificacionDW = @fechahora
FROM 
	#tmp_dim_producto AS tmp
INNER JOIN 
	DimProducto AS dim
ON
	tmp.HashKeyProducto = dim.ProductoHashKey
WHERE
	tmp.NombreProducto <> dim.NombreProducto OR 
	tmp.Categoria <> dim.Categoria OR
	COALESCE(tmp.Subcategoria, '') <> COALESCE(dim.Subcategoria, '') OR
	COALESCE(tmp.Marca, '') <> COALESCE(dim.Marca, '') OR
	tmp.PrecioLista <> dim.PrecioLista OR
	tmp.EstadoProducto <> dim.EstadoProducto;

--IDENTIFICACIÓN DE PRODUCTOS NUEVOS
INSERT INTO DimProducto (
	ProductoHashKey,
	CodigoProducto,
	NombreProducto,
	Categoria,
	Subcategoria,
	Marca,
	PrecioLista,
	EstadoProducto,
	FechaInsercionDW,
	FechaUltimaModificacionDW
)
SELECT 
	tmp.HashKeyProducto,
	tmp.CodigoProducto,
	tmp.NombreProducto,
	tmp.Categoria,
	tmp.Subcategoria,
	tmp.Marca,
	tmp.PrecioLista,
	tmp.EstadoProducto,
	@fechahora AS FechaInsercionDW,
	null AS FechaUltimaModificacionDW
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