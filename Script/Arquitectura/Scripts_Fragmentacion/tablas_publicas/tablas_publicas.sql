-- =========================================================================
-- Ejecutar este script en los 3 nodos, en el Corporativo,
-- en la sucursal de limon y en la sucursal de san jose
-- =========================================================================


-- =========================================================================
-- Clientes y proveedores
-- =========================================================================

-- validacion de esquemas, si no existen los crea
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales') EXEC('CREATE SCHEMA Sales');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Purchasing') EXEC('CREATE SCHEMA Purchasing');
GO

-- si existe la tabla, las elimina (con su contenido) y las vuelve a crear
DROP TABLE IF EXISTS Sales.Customers_Public;
DROP TABLE IF EXISTS Purchasing.Suppliers_Public;
GO

-- tabla publica de clientes
CREATE TABLE Sales.Customers_Public (
    BranchID INT NOT NULL,
    CustomerID INT NOT NULL, 
    CustomerName NVARCHAR(100) NOT NULL,
    BillToCustomerID INT NOT NULL,
    CustomerCategoryID INT NOT NULL,
    BuyingGroupID INT,
    DeliveryMethodID INT NOT NULL,
    DeliveryRun NVARCHAR(5),
    RunPosition NVARCHAR(5),
    CreditLimit DECIMAL(18,2),
    AccountOpenedDate DATE NOT NULL,
    StandardDiscountPercentage DECIMAL(18,3) NOT NULL,
    IsStatementSent BIT NOT NULL,
    IsOnCreditHold BIT NOT NULL,
    PaymentDays INT NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION, 
    CONSTRAINT PK_Customers_Public PRIMARY KEY (BranchID, CustomerID)
);
GO

-- tabla publica de proveedores
CREATE TABLE Purchasing.Suppliers_Public (
    BranchID INT NOT NULL,
    SupplierID INT NOT NULL, 
    SupplierName NVARCHAR(100) NOT NULL,
    SupplierCategoryID INT NOT NULL,
    SupplierReference NVARCHAR(20),
    DeliveryMethodID INT NOT NULL,
    PaymentDays INT NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_Suppliers_Public PRIMARY KEY (BranchID, SupplierID)
);
GO


-- =========================================================================
-- Catalogo y Ventas
-- =========================================================================

-- validacion de esquemas, si no existen los crea
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Warehouse') EXEC('CREATE SCHEMA Warehouse');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales') EXEC('CREATE SCHEMA Sales');
GO

-- si existe la tabla, las elimina (con su contenido) y las vuelve a crear
DROP TABLE IF EXISTS Sales.Invoices;
DROP TABLE IF EXISTS Warehouse.StockItems;
GO

-- tabala de catalogo de productos
CREATE TABLE Warehouse.StockItems (
    BranchID INT NOT NULL,
    StockItemID INT NOT NULL, 
    StockItemName NVARCHAR(100) NOT NULL,
    SupplierID INT NOT NULL,
    ColorID INT,
    UnitPackageID INT NOT NULL,
    OuterPackageID INT NOT NULL,
    Brand NVARCHAR(50),
    Size NVARCHAR(20),
    LeadTimeDays INT NOT NULL,
    QuantityPerOuter INT NOT NULL,
    IsChillerStock BIT NOT NULL,
    Barcode NVARCHAR(50),
    TaxRate DECIMAL(18, 3) NOT NULL,
    UnitPrice DECIMAL(18, 2) NOT NULL,
    RecommendedRetailPrice DECIMAL(18, 2),
    TypicalWeightPerUnit DECIMAL(18, 3) NOT NULL,
    MarketingComments NVARCHAR(MAX),
    InternalComments NVARCHAR(MAX),
    CustomFields NVARCHAR(MAX),
    Tags AS (CAST(JSON_QUERY(CustomFields, N'$.Tags') AS NVARCHAR(MAX))),
    SearchDetails AS (CAST(CONCAT(StockItemName, N' ', Barcode, N' ', CustomFields) AS NVARCHAR(MAX))) PERSISTED NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_StockItems PRIMARY KEY (BranchID, StockItemID)
);
GO

