/*
======================
1. Definimos el conjunto de datos a procesar: 
Se utiliza el watermark para poder filtrar los nuevos datos provinientes del nuevo lote del origen de datos.
======================
*/

--FECHA Y HORA DEL PROCESO
DECLARE @FechaHoraActual DATETIME = GETDATE();

DROP TABLE IF EXISTS #tmp_stg_process;
DROP TABLE IF EXISTS #tmp_dimcliente_process;
DROP TABLE IF EXISTS #tmp_clientesinsertados;

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
    COALESCE(cli.Apellidos, '') <> COALESCE(tmp.Apellidos, '') OR
    cli.Ciudad <> tmp.CiudadCliente;

--2.2. IDENTIFCACIÓN DE NUEVOS CLIENTES O VERSIONES DE CLIENTES YA EXISTENTES PERO CUYAS VERSIONES NO SE ENCUENTRAN EN LA DIMENSIÓN

--2.2.1. INSERCIÓN DE NUEVOS CLIENTES O VERSIONES NUEVAS DE CLIENTES YA EXISTENTES
--Se añade también proceso de captura de los clientes insertados en una tb tmp
CREATE TABLE #tmp_clientesinsertados (
    HashKeyCliente BINARY(32) not null
);

INSERT INTO LabSCD2.DimCliente (
    ClienteHashKey,
    TipoDocumento,
    NumeroDocumento,
    Nombres,
    Apellidos,
    Ciudad,
    FechaInicioVigencia,
    FechaFinVigencia,
    EsActual,
    FechaInsercionDW,
    FechaUltimaModificacionDW
)

--Capturamos a los clientes insertados
OUTPUT inserted.ClienteHashKey
INTO #tmp_clientesinsertados(HashKeyCliente)

SELECT 
    tmp.HashKeyCliente,
    tmp.TipoDocumento,
    tmp.NumeroDocumento,
    tmp.Nombres,
    tmp.Apellidos,
    tmp.CiudadCliente,
    tmp.FechaCambioCliente,
   '9999-12-31' AS FechaFinVigencia,
   0 AS EsActual,
   @FechaHoraActual AS FechaInsercionDW,
   null AS FechaUltimaModificacionDW
FROM 
    LabSCD2.DimCliente AS cli
RIGHT JOIN 
    #tmp_dimcliente_process AS tmp
ON 
    cli.ClienteHashKey = tmp.HashKeyCliente AND 
    cli.FechaInicioVigencia = tmp.FechaCambioCliente
WHERE
    cli.ClienteHashKey IS NULL;

--IDENTIFICACIÓN DE LOS CLIENTES INSERTADOS Y MODIFICACIÓN DE FECHAS DE VIGENCIA FINAL Y ESTADO ACTUAL:
WITH 
tb_clientes_insertados_unicos AS (
    SELECT DISTINCT
        HashKeyCliente
    FROM 
        #tmp_clientesinsertados
),
tb_dim_cliente_pre AS (
    SELECT 
        *
    FROM 
        LabSCD2.DimCliente AS dim
    INNER JOIN 
        tb_clientes_insertados_unicos AS cliu
    ON 
        dim.ClienteHashKey = cliu.HashKeyCliente
), 
tb_dimcliente3 AS (
    SELECT 
        *,
        LEAD(FechaInicioVigencia) OVER(
            PARTITION BY HashKeyCliente
            ORDER BY FechaInicioVigencia ASC
        ) AS VerificacionUltimaVersion
    FROM 
        tb_dim_cliente_pre
), 
tb_dimcliente_recal AS (
    SELECT 
        *,
        COALESCE(VerificacionUltimaVersion, '9999-12-31 23:59:59') AS NuevaFechaFinVigencia,
        CASE
            WHEN VerificacionUltimaVersion IS NULL
                THEN 1
            ELSE 0
        END AS EstadoActual
    FROM tb_dimcliente3
)

UPDATE dim
SET
    dim.FechaFinVigencia = re.NuevaFechaFinVigencia,
    dim.EsActual = re.EstadoActual,
    dim.FechaUltimaModificacionDW = @FechaHoraActual
FROM 
    LabSCD2.DimCliente AS dim
INNER JOIN 
    tb_dimcliente_recal AS re
ON 
    dim.ClienteSK = re.ClienteSK
WHERE
    dim.FechaFinVigencia <> re.NuevaFechaFinVigencia OR
    dim.EsActual <> re.EstadoActual;

--LIMPIEZA DE TABLAS TEMPORALES
DROP TABLE IF EXISTS #tmp_stg_process;
DROP TABLE IF EXISTS #tmp_dimcliente_process;
DROP TABLE IF EXISTS #tmp_clientesinsertados;


/*
========================================================
EJERCICIO FINALIZADO
========================================================
*/