-- =========================================================================
-- 07_migrar_sucursales.sql
-- Se ejecuta desde el corporativo
-- =========================================================================

USE master;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_WARNINGS ON;
SET ANSI_PADDING ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
GO

PRINT '=================================================================================';
PRINT 'FASE 3: MIGRACION DISTRIBUIDA';
PRINT '=================================================================================';

-- Habilitar comandos remotos
EXEC sp_serveroption 'nodo_sucursal_sj', 'rpc out', 'true';
EXEC sp_serveroption 'nodo_sucursal_limon', 'rpc out', 'true';
GO

PRINT '--------------------------------------------------';
PRINT '1. MIGRANDO CATALOGOS BASE Y DE SOPORTE';
PRINT '--------------------------------------------------';
USE WideWorldImporters;
GO

-- Application.People
INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Application].[People] (BranchID, PersonID, FullName, PreferredName, SearchName, IsPermittedToLogon, LogonName, IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee, IsSalesperson, UserPreferences, PhoneNumber, FaxNumber, EmailAddress, Photo, CustomFields, OtherLanguages, LastEditedBy)
SELECT 1, PersonID, FullName, PreferredName, SearchName, IsPermittedToLogon, LogonName, IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee, IsSalesperson, UserPreferences, PhoneNumber, FaxNumber, EmailAddress, Photo, CustomFields, OtherLanguages, LastEditedBy FROM Application.People;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Application].[People] (BranchID, PersonID, FullName, PreferredName, SearchName, IsPermittedToLogon, LogonName, IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee, IsSalesperson, UserPreferences, PhoneNumber, FaxNumber, EmailAddress, Photo, CustomFields, OtherLanguages, LastEditedBy)
SELECT 1, PersonID, FullName, PreferredName, SearchName, IsPermittedToLogon, LogonName, IsExternalLogonProvider, HashedPassword, IsSystemUser, IsEmployee, IsSalesperson, UserPreferences, PhoneNumber, FaxNumber, EmailAddress, Photo, CustomFields, OtherLanguages, LastEditedBy FROM Application.People;

-- Auxiliares
INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Application].[DeliveryMethods] (BranchID, DeliveryMethodID, DeliveryMethodName, LastEditedBy) SELECT 1, DeliveryMethodID, DeliveryMethodName, LastEditedBy FROM Application.DeliveryMethods;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Application].[DeliveryMethods] (BranchID, DeliveryMethodID, DeliveryMethodName, LastEditedBy) SELECT 1, DeliveryMethodID, DeliveryMethodName, LastEditedBy FROM Application.DeliveryMethods;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[Colors] (BranchID, ColorID, ColorName, LastEditedBy) SELECT 1, ColorID, ColorName, LastEditedBy FROM Warehouse.Colors;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[Colors] (BranchID, ColorID, ColorName, LastEditedBy) SELECT 1, ColorID, ColorName, LastEditedBy FROM Warehouse.Colors;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[PackageTypes] (BranchID, PackageTypeID, PackageTypeName, LastEditedBy) SELECT 1, PackageTypeID, PackageTypeName, LastEditedBy FROM Warehouse.PackageTypes;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[PackageTypes] (BranchID, PackageTypeID, PackageTypeName, LastEditedBy) SELECT 1, PackageTypeID, PackageTypeName, LastEditedBy FROM Warehouse.PackageTypes;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockGroups] (BranchID, StockGroupID, StockGroupName, LastEditedBy) SELECT 1, StockGroupID, StockGroupName, LastEditedBy FROM Warehouse.StockGroups;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockGroups] (BranchID, StockGroupID, StockGroupName, LastEditedBy) SELECT 1, StockGroupID, StockGroupName, LastEditedBy FROM Warehouse.StockGroups;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[CustomerCategories] (BranchID, CustomerCategoryID, CustomerCategoryName, LastEditedBy) SELECT 1, CustomerCategoryID, CustomerCategoryName, LastEditedBy FROM Sales.CustomerCategories;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[CustomerCategories] (BranchID, CustomerCategoryID, CustomerCategoryName, LastEditedBy) SELECT 1, CustomerCategoryID, CustomerCategoryName, LastEditedBy FROM Sales.CustomerCategories;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[SupplierCategories] (BranchID, SupplierCategoryID, SupplierCategoryName, LastEditedBy) SELECT 1, SupplierCategoryID, SupplierCategoryName, LastEditedBy FROM Purchasing.SupplierCategories;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[SupplierCategories] (BranchID, SupplierCategoryID, SupplierCategoryName, LastEditedBy) SELECT 1, SupplierCategoryID, SupplierCategoryName, LastEditedBy FROM Purchasing.SupplierCategories;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Application].[TransactionTypes] (BranchID, TransactionTypeID, TransactionTypeName, LastEditedBy) SELECT 1, TransactionTypeID, TransactionTypeName, LastEditedBy FROM Application.TransactionTypes;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Application].[TransactionTypes] (BranchID, TransactionTypeID, TransactionTypeName, LastEditedBy) SELECT 1, TransactionTypeID, TransactionTypeName, LastEditedBy FROM Application.TransactionTypes;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Application].[PaymentMethods] (BranchID, PaymentMethodID, PaymentMethodName, LastEditedBy) SELECT 1, PaymentMethodID, PaymentMethodName, LastEditedBy FROM Application.PaymentMethods;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Application].[PaymentMethods] (BranchID, PaymentMethodID, PaymentMethodName, LastEditedBy) SELECT 1, PaymentMethodID, PaymentMethodName, LastEditedBy FROM Application.PaymentMethods;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[BuyingGroups] (BranchID, BuyingGroupID, BuyingGroupName, LastEditedBy) SELECT 1, BuyingGroupID, BuyingGroupName, LastEditedBy FROM Sales.BuyingGroups;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[BuyingGroups] (BranchID, BuyingGroupID, BuyingGroupName, LastEditedBy) SELECT 1, BuyingGroupID, BuyingGroupName, LastEditedBy FROM Sales.BuyingGroups;


