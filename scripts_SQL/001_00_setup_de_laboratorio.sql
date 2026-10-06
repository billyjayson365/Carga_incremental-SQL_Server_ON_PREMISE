/*
¡¡ATENCIÓN!!:
ESTE LABORATORIO DE PRÁCTICA DE CARGA INCREMENTAL FUE ELABORADO POR CHATGPT, 
NO ES DE MI AUTORÍA, LO UTILICÉ PARA QUE ME BRINDE UNA CASUÍSTICA Y YO PODER RESOLVERLO.
LO QUE SI ES DE MI COMPLETA AUTORÍA ES LA SOLUCIÓN BRINDADA A LA CASUÍSTICA PRESENTADA,
ESTO SE VE DESARROLLADA EN LOS SIGUIENTES SCRIPTS DE ETL.
*/

SET NOCOUNT ON;

DROP TABLE IF EXISTS dbo.tmp_stg_Ventas_process;
DROP TABLE IF EXISTS dbo.stg_Ventas;
DROP TABLE IF EXISTS dbo.FactVentas;
DROP TABLE IF EXISTS dbo.DimCliente;
DROP TABLE IF EXISTS dbo.DimProducto;
DROP TABLE IF EXISTS dbo.DimTienda;
DROP TABLE IF EXISTS dbo.ControlCarga;

DROP TABLE IF EXISTS #ClienteCatalogo;
DROP TABLE IF EXISTS #ProductoCatalogo;
DROP TABLE IF EXISTS #TiendaCatalogo;


/*
==================================================
CREACIÓN DE TABLAS TEMPORALES CON DATOS SIMULADOS
==================================================
*/


--AUXILIAR CLIENTES

CREATE TABLE #ClienteCatalogo
(
    IdCliente          INT NOT NULL,
    TipoDocumento      VARCHAR(10) NOT NULL,
    NumeroDocumento    VARCHAR(20) NOT NULL,
    Nombres            VARCHAR(100) NOT NULL,
    Apellidos          VARCHAR(100) NOT NULL,
    Email              VARCHAR(150) NULL,
    Telefono           VARCHAR(20) NULL,
    Ciudad             VARCHAR(100) NULL,
    EstadoCliente      VARCHAR(20) NOT NULL
);


;WITH Numeros AS
(
    SELECT 1 AS N

    UNION ALL

    SELECT N + 1
    FROM Numeros
    WHERE N < 130
),

Clientes AS
(
    SELECT
        N,

        CHOOSE(
            ((N - 1) % 20) + 1,
            'ANA',
            'LUIS',
            'MARIA',
            'CARLOS',
            'DIEGO',
            'SOFIA',
            'JORGE',
            'CAMILA',
            'MIGUEL',
            'VALERIA',
            'ANDREA',
            'RENATO',
            'PAOLA',
            'FERNANDO',
            'DANIELA',
            'RICARDO',
            'LUCIANA',
            'SEBASTIAN',
            'MELISSA',
            'ALONSO'
        ) AS Nombres,

        CHOOSE(
            (((N * 3) - 1) % 17) + 1,
            'TORRES',
            'MENDOZA',
            'ROJAS',
            'SALAZAR',
            'FLORES',
            'RAMIREZ',
            'CASTILLO',
            'VARGAS',
            'PAREDES',
            'CHAVEZ',
            'GONZALES',
            'ESPINOZA',
            'NAVARRO',
            'CABRERA',
            'FERNANDEZ',
            'VASQUEZ',
            'AGUILAR'
        ) AS ApellidoPaterno,

        CHOOSE(
            (((N * 7) - 1) % 19) + 1,
            'GARCIA',
            'PEREZ',
            'DIAZ',
            'LOPEZ',
            'SILVA',
            'REYES',
            'CRUZ',
            'SOTO',
            'MEDINA',
            'VEGA',
            'HERRERA',
            'ROMERO',
            'MORALES',
            'RAMOS',
            'ORTIZ',
            'NUÑEZ',
            'CASTRO',
            'MENDOZA',
            'ROJAS'
        ) AS ApellidoMaterno

    FROM Numeros
)

