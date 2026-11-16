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

CREATE OR ALTER FUNCTION dbo.fn_BranchIDLocal()
RETURNS INT
AS
BEGIN
    RETURN CASE DB_NAME() WHEN N'WWI_Corporativo' THEN 1
                         WHEN N'WWI_SanJose' THEN 2
                         WHEN N'WWI_Limon' THEN 3 END;
END;
GO
IF SCHEMA_ID(N'Repl') IS NULL EXEC(N'CREATE SCHEMA Repl AUTHORIZATION dbo;');
GO


DECLARE @tablas TABLE (Nombre SYSNAME, Tabla NVARCHAR(128), Columna SYSNAME);
INSERT @tablas VALUES
(N'Customers_Public', N'Sales.Customers_Public', N'CustomerID'),
(N'Suppliers_Public', N'Purchasing.Suppliers_Public', N'SupplierID'),
(N'StockItems', N'Warehouse.StockItems', N'StockItemID'),
(N'StockGroups', N'Warehouse.StockGroups', N'StockGroupID'),
(N'Colors', N'Warehouse.Colors', N'ColorID'),
(N'PackageTypes', N'Warehouse.PackageTypes', N'PackageTypeID'),
(N'StockItemStockGroups', N'Warehouse.StockItemStockGroups', N'StockItemStockGroupID'),
(N'SupplierCategories', N'Purchasing.SupplierCategories', N'SupplierCategoryID'),
(N'DeliveryMethods', N'Application.DeliveryMethods', N'DeliveryMethodID'),
(N'Invoices', N'Sales.Invoices', N'InvoiceID'),
(N'InvoiceLines', N'Sales.InvoiceLines', N'InvoiceLineID');
DECLARE @nombre SYSNAME, @tabla NVARCHAR(128), @col SYSNAME,
        @inicio BIGINT, @limite BIGINT, @maximo BIGINT, @sql NVARCHAR(MAX);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre, Tabla, Columna FROM @tablas;
OPEN c;
FETCH NEXT FROM c INTO @nombre, @tabla, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @inicio = CONVERT(BIGINT, dbo.fn_BranchIDLocal()) * 1000000;
    SET @limite = @inicio + 999999;
    SET @sql = N'SELECT @m = MAX(' + QUOTENAME(@col) + N') FROM ' + @tabla
             + N' WHERE ' + QUOTENAME(@col) + N' BETWEEN @i AND @l;';
    EXEC sys.sp_executesql @sql, N'@m BIGINT OUTPUT, @i BIGINT, @l BIGINT',
                          @m = @maximo OUTPUT, @i = @inicio, @l = @limite;
    IF @maximo IS NOT NULL SET @inicio = @maximo + 1;
    IF NOT EXISTS (SELECT 1 FROM sys.sequences
                   WHERE schema_id = SCHEMA_ID(N'Repl') AND name = N'seq_' + @nombre)
    BEGIN
        SET @sql = N'CREATE SEQUENCE Repl.' + QUOTENAME(N'seq_' + @nombre)
                 + N' AS INT START WITH ' + CONVERT(NVARCHAR(20), @inicio)
                 + N' INCREMENT BY 1 MAXVALUE ' + CONVERT(NVARCHAR(20), @limite) + N' NO CYCLE;';
        EXEC (@sql);
    END;
    FETCH NEXT FROM c INTO @nombre, @tabla, @col;
END;
CLOSE c;
DEALLOCATE c;
GO
IF dbo.fn_BranchIDLocal() = 1
    EXEC(N'CREATE OR ALTER VIEW dbo.vw_Customers AS SELECT p.*, q.PrimaryContactPersonID, q.AlternateContactPersonID, q.DeliveryCityID, q.PostalCityID, q.PhoneNumber, q.FaxNumber, q.WebsiteURL, q.DeliveryAddressLine1, q.DeliveryAddressLine2, q.DeliveryPostalCode, q.DeliveryLocation, q.PostalAddressLine1, q.PostalAddressLine2, q.PostalPostalCode FROM Sales.Customers_Public AS p LEFT JOIN Sales.Customers_Private AS q ON q.BranchID = p.BranchID AND q.CustomerID = p.CustomerID;');
ELSE
    EXEC(N'CREATE OR ALTER VIEW dbo.vw_Customers AS SELECT p.*, CAST(NULL AS INT) AS PrimaryContactPersonID, CAST(NULL AS INT) AS AlternateContactPersonID, CAST(NULL AS INT) AS DeliveryCityID, CAST(NULL AS INT) AS PostalCityID, CAST(NULL AS NVARCHAR(20)) AS PhoneNumber, CAST(NULL AS NVARCHAR(20)) AS FaxNumber, CAST(NULL AS NVARCHAR(256)) AS WebsiteURL, CAST(NULL AS NVARCHAR(60)) AS DeliveryAddressLine1, CAST(NULL AS NVARCHAR(60)) AS DeliveryAddressLine2, CAST(NULL AS NVARCHAR(10)) AS DeliveryPostalCode, CAST(NULL AS GEOGRAPHY) AS DeliveryLocation, CAST(NULL AS NVARCHAR(60)) AS PostalAddressLine1, CAST(NULL AS NVARCHAR(60)) AS PostalAddressLine2, CAST(NULL AS NVARCHAR(10)) AS PostalPostalCode FROM Sales.Customers_Public AS p;');
