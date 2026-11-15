-- =========================================================================
-- 12_verificacion_y_pruebas.sql
-- =========================================================================

-- ======================= A. UNIDIRECCIONAL: Corp = San Jose + Limon ========
USE WWI_Corporativo;
GO
SET NOCOUNT ON;
DECLARE @t TABLE (Tabla SYSNAME);
INSERT @t VALUES (N'Sales.Orders'), (N'Sales.OrderLines'), (N'Sales.Invoices'), (N'Sales.InvoiceLines'),
                 (N'Sales.CustomerTransactions'), (N'Purchasing.PurchaseOrders'), (N'Purchasing.PurchaseOrderLines'),
                 (N'Purchasing.SupplierTransactions'), (N'Warehouse.StockItemTransactions'), (N'Warehouse.StockItemHoldings');
DECLARE @r TABLE (Tabla SYSNAME, SanJose INT, Limon INT, Corp INT);
DECLARE @x SYSNAME, @sql NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Tabla FROM @t;
OPEN c; FETCH NEXT FROM c INTO @x;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT N''' + @x + N''', (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].' + @x
             + N'), (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].' + @x
             + N'), (SELECT COUNT(*) FROM WWI_Corporativo.' + @x + N')';
    INSERT @r EXEC (@sql);
    FETCH NEXT FROM c INTO @x;
END
CLOSE c; DEALLOCATE c;
SELECT *, Estado = CASE WHEN Corp = SanJose + Limon THEN N'OK' ELSE N'PENDIENTE (espera el snapshot) o DESVIACION' END
FROM @r ORDER BY Tabla;
GO

-- ======================= B. CATALOGOS: mismos datos en los 3 nodos =========
SET NOCOUNT ON;
DECLARE @t TABLE (Tabla SYSNAME);
INSERT @t VALUES (N'Application.DeliveryMethods'), (N'Sales.CustomerCategories'), (N'Sales.BuyingGroups'),
                 (N'Purchasing.SupplierCategories'), (N'Warehouse.Colors'), (N'Warehouse.PackageTypes'),
                 (N'Warehouse.StockGroups'), (N'Warehouse.StockItemStockGroups'), (N'Warehouse.StockItems'),
                 (N'Sales.Customers_Public'), (N'Purchasing.Suppliers_Public'), (N'dbo.Users');
DECLARE @r TABLE (Tabla SYSNAME, Corp INT, SanJose INT, Limon INT);
DECLARE @x SYSNAME, @sql NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Tabla FROM @t;
OPEN c; FETCH NEXT FROM c INTO @x;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT N''' + @x + N''', (SELECT COUNT(*) FROM WWI_Corporativo.' + @x
             + N'), (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].' + @x
             + N'), (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].' + @x + N')';
    INSERT @r EXEC (@sql);
    FETCH NEXT FROM c INTO @x;
END
CLOSE c; DEALLOCATE c;
SELECT *, Estado = CASE WHEN Corp = SanJose AND SanJose = Limon THEN N'OK' ELSE N'DIFERENTE' END FROM @r ORDER BY Tabla;

-- Convergencia de contenido en productos (las 3 sumas deben ser iguales)
SELECT (SELECT CHECKSUM_AGG(CHECKSUM(BranchID, StockItemID, StockItemName, UnitPrice, RecommendedRetailPrice)) FROM WWI_Corporativo.Warehouse.StockItems) AS Corp,
       (SELECT CHECKSUM_AGG(CHECKSUM(BranchID, StockItemID, StockItemName, UnitPrice, RecommendedRetailPrice)) FROM [nodo_sucursal_sj].[WWI_SanJose].Warehouse.StockItems) AS SanJose,
       (SELECT CHECKSUM_AGG(CHECKSUM(BranchID, StockItemID, StockItemName, UnitPrice, RecommendedRetailPrice)) FROM [nodo_sucursal_limon].[WWI_Limon].Warehouse.StockItems) AS Limon;
GO



-- ======================= D. ESTADISTICAS (solo Corporativo) ================
-- USE WWI_Corporativo;
-- EXEC Reporting.sp_EstadisticasVentas @BranchID = NULL;   -- consolidado
-- EXEC Reporting.sp_EstadisticasVentas @BranchID = 2;      -- San Jose
-- EXEC Reporting.sp_EstadisticasVentas @BranchID = 3;      -- Limon