INSERT INTO #ClienteCatalogo
(
    IdCliente,
    TipoDocumento,
    NumeroDocumento,
    Nombres,
    Apellidos,
    Email,
    Telefono,
    Ciudad,
    EstadoCliente
)

SELECT
    N,

    CASE
        WHEN N % 5 = 0 THEN 'CE'
        ELSE 'DNI'
    END,

    CASE
        WHEN N % 5 = 0
            THEN CAST(900000000 + N AS VARCHAR(20))
        ELSE
            CAST(70000000 + N AS VARCHAR(20))
    END,

    Nombres,

    CONCAT(
        ApellidoPaterno,
        ' ',
        ApellidoMaterno
    ),

    LOWER(
        CONCAT(
            Nombres,
            '.',
            ApellidoPaterno,
            N,
            '@correo.pe'
        )
    ),

    CONCAT(
        '9',
        RIGHT(
            '00000000' +
            CAST(10000000 + N AS VARCHAR(8)),
            8
        )
    ),

    CHOOSE(
        ((N - 1) % 10) + 1,
        'LIMA',
        'AREQUIPA',
        'CUSCO',
        'TRUJILLO',
        'PIURA',
        'ICA',
        'HUARAZ',
        'TACNA',
        'CHICLAYO',
        'HUANCAYO'
    ),

    CASE
        WHEN N % 17 = 0 THEN 'INACTIVO'
        ELSE 'ACTIVO'
    END

FROM Clientes

OPTION (MAXRECURSION 0);



--AUXILIAR PRODUCTOS

CREATE TABLE #ProductoCatalogo
(
    IdProducto        INT NOT NULL,
    CodigoProducto    VARCHAR(30) NOT NULL,
    NombreProducto    VARCHAR(150) NOT NULL,
    Categoria         VARCHAR(100) NOT NULL,
    Subcategoria      VARCHAR(100) NULL,
    Marca             VARCHAR(100) NULL,
    PrecioLista       DECIMAL(12,2) NOT NULL,
    EstadoProducto    VARCHAR(20) NOT NULL
);


;WITH Numeros AS
(
    SELECT 1 AS N

    UNION ALL

    SELECT N + 1
    FROM Numeros
    WHERE N < 90
)

INSERT INTO #ProductoCatalogo
(
    IdProducto,
    CodigoProducto,
    NombreProducto,
    Categoria,
    Subcategoria,
    Marca,
    PrecioLista,
    EstadoProducto
)

SELECT
    N,

    CONCAT(
        'P',
        RIGHT('0000' + CAST(N AS VARCHAR(4)), 4)
    ),

    CONCAT(
        CHOOSE(
            ((N - 1) % 8) + 1,
            'SMART TV',
            'LAPTOP',
            'MOUSE',
            'TECLADO',
            'AUDIFONOS',
            'MONITOR',
            'CELULAR',
            'TABLET'
        ),
        ' MODELO ',
        RIGHT('000' + CAST(N AS VARCHAR(3)), 3)
    ),

    CHOOSE(
        ((N - 1) % 5) + 1,
        'TELEVISORES',
        'COMPUTO',
        'ACCESORIOS',
        'MOVILES',
        'AUDIO'
    ),

    CHOOSE(
        ((N - 1) % 6) + 1,
        'SMART TV',
        'PERIFERICOS',
        'PORTATILES',
        'SMARTPHONE',
        'AUDIO PERSONAL',
        'MONITORES'
    ),

    CHOOSE(
        ((N - 1) % 7) + 1,
        'SAMSUNG',
        'LG',
        'LENOVO',
        'LOGITECH',
        'REDRAGON',
        'XIAOMI',
        'HP'
    ),

    CAST(
        49.90 + (N * 17.35)
        AS DECIMAL(12,2)
    ),

    CASE
        WHEN N % 29 = 0 THEN 'INACTIVO'
        ELSE 'ACTIVO'
    END

FROM Numeros

OPTION (MAXRECURSION 0);



--AUXILIAR TIENDAS

