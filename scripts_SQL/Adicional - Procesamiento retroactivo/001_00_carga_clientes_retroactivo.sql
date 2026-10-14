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
    TRIM(CiudadCliente) AS CiudadCliente,
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
    TipoDocumento,
    NumeroDocumento,
    Nombres,
    Apellidos,
    CiudadCliente,
    FechaCambioCliente
INTO #tmp_dimcliente_process
FROM 
    #tmp_stg_process;

SELECT *
FROM #tmp_dimcliente_process;

SELECT *
FROM LabSCD2.DimCliente;

DROP TABLE IF EXISTS #tmp_stg_process;
DROP TABLE IF EXISTS #tmp_dimcliente_process;