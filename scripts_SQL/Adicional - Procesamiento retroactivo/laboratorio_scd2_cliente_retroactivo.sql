/*
LABORATORIO SCD2 - CLIENTES (SIN SOLUCION)
SQL Server 2017+

Objetivo: practicar watermark, limpieza, hash de cliente,
INNER JOIN + UPDATE, LEFT JOIN + INSERT y LEAD + UPDATE.

Casos del ejercicio:
- Cliente sin cambios
- Cliente nuevo
- Correccion de una version historica existente
- Version historica que llega atrasada
- Cliente que regresa a una ciudad anterior
- Varias versiones de un mismo cliente en un lote

SUPUESTOS:
- FechaCambioCliente indica desde cuando rige esa version del cliente.
- Es distinta para cada version de un mismo cliente.
- El archivo recibido es fuente autorizada de correcciones historicas.
- No hay conflictos, valores obligatorios nulos ni cambios simultaneos.
- FechaInsercionOrigen / FechaUltimaModificacionOrigen sirven al watermark,
  no a la fecha de vigencia SCD2.
- Hash estable = SHA2_256(UPPER(TRIM(TipoDocumento)) + '|' +
                      UPPER(TRIM(NumeroDocumento))).
- No incluyas la ciudad en el hash.

Este script SOLO crea datos para la practica: no resuelve el ETL.
ADVERTENCIA: reinicia estas tres tablas del esquema LabSCD2.
*/

IF SCHEMA_ID('LabSCD2') IS NULL
    EXEC('CREATE SCHEMA LabSCD2');
GO

DROP TABLE IF EXISTS LabSCD2.VentasOrigen;
DROP TABLE IF EXISTS LabSCD2.DimCliente;
DROP TABLE IF EXISTS LabSCD2.ControlCarga;
GO

-- 1. TABLAS
CREATE TABLE LabSCD2.VentasOrigen (
    VentaID VARCHAR(10) NOT NULL PRIMARY KEY,
    FechaVenta DATE NOT NULL,
    TipoDocumento VARCHAR(10) NOT NULL,
    NumeroDocumento VARCHAR(20) NOT NULL,
    Nombres VARCHAR(80) NOT NULL,
    Apellidos VARCHAR(80) NULL,
    CiudadCliente VARCHAR(60) NOT NULL,
    FechaCambioCliente DATETIME2(0) NOT NULL,
    FechaInsercionOrigen DATETIME2(0) NOT NULL,
    FechaUltimaModificacionOrigen DATETIME2(0) NULL,
    Producto VARCHAR(50) NOT NULL,
    Importe DECIMAL(12,2) NOT NULL
);

CREATE TABLE LabSCD2.DimCliente (
    ClienteSK INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ClienteHashKey BINARY(32) NOT NULL,
    TipoDocumento VARCHAR(10) NOT NULL,
    NumeroDocumento VARCHAR(20) NOT NULL,
    Nombres VARCHAR(80) NOT NULL,
    Apellidos VARCHAR(80) NULL,
    Ciudad VARCHAR(60) NOT NULL,
    FechaInicioVigencia DATETIME2(0) NOT NULL,
    FechaFinVigencia DATETIME2(0) NOT NULL,
    EsActual BIT NOT NULL,
    FechaInsercionDW DATETIME2(0) NOT NULL,
    FechaUltimaModificacionDW DATETIME2(0) NULL,
    CONSTRAINT CK_LabSCD2_Fecha CHECK (FechaInicioVigencia < FechaFinVigencia)
);

CREATE TABLE LabSCD2.ControlCarga (
    NombreProceso VARCHAR(100) NOT NULL PRIMARY KEY,
    UltimaMarcaAgua DATETIME2(0) NOT NULL
);

CREATE UNIQUE NONCLUSTERED INDEX IX_Cliente_Periodo
ON LabSCD2.DimCliente (ClienteHashKey, FechaInicioVigencia);

-- 2. MARCA DE AGUA
INSERT INTO LabSCD2.ControlCarga (NombreProceso, UltimaMarcaAgua)
VALUES ('ETL_Clientes', '2026-10-01T00:00:00');

-- 3. DIMENSION YA CARGADA (HISTORIAL INICIAL)
INSERT INTO LabSCD2.DimCliente (
    ClienteHashKey, TipoDocumento, NumeroDocumento, Nombres, Apellidos,
    Ciudad, FechaInicioVigencia, FechaFinVigencia,
    EsActual, FechaInsercionDW
)
SELECT
    CONVERT(BINARY(32), HASHBYTES('SHA2_256',
        CONCAT(UPPER(TRIM(x.TipoDocumento)), '|', UPPER(TRIM(x.NumeroDocumento))))),
    x.TipoDocumento, x.NumeroDocumento, x.Nombres, x.Apellidos, x.Ciudad,
    CONVERT(DATETIME2(0), x.FechaInicio),
    CONVERT(DATETIME2(0), x.FechaFin),
    x.EsActual, '2026-09-30T09:00:00'
