/*
¡¡ATENCIÓN!!:
ESTE LABORATORIO DE PRÁCTICA DE CARGA INCREMENTAL FUE ELABORADO POR CHATGPT, 
NO ES DE MI AUTORÍA, LO UTILICÉ PARA QUE ME BRINDE UNA CASUÍSTICA Y YO PODER RESOLVERLO.
LO QUE SI ES DE MI COMPLETA AUTORÍA ES LA SOLUCIÓN BRINDADA A LA CASUÍSTICA PRESENTADA,
ESTO SE VE DESARROLLADA EN LOS SIGUIENTES SCRIPTS DE ETL.
*/

SET NOCOUNT ON;

USE bd_ventas;
GO


/* ============================================================
   LIMPIEZA DEL ENTORNO
============================================================ */

DROP TABLE IF EXISTS dbo.stg_Ventas;
DROP TABLE IF EXISTS dbo.FactVentas;
DROP TABLE IF EXISTS dbo.DimCliente;
DROP TABLE IF EXISTS dbo.DimProducto;
DROP TABLE IF EXISTS dbo.DimTienda;
DROP TABLE IF EXISTS dbo.ControlCarga;
GO


/* ============================================================
   TABLA DE CONTROL
============================================================ */

CREATE TABLE dbo.ControlCarga
(
    NombreProceso          VARCHAR(100) NOT NULL,
    UltimaMarcaAgua        DATETIME2(3) NOT NULL,
    FechaUltimaEjecucion   DATETIME2(3) NULL,
    EstadoUltimaEjecucion  VARCHAR(20) NULL
);

INSERT INTO dbo.ControlCarga
(
    NombreProceso,
    UltimaMarcaAgua,
    FechaUltimaEjecucion,
    EstadoUltimaEjecucion
)
VALUES
(
    'ETL_VENTAS',
    '2026-09-29 08:00:00.000',
    '2026-09-29 08:00:00.000',
    'OK'
);
GO


/* ============================================================
   DIMENSIÓN CLIENTE

   HashKey:
   TipoDocumento | NumeroDocumento
============================================================ */

CREATE TABLE dbo.DimCliente
(
    ClienteHashKey                  BINARY(32) NOT NULL,

    TipoDocumento                   VARCHAR(10) NOT NULL,
    NumeroDocumento                 VARCHAR(20) NOT NULL,

    Nombres                         VARCHAR(100) NOT NULL,
    Apellidos                       VARCHAR(100) NOT NULL,
    Email                           VARCHAR(150) NULL,
    Telefono                        VARCHAR(20) NULL,
    Ciudad                          VARCHAR(100) NULL,
    EstadoCliente                   VARCHAR(20) NOT NULL,

    FechaInsercionOrigen            DATETIME2(3) NOT NULL,
    FechaUltimaModificacionOrigen   DATETIME2(3) NULL,

    FechaInsercionDW                DATETIME2(3) NOT NULL,
    FechaUltimaModificacionDW       DATETIME2(3) NULL
);


;WITH Clientes AS
(
    SELECT *
    FROM
    (
        VALUES
        (
            'DNI',
            '71234567',
            'ANA',
            'TORRES GARCIA',
            'ana@gmail.com',
            '987111222',
            'LIMA',
            'ACTIVO',
            CAST('2026-09-20 10:00:00.000' AS DATETIME2(3))
        ),
        (
            'DNI',
            '72345678',
            'LUIS',
            'MENDOZA PEREZ',
            'luis@gmail.com',
            '999111222',
            'AREQUIPA',
            'ACTIVO',
            CAST('2026-09-20 11:00:00.000' AS DATETIME2(3))
        ),
        (
            'CE',
            '00445566',
            'MARIA',
            'ROJAS DIAZ',
            'maria@gmail.com',
            '988555666',
            'TRUJILLO',
            'ACTIVO',
            CAST('2026-09-21 09:00:00.000' AS DATETIME2(3))
        )
    ) C
    (
        TipoDocumento,
        NumeroDocumento,
        Nombres,
        Apellidos,
        Email,
        Telefono,
        Ciudad,
        EstadoCliente,
        FechaInsercionOrigen
    )
)

