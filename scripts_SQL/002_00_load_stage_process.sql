/*
=================================================
ETL_PASO 1. FILTRADO Y CARGA DE DATOS A PROCESAR
=================================================
*/

--LIMPIEZA DE LA TABLA STAGE CON LOS DATOS A PROCESAR
TRUNCATE TABLE tmp_stg_ventas_process;

WITH tb_ult_fecha AS (
	SELECT 
		UltimaMarcaAgua
	FROM 
		ControlCarga
	WHERE 
		NombreProceso = 'ETL_VENTAS'
),

tb_datos_process AS (
	SELECT 
		*
	FROM 
		stg_ventas
	WHERE 
		COALESCE(FechaUltimaModificacionOrigen, FechaInsercionOrigen) > (SELECT UltimaMarcaAgua FROM tb_ult_fecha)
)

INSERT INTO tmp_stg_ventas_process
SELECT *
FROM tb_datos_process;