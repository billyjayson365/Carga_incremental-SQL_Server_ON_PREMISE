--DIM CLIENTE -> Tipo SCD1, lo que quiere decir que la información solo se actualiza, 
--no se guarda el histórico (esto se define según reglas del negocio.)

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
FROM 
	tb_pre_cliente