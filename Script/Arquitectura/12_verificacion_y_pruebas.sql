-- =========================================================================
-- 12_verificacion_y_pruebas.sql
-- =========================================================================

-- ======================= A. FRAGMENTACION / REPLICACION UNIDIRECCIONAL =====
USE WWI_Corporativo;
GO
SELECT Tabla, Original, SanJose, Limon, Corp_Replicado,
       Estado = CASE WHEN Original = SanJose + Limon AND Corp_Replicado = SanJose + Limon THEN N'OK'
                     WHEN Original = SanJose + Limon THEN N'Fragmentacion OK, replicacion pendiente'
                     ELSE N'DESVIACION' END
FROM (
SELECT N'Sales.Orders' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Sales.Orders) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[Orders]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[Orders]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.Orders) AS Corp_Replicado
UNION ALL
SELECT N'Sales.OrderLines' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Sales.OrderLines) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[OrderLines]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[OrderLines]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.OrderLines) AS Corp_Replicado
UNION ALL
SELECT N'Sales.Invoices' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Sales.Invoices) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[Invoices]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[Invoices]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.Invoices) AS Corp_Replicado
UNION ALL
SELECT N'Sales.InvoiceLines' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Sales.InvoiceLines) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[InvoiceLines]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[InvoiceLines]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.InvoiceLines) AS Corp_Replicado
UNION ALL
SELECT N'Sales.CustomerTransactions' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Sales.CustomerTransactions) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[CustomerTransactions]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[CustomerTransactions]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.CustomerTransactions) AS Corp_Replicado
UNION ALL
SELECT N'Purchasing.PurchaseOrders' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Purchasing.PurchaseOrders) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[PurchaseOrders]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[PurchaseOrders]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Purchasing.PurchaseOrders) AS Corp_Replicado
UNION ALL
SELECT N'Purchasing.PurchaseOrderLines' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Purchasing.PurchaseOrderLines) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[PurchaseOrderLines]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[PurchaseOrderLines]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Purchasing.PurchaseOrderLines) AS Corp_Replicado
UNION ALL
SELECT N'Purchasing.SupplierTransactions' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Purchasing.SupplierTransactions) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[SupplierTransactions]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[SupplierTransactions]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Purchasing.SupplierTransactions) AS Corp_Replicado
UNION ALL
SELECT N'Warehouse.StockItemTransactions' AS Tabla,
       (SELECT COUNT(*) FROM WideWorldImporters.Warehouse.StockItemTransactions) AS Original,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItemTransactions]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItemTransactions]) AS Limon,
       (SELECT COUNT(*) FROM WWI_Corporativo.Warehouse.StockItemTransactions) AS Corp_Replicado
) x ORDER BY Tabla;
GO

SELECT (SELECT SUM(CAST(QuantityOnHand AS BIGINT)) FROM WideWorldImporters.Warehouse.StockItemHoldings) AS Original,
       (SELECT SUM(CAST(QuantityOnHand AS BIGINT)) FROM [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItemHoldings]) AS SanJose,
       (SELECT SUM(CAST(QuantityOnHand AS BIGINT)) FROM [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItemHoldings]) AS Limon,
       (SELECT SUM(CAST(QuantityOnHand AS BIGINT)) FROM WWI_Corporativo.Warehouse.StockItemHoldings) AS Corp_Replicado;
GO

-- ======================= B. CATALOGOS IGUALES EN LOS 3 NODOS ===============
SELECT * FROM (
SELECT N'Application.DeliveryMethods' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Application.DeliveryMethods) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Application].[DeliveryMethods]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Application].[DeliveryMethods]) AS Limon
UNION ALL
SELECT N'Sales.CustomerCategories' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.CustomerCategories) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[CustomerCategories]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[CustomerCategories]) AS Limon
UNION ALL
SELECT N'Sales.BuyingGroups' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.BuyingGroups) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[BuyingGroups]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[BuyingGroups]) AS Limon
UNION ALL
SELECT N'Purchasing.SupplierCategories' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Purchasing.SupplierCategories) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[SupplierCategories]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[SupplierCategories]) AS Limon
UNION ALL
SELECT N'Warehouse.Colors' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Warehouse.Colors) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[Colors]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[Colors]) AS Limon
UNION ALL
SELECT N'Warehouse.PackageTypes' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Warehouse.PackageTypes) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[PackageTypes]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[PackageTypes]) AS Limon
UNION ALL
SELECT N'Warehouse.StockGroups' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Warehouse.StockGroups) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockGroups]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockGroups]) AS Limon
UNION ALL
SELECT N'Warehouse.StockItemStockGroups' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Warehouse.StockItemStockGroups) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItemStockGroups]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItemStockGroups]) AS Limon
UNION ALL
SELECT N'Warehouse.StockItems' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Warehouse.StockItems) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItems]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItems]) AS Limon
UNION ALL
SELECT N'Sales.Customers_Public' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Sales.Customers_Public) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Sales].[Customers_Public]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Sales].[Customers_Public]) AS Limon
UNION ALL
SELECT N'Purchasing.Suppliers_Public' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.Purchasing.Suppliers_Public) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[Suppliers_Public]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[Suppliers_Public]) AS Limon
UNION ALL
SELECT N'dbo.Branches' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.dbo.Branches) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[dbo].[Branches]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[dbo].[Branches]) AS Limon
UNION ALL
SELECT N'dbo.Users' AS Tabla,
       (SELECT COUNT(*) FROM WWI_Corporativo.dbo.Users) AS Corp,
       (SELECT COUNT(*) FROM [nodo_sucursal_sj].[WWI_SanJose].[dbo].[Users]) AS SanJose,
       (SELECT COUNT(*) FROM [nodo_sucursal_limon].[WWI_Limon].[dbo].[Users]) AS Limon
) y ORDER BY Tabla;
GO