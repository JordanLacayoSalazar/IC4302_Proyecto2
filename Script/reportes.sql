-- Ejecutar conectado a cada base WWI; no usar la base original WideWorldImporters.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ANSI_PADDING ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO
IF DB_NAME() NOT IN (N'WWI_Corporativo', N'WWI_SanJose', N'WWI_Limon')
    THROW 50040, 'Conectese a WWI_Corporativo, WWI_SanJose o WWI_Limon.', 1;
GO


/*
Los reportes solo se consultan en WWI_Corporativo, usando las replicas locales.
*/
CREATE OR ALTER FUNCTION dbo.fn_ReporteFacturas(@BranchID INT)
RETURNS TABLE
AS RETURN (
    SELECT * FROM Sales.Invoices
    WHERE (@BranchID IS NULL OR BranchID = @BranchID)
      AND DB_NAME() = N'WWI_Corporativo'
);
GO
CREATE OR ALTER FUNCTION dbo.fn_ReporteLineasFactura(@BranchID INT)
RETURNS TABLE
AS RETURN (
    SELECT * FROM Sales.InvoiceLines
    WHERE (@BranchID IS NULL OR BranchID = @BranchID)
      AND DB_NAME() = N'WWI_Corporativo'
);
GO
CREATE OR ALTER FUNCTION dbo.fn_ReporteOrdenesCompra(@BranchID INT)
RETURNS TABLE
AS RETURN (
    SELECT * FROM Purchasing.PurchaseOrders
    WHERE (@BranchID IS NULL OR BranchID = @BranchID)
      AND DB_NAME() = N'WWI_Corporativo'
);
GO
CREATE OR ALTER FUNCTION dbo.fn_ReporteLineasOrdenCompra(@BranchID INT)
RETURNS TABLE
AS RETURN (
    SELECT * FROM Purchasing.PurchaseOrderLines
    WHERE (@BranchID IS NULL OR BranchID = @BranchID)
      AND DB_NAME() = N'WWI_Corporativo'
);
GO
CREATE OR ALTER FUNCTION dbo.fn_ReporteInventario(@BranchID INT)
RETURNS TABLE
AS RETURN (
    SELECT * FROM Warehouse.StockItemHoldings
    WHERE (@BranchID IS NULL OR BranchID = @BranchID)
      AND DB_NAME() = N'WWI_Corporativo'
);
GO


/*
Lista de códigos de errores:
- 50101: El año inicial no puede ser mayor que el año final.
- 50102: El año inicial no existe en los datos de facturación.
- 50103: El año final no existe en los datos de facturación.
- 50104: El año inicial no existe en los datos de órdenes de compra.
- 50105: El año final no existe en los datos de órdenes de compra.
- 50201: El año indicado no existe en las facturas de la base de datos.
- 50202: El año indicado no existe en las órdenes de compra.
- 50203: El mes debe estar entre 1 y 12.
- 50204: El año indicado no existe en las facturas de la base de datos.
*/

-- ================================================================
-- REPORTE 1: compras a proveedores por proveedor y categoría
-- Parámetros : @Proveedor, @Categoria
-- Requisitos : MAX, MIN, AVG, agrupación y ROLLUP.
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte1
    @Proveedor NVARCHAR(100) = NULL,
    @Categoria NVARCHAR(50) = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    WITH ComprasPorOrden AS
    (
        SELECT
            po.BranchID, po.PurchaseOrderID,
            s.SupplierName,
            sc.SupplierCategoryName,
            SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS MontoOrden
        FROM dbo.fn_ReporteOrdenesCompra(@BranchID) AS po
        INNER JOIN dbo.fn_ReporteLineasOrdenCompra(@BranchID) AS pol
            ON po.BranchID = pol.BranchID AND po.PurchaseOrderID = pol.PurchaseOrderID
        INNER JOIN syn_Proveedores AS s
            ON po.SupplierID = s.SupplierID
        INNER JOIN syn_CategoriasProveedor AS sc
            ON s.SupplierCategoryID = sc.SupplierCategoryID
        WHERE
            (
                NULLIF(LTRIM(RTRIM(@Proveedor)), '') IS NULL
                OR s.SupplierName LIKE '%' + LTRIM(RTRIM(@Proveedor)) + '%'
            )
            AND
            (
                NULLIF(LTRIM(RTRIM(@Categoria)), '') IS NULL
                OR sc.SupplierCategoryName LIKE '%' + LTRIM(RTRIM(@Categoria)) + '%'
            )
        GROUP BY
            po.BranchID, po.PurchaseOrderID,
            s.SupplierName,
            sc.SupplierCategoryName
    )

    SELECT
        CASE
            WHEN GROUPING(SupplierCategoryName) = 1
                    AND GROUPING(SupplierName) = 1
                THEN 'TOTAL GENERAL'
            WHEN GROUPING(SupplierName) = 1
                THEN 'TOTAL CATEGORÍA'
            ELSE SupplierCategoryName
        END AS Categoria,
        CASE
            WHEN GROUPING(SupplierCategoryName) = 1
                    AND GROUPING(SupplierName) = 1
                THEN 'TOTAL GENERAL'
            WHEN GROUPING(SupplierName) = 1
                THEN SupplierCategoryName
            ELSE SupplierName
        END AS Proveedor,
        CAST(MAX(MontoOrden) AS DECIMAL(18,2)) AS MontoMasAlto,
        CAST(MIN(MontoOrden) AS DECIMAL(18,2)) AS MontoMasBajo,
        CAST(AVG(MontoOrden) AS DECIMAL(18,2)) AS CompraPromedio
    FROM ComprasPorOrden
    GROUP BY ROLLUP(SupplierCategoryName, SupplierName)
    ORDER BY Categoria ASC, Proveedor ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO


