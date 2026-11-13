-- =========================================================================
-- Este script contiene solo las tablas privadas, y se debe ejcutar
-- en el nodo corporativo, se debe ejecutar antes el script,
-- de tablas publicas
-- =========================================================================

-- validacion de esquemas, si no existen los crea
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales') EXEC('CREATE SCHEMA Sales');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Purchasing') EXEC('CREATE SCHEMA Purchasing');
GO


-- si existe la tabla, las elimina (con su contenido) y las vuelve a crear
DROP TABLE IF EXISTS Sales.Customers_Private;
DROP TABLE IF EXISTS Purchasing.Suppliers_Private;
GO

-- tabla privada de clientes
CREATE TABLE Sales.Customers_Private (
    BranchID INT NOT NULL,
    CustomerID INT NOT NULL,
    PrimaryContactPersonID INT NOT NULL,
    AlternateContactPersonID INT,
    DeliveryCityID INT NOT NULL,
    PostalCityID INT NOT NULL,
    PhoneNumber NVARCHAR(20),
    FaxNumber NVARCHAR(20),
    WebsiteURL NVARCHAR(256),
    DeliveryAddressLine1 NVARCHAR(60) NOT NULL,
    DeliveryAddressLine2 NVARCHAR(60),
    DeliveryPostalCode NVARCHAR(10) NOT NULL,
    DeliveryLocation GEOGRAPHY NOT NULL,
    PostalAddressLine1 NVARCHAR(60) NOT NULL,
    PostalAddressLine2 NVARCHAR(60),
    PostalPostalCode NVARCHAR(10) NOT NULL,
    
    CONSTRAINT PK_Customers_Private PRIMARY KEY (BranchID, CustomerID),
    CONSTRAINT FK_CustomersPrivate_Public FOREIGN KEY (BranchID, CustomerID)
        REFERENCES Sales.Customers_Public(BranchID, CustomerID)
);
GO


-- tabla privada de proveedores
CREATE TABLE Purchasing.Suppliers_Private (
    BranchID INT NOT NULL,
    SupplierID INT NOT NULL,
    PrimaryContactPersonID INT NOT NULL,
    AlternateContactPersonID INT,
    DeliveryCityID INT NOT NULL,
    PostalCityID INT NOT NULL,
    PhoneNumber NVARCHAR(20),
    FaxNumber NVARCHAR(20),
    WebsiteURL NVARCHAR(256),
    DeliveryAddressLine1 NVARCHAR(60) NOT NULL,
    DeliveryAddressLine2 NVARCHAR(60),
    DeliveryPostalCode NVARCHAR(10) NOT NULL,
    DeliveryLocation GEOGRAPHY NOT NULL,
    PostalAddressLine1 NVARCHAR(60) NOT NULL,
    PostalAddressLine2 NVARCHAR(60),
    PostalPostalCode NVARCHAR(10) NOT NULL,
    BankAccountName NVARCHAR(50),
    BankAccountBranch NVARCHAR(50),
    BankAccountCode NVARCHAR(20),
    BankAccountNumber NVARCHAR(20),
    BankInternationalCode NVARCHAR(20),
    InternalComments NVARCHAR(MAX),

    CONSTRAINT PK_Suppliers_Private PRIMARY KEY (BranchID, SupplierID),
    CONSTRAINT FK_SuppliersPrivate_Public FOREIGN KEY (BranchID, SupplierID)
        REFERENCES Purchasing.Suppliers_Public(BranchID, SupplierID)
);
GO