INSERT INTO dbo.DimCliente
(
    ClienteHashKey,
    TipoDocumento,
    NumeroDocumento,
    Nombres,
    Apellidos,
    Email,
    Telefono,
    Ciudad,
    EstadoCliente,
    FechaInsercionOrigen,
    FechaUltimaModificacionOrigen,
    FechaInsercionDW,
    FechaUltimaModificacionDW
)
SELECT
    HASHBYTES
    (
        'SHA2_256',
        CONCAT
        (
            UPPER(LTRIM(RTRIM(TipoDocumento))),
            '|',
            UPPER(LTRIM(RTRIM(NumeroDocumento)))
        )
    ),

    TipoDocumento,
    NumeroDocumento,
    Nombres,
    Apellidos,
    Email,
    Telefono,
    Ciudad,
    EstadoCliente,

    FechaInsercionOrigen,
    NULL,

    '2026-09-21 23:00:00.000',
    NULL

FROM Clientes;
GO


/* ============================================================
   DIMENSIÓN PRODUCTO

   HashKey:
   CodigoProducto
============================================================ */

CREATE TABLE dbo.DimProducto
(
    ProductoHashKey                 BINARY(32) NOT NULL,

    CodigoProducto                  VARCHAR(30) NOT NULL,
    NombreProducto                  VARCHAR(150) NOT NULL,
    Categoria                       VARCHAR(100) NOT NULL,
    Subcategoria                    VARCHAR(100) NULL,
    Marca                           VARCHAR(100) NULL,
    PrecioLista                     DECIMAL(12,2) NOT NULL,
    EstadoProducto                  VARCHAR(20) NOT NULL,

    FechaInsercionOrigen            DATETIME2(3) NOT NULL,
    FechaUltimaModificacionOrigen   DATETIME2(3) NULL,

    FechaInsercionDW                DATETIME2(3) NOT NULL,
    FechaUltimaModificacionDW       DATETIME2(3) NULL
);


;WITH Productos AS
(
    SELECT *
    FROM
    (
        VALUES
        (
            'P100',
            'SMART TV SAMSUNG 55 QLED',
            'TELEVISORES',
            'SMART TV',
            'SAMSUNG',
            CAST(1899.90 AS DECIMAL(12,2)),
            'ACTIVO',
            CAST('2026-09-15 09:00:00.000' AS DATETIME2(3))
        ),
        (
            'P200',
            'CABLE HDMI 2M',
            'ACCESORIOS',
            'CABLES',
            'GENERICO',
            CAST(39.90 AS DECIMAL(12,2)),
            'ACTIVO',
            CAST('2026-09-15 09:10:00.000' AS DATETIME2(3))
        ),
        (
            'P300',
            'MOUSE LOGITECH M280',
            'COMPUTO',
            'MOUSE',
            'LOGITECH',
            CAST(89.90 AS DECIMAL(12,2)),
            'ACTIVO',
            CAST('2026-09-15 09:20:00.000' AS DATETIME2(3))
        )
    ) P
    (
        CodigoProducto,
        NombreProducto,
        Categoria,
        Subcategoria,
        Marca,
        PrecioLista,
        EstadoProducto,
        FechaInsercionOrigen
    )
)

INSERT INTO dbo.DimProducto
(
    ProductoHashKey,
    CodigoProducto,
    NombreProducto,
    Categoria,
    Subcategoria,
    Marca,
    PrecioLista,
    EstadoProducto,
    FechaInsercionOrigen,
    FechaUltimaModificacionOrigen,
    FechaInsercionDW,
    FechaUltimaModificacionDW
)
SELECT
    HASHBYTES
    (
        'SHA2_256',
        UPPER(LTRIM(RTRIM(CodigoProducto)))
    ),

    CodigoProducto,
    NombreProducto,
    Categoria,
    Subcategoria,
    Marca,
    PrecioLista,
    EstadoProducto,

    FechaInsercionOrigen,
    NULL,

    '2026-09-15 23:00:00.000',
    NULL

FROM Productos;
GO


/* ============================================================
   DIMENSIÓN TIENDA

   HashKey:
   CodigoTienda
============================================================ */