PRINT '--------------------------------------------------';
PRINT '2. MIGRANDO DATOS ESPACIALES (GEOGRAPHY)';
PRINT '--------------------------------------------------';

INSERT INTO OPENQUERY([nodo_sucursal_sj], 'SELECT BranchID, CountryID, CountryName, FormalName, IsoAlpha3Code, IsoNumericCode, CountryType, LatestRecordedPopulation, Continent, Region, Subregion, Border, LastEditedBy FROM WWI_SanJose.Application.Countries')
SELECT 1, CountryID, CountryName, FormalName, IsoAlpha3Code, IsoNumericCode, CountryType, LatestRecordedPopulation, Continent, Region, Subregion, CAST(CAST(Border AS VARBINARY(MAX)) AS GEOGRAPHY), LastEditedBy FROM Application.Countries;

INSERT INTO OPENQUERY([nodo_sucursal_limon], 'SELECT BranchID, CountryID, CountryName, FormalName, IsoAlpha3Code, IsoNumericCode, CountryType, LatestRecordedPopulation, Continent, Region, Subregion, Border, LastEditedBy FROM WWI_Limon.Application.Countries')
SELECT 1, CountryID, CountryName, FormalName, IsoAlpha3Code, IsoNumericCode, CountryType, LatestRecordedPopulation, Continent, Region, Subregion, CAST(CAST(Border AS VARBINARY(MAX)) AS GEOGRAPHY), LastEditedBy FROM Application.Countries;

INSERT INTO OPENQUERY([nodo_sucursal_sj], 'SELECT BranchID, StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, SalesTerritory, Border, LatestRecordedPopulation, LastEditedBy FROM WWI_SanJose.Application.StateProvinces')
SELECT 1, StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, SalesTerritory, CAST(CAST(Border AS VARBINARY(MAX)) AS GEOGRAPHY), LatestRecordedPopulation, LastEditedBy FROM Application.StateProvinces;

INSERT INTO OPENQUERY([nodo_sucursal_limon], 'SELECT BranchID, StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, SalesTerritory, Border, LatestRecordedPopulation, LastEditedBy FROM WWI_Limon.Application.StateProvinces')
SELECT 1, StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, SalesTerritory, CAST(CAST(Border AS VARBINARY(MAX)) AS GEOGRAPHY), LatestRecordedPopulation, LastEditedBy FROM Application.StateProvinces;

INSERT INTO OPENQUERY([nodo_sucursal_sj], 'SELECT BranchID, CityID, CityName, StateProvinceID, Location, LatestRecordedPopulation, LastEditedBy FROM WWI_SanJose.Application.Cities')
SELECT 1, CityID, CityName, StateProvinceID, CAST(CAST(Location AS VARBINARY(MAX)) AS GEOGRAPHY), LatestRecordedPopulation, LastEditedBy FROM Application.Cities;