GO
IF dbo.fn_BranchIDLocal() = 1
    EXEC(N'CREATE OR ALTER VIEW dbo.vw_Suppliers AS SELECT p.*, q.PrimaryContactPersonID, q.AlternateContactPersonID, q.DeliveryCityID, q.PostalCityID, q.PhoneNumber, q.FaxNumber, q.WebsiteURL, q.DeliveryAddressLine1, q.DeliveryAddressLine2, q.DeliveryPostalCode, q.DeliveryLocation, q.PostalAddressLine1, q.PostalAddressLine2, q.PostalPostalCode, q.BankAccountName, q.BankAccountBranch, q.BankAccountCode, q.BankAccountNumber, q.BankInternationalCode, q.InternalComments FROM Purchasing.Suppliers_Public AS p LEFT JOIN Purchasing.Suppliers_Private AS q ON q.BranchID = p.BranchID AND q.SupplierID = p.SupplierID;');
ELSE
    EXEC(N'CREATE OR ALTER VIEW dbo.vw_Suppliers AS SELECT p.*, CAST(NULL AS INT) AS PrimaryContactPersonID, CAST(NULL AS INT) AS AlternateContactPersonID, CAST(NULL AS INT) AS DeliveryCityID, CAST(NULL AS INT) AS PostalCityID, CAST(NULL AS NVARCHAR(20)) AS PhoneNumber, CAST(NULL AS NVARCHAR(20)) AS FaxNumber, CAST(NULL AS NVARCHAR(256)) AS WebsiteURL, CAST(NULL AS NVARCHAR(60)) AS DeliveryAddressLine1, CAST(NULL AS NVARCHAR(60)) AS DeliveryAddressLine2, CAST(NULL AS NVARCHAR(10)) AS DeliveryPostalCode, CAST(NULL AS GEOGRAPHY) AS DeliveryLocation, CAST(NULL AS NVARCHAR(60)) AS PostalAddressLine1, CAST(NULL AS NVARCHAR(60)) AS PostalAddressLine2, CAST(NULL AS NVARCHAR(10)) AS PostalPostalCode, CAST(NULL AS NVARCHAR(50)) AS BankAccountName, CAST(NULL AS NVARCHAR(50)) AS BankAccountBranch, CAST(NULL AS NVARCHAR(20)) AS BankAccountCode, CAST(NULL AS NVARCHAR(20)) AS BankAccountNumber, CAST(NULL AS NVARCHAR(20)) AS BankInternationalCode, CAST(NULL AS NVARCHAR(MAX)) AS InternalComments FROM Purchasing.Suppliers_Public AS p;');
GO
DROP SYNONYM IF EXISTS syn_Clientes;
CREATE SYNONYM syn_Clientes FOR dbo.vw_Customers;
DROP SYNONYM IF EXISTS syn_CategoriasCliente;
CREATE SYNONYM syn_CategoriasCliente FOR Sales.CustomerCategories;
DROP SYNONYM IF EXISTS syn_GruposCompra;
CREATE SYNONYM syn_GruposCompra FOR Sales.BuyingGroups;
DROP SYNONYM IF EXISTS syn_Proveedores;
CREATE SYNONYM syn_Proveedores FOR dbo.vw_Suppliers;
DROP SYNONYM IF EXISTS syn_CategoriasProveedor;
CREATE SYNONYM syn_CategoriasProveedor FOR Purchasing.SupplierCategories;
DROP SYNONYM IF EXISTS syn_MetodosEntrega;
CREATE SYNONYM syn_MetodosEntrega FOR Application.DeliveryMethods;
DROP SYNONYM IF EXISTS syn_Ciudades;
CREATE SYNONYM syn_Ciudades FOR Application.Cities;
DROP SYNONYM IF EXISTS syn_Personas;
CREATE SYNONYM syn_Personas FOR Application.People;
DROP SYNONYM IF EXISTS syn_Productos;
CREATE SYNONYM syn_Productos FOR Warehouse.StockItems;
DROP SYNONYM IF EXISTS syn_Colores;
CREATE SYNONYM syn_Colores FOR Warehouse.Colors;
DROP SYNONYM IF EXISTS syn_TiposEmpaque;
CREATE SYNONYM syn_TiposEmpaque FOR Warehouse.PackageTypes;
DROP SYNONYM IF EXISTS syn_GruposProducto;
CREATE SYNONYM syn_GruposProducto FOR Warehouse.StockGroups;
DROP SYNONYM IF EXISTS syn_ProductoGrupos;
CREATE SYNONYM syn_ProductoGrupos FOR Warehouse.StockItemStockGroups;
DROP SYNONYM IF EXISTS syn_Inventario;
CREATE SYNONYM syn_Inventario FOR Warehouse.StockItemHoldings;
DROP SYNONYM IF EXISTS syn_OrdenesCompra;
CREATE SYNONYM syn_OrdenesCompra FOR Purchasing.PurchaseOrders;
DROP SYNONYM IF EXISTS syn_LineasOrdenCompra;
CREATE SYNONYM syn_LineasOrdenCompra FOR Purchasing.PurchaseOrderLines;
DROP SYNONYM IF EXISTS syn_Facturas;
CREATE SYNONYM syn_Facturas FOR Sales.Invoices;
DROP SYNONYM IF EXISTS syn_LineasFactura;
CREATE SYNONYM syn_LineasFactura FOR Sales.InvoiceLines;
DROP SYNONYM IF EXISTS syn_TransaccionesCliente;
CREATE SYNONYM syn_TransaccionesCliente FOR Sales.CustomerTransactions;
DROP SYNONYM IF EXISTS syn_TransaccionesInventario;
CREATE SYNONYM syn_TransaccionesInventario FOR Warehouse.StockItemTransactions;

