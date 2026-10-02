/*
=============================================================
CREACIÓN DE LOS INDICES PARA CONSULTAS Y FILTROS EFICIENTES
=============================================================
*/

CREATE INDEX IX_DimCliente_ClienteHashKey
ON DimCliente(ClienteHashKey);

CREATE INDEX IX_DimProducto_ProductoHashKey
ON DimProducto(ProductoHashKey);

CREATE INDEX IX_DimTienda_TiendaHashKey
ON DimTienda(TiendaHashKey);

CREATE INDEX IX_FactVentas_VentaHashKey
ON FactVentas(VentaHashKey);