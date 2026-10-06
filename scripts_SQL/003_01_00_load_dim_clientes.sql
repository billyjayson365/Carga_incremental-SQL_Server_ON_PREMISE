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

--DETECCIÓN DE REGISTROS EXISTENTES CON MODIFICACIONES
SELECT 
	*
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


--DETECCIÓN DE REGISTROS NUEVOS
SELECT 
	*
FROM 
	#tmp_stg_cliente AS stg
LEFT JOIN 
	DimCliente AS dim
ON 
	(stg.hashkeycliente = dim.ClienteHashKey AND dim.EsActual = 1)
WHERE
	dim.ClienteHashKey IS NULL

DROP TABLE IF EXISTS #tmp_stg_cliente;