FROM (VALUES
    ('DNI','70000001','Rosa','Quispe','HUARAZ',  '2026-01-01T00:00:00','2026-03-01T00:00:00',0),
    ('DNI','70000001','Rosa','Quispe','LIMA',    '2026-03-01T00:00:00','2026-06-01T00:00:00',0),
    ('DNI','70000001','Rosa','Quispe','TRUJILLO','2026-06-01T00:00:00','9999-12-31T23:59:59',1),
    ('RUC','20123456789','Distribuidora Pacifico',NULL,'PIURA','2026-02-01T00:00:00','9999-12-31T23:59:59',1),
    ('DNI','70000003','Jose','Soto','TACNA',    '2026-02-10T00:00:00','9999-12-31T23:59:59',1)
) AS x (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Ciudad,
        FechaInicio, FechaFin, EsActual);

-- 4. TABLA PLANA DE VENTAS (LOTE DE PRUEBA)
INSERT INTO LabSCD2.VentasOrigen (
    VentaID, FechaVenta, TipoDocumento, NumeroDocumento, Nombres, Apellidos,
    CiudadCliente, FechaCambioCliente,
    FechaInsercionOrigen, FechaUltimaModificacionOrigen,
    Producto, Importe
)
VALUES
    ('V001','2026-01-15',' dni ',' 70000001 ','Rosa','Quispe',' Arequipa ',
     '2026-01-01T00:00:00','2026-10-05T09:00:00',NULL,'Arroz',42.50),
    ('V002','2026-01-16','DNI','70000001','Rosa','Quispe','AREQUIPA',
     '2026-01-01T00:00:00','2026-10-05T09:01:00',NULL,'Aceite',28.00),
    ('V003','2026-03-15','DNI','70000001','Rosa','Quispe','LIMA',
     '2026-03-01T00:00:00','2026-10-05T09:02:00',NULL,'Azucar',36.00),
    ('V004','2026-04-20','DNI','70000001','Rosa','Quispe','CUSCO',
     '2026-04-15T00:00:00','2026-10-05T09:03:00',NULL,'Leche',23.90),
    ('V005','2026-06-20','DNI','70000001','Rosa','Quispe','TRUJILLO',
     '2026-06-01T00:00:00','2026-10-05T09:04:00',NULL,'Harina',19.80),
    ('V006','2026-08-15','DNI','70000001','Rosa','Quispe','LIMA',
     '2026-08-01T00:00:00','2026-10-05T09:05:00',NULL,'Fideos',31.40),
    ('V007','2026-02-20','RUC','20123456789','Distribuidora Pacifico',NULL,'PIURA',
     '2026-02-01T00:00:00','2026-10-06T10:00:00',NULL,'Arroz',430.00),
    ('V008','2026-05-20','RUC','20123456789','Distribuidora Pacifico',NULL,'CHICLAYO',
     '2026-05-10T00:00:00','2026-10-06T10:01:00',NULL,'Aceite',290.00),
    ('V009','2026-09-30','DNI','70000003','Jose','Soto','TACNA',
     '2026-02-10T00:00:00','2026-10-07T11:00:00',NULL,'Leche',40.00),
    ('V010','2026-07-15','DNI','70000004','Ana','Campos','PIURA',
     '2026-07-01T00:00:00','2026-10-07T11:01:00',NULL,'Aceite',52.00),
    ('V011','2026-09-10','DNI','70000004','Ana','Campos','CUSCO',
     '2026-09-01T00:00:00','2026-10-07T11:02:00',NULL,'Arroz',61.50),
    -- Registro anterior al watermark: no corresponde al lote incremental.
    ('V012','2026-09-15','DNI','70000003','Jose','Soto','TACNA',
     '2026-02-10T00:00:00','2026-09-20T08:00:00',NULL,'Aceite',17.50),
    -- Registro antiguo, pero modificado despues del watermark.
    ('V013','2026-09-15','DNI','70000003','Jose','Soto','TACNA',
     '2026-02-10T00:00:00','2026-09-20T08:05:00',
     '2026-10-10T12:00:00','Leche',20.00);

-- 5. VERIFICAR LOS DATOS ANTES DE COMENZAR
SELECT * FROM LabSCD2.ControlCarga;

SELECT VentaID, TipoDocumento, NumeroDocumento, CiudadCliente,
       FechaCambioCliente, FechaInsercionOrigen, FechaUltimaModificacionOrigen
FROM LabSCD2.VentasOrigen
ORDER BY VentaID;

SELECT ClienteSK, TipoDocumento, NumeroDocumento, Ciudad,
       FechaInicioVigencia, FechaFinVigencia, EsActual
FROM LabSCD2.DimCliente
ORDER BY NumeroDocumento, FechaInicioVigencia;