GO

-- Las tablas distribuidas no declaran todas las FK del modelo original.
-- Comprobar tambien las sucursales evita depender de que la replica ya llego.
CREATE OR ALTER PROCEDURE dbo.sp_ValidarEliminacionLocal
    @Entidad VARCHAR(20), @ID INT, @SucursalInventario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Entidad = 'Producto' AND (@SucursalInventario IS NULL OR @SucursalInventario NOT IN (1, 2, 3))
        THROW 50045, 'Indique la sucursal propietaria del inventario.', 1;
    IF @Entidad = 'Cliente'
    BEGIN
        IF EXISTS (SELECT 1 FROM Sales.Invoices WHERE CustomerID = @ID OR BillToCustomerID = @ID)
           OR EXISTS (SELECT 1 FROM Sales.Orders WHERE CustomerID = @ID)
           OR EXISTS (SELECT 1 FROM Sales.CustomerTransactions WHERE CustomerID = @ID)
           OR EXISTS (SELECT 1 FROM Warehouse.StockItemTransactions WHERE CustomerID = @ID)
           OR EXISTS (SELECT 1 FROM Sales.Customers_Public WHERE BillToCustomerID = @ID AND CustomerID <> @ID)
            THROW 50043, 'El cliente tiene facturas, pedidos, movimientos o clientes de facturacion asociados.', 1;
    END
    ELSE IF @Entidad = 'Proveedor'
    BEGIN
        IF EXISTS (SELECT 1 FROM Warehouse.StockItems WHERE SupplierID = @ID)
           OR EXISTS (SELECT 1 FROM Purchasing.PurchaseOrders WHERE SupplierID = @ID)
           OR EXISTS (SELECT 1 FROM Purchasing.SupplierTransactions WHERE SupplierID = @ID)
           OR EXISTS (SELECT 1 FROM Warehouse.StockItemTransactions WHERE SupplierID = @ID)
            THROW 50043, 'El proveedor tiene productos, compras o movimientos asociados.', 1;
    END
    ELSE IF @Entidad = 'Producto'
    BEGIN
        IF EXISTS (SELECT 1 FROM Sales.InvoiceLines WHERE StockItemID = @ID)
           OR EXISTS (SELECT 1 FROM Sales.OrderLines WHERE StockItemID = @ID)
           OR EXISTS (SELECT 1 FROM Purchasing.PurchaseOrderLines WHERE StockItemID = @ID)
           OR EXISTS (SELECT 1 FROM Warehouse.StockItemTransactions WHERE StockItemID = @ID)
           OR EXISTS (SELECT 1 FROM Warehouse.StockItemHoldings WHERE StockItemID = @ID AND BranchID <> @SucursalInventario)
            THROW 50044, 'El producto tiene movimientos o existencias en otra sucursal.', 1;
    END
    ELSE
        THROW 50048, 'Entidad no admitida para validar la eliminacion.', 1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.sp_ValidarEliminacionGlobal
    @Entidad VARCHAR(20), @ID INT, @SucursalInventario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @@TRANCOUNT <> 0
        THROW 50041, 'Valide la eliminacion fuera de una transaccion local.', 1;
    IF dbo.fn_BranchIDLocal() <> 1
    BEGIN
        EXEC [nodo_corporativo].[WWI_Corporativo].dbo.sp_ValidarEliminacionGlobal
            @Entidad = @Entidad, @ID = @ID, @SucursalInventario = @SucursalInventario;
        RETURN;
    END;
    EXEC dbo.sp_ValidarEliminacionLocal @Entidad, @ID, @SucursalInventario;
    EXEC [nodo_sucursal_sj].[WWI_SanJose].dbo.sp_ValidarEliminacionLocal
        @Entidad = @Entidad, @ID = @ID, @SucursalInventario = @SucursalInventario;
    EXEC [nodo_sucursal_limon].[WWI_Limon].dbo.sp_ValidarEliminacionLocal
        @Entidad = @Entidad, @ID = @ID, @SucursalInventario = @SucursalInventario;
END;
GO