-- tabla de ventas
CREATE TABLE Sales.Invoices (
    BranchID INT NOT NULL,
    InvoiceID INT NOT NULL, 
    CustomerID INT NOT NULL,
    BillToCustomerID INT NOT NULL,
    OrderID INT,
    DeliveryMethodID INT NOT NULL,
    ContactPersonID INT NOT NULL,
    AccountsPersonID INT NOT NULL,
    SalespersonPersonID INT NOT NULL,
    PackedByPersonID INT NOT NULL,
    InvoiceDate DATE NOT NULL,
    CustomerPurchaseOrderNumber NVARCHAR(20),
    IsCreditNote BIT NOT NULL,
    CreditNoteReason NVARCHAR(MAX),
    Comments NVARCHAR(MAX),
    DeliveryInstructions NVARCHAR(MAX),
    InternalComments NVARCHAR(MAX),
    TotalDryItems INT NOT NULL,
    TotalChillerItems INT NOT NULL,
    DeliveryRun NVARCHAR(5),
    RunPosition NVARCHAR(5),
    ReturnedDeliveryData NVARCHAR(MAX),
    ConfirmedDeliveryTime AS (TRY_CAST(JSON_VALUE(ReturnedDeliveryData, N'$.Events[1].EventTime') AS datetime2(7))),
    ConfirmedReceivedBy AS (CAST(JSON_VALUE(ReturnedDeliveryData, N'$.Events[1].Conformation.ReceivedBy') AS nvarchar(4000))),
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_Invoices PRIMARY KEY (BranchID, InvoiceID)
);
GO


-- =========================================================================
-- Catalogos de soporte
-- =========================================================================

-- validacion de esquemas, si no existen los crea
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Application') EXEC('CREATE SCHEMA Application');
GO

-- si existe la tabla, las elimina (con su contenido) y las vuelve a crear
DROP TABLE IF EXISTS Warehouse.StockGroups;
DROP TABLE IF EXISTS Sales.CustomerCategories;
DROP TABLE IF EXISTS Purchasing.SupplierCategories;
DROP TABLE IF EXISTS Application.Cities;
DROP TABLE IF EXISTS Application.DeliveryMethods;
GO

-- tabla de grupo de productos
CREATE TABLE Warehouse.StockGroups (
    BranchID INT NOT NULL,
    StockGroupID INT NOT NULL,
    StockGroupName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_StockGroups PRIMARY KEY (BranchID, StockGroupID)
);
GO

-- tabla de categoria clientes
CREATE TABLE Sales.CustomerCategories (
    BranchID INT NOT NULL,
    CustomerCategoryID INT NOT NULL,
    CustomerCategoryName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_CustomerCategories PRIMARY KEY (BranchID, CustomerCategoryID)
);
GO

-- tabla de categoria proveedores
CREATE TABLE Purchasing.SupplierCategories (
    BranchID INT NOT NULL,
    SupplierCategoryID INT NOT NULL,
    SupplierCategoryName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_SupplierCategories PRIMARY KEY (BranchID, SupplierCategoryID)
);
GO

-- tabla de ciudades
CREATE TABLE Application.Cities (
    BranchID INT NOT NULL,
    CityID INT NOT NULL,
    CityName NVARCHAR(50) NOT NULL,
    StateProvinceID INT NOT NULL,
    Location GEOGRAPHY,
    LatestRecordedPopulation BIGINT,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_Cities PRIMARY KEY (BranchID, CityID)
);
GO

-- tabla de metodos de entrega
CREATE TABLE Application.DeliveryMethods (
    BranchID INT NOT NULL,
    DeliveryMethodID INT NOT NULL,
    DeliveryMethodName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_DeliveryMethods PRIMARY KEY (BranchID, DeliveryMethodID)
);
GO


-- =========================================================================
-- Transaccionales y Detalles
-- =========================================================================

-- si existe la tabla, las elimina (con su contenido) y las vuelve a crear
DROP TABLE IF EXISTS Sales.InvoiceLines;
DROP TABLE IF EXISTS Purchasing.PurchaseOrderLines;
DROP TABLE IF EXISTS Purchasing.PurchaseOrders;
GO

