/*
DIM CLIENTE -> 
Tipo SCD2, lo que quiere decir que la información se actualiza y guarda el histórico.
*/
DROP TABLE IF EXISTS #tmp_stg_cliente;

WITH tb_pre_cliente AS (
	SELECT DISTINCT
		UPPER(TRIM(TipoDocumento)) AS TipoDocumento,
		TRIM(NumeroDocumento) AS NumeroDocumento,
		TRIM(Nombres) AS Nombres,
		TRIM(Apellidos) AS Apellidos,
		TRIM(Email) AS Email,
		TRIM(Telefono) AS Telefono,
		TRIM(CiudadCliente) AS CiudadCliente,
		TRIM(EstadoCliente) AS EstadoCliente
	FROM 
		tmp_stg_Ventas_process
)

SELECT 
	*,
	HASHBYTES(
		'SHA2_256', 
		CONCAT(TipoDocumento, '|', NumeroDocumento)
	) AS HashKeyCliente
INTO #tmp_stg_cliente
FROM 
	tb_pre_cliente;

DECLARE @fechahora DATETIME = GETDATE();

--DETECCIÓN Y ACTUALIZACIÓN DE REGISTROS EXISTENTES CON MODIFICACIONES
UPDATE dim
SET
	dim.EsActual = 0,
	dim.FechaFinVigencia = @fechahora,
	dim.EstadoCliente = 'INACTIVO',
	dim.FechaUltimaModificacionDW = @fechahora
FROM 
	#tmp_stg_cliente AS stg
INNER JOIN 
	DimCliente AS dim
ON 
	(stg.hashkeycliente = dim.ClienteHashKey AND dim.EsActual = 1) 
WHERE
	(stg.Nombres <> dim.Nombres OR 
	stg.apellidos <> dim.Apellidos OR 
	ISNULL(stg.email, '') <> ISNULL(dim.email, '') OR 
	ISNULL(stg.Telefono, '') <> ISNULL(dim.Telefono, '') OR 
	ISNULL(stg.CiudadCliente, '') <> ISNULL(dim.Ciudad, ''))

--DETECCIÓN Y ACTUALIZACIÓN DE REGISTROS NUEVOS
INSERT INTO DimCliente
SELECT 
	stg.HashKeyCliente,
	stg.TipoDocumento,
	stg.NumeroDocumento,
	stg.Nombres,
	stg.Apellidos,
	stg.Email,
	stg.Telefono,
	stg.CiudadCliente,
	'ACTIVO' AS EstadoCliente,
	@fechahora AS FechaInicioVigencia,
	'9999-12-31 23:59:59.999' AS FechaFinVigencia,
	1 AS EsActual,
	@fechahora AS FechaInsercionDW,
	null AS FechaUltimaModificacionDW
FROM 
	#tmp_stg_cliente AS stg
LEFT JOIN 
	DimCliente AS dim
ON 
	(stg.hashkeycliente = dim.ClienteHashKey AND dim.EsActual = 1)
WHERE
	dim.ClienteHashKey IS NULL

DROP TABLE IF EXISTS #tmp_stg_cliente;