CREATE TABLE dbo.DimTienda
(
    TiendaHashKey                   BINARY(32) NOT NULL,

    CodigoTienda                    VARCHAR(20) NOT NULL,
    NombreTienda                    VARCHAR(150) NOT NULL,
    Ciudad                          VARCHAR(100) NOT NULL,
    Departamento                    VARCHAR(100) NOT NULL,
    TipoTienda                      VARCHAR(30) NOT NULL,
    EstadoTienda                    VARCHAR(20) NOT NULL,

    FechaInsercionOrigen            DATETIME2(3) NOT NULL,
    FechaUltimaModificacionOrigen   DATETIME2(3) NULL,

    FechaInsercionDW                DATETIME2(3) NOT NULL,
    FechaUltimaModificacionDW       DATETIME2(3) NULL
);


;WITH Tiendas AS
(
    SELECT *
    FROM
    (
        VALUES
        (
            'LIM01',
            'TIENDA LIMA CENTRO',
            'LIMA',
            'LIMA',
            'FISICA',
            'ACTIVO',
            CAST('2026-01-10 08:00:00.000' AS DATETIME2(3))
        ),
        (
            'AQP01',
            'TIENDA AREQUIPA MALL',
            'AREQUIPA',
            'AREQUIPA',
            'FISICA',
            'ACTIVO',
            CAST('2026-02-15 08:00:00.000' AS DATETIME2(3))
        )
    ) T
    (
        CodigoTienda,
        NombreTienda,
        Ciudad,
        Departamento,
        TipoTienda,
        EstadoTienda,
        FechaInsercionOrigen
    )
)

INSERT INTO dbo.DimTienda
(
    TiendaHashKey,
    CodigoTienda,
    NombreTienda,
    Ciudad,
    Departamento,
    TipoTienda,
    EstadoTienda,
    FechaInsercionOrigen,
    FechaUltimaModificacionOrigen,
    FechaInsercionDW,
    FechaUltimaModificacionDW
)
SELECT
    HASHBYTES
    (
        'SHA2_256',
        UPPER(LTRIM(RTRIM(CodigoTienda)))
    ),

    CodigoTienda,
    NombreTienda,
    Ciudad,
    Departamento,
    TipoTienda,
    EstadoTienda,

    FechaInsercionOrigen,
    NULL,

    '2026-02-15 23:00:00.000',
    NULL

FROM Tiendas;
GO


/* ============================================================
   TABLA DE HECHOS

   Granularidad:
   Una fila por producto dentro de cada ticket.

   HashKey:
   FechaVenta | CodigoTienda | NumeroTicket | NumeroLinea
============================================================ */

CREATE TABLE dbo.FactVentas
(
    VentaHashKey                    BINARY(32) NOT NULL,

    FechaVenta                      DATE NOT NULL,
    CodigoTienda                    VARCHAR(20) NOT NULL,
    NumeroTicket                    VARCHAR(30) NOT NULL,
    NumeroLinea                     INT NOT NULL,

    ClienteHashKey                  BINARY(32) NOT NULL,
    ProductoHashKey                 BINARY(32) NOT NULL,
    TiendaHashKey                   BINARY(32) NOT NULL,

    Cantidad                        INT NOT NULL,
    PrecioUnitario                  DECIMAL(12,2) NOT NULL,

    MontoBruto                      DECIMAL(14,2) NOT NULL,
    MontoDescuento                  DECIMAL(14,2) NOT NULL,
    MontoNeto                       DECIMAL(14,2) NOT NULL,

    Canal                           VARCHAR(30) NOT NULL,
    MedioPago                       VARCHAR(30) NOT NULL,
    EstadoVenta                     VARCHAR(30) NOT NULL,

    FechaInsercionOrigen            DATETIME2(3) NOT NULL,
    FechaUltimaModificacionOrigen   DATETIME2(3) NULL,

    FechaInsercionDW                DATETIME2(3) NOT NULL,
    FechaUltimaModificacionDW       DATETIME2(3) NULL
);