-- tabla detalles de facturas
CREATE TABLE Sales.InvoiceLines (
    BranchID INT NOT NULL,
    InvoiceLineID INT NOT NULL,
    InvoiceID INT NOT NULL,
    StockItemID INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    PackageTypeID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    LineProfit DECIMAL(18,2) NOT NULL,
    ExtendedPrice DECIMAL(18,2) NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_InvoiceLines PRIMARY KEY (BranchID, InvoiceLineID),
    CONSTRAINT FK_InvoiceLines_Invoices FOREIGN KEY (BranchID, InvoiceID) 
        REFERENCES Sales.Invoices(BranchID, InvoiceID)
);
GO

-- tabla ordenes de compra
CREATE TABLE Purchasing.PurchaseOrders (
    BranchID INT NOT NULL,
    PurchaseOrderID INT NOT NULL,
    SupplierID INT NOT NULL,
    OrderDate DATE NOT NULL,
    DeliveryMethodID INT NOT NULL,
    ContactPersonID INT NOT NULL,
    ExpectedDeliveryDate DATE,
    SupplierReference NVARCHAR(20),
    IsOrderFinalized BIT NOT NULL,
    Comments NVARCHAR(MAX),
    InternalComments NVARCHAR(MAX),
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_PurchaseOrders PRIMARY KEY (BranchID, PurchaseOrderID)
);
GO

-- tabla detalles ordenes de compra
CREATE TABLE Purchasing.PurchaseOrderLines (
    BranchID INT NOT NULL,
    PurchaseOrderLineID INT NOT NULL,
    PurchaseOrderID INT NOT NULL,
    StockItemID INT NOT NULL,
    OrderedOuters INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    ReceivedOuters INT NOT NULL,
    PackageTypeID INT NOT NULL,
    ExpectedUnitPricePerOuter DECIMAL(18,2) NOT NULL,
    LastReceiptDate DATE,
    IsOrderLineFinalized BIT NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_PurchaseOrderLines PRIMARY KEY (BranchID, PurchaseOrderLineID),
    CONSTRAINT FK_PurchaseOrderLines_Orders FOREIGN KEY (BranchID, PurchaseOrderID) 
        REFERENCES Purchasing.PurchaseOrders(BranchID, PurchaseOrderID)
);
GO


-- =========================================================================
-- Transacciones, pedidos y inventario
-- =========================================================================

-- si existe la tabla, las elimina (con su contenido) y las vuelve a crear
DROP TABLE IF EXISTS Sales.OrderLines;
DROP TABLE IF EXISTS Sales.Orders;
DROP TABLE IF EXISTS Sales.CustomerTransactions;
DROP TABLE IF EXISTS Purchasing.SupplierTransactions;
DROP TABLE IF EXISTS Warehouse.StockItemTransactions;
DROP TABLE IF EXISTS Warehouse.StockItemHoldings;
GO

-- tabla de ordenes de venta
CREATE TABLE Sales.Orders (
    BranchID INT NOT NULL,
    OrderID INT NOT NULL,
    CustomerID INT NOT NULL,
    SalespersonPersonID INT NOT NULL,
    PickedByPersonID INT,
    ContactPersonID INT NOT NULL,
    BackorderOrderID INT,
    OrderDate DATE NOT NULL,
    ExpectedDeliveryDate DATE NOT NULL,
    CustomerPurchaseOrderNumber NVARCHAR(20),
    IsUndersupplyBackordered BIT NOT NULL,
    Comments NVARCHAR(MAX),
    DeliveryInstructions NVARCHAR(MAX),
    InternalComments NVARCHAR(MAX),
    PickingCompletedWhen DATETIME2(7),
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (BranchID, OrderID)
);
GO

-- tabla de detalles de ordenes de venta
CREATE TABLE Sales.OrderLines (
    BranchID INT NOT NULL,
    OrderLineID INT NOT NULL,
    OrderID INT NOT NULL,
    StockItemID INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    PackageTypeID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    TaxRate DECIMAL(18,3) NOT NULL,
    PickedQuantity INT NOT NULL,
    PickingCompletedWhen DATETIME2(7),
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_OrderLines PRIMARY KEY (BranchID, OrderLineID),
    CONSTRAINT FK_OrderLines_Orders FOREIGN KEY (BranchID, OrderID) 
        REFERENCES Sales.Orders(BranchID, OrderID)
);
GO