CREATE TABLE #TiendaCatalogo
(
    IdTienda        INT NOT NULL,
    CodigoTienda    VARCHAR(20) NOT NULL,
    NombreTienda    VARCHAR(150) NOT NULL,
    Ciudad          VARCHAR(100) NOT NULL,
    Departamento    VARCHAR(100) NOT NULL,
    TipoTienda      VARCHAR(30) NOT NULL,
    EstadoTienda    VARCHAR(20) NOT NULL
);


INSERT INTO #TiendaCatalogo
VALUES
(1,  'LIM01', 'TIENDA LIMA CENTRO',       'LIMA',       'LIMA',        'FISICA', 'ACTIVO'),
(2,  'LIM02', 'TIENDA LIMA NORTE',        'LIMA',       'LIMA',        'FISICA', 'ACTIVO'),
(3,  'AQP01', 'TIENDA AREQUIPA MALL',     'AREQUIPA',   'AREQUIPA',    'FISICA', 'ACTIVO'),
(4,  'CUS01', 'TIENDA CUSCO CENTRO',      'CUSCO',      'CUSCO',       'FISICA', 'ACTIVO'),
(5,  'TRU01', 'TIENDA TRUJILLO MALL',     'TRUJILLO',   'LA LIBERTAD', 'FISICA', 'ACTIVO'),
(6,  'PIU01', 'TIENDA PIURA CENTRO',      'PIURA',      'PIURA',       'FISICA', 'ACTIVO'),
(7,  'CHI01', 'TIENDA CHICLAYO',          'CHICLAYO',   'LAMBAYEQUE',  'FISICA', 'ACTIVO'),
(8,  'ICA01', 'TIENDA ICA',               'ICA',        'ICA',         'FISICA', 'ACTIVO'),
(9,  'HUA01', 'TIENDA HUARAZ',            'HUARAZ',     'ANCASH',      'FISICA', 'ACTIVO'),
(10, 'TAC01', 'TIENDA TACNA',             'TACNA',      'TACNA',       'FISICA', 'ACTIVO'),
(11, 'CAJ01', 'TIENDA CAJAMARCA',         'CAJAMARCA',  'CAJAMARCA',   'FISICA', 'ACTIVO'),
(12, 'PUN01', 'TIENDA PUNO',              'PUNO',       'PUNO',        'FISICA', 'ACTIVO'),
(13, 'TAR01', 'TIENDA TARAPOTO',          'TARAPOTO',   'SAN MARTIN',  'FISICA', 'ACTIVO'),
(14, 'LOR01', 'TIENDA IQUITOS',           'IQUITOS',    'LORETO',      'FISICA', 'ACTIVO'),
(15, 'JUN01', 'TIENDA HUANCAYO',          'HUANCAYO',   'JUNIN',       'FISICA', 'ACTIVO'),
(16, 'AYA01', 'TIENDA AYACUCHO',          'AYACUCHO',   'AYACUCHO',    'FISICA', 'ACTIVO'),
(17, 'MOQ01', 'TIENDA MOQUEGUA',          'MOQUEGUA',   'MOQUEGUA',    'FISICA', 'ACTIVO');


/*
================================
CREACIÓN DE TABLA DE CONTROL
================================
*/


CREATE TABLE dbo.ControlCarga
(
    NombreProceso           VARCHAR(100) NOT NULL,
    UltimaMarcaAgua         DATETIME2(3) NOT NULL,
    FechaUltimaEjecucion    DATETIME2(3) NULL,
    EstadoUltimaEjecucion   VARCHAR(20) NULL
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
    '2026-10-01 00:00:00.000',
    '2026-10-01 00:30:00.000',
    'OK'
);


/*
===================================================
CREACIÓN Y CARGA DE DATOS DE TABLAS DE DIMENSIONES
===================================================
*/


--DIM CLIENTE SCD2
--HASH KEY: TipoDocumento | NumeroDocumento

