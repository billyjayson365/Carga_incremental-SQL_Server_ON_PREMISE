/*
======================
1. Definimos el conjunto de datos a procesar: 
Se utiliza el watermark para poder filtrar los nuevos datos provinientes del nuevo lote del origen de datos.
======================
*/

DROP TABLE IF EXISTS #tmp_stg_process;


SELECT
    VentaID,
    FechaVenta,
    UPPER(TRIM(TipoDocumento)) AS TipoDocumento,
    TRIM(NumeroDocumento),
    TRIM(Nombres),
    TRIM(Apellidos),
    TRIM(CiudadCliente),
    FechaCambioCliente,
    FechaInsercionOrigen,
    FechaUltimaModificacionOrigen,
    Producto,
    Importe
FROM 
    LabSCD2.VentasOrigen
WHERE 
    COALESCE(FechaInsercionOrigen, FechaUltimaModificacionOrigen) >= (SELECT UltimaMarcaAgua FROM LabSCD2.ControlCarga)