;WITH Ventas AS
(
    SELECT *
    FROM
    (
        VALUES
        (
            CAST('2026-09-28' AS DATE),
            'LIM01',
            'T0001001',
            1,
            'DNI',
            '71234567',
            'P100',
            1,
            CAST(1800.00 AS DECIMAL(12,2)),
            CAST(100.00 AS DECIMAL(14,2)),
            'TIENDA',
            'TARJETA',
            'COMPLETADA',
            CAST('2026-09-28 10:00:00.000' AS DATETIME2(3))
        ),
        (
            CAST('2026-09-28' AS DATE),
            'LIM01',
            'T0001001',
            2,
            'DNI',
            '71234567',
            'P200',
            2,
            CAST(35.00 AS DECIMAL(12,2)),
            CAST(0.00 AS DECIMAL(14,2)),
            'TIENDA',
            'TARJETA',
            'COMPLETADA',
            CAST('2026-09-28 10:00:00.000' AS DATETIME2(3))
        ),
        (
            CAST('2026-09-28' AS DATE),
            'LIM01',
            'T0001002',
            1,
            'DNI',
            '72345678',
            'P300',
            1,
            CAST(85.00 AS DECIMAL(12,2)),
            CAST(5.00 AS DECIMAL(14,2)),
            'WEB',
            'YAPE',
            'COMPLETADA',
            CAST('2026-09-28 11:00:00.000' AS DATETIME2(3))
        ),
        (
            CAST('2026-09-28' AS DATE),
            'AQP01',
            'T0002001',
            1,
            'CE',
            '00445566',
            'P100',
            1,
            CAST(1750.00 AS DECIMAL(12,2)),
            CAST(50.00 AS DECIMAL(14,2)),
            'TIENDA',
            'TARJETA',
            'COMPLETADA',
            CAST('2026-09-28 12:00:00.000' AS DATETIME2(3))
        )
    ) V
    (
        FechaVenta,
        CodigoTienda,
        NumeroTicket,
        NumeroLinea,
        TipoDocumento,
        NumeroDocumento,
        CodigoProducto,
        Cantidad,
        PrecioUnitario,
        MontoDescuento,
        Canal,
        MedioPago,
        EstadoVenta,
        FechaInsercionOrigen
    )
)

INSERT INTO dbo.FactVentas
(
    VentaHashKey,
    FechaVenta,
    CodigoTienda,
    NumeroTicket,
    NumeroLinea,
    ClienteHashKey,
    ProductoHashKey,
    TiendaHashKey,
    Cantidad,
    PrecioUnitario,
    MontoBruto,
    MontoDescuento,
    MontoNeto,
    Canal,
    MedioPago,
    EstadoVenta,
    FechaInsercionOrigen,
    FechaUltimaModificacionOrigen,
    FechaInsercionDW,
    FechaUltimaModificacionDW
)
SELECT
    HASHBYTES
    (
        'SHA2_256',
        CONCAT
        (
            CONVERT(VARCHAR(10), V.FechaVenta, 23),
            '|',
            UPPER(LTRIM(RTRIM(V.CodigoTienda))),
            '|',
            UPPER(LTRIM(RTRIM(V.NumeroTicket))),
            '|',
            V.NumeroLinea
        )
    ),

    V.FechaVenta,
    V.CodigoTienda,
    V.NumeroTicket,
    V.NumeroLinea,

    C.ClienteHashKey,
    P.ProductoHashKey,
    T.TiendaHashKey,

    V.Cantidad,
    V.PrecioUnitario,

    V.Cantidad * V.PrecioUnitario,
    V.MontoDescuento,
    (V.Cantidad * V.PrecioUnitario) - V.MontoDescuento,

    V.Canal,
    V.MedioPago,
    V.EstadoVenta,

    V.FechaInsercionOrigen,
    NULL,

    '2026-09-28 22:00:00.000',
    NULL

FROM Ventas V

INNER JOIN dbo.DimCliente C
    ON C.TipoDocumento = V.TipoDocumento
   AND C.NumeroDocumento = V.NumeroDocumento

INNER JOIN dbo.DimProducto P
    ON P.CodigoProducto = V.CodigoProducto

INNER JOIN dbo.DimTienda T
    ON T.CodigoTienda = V.CodigoTienda;
GO


/* ============================================================
   STAGING
============================================================ */