-- tabla de transacciones de clientes
CREATE TABLE Sales.CustomerTransactions (
    BranchID INT NOT NULL,
    CustomerTransactionID INT NOT NULL,
    CustomerID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    InvoiceID INT,
    PaymentMethodID INT,
    TransactionDate DATE NOT NULL,
    AmountExcludingTax DECIMAL(18,2) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    TransactionAmount DECIMAL(18,2) NOT NULL,
    OutstandingBalance DECIMAL(18,2) NOT NULL,
    FinalizationDate DATE,
    IsFinalized AS (CAST(IIF(FinalizationDate IS NULL, 0, 1) AS BIT)) PERSISTED NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_CustomerTransactions PRIMARY KEY (BranchID, CustomerTransactionID)
);
GO

-- tabla de transacciones de proveedores
CREATE TABLE Purchasing.SupplierTransactions (
    BranchID INT NOT NULL,
    SupplierTransactionID INT NOT NULL,
    SupplierID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    PurchaseOrderID INT,
    PaymentMethodID INT,
    SupplierInvoiceNumber NVARCHAR(20),
    TransactionDate DATE NOT NULL,
    AmountExcludingTax DECIMAL(18,2) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    TransactionAmount DECIMAL(18,2) NOT NULL,
    OutstandingBalance DECIMAL(18,2) NOT NULL,
    FinalizationDate DATE,
    IsFinalized AS (CAST(IIF(FinalizationDate IS NULL, 0, 1) AS BIT)) PERSISTED NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_SupplierTransactions PRIMARY KEY (BranchID, SupplierTransactionID)
);
GO
-- tabla de transacciones de inventario
CREATE TABLE Warehouse.StockItemTransactions (
    BranchID INT NOT NULL,
    StockItemTransactionID INT NOT NULL,
    StockItemID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    CustomerID INT,
    InvoiceID INT,
    SupplierID INT,
    PurchaseOrderID INT,
    TransactionOccurredWhen DATETIME2(7) NOT NULL,
    Quantity DECIMAL(18,3) NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL,
    CONSTRAINT PK_StockItemTransactions PRIMARY KEY (BranchID, StockItemTransactionID)
);
GO

-- tabla de existencias fisicas
CREATE TABLE Warehouse.StockItemHoldings (
    BranchID INT NOT NULL,
    StockItemID INT NOT NULL,
    QuantityOnHand INT NOT NULL,
    BinLocation NVARCHAR(20) NOT NULL,
    LastStocktakeQuantity INT NOT NULL,
    LastCostPrice DECIMAL(18,2) NOT NULL,
    ReorderLevel INT NOT NULL,
    TargetStockLevel INT NOT NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL, -- RECUPERADA
    CONSTRAINT PK_StockItemHoldings PRIMARY KEY (BranchID, StockItemID)
);
GO

-- =========================================================================
-- Personas, Geografia y Catalogo menores
-- =========================================================================

-- si existe la tabla, las elimina (con su contenido) y las vuelve a crear
DROP TABLE IF EXISTS Warehouse.StockItemStockGroups;
DROP TABLE IF EXISTS Warehouse.Colors;
DROP TABLE IF EXISTS Warehouse.PackageTypes;
DROP TABLE IF EXISTS Sales.BuyingGroups;
DROP TABLE IF EXISTS Application.TransactionTypes;
DROP TABLE IF EXISTS Application.PaymentMethods;
DROP TABLE IF EXISTS Application.StateProvinces;
DROP TABLE IF EXISTS Application.Countries;
DROP TABLE IF EXISTS Application.People;
GO

