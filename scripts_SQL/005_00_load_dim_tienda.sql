/*
============================
DIMTIENDA -> Tipo SCD1
===========================
*/

--ELIMINACIÓN DE LA TABLA TEMPORAL
DROP TABLE IF EXISTS #tmp_DimTienda;

--CTE QUE CAPTURA LOS VALORES DISTINTOS DE LA DIMENSIÓN TIENDA A PARTIR DE LA TABLA STAGE
WITH tb_DimTiendaPre AS (
	SELECT DISTINCT
		HASHBYTES(
			'SHA2_256',
			UPPER(TRIM(CodigoTienda))
		) AS HashKeyTienda,
		CodigoTienda,
		NombreTienda,
		CiudadTienda,
		DepartamentoTienda,
		TipoTienda,
		EstadoTienda
	FROM 
		tmp_stg_Ventas_process
)

--CREACIÓN DE LA TABLA TEMPORAL PARA EJECUTAR EL UPSERT A PARTIR DEL CTE ANTERIOR
SELECT 
	*
INTO 
	#tmp_DimTienda
FROM 
	tb_DimTiendaPre


--UPDATE: DETECCIÓN DE REGISTROS EXISTENTES PERO CON ATRIBUTOS MODIFICADOS
UPDATE 
	dim
SET
	dim.NombreTienda = tmp.NombreTienda,
	dim.Ciudad = tmp.CiudadTienda,
	dim.Departamento = tmp.DepartamentoTienda,
	dim.TipoTienda = tmp.TipoTienda,
	dim.EstadoTienda = tmp.EstadoTienda,
	FechaUltimaModificacionDW = GETDATE()
FROM 
	#tmp_DimTienda AS tmp
INNER JOIN
	DimTienda AS dim
ON
	tmp.HashKeyTienda = dim.TiendaHashKey
WHERE
	tmp.NombreTienda <> dim.NombreTienda OR
	tmp.CiudadTienda <> dim.Ciudad OR
	tmp.DepartamentoTienda <> dim.Departamento OR
	tmp.TipoTienda <> dim.TipoTienda OR
	tmp.EstadoTienda <> dim.EstadoTienda

--INSERT: DETECCIÓN DE REGISTROS NUEVOS E INSERCIÓN
INSERT INTO DimTienda (
	TiendaHashKey,
	CodigoTienda,
	NombreTienda,
	Ciudad,
	Departamento,
	TipoTienda,
	EstadoTienda,
	FechaInsercionDW,
	FechaUltimaModificacionDW
)
SELECT 
	tmp.HashKeyTienda,
	tmp.CodigoTienda,
	tmp.NombreTienda,
	tmp.CiudadTienda,
	tmp.DepartamentoTienda,
	tmp.TipoTienda,
	tmp.EstadoTienda,
	GETDATE() AS FechaInsercionDW,
	NULL AS FechaUltimaModificacion
FROM 
	#tmp_DimTienda AS tmp
LEFT JOIN
	DimTienda AS dim
ON
	tmp.HashKeyTienda = dim.TiendaHashKey
WHERE 
	dim.TiendaHashKey IS NULL

--ELIMINACIÓN DE LA TABLA TEMPORAL
DROP TABLE IF EXISTS #tmp_DimTienda;