INSERT INTO OPENQUERY([nodo_sucursal_limon], 'SELECT BranchID, CityID, CityName, StateProvinceID, Location, LatestRecordedPopulation, LastEditedBy FROM WWI_Limon.Application.Cities')
SELECT 1, CityID, CityName, StateProvinceID, CAST(CAST(Location AS VARBINARY(MAX)) AS GEOGRAPHY), LatestRecordedPopulation, LastEditedBy FROM Application.Cities;

INSERT INTO OPENQUERY([nodo_sucursal_sj], 'SELECT BranchID, SystemParameterID, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode, ApplicationSettings, LastEditedBy, LastEditedWhen FROM WWI_SanJose.Application.SystemParameters')
SELECT 1, SystemParameterID, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID, DeliveryPostalCode, CAST(CAST(DeliveryLocation AS VARBINARY(MAX)) AS GEOGRAPHY), PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode, ApplicationSettings, LastEditedBy, LastEditedWhen FROM Application.SystemParameters;

INSERT INTO OPENQUERY([nodo_sucursal_limon], 'SELECT BranchID, SystemParameterID, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode, ApplicationSettings, LastEditedBy, LastEditedWhen FROM WWI_Limon.Application.SystemParameters')
SELECT 1, SystemParameterID, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID, DeliveryPostalCode, CAST(CAST(DeliveryLocation AS VARBINARY(MAX)) AS GEOGRAPHY), PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode, ApplicationSettings, LastEditedBy, LastEditedWhen FROM Application.SystemParameters;


PRINT '-----------------------------------------------------';
PRINT '3. MIGRANDO RELACIONES, PRODUCTOS Y CLIENTES PÚBLICOS';
PRINT '-----------------------------------------------------';

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItemStockGroups] (BranchID, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy) SELECT 1, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy FROM Warehouse.StockItemStockGroups;
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItemStockGroups] (BranchID, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy) SELECT 1, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy FROM Warehouse.StockItemStockGroups;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[Customers_Public] (BranchID, CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, DeliveryMethodID, DeliveryRun, RunPosition, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, LastEditedBy)
SELECT 1, CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, DeliveryMethodID, DeliveryRun, RunPosition, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, LastEditedBy FROM Sales.Customers;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[Customers_Public] (BranchID, CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, DeliveryMethodID, DeliveryRun, RunPosition, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, LastEditedBy)
SELECT 1, CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, DeliveryMethodID, DeliveryRun, RunPosition, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, LastEditedBy FROM Sales.Customers;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[Suppliers_Public] (BranchID, SupplierID, SupplierName, SupplierCategoryID, SupplierReference, DeliveryMethodID, PaymentDays, LastEditedBy)
SELECT 1, SupplierID, SupplierName, SupplierCategoryID, SupplierReference, DeliveryMethodID, PaymentDays, LastEditedBy FROM Purchasing.Suppliers;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[Suppliers_Public] (BranchID, SupplierID, SupplierName, SupplierCategoryID, SupplierReference, DeliveryMethodID, PaymentDays, LastEditedBy)
SELECT 1, SupplierID, SupplierName, SupplierCategoryID, SupplierReference, DeliveryMethodID, PaymentDays, LastEditedBy FROM Purchasing.Suppliers;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItems] (BranchID, StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, CustomFields, LastEditedBy, ValidFrom)
SELECT 1, StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, CustomFields, LastEditedBy, ValidFrom FROM Warehouse.StockItems;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItems] (BranchID, StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, CustomFields, LastEditedBy, ValidFrom)
SELECT 1, StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, CustomFields, LastEditedBy, ValidFrom FROM Warehouse.StockItems;


PRINT '--------------------------------------------------------------';
PRINT '4. FRAGMENTANDO TRANSACCIONES (PARES SAN JOSE / IMPARES LIMON)';
PRINT '--------------------------------------------------------------';