/*
================================================================================
REPORTE 2: Estadísticas de ventas por cliente y categoría
-- Parámetros : @NombreCliente, @Categoria
-- Requisitos : MAX, MIN, AVG, agrupación y ROLLUP.
Obtiene el monto más alto, monto más bajo y venta promedio por
cliente y categoría de cliente. Se puede filtrar por nombre de cliente y categoría.
================================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte2
    @NombreCliente NVARCHAR(100) = NULL,
    @Categoria NVARCHAR(100) = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    -- ExtendedPrice ya incluye impuestos; sumar una sola vez por linea y sucursal.
    WITH TotalesFactura AS (
        SELECT
            il.BranchID, il.InvoiceID,
            SUM(ISNULL(il.ExtendedPrice, 0)) AS Monto
        FROM dbo.fn_ReporteLineasFactura(@BranchID) AS il
        GROUP BY il.BranchID, il.InvoiceID
    )

    SELECT
        CASE
            WHEN GROUPING(cc.CustomerCategoryName) = 1 AND GROUPING(c.CustomerName) = 1
                THEN 'TOTAL GENERAL'
            WHEN GROUPING(c.CustomerName) = 1
                THEN CONCAT('TOTAL CATEGORÍA: ', cc.CustomerCategoryName)
            ELSE cc.CustomerCategoryName
        END AS Categoria,

        CASE
            WHEN GROUPING(cc.CustomerCategoryName) = 1 AND GROUPING(c.CustomerName) = 1
                OR GROUPING(c.CustomerName) = 1
                THEN ''
            ELSE c.CustomerName
        END AS Cliente,

        CASE WHEN GROUPING(c.CustomerName) = 1 THEN NULL ELSE MAX(c.CustomerID) END AS ClienteID,

        MAX(ISNULL(tf.Monto, 0)) AS MontoMasAlto,
        MIN(ISNULL(tf.Monto, 0)) AS MontoMasBajo,
        AVG(CAST(ISNULL(tf.Monto, 0) AS DECIMAL(18, 2))) AS VentaPromedio
    FROM dbo.fn_ReporteFacturas(@BranchID) AS i
        
    INNER JOIN syn_Clientes AS c
        ON i.CustomerID = c.CustomerID

    INNER JOIN syn_CategoriasCliente AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID

    LEFT JOIN TotalesFactura AS tf
        ON i.BranchID = tf.BranchID AND i.InvoiceID = tf.InvoiceID

    WHERE
        (@NombreCliente IS NULL OR c.CustomerName LIKE '%' + LTRIM(RTRIM(@NombreCliente)) + '%')
        AND (@Categoria IS NULL OR cc.CustomerCategoryName LIKE '%' + LTRIM(RTRIM(@Categoria)) + '%')

    GROUP BY ROLLUP (cc.CustomerCategoryName, c.CustomerName)
    ORDER BY Categoria ASC, Cliente ASC, ClienteID ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO


-- ================================================================
-- REPORTE 3: Top 5 productos con mayor ganancia por año
-- Parámetros : @Anio
-- Requisitos : DENSE_RANK + PARTITION BY + filtro de año.
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte3
    @Anio INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;
    IF @Anio IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.fn_ReporteFacturas(@BranchID) WHERE YEAR(InvoiceDate) = @Anio)
        THROW 50201, 'El año indicado no existe en las facturas de la base de datos.', 1;


    WITH Ganancias AS
    (
        SELECT
            YEAR(i.InvoiceDate) AS Anio,
            si.StockItemName AS Producto,
            SUM(il.LineProfit) AS GananciaTotal,
            DENSE_RANK() OVER
            (
                PARTITION BY YEAR(i.InvoiceDate)
                ORDER BY SUM(il.LineProfit) DESC
            ) AS Ranking
        FROM dbo.fn_ReporteFacturas(@BranchID) AS i
        INNER JOIN dbo.fn_ReporteLineasFactura(@BranchID) AS il
            ON i.BranchID = il.BranchID AND i.InvoiceID = il.InvoiceID
        INNER JOIN syn_Productos AS si
            ON il.StockItemID = si.StockItemID
        WHERE @Anio IS NULL OR YEAR(i.InvoiceDate) = @Anio
        GROUP BY
            YEAR(i.InvoiceDate),
            si.StockItemName
    )

    SELECT
        Anio,
        Ranking,
        Producto,
        CAST(GananciaTotal AS DECIMAL(18,2)) AS GananciaTotal
    FROM Ganancias
    WHERE Ranking <= 5
    ORDER BY Anio DESC, Ranking ASC, Producto ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO


/*
================================================================================
REPORTE 4: Top 5 clientes por cantidad de facturas emitidas por año.
-- Parámetros : @AnioInicio, @AnioFin
-- Requisitos : DENSE_RANK + PARTITION BY + filtro de año.
Devuelve el ranking con el monto total facturado por cliente.
================================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte4
    @AnioInicio INT = NULL,
    @AnioFin INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    IF @AnioInicio IS NOT NULL AND @AnioFin IS NOT NULL
        AND @AnioInicio > @AnioFin
    BEGIN
        ;THROW 50101, 'El año inicial no puede ser mayor que el año final.', 1;
    END;

    WITH AniosFacturacion AS (
        -- Se obtienen los años distintos de facturación que existen
        SELECT DISTINCT -- Para obtener los años distintos de facturación que existen
            DATEPART(YEAR, i.InvoiceDate) AS Anio
        FROM dbo.fn_ReporteFacturas(@BranchID) AS i
    )
    SELECT Anio
    INTO #AniosFacturacion -- Se crea una tabla temporal para almacenar los años de facturación
    FROM AniosFacturacion;

    IF @AnioInicio IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM #AniosFacturacion
            WHERE Anio = @AnioInicio
        )
    BEGIN
        ;THROW 50102, 'El año inicial no existe en los datos de facturación.', 1;
    END;

    IF @AnioFin IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM #AniosFacturacion
            WHERE Anio = @AnioFin
        )
    BEGIN
        ;THROW 50103, 'El año final no existe en los datos de facturación.', 1;
    END;


    WITH TotalesFactura AS (
        SELECT
            il.BranchID, il.InvoiceID,
            SUM(ISNULL(il.ExtendedPrice, 0)) AS Monto
        FROM dbo.fn_ReporteLineasFactura(@BranchID) AS il
        GROUP BY il.BranchID, il.InvoiceID
    ),

    -- Se obtiene la cantidad de facturas y el monto total facturado por año y cliente
    VentasClienteAnio AS (
        SELECT
            DATEPART(YEAR, i.InvoiceDate) AS Anio,
            c.CustomerID,
            c.CustomerName AS Cliente,
            COUNT(*) AS CantidadFacturas,
            SUM(ISNULL(tf.Monto, 0)) AS MontoTotalFacturado
        FROM dbo.fn_ReporteFacturas(@BranchID) AS i

        INNER JOIN syn_Clientes AS c
            ON i.CustomerID = c.CustomerID

        LEFT JOIN TotalesFactura AS tf
            ON i.BranchID = tf.BranchID AND i.InvoiceID = tf.InvoiceID

        WHERE
            (@AnioInicio IS NULL OR DATEPART(YEAR, i.InvoiceDate) >= @AnioInicio)
            AND (@AnioFin IS NULL OR DATEPART(YEAR, i.InvoiceDate) <= @AnioFin)
        GROUP BY
            DATEPART(YEAR, i.InvoiceDate),
            c.CustomerID,
            c.CustomerName
    ),

    -- Se hace un ranking de los clientes por cantidad de facturas emitidas por año
    ClientesRanking AS (
        SELECT
            Anio,
            CustomerID,
            Cliente,
            CantidadFacturas,
            MontoTotalFacturado,
            DENSE_RANK() OVER (
                PARTITION BY Anio
                ORDER BY CantidadFacturas DESC
            ) AS Posicion
        FROM VentasClienteAnio
    )

    SELECT
        Anio,
        Posicion,
        CustomerID,
        Cliente,
        CantidadFacturas,
        MontoTotalFacturado
    FROM ClientesRanking
    WHERE Posicion <= 5
    ORDER BY Anio DESC, Posicion ASC, Cliente ASC, CustomerID ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;

    DROP TABLE #AniosFacturacion;
END;
GO


/*
================================================================================
REPORTE 5: Top 5 proveedores por cantidad de órdenes de compra y año.
-- Parámetros : @AnioInicio, @AnioFin
-- Requisitos : DENSE_RANK + PARTITION BY + filtro de año.
Valida que los años del rango existan en los datos de órdenes de compra y
devuelve el monto total de las órdenes por proveedor.
================================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte5
    @AnioInicio INT = NULL,
    @AnioFin INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    IF @AnioInicio IS NOT NULL AND @AnioFin IS NOT NULL
        AND @AnioInicio > @AnioFin
    BEGIN
        ;THROW 50101, 'El año inicial no puede ser mayor que el año final.', 1;
    END;

    WITH AniosOrdenCompra AS (
        SELECT DISTINCT
            DATEPART(YEAR, po.OrderDate) AS Anio
        FROM dbo.fn_ReporteOrdenesCompra(@BranchID) AS po
    )
    SELECT Anio
    INTO #AniosOrdenCompra
    FROM AniosOrdenCompra;

    IF @AnioInicio IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM #AniosOrdenCompra
            WHERE Anio = @AnioInicio
        )
    BEGIN
        ;THROW 50104, 'El año inicial no existe en los datos de órdenes de compra.', 1;
    END;

    IF @AnioFin IS NOT NULL
        AND NOT EXISTS (
            SELECT 1
            FROM #AniosOrdenCompra
            WHERE Anio = @AnioFin
        )
    BEGIN
        ;THROW 50105, 'El año final no existe en los datos de órdenes de compra.', 1;
    END;

    -- Se calcula el monto total de cada orden de compra sumando los precios por unidad por
    -- la cantidad de unidades ordenadas en cada línea de la orden
    WITH TotalesOrden AS (
        SELECT
            pol.BranchID, pol.PurchaseOrderID,
            SUM(pol.OrderedOuters * ISNULL(pol.ExpectedUnitPricePerOuter, 0)) AS Monto
        FROM dbo.fn_ReporteLineasOrdenCompra(@BranchID) AS pol
        GROUP BY pol.BranchID, pol.PurchaseOrderID
    ),

    -- Se obtiene la cantidad de órdenes y el monto total por año y proveedor
    ComprasProveedorAnio AS (
        SELECT
            DATEPART(YEAR, po.OrderDate) AS Anio,
            s.SupplierID,
            s.SupplierName AS Proveedor,
            sc.SupplierCategoryName AS Categoria,
            COUNT(*) AS CantidadOrdenes,
            SUM(ISNULL(tord.Monto, 0)) AS MontoTotal
        FROM dbo.fn_ReporteOrdenesCompra(@BranchID) AS po

        INNER JOIN syn_Proveedores AS s
            ON po.SupplierID = s.SupplierID

        INNER JOIN syn_CategoriasProveedor AS sc
            ON s.SupplierCategoryID = sc.SupplierCategoryID

        LEFT JOIN TotalesOrden AS tord
            ON po.BranchID = tord.BranchID AND po.PurchaseOrderID = tord.PurchaseOrderID

        WHERE
            (@AnioInicio IS NULL OR DATEPART(YEAR, po.OrderDate) >= @AnioInicio)
            AND (@AnioFin IS NULL OR DATEPART(YEAR, po.OrderDate) <= @AnioFin)
        GROUP BY
            DATEPART(YEAR, po.OrderDate),
            s.SupplierID,
            s.SupplierName,
            sc.SupplierCategoryName
    ),

    -- Se hace un ranking de los proveedores por cantidad de órdenes emitidas por año
    ProveedoresRanking AS (
        SELECT
            Anio,
            SupplierID,
            Proveedor,
            Categoria,
            CantidadOrdenes,
            MontoTotal,
            DENSE_RANK() OVER (
                PARTITION BY Anio
                ORDER BY CantidadOrdenes DESC
            ) AS Posicion
        FROM ComprasProveedorAnio
    )

    SELECT
        Anio,
        Posicion,
        SupplierID,
        Proveedor,
        Categoria,
        CantidadOrdenes,
        MontoTotal
    FROM ProveedoresRanking
    WHERE Posicion <= 5
    ORDER BY Anio DESC, Posicion ASC, Proveedor ASC, SupplierID ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;

    DROP TABLE #AniosOrdenCompra;
END;
GO


-- ================================================================
-- REPORTE 6: matriz resumen de ventas por categoría y año
-- Parámetros : ninguno
-- Requisitos : resumen tipo matriz por categorías y años vendidos.
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte6
    @AnioInicio INT = NULL,
    @AnioFin INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @ColumnasPivot NVARCHAR(MAX);
    DECLARE @ColumnasSelect NVARCHAR(MAX);
    DECLARE @SQL NVARCHAR(MAX);

    SELECT @ColumnasPivot = STUFF((
        SELECT ', ' + QUOTENAME(CAST(YEAR(InvoiceDate) AS NVARCHAR(4)))
        FROM dbo.fn_ReporteFacturas(@BranchID)
        WHERE InvoiceDate IS NOT NULL
          AND (@AnioInicio IS NULL OR YEAR(InvoiceDate) >= @AnioInicio)
          AND (@AnioFin IS NULL OR YEAR(InvoiceDate) <= @AnioFin)
        GROUP BY YEAR(InvoiceDate)
        ORDER BY YEAR(InvoiceDate) ASC
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    SELECT @ColumnasSelect = STUFF((
        SELECT ', ISNULL(' + QUOTENAME(CAST(YEAR(InvoiceDate) AS NVARCHAR(4))) + ', 0) AS [Ventas_' + CAST(YEAR(InvoiceDate) AS NVARCHAR(4)) + ']'
        FROM dbo.fn_ReporteFacturas(@BranchID)
        WHERE InvoiceDate IS NOT NULL
          AND (@AnioInicio IS NULL OR YEAR(InvoiceDate) >= @AnioInicio)
          AND (@AnioFin IS NULL OR YEAR(InvoiceDate) <= @AnioFin)
        GROUP BY YEAR(InvoiceDate)
        ORDER BY YEAR(InvoiceDate) ASC
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    IF @ColumnasPivot IS NOT NULL AND LEN(@ColumnasPivot) > 0
    BEGIN
        SET @SQL = N'
        DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;
        
        WITH DatosBase AS (
            SELECT
                sg.StockGroupName AS Categoria,
                YEAR(i.InvoiceDate) AS Anio,
                ISNULL(il.ExtendedPrice, 0) AS Monto
            FROM dbo.fn_ReporteFacturas(@BranchID) AS i
            INNER JOIN dbo.fn_ReporteLineasFactura(@BranchID) AS il ON i.BranchID = il.BranchID AND i.InvoiceID = il.InvoiceID
            INNER JOIN syn_ProductoGrupos AS pig ON il.StockItemID = pig.StockItemID
            INNER JOIN syn_GruposProducto AS sg ON pig.StockGroupID = sg.StockGroupID
            WHERE i.InvoiceDate IS NOT NULL
              AND (@AnioInicio IS NULL OR YEAR(i.InvoiceDate) >= @AnioInicio)
              AND (@AnioFin IS NULL OR YEAR(i.InvoiceDate) <= @AnioFin)
        )
        SELECT Categoria, ' + @ColumnasSelect + N'
        FROM DatosBase
        PIVOT (
            SUM(Monto)
            FOR Anio IN (' + @ColumnasPivot + N')
        ) AS Matriz
        ORDER BY Categoria ASC
        OFFSET (@Pagina * @FilasPorPagina) ROWS
        FETCH NEXT @FilasConIndicador ROWS ONLY;
        ';

        EXEC sp_executesql @SQL, 
            N'@AnioInicio INT, @AnioFin INT, @Pagina INT, @FilasPorPagina INT, @BranchID INT',
            @AnioInicio, @AnioFin, @Pagina, @FilasPorPagina, @BranchID;
    END
    ELSE
    BEGIN
        SELECT TOP 0 'Categoria' AS Categoria;
    END
END;
GO


/*
================================================================================
REPORTE 7: Seguimiento mensual de ventas por cliente.
-- Parámetros : @Anio, @Mes, @CategoriaProducto, @SubcategoriaProducto
-- Requisitos : filtros por año, mes, categoría y subcategoría de producto.
================================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte7
    @Anio INT = NULL,
    @Mes INT = NULL,
    @CategoriaProducto NVARCHAR(50) = NULL,
    @SubcategoriaProducto NVARCHAR(100) = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    -- Obtiene los productos y sus categorías para poder filtrar por categoría de producto
    WITH ProductosPorCategoria AS (
        SELECT sisg.StockItemID, sg.StockGroupName
        FROM syn_ProductoGrupos AS sisg
        INNER JOIN syn_GruposProducto AS sg
            ON sisg.StockGroupID = sg.StockGroupID
    )
    SELECT
        c.CustomerID,
        c.CustomerName AS Cliente,
        DATEPART(YEAR, i.InvoiceDate) AS Anio,
        DATEPART(MONTH, i.InvoiceDate) AS Mes,
        MIN(i.InvoiceDate) AS PrimeraFacturaDelMes,
        MAX(i.InvoiceDate) AS UltimaFacturaDelMes,
        SUM(ISNULL(il.ExtendedPrice, 0)) AS MontoTotalComprado,
        SUM(il.Quantity) AS CantidadTotal,
        MIN(il.Quantity) AS CantidadMinima,
        MAX(il.Quantity) AS CantidadMaxima
    FROM dbo.fn_ReporteFacturas(@BranchID) AS i
        
    INNER JOIN syn_Clientes AS c
        ON i.CustomerID = c.CustomerID

    INNER JOIN dbo.fn_ReporteLineasFactura(@BranchID) AS il
        ON i.BranchID = il.BranchID AND i.InvoiceID = il.InvoiceID

    INNER JOIN syn_Productos AS si
        ON il.StockItemID = si.StockItemID

    WHERE
        -- Año y mes
        (@Anio IS NULL OR DATEPART(YEAR, i.InvoiceDate) = @Anio)
        AND (@Mes IS NULL OR DATEPART(MONTH, i.InvoiceDate) = @Mes)

        --Categoría de producto
        AND (
            @CategoriaProducto IS NULL
            OR si.StockItemID IN ( -- Se filtra por productos que pertenecen a la categoría especificada
                SELECT StockItemID
                FROM ProductosPorCategoria
                WHERE StockGroupName LIKE '%' + LTRIM(RTRIM(@CategoriaProducto)) + '%'
            )
        )

        -- Subcategoría de producto
        AND (
            @SubcategoriaProducto IS NULL
            OR si.StockItemName LIKE '%' + LTRIM(RTRIM(@SubcategoriaProducto)) + '%'
        )

    GROUP BY
        c.CustomerID,
        c.CustomerName,
        DATEPART(YEAR, i.InvoiceDate),
        DATEPART(MONTH, i.InvoiceDate)
    ORDER BY Cliente ASC, Anio DESC, Mes DESC, CustomerID ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO


-- ================================================================
-- REPORTE 8: seguimiento mensual de compras a proveedores
-- Parámetros : @Anio, @Mes, @CategoriaProducto, @SubcategoriaProducto
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte8
    @Anio INT = NULL,
    @Mes INT = NULL,
    @CategoriaProducto NVARCHAR(50) = NULL,
    @SubcategoriaProducto NVARCHAR(100) = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;
    IF @Anio IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.fn_ReporteOrdenesCompra(@BranchID) WHERE YEAR(OrderDate) = @Anio)
        THROW 50202, 'El año indicado no existe en las órdenes de compra.', 1;

    IF @Mes IS NOT NULL AND (@Mes < 1 OR @Mes > 12)
        THROW 50203, 'El mes debe estar entre 1 y 12.', 1;

    SELECT
        s.SupplierName AS Proveedor,
        YEAR(po.OrderDate) AS Anio,
        MONTH(po.OrderDate) AS Mes,
        CAST(SUM(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) AS DECIMAL(18,2)) AS MontoTotal,
        MIN(po.OrderDate) AS PrimeraFacturaMes,
        MAX(po.OrderDate) AS UltimaFacturaMes,
        SUM(pol.OrderedOuters) AS CantidadTotal,
        MIN(pol.OrderedOuters) AS CantidadMinima,
        MAX(pol.OrderedOuters) AS CantidadMaxima
    FROM dbo.fn_ReporteOrdenesCompra(@BranchID) AS po
    INNER JOIN dbo.fn_ReporteLineasOrdenCompra(@BranchID) AS pol
        ON po.BranchID = pol.BranchID AND po.PurchaseOrderID = pol.PurchaseOrderID
    INNER JOIN syn_Proveedores AS s
        ON po.SupplierID = s.SupplierID
    INNER JOIN syn_Productos AS si
        ON pol.StockItemID = si.StockItemID
    WHERE
        (@Anio IS NULL OR YEAR(po.OrderDate) = @Anio)
        AND (@Mes IS NULL OR MONTH(po.OrderDate) = @Mes)
        AND
        (
            NULLIF(LTRIM(RTRIM(@CategoriaProducto)), '') IS NULL
            OR EXISTS (SELECT 1 FROM syn_ProductoGrupos AS pig
                       INNER JOIN syn_GruposProducto AS sg ON sg.StockGroupID = pig.StockGroupID
                       WHERE pig.StockItemID = si.StockItemID
                         AND sg.StockGroupName LIKE '%' + LTRIM(RTRIM(@CategoriaProducto)) + '%')
        )
        AND
        (
            NULLIF(LTRIM(RTRIM(@SubcategoriaProducto)), '') IS NULL
            OR si.StockItemName LIKE '%' + LTRIM(RTRIM(@SubcategoriaProducto)) + '%'
        )
    GROUP BY
        s.SupplierName,
        YEAR(po.OrderDate),
        MONTH(po.OrderDate)
    ORDER BY Anio DESC, Mes DESC, MontoTotal DESC, Proveedor ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO


-- ================================================================
-- REPORTE 9: días estimados de rotación/cobertura por producto
-- Parámetros : @CategoriaProducto, @Anio, @Proveedor
-- Nota       : StockItemHoldings representa existencia actual, por lo
--              que el indicador usa inventario actual frente a unidades
--              vendidas del año seleccionado como métrica de rotación.
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte9
    @CategoriaProducto NVARCHAR(50) = NULL,
    @Anio INT = NULL,
    @Proveedor NVARCHAR(100) = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;

    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    WITH VentasPorProducto AS
    (
        SELECT 
            il.StockItemID,
            SUM(il.Quantity) AS TotalVendido
        FROM dbo.fn_ReporteFacturas(@BranchID) AS i
        INNER JOIN dbo.fn_ReporteLineasFactura(@BranchID) AS il ON i.BranchID = il.BranchID AND i.InvoiceID = il.InvoiceID
        WHERE YEAR(i.InvoiceDate) = COALESCE(@Anio, YEAR(GETDATE()))
        GROUP BY il.StockItemID
    )
    SELECT
        si.StockItemName AS Producto,
        grupo.StockGroupName AS Categoria,
        s.SupplierName AS Proveedor,
        ISNULL(@Anio, YEAR(GETDATE())) AS Anio,
        ISNULL(holdings.QuantityOnHand, 0) AS InventarioActual,
        v.TotalVendido,
        
        CASE
            WHEN v.TotalVendido > 0
                THEN CAST((ISNULL(holdings.QuantityOnHand, 0) * 365.0) / v.TotalVendido AS DECIMAL(10,2))
            ELSE 0
        END AS PromedioDiasRotacion
        
    FROM VentasPorProducto AS v 
    INNER JOIN syn_Productos AS si ON v.StockItemID = si.StockItemID
    INNER JOIN syn_Proveedores AS s ON si.SupplierID = s.SupplierID
    OUTER APPLY (
        SELECT SUM(CONVERT(BIGINT, h.QuantityOnHand)) AS QuantityOnHand
        FROM dbo.fn_ReporteInventario(@BranchID) AS h
        WHERE h.StockItemID = si.StockItemID
    ) AS holdings
    OUTER APPLY
    (
        SELECT TOP (1) sg.StockGroupName
        FROM syn_ProductoGrupos AS pig
        INNER JOIN syn_GruposProducto AS sg ON pig.StockGroupID = sg.StockGroupID
        WHERE pig.StockItemID = si.StockItemID
        ORDER BY sg.StockGroupName ASC
    ) AS grupo
    WHERE 
        (NULLIF(LTRIM(RTRIM(@Proveedor)), '') IS NULL OR s.SupplierName LIKE '%' + LTRIM(RTRIM(@Proveedor)) + '%')
        AND 
        (NULLIF(LTRIM(RTRIM(@CategoriaProducto)), '') IS NULL OR grupo.StockGroupName LIKE '%' + LTRIM(RTRIM(@CategoriaProducto)) + '%')
    ORDER BY PromedioDiasRotacion DESC, Producto ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO

/*
================================================================================
REPORTE 10: Métodos de entrega más utilizados por destino.
-- Parámetros : @Anio, @Mes, @CategoriaClienteID, @CategoriaProductoID, @ProductoID
-- Requisitos : DENSE_RANK + PARTITION BY + filtros por año, mes, categoría de cliente, categoría de producto y producto.
================================================================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerReporte10
    @Anio INT = NULL,
    @Mes INT = NULL,
    @CategoriaClienteID INT = NULL,
    @CategoriaProductoID INT = NULL,
    @ProductoID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF DB_NAME() <> N'WWI_Corporativo'
        THROW 50206, 'Los reportes solo estan disponibles en el nodo Corporativo.', 1;
    IF @BranchID IS NOT NULL AND @BranchID NOT IN (1, 2, 3)
        THROW 50205, 'La sucursal indicada no es valida.', 1;
    IF @Pagina IS NULL OR @Pagina < 0 OR @FilasPorPagina IS NULL OR @FilasPorPagina < 1
        THROW 50207, 'La pagina y la cantidad de filas no son validas.', 1;


    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    -- Se obtiene la cantidad de facturas por destino y método de entrega
    WITH VentasPorDestinoYMetodo AS
    (
        SELECT
            cty.CityName AS LugarDestino,
            dm.DeliveryMethodName AS MetodoEnvio,
            COUNT(DISTINCT CONCAT(i.BranchID, ':', i.InvoiceID)) AS CantidadVentas
            -- Se hace DISTINCT para contar cada factura una sola vez, aunque tenga varias líneas de productos,
            -- debido a que se hace un JOIN con Sales.InvoiceLines

        FROM dbo.fn_ReporteFacturas(@BranchID) AS i

        INNER JOIN syn_Clientes AS c
            ON i.CustomerID = c.CustomerID

        INNER JOIN syn_Ciudades AS cty
            ON c.DeliveryCityID = cty.CityID

        INNER JOIN syn_MetodosEntrega AS dm
            ON i.DeliveryMethodID = dm.DeliveryMethodID

        INNER JOIN dbo.fn_ReporteLineasFactura(@BranchID) AS il
            ON i.BranchID = il.BranchID AND i.InvoiceID = il.InvoiceID

        INNER JOIN syn_Productos AS si
            ON il.StockItemID = si.StockItemID

        WHERE
            -- Año y mes
            (@Anio IS NULL OR YEAR(i.InvoiceDate) = @Anio)
            AND (@Mes IS NULL OR MONTH(i.InvoiceDate) = @Mes)

            -- Categoría del cliente
            AND (
                @CategoriaClienteID IS NULL
                OR c.CustomerCategoryID = @CategoriaClienteID
            )

            -- Categoría del producto
            AND (
                @CategoriaProductoID IS NULL OR
                EXISTS (
                    SELECT 1
                    FROM syn_ProductoGrupos AS sisg
                    WHERE sisg.StockItemID = si.StockItemID
                      AND sisg.StockGroupID = @CategoriaProductoID
                )
            )

            -- Producto
            AND (@ProductoID IS NULL OR si.StockItemID = @ProductoID)

        GROUP BY
            cty.CityName,
            dm.DeliveryMethodName
    ),

    MetodosEntregaRanking AS
    (
        SELECT
            LugarDestino,
            MetodoEnvio,
            CantidadVentas,
            DENSE_RANK() OVER (
                PARTITION BY LugarDestino
                ORDER BY CantidadVentas DESC
            ) AS Posicion
        FROM VentasPorDestinoYMetodo
    )

    SELECT
        LugarDestino,
        MetodoEnvio,
        CantidadVentas
    FROM MetodosEntregaRanking
    WHERE Posicion = 1
    ORDER BY CantidadVentas DESC, LugarDestino ASC, MetodoEnvio ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;

END;
GO