CREATE TABLE dbo.stg_Ventas
(
    FechaVenta                      DATE NOT NULL,
    CodigoTienda                    VARCHAR(20) NOT NULL,
    NumeroTicket                    VARCHAR(30) NOT NULL,
    NumeroLinea                     INT NOT NULL,

    TipoDocumento                   VARCHAR(10) NOT NULL,
    NumeroDocumento                 VARCHAR(20) NOT NULL,

    Nombres                         VARCHAR(100) NOT NULL,
    Apellidos                       VARCHAR(100) NOT NULL,
    Email                           VARCHAR(150) NULL,
    Telefono                        VARCHAR(20) NULL,
    CiudadCliente                   VARCHAR(100) NULL,
    EstadoCliente                   VARCHAR(20) NOT NULL,

    CodigoProducto                  VARCHAR(30) NOT NULL,
    NombreProducto                  VARCHAR(150) NOT NULL,
    Categoria                       VARCHAR(100) NOT NULL,
    Subcategoria                    VARCHAR(100) NULL,
    Marca                           VARCHAR(100) NULL,
    PrecioLista                     DECIMAL(12,2) NOT NULL,
    EstadoProducto                  VARCHAR(20) NOT NULL,

    NombreTienda                    VARCHAR(150) NOT NULL,
    CiudadTienda                    VARCHAR(100) NOT NULL,
    DepartamentoTienda              VARCHAR(100) NOT NULL,
    TipoTienda                      VARCHAR(30) NOT NULL,
    EstadoTienda                    VARCHAR(20) NOT NULL,

    Cantidad                        INT NOT NULL,
    PrecioUnitario                  DECIMAL(12,2) NOT NULL,
    MontoDescuento                  DECIMAL(14,2) NOT NULL,

    Canal                           VARCHAR(30) NOT NULL,
    MedioPago                       VARCHAR(30) NOT NULL,
    EstadoVenta                     VARCHAR(30) NOT NULL,

    FechaInsercionOrigen            DATETIME2(3) NOT NULL,
    FechaUltimaModificacionOrigen   DATETIME2(3) NULL
);
GO


/* ============================================================
   DATOS DE STAGING
============================================================ */

INSERT INTO dbo.stg_Ventas
VALUES

(
    '2026-09-28',
    'AQP01',
    'T0002001',
    1,

    'CE',
    '00445566',
    'MARIA',
    'ROJAS DIAZ',
    'maria@gmail.com',
    '988555666',
    'TRUJILLO',
    'ACTIVO',

    'P100',
    'SMART TV SAMSUNG 55 QLED',
    'TELEVISORES',
    'SMART TV',
    'SAMSUNG',
    1899.90,
    'ACTIVO',

    'TIENDA AREQUIPA MALL',
    'AREQUIPA',
    'AREQUIPA',
    'FISICA',
    'ACTIVO',

    1,
    1750.00,
    50.00,

    'TIENDA',
    'TARJETA',
    'COMPLETADA',

    '2026-09-28 12:00:00.000',
    '2026-09-29 07:40:00.000'
),

(
    '2026-09-28',
    'LIM01',
    'T0001001',
    1,

    'DNI',
    '71234567',
    'ANA',
    'TORRES GARCIA',
    'ana@gmail.com',
    '987111222',
    'LIMA',
    'ACTIVO',

    'P100',
    'SMART TV SAMSUNG 55 QLED',
    'TELEVISORES',
    'SMART TV',
    'SAMSUNG',
    1899.90,
    'ACTIVO',

    'TIENDA LIMA CENTRO',
    'LIMA',
    'LIMA',
    'FISICA',
    'ACTIVO',

    1,
    1800.00,
    100.00,

    'TIENDA',
    'TARJETA',
    'COMPLETADA',

    '2026-09-28 10:00:00.000',
    '2026-09-29 08:10:00.000'
),

(
    '2026-09-28',
    'LIM01',
    'T0001001',
    2,

    'DNI',
    '71234567',
    'ANA',
    'TORRES GARCIA',
    'ana@gmail.com',
    '987111222',
    'LIMA',
    'ACTIVO',

    'P200',
    'CABLE HDMI 2.1 2M',
    'ACCESORIOS',
    'CABLES',
    'GENERICO',
    44.90,
    'ACTIVO',

    'TIENDA LIMA CENTRO',
    'LIMA',
    'LIMA',
    'FISICA',
    'ACTIVO',

    3,
    35.00,
    5.00,

    'TIENDA',
    'TARJETA',
    'COMPLETADA',

    '2026-09-28 10:00:00.000',
    '2026-09-29 08:20:00.000'
),