-- ========================== SAN JOSE (PARES) ==========================
INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[Orders] (BranchID, OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
SELECT 2, OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments, PickingCompletedWhen, LastEditedBy, LastEditedWhen
FROM Sales.Orders WHERE CustomerID % 2 = 0;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[Invoices] (BranchID, InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments, TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData, LastEditedBy, LastEditedWhen)
SELECT 2, InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments, TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData, LastEditedBy, LastEditedWhen
FROM Sales.Invoices WHERE CustomerID % 2 = 0;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[PurchaseOrders] (BranchID, PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID, ContactPersonID, ExpectedDeliveryDate, SupplierReference, IsOrderFinalized, Comments, InternalComments, LastEditedBy, LastEditedWhen)
SELECT 2, PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID, ContactPersonID, ExpectedDeliveryDate, SupplierReference, IsOrderFinalized, Comments, InternalComments, LastEditedBy, LastEditedWhen
FROM Purchasing.PurchaseOrders WHERE SupplierID % 2 = 0;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[CustomerTransactions] (BranchID, CustomerTransactionID, CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
SELECT 2, CustomerTransactionID, CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen
FROM Sales.CustomerTransactions WHERE CustomerID % 2 = 0;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[SupplierTransactions] (BranchID, SupplierTransactionID, SupplierID, TransactionTypeID, PurchaseOrderID, PaymentMethodID, SupplierInvoiceNumber, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
SELECT 2, SupplierTransactionID, SupplierID, TransactionTypeID, PurchaseOrderID, PaymentMethodID, SupplierInvoiceNumber, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen
FROM Purchasing.SupplierTransactions WHERE SupplierID % 2 = 0;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItemTransactions] (BranchID, StockItemTransactionID, StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID, TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
SELECT 2, StockItemTransactionID, StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID, TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen
FROM Warehouse.StockItemTransactions
WHERE (CustomerID IS NOT NULL AND CustomerID % 2 = 0) OR (CustomerID IS NULL AND SupplierID IS NOT NULL AND SupplierID % 2 = 0) OR (CustomerID IS NULL AND SupplierID IS NULL AND StockItemTransactionID % 2 = 0);

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Warehouse].[StockItemHoldings] (BranchID, StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen)
SELECT 2, StockItemID, (QuantityOnHand / 2), BinLocation, (LastStocktakeQuantity / 2), LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen FROM Warehouse.StockItemHoldings;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[OrderLines] (BranchID, OrderLineID, OrderID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
SELECT 2, ol.OrderLineID, ol.OrderID, ol.StockItemID, ol.Description, ol.PackageTypeID, ol.Quantity, ol.UnitPrice, ol.TaxRate, ol.PickedQuantity, ol.PickingCompletedWhen, ol.LastEditedBy, ol.LastEditedWhen
FROM Sales.OrderLines ol JOIN Sales.Orders o ON ol.OrderID = o.OrderID WHERE o.CustomerID % 2 = 0;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Sales].[InvoiceLines] (BranchID, InvoiceLineID, InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
SELECT 2, il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.PackageTypeID, il.Quantity, il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit, il.ExtendedPrice, il.LastEditedBy, il.LastEditedWhen
FROM Sales.InvoiceLines il JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID WHERE i.CustomerID % 2 = 0;

INSERT INTO [nodo_sucursal_sj].[WWI_SanJose].[Purchasing].[PurchaseOrderLines] (BranchID, PurchaseOrderLineID, PurchaseOrderID, StockItemID, OrderedOuters, Description, ReceivedOuters, PackageTypeID, ExpectedUnitPricePerOuter, LastReceiptDate, IsOrderLineFinalized, LastEditedBy, LastEditedWhen)
SELECT 2, pol.PurchaseOrderLineID, pol.PurchaseOrderID, pol.StockItemID, pol.OrderedOuters, pol.Description, pol.ReceivedOuters, pol.PackageTypeID, pol.ExpectedUnitPricePerOuter, pol.LastReceiptDate, pol.IsOrderLineFinalized, pol.LastEditedBy, pol.LastEditedWhen
FROM Purchasing.PurchaseOrderLines pol JOIN Purchasing.PurchaseOrders po ON pol.PurchaseOrderID = po.PurchaseOrderID WHERE po.SupplierID % 2 = 0;


-- ========================== LIMON (IMPARES) ==========================
INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[Orders] (BranchID, OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
SELECT 3, OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate, CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments, PickingCompletedWhen, LastEditedBy, LastEditedWhen
FROM Sales.Orders WHERE CustomerID % 2 <> 0;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[Invoices] (BranchID, InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments, TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData, LastEditedBy, LastEditedWhen)
SELECT 3, InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments, TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData, LastEditedBy, LastEditedWhen
FROM Sales.Invoices WHERE CustomerID % 2 <> 0;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[PurchaseOrders] (BranchID, PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID, ContactPersonID, ExpectedDeliveryDate, SupplierReference, IsOrderFinalized, Comments, InternalComments, LastEditedBy, LastEditedWhen)
SELECT 3, PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID, ContactPersonID, ExpectedDeliveryDate, SupplierReference, IsOrderFinalized, Comments, InternalComments, LastEditedBy, LastEditedWhen
FROM Purchasing.PurchaseOrders WHERE SupplierID % 2 <> 0;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[CustomerTransactions] (BranchID, CustomerTransactionID, CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
SELECT 3, CustomerTransactionID, CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen
FROM Sales.CustomerTransactions WHERE CustomerID % 2 <> 0;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[SupplierTransactions] (BranchID, SupplierTransactionID, SupplierID, TransactionTypeID, PurchaseOrderID, PaymentMethodID, SupplierInvoiceNumber, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
SELECT 3, SupplierTransactionID, SupplierID, TransactionTypeID, PurchaseOrderID, PaymentMethodID, SupplierInvoiceNumber, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen
FROM Purchasing.SupplierTransactions WHERE SupplierID % 2 <> 0;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItemTransactions] (BranchID, StockItemTransactionID, StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID, TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
SELECT 3, StockItemTransactionID, StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID, TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen
FROM Warehouse.StockItemTransactions
WHERE (CustomerID IS NOT NULL AND CustomerID % 2 <> 0) OR (CustomerID IS NULL AND SupplierID IS NOT NULL AND SupplierID % 2 <> 0) OR (CustomerID IS NULL AND SupplierID IS NULL AND StockItemTransactionID % 2 <> 0);

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Warehouse].[StockItemHoldings] (BranchID, StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen)
SELECT 3, StockItemID, (QuantityOnHand - (QuantityOnHand / 2)), BinLocation, (LastStocktakeQuantity - (LastStocktakeQuantity / 2)), LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy, LastEditedWhen FROM Warehouse.StockItemHoldings;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[OrderLines] (BranchID, OrderLineID, OrderID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, PickedQuantity, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
SELECT 3, ol.OrderLineID, ol.OrderID, ol.StockItemID, ol.Description, ol.PackageTypeID, ol.Quantity, ol.UnitPrice, ol.TaxRate, ol.PickedQuantity, ol.PickingCompletedWhen, ol.LastEditedBy, ol.LastEditedWhen
FROM Sales.OrderLines ol JOIN Sales.Orders o ON ol.OrderID = o.OrderID WHERE o.CustomerID % 2 <> 0;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Sales].[InvoiceLines] (BranchID, InvoiceLineID, InvoiceID, StockItemID, Description, PackageTypeID, Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice, LastEditedBy, LastEditedWhen)
SELECT 3, il.InvoiceLineID, il.InvoiceID, il.StockItemID, il.Description, il.PackageTypeID, il.Quantity, il.UnitPrice, il.TaxRate, il.TaxAmount, il.LineProfit, il.ExtendedPrice, il.LastEditedBy, il.LastEditedWhen
FROM Sales.InvoiceLines il JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID WHERE i.CustomerID % 2 <> 0;

INSERT INTO [nodo_sucursal_limon].[WWI_Limon].[Purchasing].[PurchaseOrderLines] (BranchID, PurchaseOrderLineID, PurchaseOrderID, StockItemID, OrderedOuters, Description, ReceivedOuters, PackageTypeID, ExpectedUnitPricePerOuter, LastReceiptDate, IsOrderLineFinalized, LastEditedBy, LastEditedWhen)
SELECT 3, pol.PurchaseOrderLineID, pol.PurchaseOrderID, pol.StockItemID, pol.OrderedOuters, pol.Description, pol.ReceivedOuters, pol.PackageTypeID, pol.ExpectedUnitPricePerOuter, pol.LastReceiptDate, pol.IsOrderLineFinalized, pol.LastEditedBy, pol.LastEditedWhen
FROM Purchasing.PurchaseOrderLines pol JOIN Purchasing.PurchaseOrders po ON pol.PurchaseOrderID = po.PurchaseOrderID WHERE po.SupplierID % 2 <> 0;

PRINT '=================================================================================';
PRINT 'MIGRACION COMPLETADA. Nodos listos para la Configuracion de Replicacion.';
PRINT '=================================================================================';
GO