CREATE TABLE dbo.DimCliente
(
    ClienteSK                    BIGINT IDENTITY(1,1) NOT NULL,
    ClienteHashKey               BINARY(32) NOT NULL,

    TipoDocumento                VARCHAR(10) NOT NULL,
    NumeroDocumento              VARCHAR(20) NOT NULL,

    Nombres                      VARCHAR(100) NOT NULL,
    Apellidos                    VARCHAR(100) NOT NULL,
    Email                        VARCHAR(150) NULL,
    Telefono                     VARCHAR(20) NULL,
    Ciudad                       VARCHAR(100) NULL,
    EstadoCliente                VARCHAR(20) NOT NULL,

    FechaInicioVigencia          DATETIME2(3) NOT NULL,
    FechaFinVigencia             DATETIME2(3) NOT NULL,
    EsActual                     BIT NOT NULL,

    FechaInsercionDW             DATETIME2(3) NOT NULL,
    FechaUltimaModificacionDW    DATETIME2(3) NULL
);


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

    FechaInicioVigencia,
    FechaFinVigencia,
    EsActual,

    FechaInsercionDW,
    FechaUltimaModificacionDW
)

SELECT

    HASHBYTES
    (
        'SHA2_256',
        CONCAT(
            UPPER(TRIM(TipoDocumento)),
            '|',
            TRIM(NumeroDocumento)
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

    '2026-01-01 00:00:00.000',
    '9999-12-31 23:59:59.999',
    1,

    '2026-01-01 02:00:00.000',
    NULL

FROM #ClienteCatalogo

WHERE IdCliente <= 120;



--DIM PRODUCTO SCD1
--HASH KEY: CodigoProducto

CREATE TABLE dbo.DimProducto
(
    ProductoHashKey               BINARY(32) NOT NULL,

    CodigoProducto                VARCHAR(30) NOT NULL,
    NombreProducto                VARCHAR(150) NOT NULL,
    Categoria                     VARCHAR(100) NOT NULL,
    Subcategoria                  VARCHAR(100) NULL,
    Marca                         VARCHAR(100) NULL,
    PrecioLista                   DECIMAL(12,2) NOT NULL,
    EstadoProducto                VARCHAR(20) NOT NULL,

    FechaInsercionDW              DATETIME2(3) NOT NULL,
    FechaUltimaModificacionDW     DATETIME2(3) NULL
);


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

    FechaInsercionDW,
    FechaUltimaModificacionDW
)

SELECT

    HASHBYTES
    (
        'SHA2_256',
        UPPER(TRIM(CodigoProducto))
    ),

    CodigoProducto,
    NombreProducto,
    Categoria,
    Subcategoria,
    Marca,
    PrecioLista,
    EstadoProducto,

    '2026-01-01 03:00:00.000',
    NULL

FROM #ProductoCatalogo

WHERE IdProducto <= 80;



--DIM TIENDA SCD1
--HASH KEY: CodigoTienda

CREATE TABLE dbo.DimTienda
(
    TiendaHashKey                 BINARY(32) NOT NULL,

    CodigoTienda                  VARCHAR(20) NOT NULL,
    NombreTienda                  VARCHAR(150) NOT NULL,
    Ciudad                        VARCHAR(100) NOT NULL,
    Departamento                  VARCHAR(100) NOT NULL,
    TipoTienda                    VARCHAR(30) NOT NULL,
    EstadoTienda                  VARCHAR(20) NOT NULL,

    FechaInsercionDW              DATETIME2(3) NOT NULL,
    FechaUltimaModificacionDW     DATETIME2(3) NULL
);


INSERT INTO dbo.DimTienda
(
    TiendaHashKey,

    CodigoTienda,
    NombreTienda,
    Ciudad,
    Departamento,
    TipoTienda,
    EstadoTienda,

    FechaInsercionDW,
    FechaUltimaModificacionDW
)

SELECT

    HASHBYTES
    (
        'SHA2_256',
        UPPER(TRIM(CodigoTienda))
    ),

    CodigoTienda,
    NombreTienda,
    Ciudad,
    Departamento,
    TipoTienda,
    EstadoTienda,

    '2026-01-01 03:00:00.000',
    NULL

FROM #TiendaCatalogo

WHERE IdTienda <= 15;


/*
================================
CREACIÓN Y CARGA DE FACT VENTAS
================================
*/


--HASH KEY: FechaVenta | CodigoTienda | NumeroTicket | NumeroLinea

CREATE TABLE dbo.FactVentas
(
    VentaHashKey                    BINARY(32) NOT NULL,

    FechaVenta                      DATE NOT NULL,
    CodigoTienda                    VARCHAR(20) NOT NULL,
    NumeroTicket                    VARCHAR(30) NOT NULL,
    NumeroLinea                     INT NOT NULL,

    ClienteSK                       BIGINT NOT NULL,
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


;WITH Numeros AS
(
    SELECT 1 AS N

    UNION ALL

    SELECT N + 1
    FROM Numeros
    WHERE N < 1200
),

Base AS
(
    SELECT
        N,

        ((N - 1) / 3) + 1 AS IdTicket,

        ((N - 1) % 3) + 1 AS NumeroLinea,

        (((N - 1) / 3) % 15) + 1 AS IdTienda,

        ((((((N - 1) / 3) + 1) * 7) - 1) % 120) + 1 AS IdCliente,

        (((N * 11) - 1) % 80) + 1 AS IdProducto,

        (N % 4) + 1 AS Cantidad

    FROM Numeros
),

VentaBase AS
(
    SELECT
        B.*,

        DATEADD(
            DAY,
            (IdTicket - 1) % 30,
            CAST('2026-09-01' AS DATE)
        ) AS FechaVenta,

        CONCAT(
            'T',
            RIGHT(
                '000000' +
                CAST(IdTicket AS VARCHAR(6)),
                6
            )
        ) AS NumeroTicket

    FROM Base B
)

INSERT INTO dbo.FactVentas
(
    VentaHashKey,

    FechaVenta,
    CodigoTienda,
    NumeroTicket,
    NumeroLinea,

    ClienteSK,
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
        CONCAT(
            CONVERT(VARCHAR(10), V.FechaVenta, 23),
            '|',
            UPPER(TRIM(T.CodigoTienda)),
            '|',
            UPPER(TRIM(V.NumeroTicket)),
            '|',
            V.NumeroLinea
        )
    ),

    V.FechaVenta,
    T.CodigoTienda,
    V.NumeroTicket,
    V.NumeroLinea,

    C.ClienteSK,
    P.ProductoHashKey,
    T.TiendaHashKey,

    V.Cantidad,
    X.PrecioUnitario,

    CAST(
        V.Cantidad * X.PrecioUnitario
        AS DECIMAL(14,2)
    ),

    X.MontoDescuento,

    CAST(
        (V.Cantidad * X.PrecioUnitario)
        - X.MontoDescuento
        AS DECIMAL(14,2)
    ),

    CHOOSE(
        (V.IdTicket % 3) + 1,
        'TIENDA',
        'WEB',
        'APP'
    ),

    CHOOSE(
        (V.IdTicket % 4) + 1,
        'TARJETA',
        'YAPE',
        'PLIN',
        'EFECTIVO'
    ),

    CASE
        WHEN V.N % 50 = 0 THEN 'ANULADA'
        ELSE 'COMPLETADA'
    END,

    DATEADD(
        MINUTE,
        600 + (V.N % 300),
        CAST(V.FechaVenta AS DATETIME2(3))
    ),

    NULL,

    '2026-10-01 00:00:00.000',
    NULL

FROM VentaBase V

INNER JOIN #ClienteCatalogo CC
    ON CC.IdCliente = V.IdCliente

INNER JOIN dbo.DimCliente C
    ON C.TipoDocumento = CC.TipoDocumento
   AND C.NumeroDocumento = CC.NumeroDocumento
   AND C.EsActual = 1

INNER JOIN #ProductoCatalogo PC
    ON PC.IdProducto = V.IdProducto

INNER JOIN dbo.DimProducto P
    ON P.CodigoProducto = PC.CodigoProducto

INNER JOIN #TiendaCatalogo TC
    ON TC.IdTienda = V.IdTienda

INNER JOIN dbo.DimTienda T
    ON T.CodigoTienda = TC.CodigoTienda

CROSS APPLY
(
    SELECT
        CAST(
            ROUND(
                PC.PrecioLista
                * (0.85 + ((V.N % 10) / 100.0)),
                2
            )
            AS DECIMAL(12,2)
        ) AS PrecioUnitario,

        CAST(
            CASE
                WHEN V.N % 11 = 0 THEN 20.00
                WHEN V.N % 6 = 0 THEN 10.00
                ELSE 0.00
            END
            AS DECIMAL(14,2)
        ) AS MontoDescuento
) X

OPTION (MAXRECURSION 0);


/*
========================
CREACIÓN DE STAGE VENTAS
========================
*/


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


;WITH Numeros AS
(
    SELECT 1 AS N

    UNION ALL

    SELECT N + 1
    FROM Numeros
    WHERE N < 300
),

StageBase AS
(
    SELECT
        N,

        CASE
            WHEN N <= 120
                THEN ((N - 1) / 3) + 1
            ELSE
                10000 + ((N - 121) / 3) + 1
        END AS IdTicket,

        CASE
            WHEN N <= 120
                THEN ((N - 1) % 3) + 1
            ELSE
                ((N - 121) % 3) + 1
        END AS NumeroLinea

    FROM Numeros
),

StageClaves AS
(
    SELECT
        S.*,

        CASE
            WHEN N <= 120
                THEN ((IdTicket - 1) % 15) + 1

            WHEN N % 90 = 0
                THEN 17

            WHEN N % 75 = 0
                THEN 16

            ELSE
                ((N * 5 - 1) % 15) + 1
        END AS IdTienda,


        CASE
            WHEN N <= 120
                THEN ((IdTicket * 7 - 1) % 120) + 1

            WHEN N % 18 = 0
                THEN 121 + ((N / 18) % 10)

            ELSE
                ((N * 7 - 1) % 120) + 1
        END AS IdCliente,


        CASE
            WHEN N <= 120
                THEN ((N * 11 - 1) % 80) + 1

            WHEN N % 20 = 0
                THEN 81 + ((N / 20) % 10)

            ELSE
                ((N * 13 - 1) % 80) + 1
        END AS IdProducto

    FROM StageBase S
),

StageDatos AS
(
    SELECT
        S.*,

        CASE
            WHEN N <= 120
                THEN DATEADD(
                    DAY,
                    (IdTicket - 1) % 30,
                    CAST('2026-09-01' AS DATE)
                )

            ELSE
                DATEADD(
                    DAY,
                    ((N - 121) / 90),
                    CAST('2026-10-01' AS DATE)
                )
        END AS FechaVenta

    FROM StageClaves S
)

INSERT INTO dbo.stg_Ventas
(
    FechaVenta,
    CodigoTienda,
    NumeroTicket,
    NumeroLinea,

    TipoDocumento,
    NumeroDocumento,

    Nombres,
    Apellidos,
    Email,
    Telefono,
    CiudadCliente,
    EstadoCliente,

    CodigoProducto,
    NombreProducto,
    Categoria,
    Subcategoria,
    Marca,
    PrecioLista,
    EstadoProducto,

    NombreTienda,
    CiudadTienda,
    DepartamentoTienda,
    TipoTienda,
    EstadoTienda,

    Cantidad,
    PrecioUnitario,
    MontoDescuento,

    Canal,
    MedioPago,
    EstadoVenta,

    FechaInsercionOrigen,
    FechaUltimaModificacionOrigen
)

SELECT

    S.FechaVenta,
    T.CodigoTienda,

    CONCAT(
        'T',
        RIGHT(
            '000000' +
            CAST(S.IdTicket AS VARCHAR(6)),
            6
        )
    ),

    S.NumeroLinea,

    C.TipoDocumento,
    C.NumeroDocumento,

    C.Nombres,
    C.Apellidos,

    CASE
        WHEN C.IdCliente = 7
            THEN 'ana.actualizada007@correo.pe'

        WHEN C.IdCliente = 35
            THEN 'cliente035.actualizado@correo.pe'

        WHEN C.IdCliente = 49
            THEN 'cliente049.actualizado@correo.pe'

        ELSE C.Email
    END,

    CASE
        WHEN C.IdCliente = 14
            THEN '989000014'

        WHEN C.IdCliente = 35
            THEN '989000035'

        ELSE C.Telefono
    END,

    CASE
        WHEN C.IdCliente = 21
            THEN 'LIMA'

        WHEN C.IdCliente = 49
            THEN 'AREQUIPA'

        ELSE C.Ciudad
    END,

    CASE
        WHEN C.IdCliente = 49
            THEN 'INACTIVO'

        ELSE C.EstadoCliente
    END,


    P.CodigoProducto,

    CASE
        WHEN P.IdProducto IN (10,20,30)
            THEN CONCAT(
                P.NombreProducto,
                ' V2'
            )
        ELSE P.NombreProducto
    END,

    P.Categoria,
    P.Subcategoria,
    P.Marca,

    CASE
        WHEN P.IdProducto IN (10,20,30)
            THEN P.PrecioLista + 15
        ELSE P.PrecioLista
    END,

    P.EstadoProducto,


    CASE
        WHEN T.IdTienda IN (2,5)
            THEN CONCAT(
                T.NombreTienda,
                ' RENOVADA'
            )
        ELSE T.NombreTienda
    END,

    T.Ciudad,
    T.Departamento,
    T.TipoTienda,
    T.EstadoTienda,


    CASE
        WHEN S.N <= 120
             AND S.N % 10 = 0
            THEN (S.N % 4) + 2

        ELSE (S.N % 4) + 1
    END,


    CAST(
        ROUND(
            P.PrecioLista
            * (0.85 + ((S.N % 10) / 100.0)),
            2
        )
        AS DECIMAL(12,2)
    ),


    CAST(
        CASE
            WHEN S.N <= 120
                 AND S.N % 15 = 0
                THEN 15.00

            WHEN S.N % 11 = 0
                THEN 20.00

            WHEN S.N % 6 = 0
                THEN 10.00

            ELSE 0.00
        END
        AS DECIMAL(14,2)
    ),


    CHOOSE(
        (S.IdTicket % 3) + 1,
        'TIENDA',
        'WEB',
        'APP'
    ),

    CHOOSE(
        (S.IdTicket % 4) + 1,
        'TARJETA',
        'YAPE',
        'PLIN',
        'EFECTIVO'
    ),

    CASE
        WHEN S.N % 50 = 0 THEN 'ANULADA'
        ELSE 'COMPLETADA'
    END,


    CASE
        WHEN S.N <= 120
            THEN DATEADD(
                MINUTE,
                600 + (S.N % 300),
                CAST(S.FechaVenta AS DATETIME2(3))
            )

        ELSE
            DATEADD(
                MINUTE,
                S.N - 120,
                CAST('2026-10-01 10:00:00.000' AS DATETIME2(3))
            )
    END,


    CASE
        WHEN S.N <= 20
            THEN DATEADD(
                MINUTE,
                S.N,
                CAST('2026-09-30 20:00:00.000' AS DATETIME2(3))
            )

        WHEN S.N <= 120
            THEN DATEADD(
                MINUTE,
                S.N,
                CAST('2026-10-01 08:00:00.000' AS DATETIME2(3))
            )

        ELSE NULL
    END

FROM StageDatos S

INNER JOIN #ClienteCatalogo C
    ON C.IdCliente = S.IdCliente

INNER JOIN #ProductoCatalogo P
    ON P.IdProducto = S.IdProducto

INNER JOIN #TiendaCatalogo T
    ON T.IdTienda = S.IdTienda

OPTION (MAXRECURSION 0);


/*
=================================
TABLA STAGE LISTA PARA PROCESAR
=================================
*/


SELECT TOP (0)
    *
INTO dbo.tmp_stg_Ventas_process
FROM dbo.stg_Ventas;


/*
============================
ELIMINAR TABLAS TEMPORALES
============================
*/


DROP TABLE #ClienteCatalogo;
DROP TABLE #ProductoCatalogo;
DROP TABLE #TiendaCatalogo;