(
    '2026-09-28',
    'LIM01',
    'T0001002',
    1,

    'DNI',
    '72345678',
    'LUIS',
    'MENDOZA PEREZ',
    'luis.mendoza@gmail.com',
    '999555444',
    'AREQUIPA',
    'ACTIVO',

    'P300',
    'MOUSE LOGITECH M280',
    'COMPUTO',
    'MOUSE',
    'LOGITECH',
    89.90,
    'ACTIVO',

    'TIENDA LIMA CENTRO',
    'LIMA',
    'LIMA',
    'FISICA',
    'ACTIVO',

    1,
    85.00,
    5.00,

    'WEB',
    'YAPE',
    'COMPLETADA',

    '2026-09-28 11:00:00.000',
    '2026-09-29 08:30:00.000'
),

(
    '2026-09-29',
    'AQP01',
    'T0002002',
    1,

    'CE',
    '00445566',
    'MARIA',
    'ROJAS DIAZ',
    'maria@gmail.com',
    '988555666',
    'TRUJILLO',
    'ACTIVO',

    'P100',
    'SMART TV SAMSUNG 55 QLED',
    'TELEVISORES',
    'SMART TV',
    'SAMSUNG',
    1899.90,
    'ACTIVO',

    'TIENDA AREQUIPA MALL',
    'AREQUIPA',
    'AREQUIPA',
    'FISICA',
    'ACTIVO',

    1,
    1790.00,
    90.00,

    'TIENDA',
    'TARJETA',
    'COMPLETADA',

    '2026-09-29 09:00:00.000',
    NULL
),

(
    '2026-09-29',
    'LIM01',
    'T0001004',
    1,

    'DNI',
    '74567890',
    'DIEGO',
    'SALAZAR FLORES',
    'diego@gmail.com',
    '977888999',
    'LIMA',
    'ACTIVO',

    'P300',
    'MOUSE LOGITECH M280',
    'COMPUTO',
    'MOUSE',
    'LOGITECH',
    89.90,
    'ACTIVO',

    'TIENDA LIMA CENTRO',
    'LIMA',
    'LIMA',
    'FISICA',
    'ACTIVO',

    1,
    85.00,
    0.00,

    'WEB',
    'YAPE',
    'COMPLETADA',

    '2026-09-29 09:15:00.000',
    NULL
),

(
    '2026-09-29',
    'LIM01',
    'T0001005',
    1,

    'CE',
    '00445566',
    'MARIA',
    'ROJAS DIAZ',
    'maria@gmail.com',
    '988555666',
    'TRUJILLO',
    'ACTIVO',

    'P400',
    'TECLADO MECANICO REDRAGON K552',
    'COMPUTO',
    'TECLADOS',
    'REDRAGON',
    199.90,
    'ACTIVO',

    'TIENDA LIMA CENTRO',
    'LIMA',
    'LIMA',
    'FISICA',
    'ACTIVO',

    1,
    189.90,
    10.00,

    'WEB',
    'TARJETA',
    'COMPLETADA',

    '2026-09-29 09:30:00.000',
    NULL
),

(
    '2026-09-29',
    'CUS01',
    'T0003001',
    1,

    'DNI',
    '71234567',
    'ANA',
    'TORRES GARCIA',
    'ana@gmail.com',
    '987111222',
    'LIMA',
    'ACTIVO',

    'P200',
    'CABLE HDMI 2.1 2M',
    'ACCESORIOS',
    'CABLES',
    'GENERICO',
    44.90,
    'ACTIVO',

    'TIENDA CUSCO CENTRO',
    'CUSCO',
    'CUSCO',
    'FISICA',
    'ACTIVO',

    2,
    39.90,
    0.00,

    'TIENDA',
    'EFECTIVO',
    'COMPLETADA',

    '2026-09-29 09:45:00.000',
    NULL
);
GO