-- tabla de personas
CREATE TABLE Application.People (
    BranchID INT NOT NULL,
    PersonID INT NOT NULL,
    FullName NVARCHAR(50) NOT NULL,
    PreferredName NVARCHAR(50) NOT NULL,
    SearchName NVARCHAR(101) NOT NULL,
    IsPermittedToLogon BIT NOT NULL,
    LogonName NVARCHAR(50),
    IsExternalLogonProvider BIT NOT NULL,
    HashedPassword VARBINARY(MAX),
    IsSystemUser BIT NOT NULL,
    IsEmployee BIT NOT NULL,
    IsSalesperson BIT NOT NULL,
    UserPreferences NVARCHAR(MAX),
    PhoneNumber NVARCHAR(20),
    FaxNumber NVARCHAR(20),
    EmailAddress NVARCHAR(256),
    Photo VARBINARY(MAX),
    CustomFields NVARCHAR(MAX),
    OtherLanguages NVARCHAR(MAX),
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_People PRIMARY KEY (BranchID, PersonID)
);
GO

-- tabla de paises
CREATE TABLE Application.Countries (
    BranchID INT NOT NULL,
    CountryID INT NOT NULL,
    CountryName NVARCHAR(60) NOT NULL,
    FormalName NVARCHAR(60) NOT NULL,
    IsoAlpha3Code NVARCHAR(3),
    IsoNumericCode INT,
    CountryType NVARCHAR(20),
    LatestRecordedPopulation BIGINT,
    Continent NVARCHAR(30) NOT NULL,
    Region NVARCHAR(30) NOT NULL,
    Subregion NVARCHAR(30) NOT NULL,
    Border GEOGRAPHY,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_Countries PRIMARY KEY (BranchID, CountryID)
);
GO

-- tabla de estados o provincias
CREATE TABLE Application.StateProvinces (
    BranchID INT NOT NULL,
    StateProvinceID INT NOT NULL,
    StateProvinceCode NVARCHAR(5) NOT NULL,
    StateProvinceName NVARCHAR(50) NOT NULL,
    CountryID INT NOT NULL,
    SalesTerritory NVARCHAR(50) NOT NULL,
    Border GEOGRAPHY,
    LatestRecordedPopulation BIGINT,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_StateProvinces PRIMARY KEY (BranchID, StateProvinceID)
);
GO

-- tabla tipos de pago
CREATE TABLE Application.PaymentMethods (
    BranchID INT NOT NULL,
    PaymentMethodID INT NOT NULL,
    PaymentMethodName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_PaymentMethods PRIMARY KEY (BranchID, PaymentMethodID)
);
GO

-- tabla tipos de transaccion
CREATE TABLE Application.TransactionTypes (
    BranchID INT NOT NULL,
    TransactionTypeID INT NOT NULL,
    TransactionTypeName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_TransactionTypes PRIMARY KEY (BranchID, TransactionTypeID)
);
GO

-- tabla de tipo de empaque
CREATE TABLE Warehouse.PackageTypes (
    BranchID INT NOT NULL,
    PackageTypeID INT NOT NULL,
    PackageTypeName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_PackageTypes PRIMARY KEY (BranchID, PackageTypeID)
);
GO

-- tabla de tipo de colores o de colores
CREATE TABLE Warehouse.Colors (
    BranchID INT NOT NULL,
    ColorID INT NOT NULL,
    ColorName NVARCHAR(20) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_Colors PRIMARY KEY (BranchID, ColorID)
);
GO

-- tabla grupos de compra (clientes)
CREATE TABLE Sales.BuyingGroups (
    BranchID INT NOT NULL,
    BuyingGroupID INT NOT NULL,
    BuyingGroupName NVARCHAR(50) NOT NULL,
    LastEditedBy INT NOT NULL,
    RowVersionData ROWVERSION,
    CONSTRAINT PK_BuyingGroups PRIMARY KEY (BranchID, BuyingGroupID)
);
GO

-- tabla de productos por grupo
CREATE TABLE Warehouse.StockItemStockGroups (
    BranchID INT NOT NULL,
    StockItemStockGroupID INT NOT NULL,
    StockItemID INT NOT NULL,
    StockGroupID INT NOT NULL,
    LastEditedBy INT NOT NULL,
    CONSTRAINT PK_StockItemStockGroups PRIMARY KEY (BranchID, StockItemStockGroupID)
);
GO