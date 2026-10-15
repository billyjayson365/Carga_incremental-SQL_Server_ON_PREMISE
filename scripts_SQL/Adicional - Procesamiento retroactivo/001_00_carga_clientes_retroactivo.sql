/*
======================
1. Definimos el conjunto de datos a procesar: 
Se utiliza el watermark para poder filtrar los nuevos datos provinientes del nuevo lote del origen de datos.
======================
*/

DROP TABLE IF EXISTS #tmp_stg_process;
DROP TABLE IF EXISTS #tmp_dimcliente_process;

--SE CREA LA TABLA TEMPORAL DEL CONJUNTO DE DATOS A PROCESAR
SELECT
    VentaID,
    FechaVenta,
    UPPER(TRIM(TipoDocumento)) AS TipoDocumento,
    TRIM(NumeroDocumento) AS NumeroDocumento,
    TRIM(Nombres) AS Nombres,
    TRIM(Apellidos) AS Apellidos,
    UPPER(TRIM(CiudadCliente)) AS CiudadCliente,
    FechaCambioCliente,
    FechaInsercionOrigen,
    FechaUltimaModificacionOrigen,
    Producto,
    Importe
INTO #tmp_stg_process
FROM 
    LabSCD2.VentasOrigen
WHERE 
    COALESCE(FechaUltimaModificacionOrigen, FechaInsercionOrigen) >= (SELECT UltimaMarcaAgua FROM LabSCD2.ControlCarga);

/*
=====================================
2. PROCESAMIENTO DE LA DIM CLIENTES
=====================================
*/

SELECT DISTINCT
    HASHBYTES('SHA2_256', CONCAT(TipoDocumento, '|', NumeroDocumento)) AS HashKeyCliente,
    TipoDocumento,
    NumeroDocumento,
    Nombres,
    Apellidos,
    CiudadCliente,
    FechaCambioCliente
INTO #tmp_dimcliente_process
FROM 
    #tmp_stg_process;


--2.1. CRUCE PARA ENCONTRAR AQUELLOS CLIENTES QUE EXISTEN Y TIENEN MODIFICACIONES: 
--Se realiza alguna corrección de algún atributo en caso lo haya.

UPDATE cli 
SET
    cli.Nombres = tmp.Nombres,
    cli.Apellidos = tmp.Apellidos,
    cli.Ciudad = tmp.CiudadCliente,
    cli.FechaUltimaModificacionDW = GETDATE()
FROM 
    LabSCD2.DimCliente AS cli
INNER JOIN 
    #tmp_dimcliente_process AS tmp
ON 
    cli.ClienteHashKey = tmp.HashKeyCliente AND 
    cli.FechaInicioVigencia = tmp.FechaCambioCliente
WHERE
    cli.Nombres <> tmp.Nombres OR
    cli.Apellidos <> tmp.Apellidos OR
    cli.Ciudad <> tmp.CiudadCliente

--LIMPIEZA DE TABLAS TEMPORALES
DROP TABLE IF EXISTS #tmp_stg_process;
DROP TABLE IF EXISTS #tmp_dimcliente_process;