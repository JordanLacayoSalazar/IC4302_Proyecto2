-- =========================================================================
-- 06_migrar_corporativo.sql
-- Este scirpt migra los datos de WideWorldIporters, al nodo corporativo,
-- para poder ejecutarlo es necesario tener el WideWorldImporters restaurado
-- en el nodo corporativo
-- =========================================================================
USE WWI_Corporativo;
GO

SET QUOTED_IDENTIFIER ON;
GO

PRINT '==================================================';
PRINT 'INICIANDO MIGRACIÓN AL NODO CORPORATIVO';
PRINT '==================================================';

-- =========================================================================
-- BLOQUE A: CATÁLOGOS BASE Y DE SOPORTE
-- =========================================================================
INSERT INTO Application.People (
		BranchID,
		PersonID,
		FullName,
		PreferredName,
		SearchName,
		IsPermittedToLogon,
		LogonName,
		IsExternalLogonProvider,
		HashedPassword,
		IsSystemUser,
		IsEmployee,
		IsSalesperson,
		UserPreferences,
		PhoneNumber,
		FaxNumber,
		EmailAddress,
		Photo,
		CustomFields,
		OtherLanguages,
		LastEditedBy
)
SELECT	
		1,
		PersonID,
		FullName,
		PreferredName,
		SearchName,
		IsPermittedToLogon,
		LogonName,
		IsExternalLogonProvider,
		HashedPassword,
		IsSystemUser,
		IsEmployee,
		IsSalesperson,
		UserPreferences,
		PhoneNumber,
		FaxNumber,
		EmailAddress,
		Photo,
		CustomFields,
		OtherLanguages,
		LastEditedBy
FROM WideWorldImporters.Application.People;


INSERT INTO Application.Countries (
		BranchID,
		CountryID,
		CountryName,
		FormalName,
		IsoAlpha3Code,
		IsoNumericCode,
		CountryType,
		LatestRecordedPopulation,
		Continent,
		Region,
		Subregion,
		Border,
		LastEditedBy
)
SELECT	
		1,
		CountryID,
		CountryName,
		FormalName,
		IsoAlpha3Code,
		IsoNumericCode,
		CountryType,
		LatestRecordedPopulation,
		Continent,
		Region,
		Subregion,
		Border,
		LastEditedBy
FROM WideWorldImporters.Application.Countries;


INSERT INTO Application.StateProvinces (
		BranchID,
		StateProvinceID,
		StateProvinceCode,
		StateProvinceName,
		CountryID,
		SalesTerritory,
		Border,
		LatestRecordedPopulation,
		LastEditedBy
)
SELECT	
		1,
		StateProvinceID,
		StateProvinceCode,
		StateProvinceName,
		CountryID,
		SalesTerritory,
		Border,
		LatestRecordedPopulation,
		LastEditedBy
FROM WideWorldImporters.Application.StateProvinces;


INSERT INTO Application.Cities (
	BranchID,
	CityID,
	CityName,
	StateProvinceID,
	Location,
	LatestRecordedPopulation,
	LastEditedBy
)
SELECT	
		1,
		CityID,
		CityName,
		StateProvinceID,
		Location,
		LatestRecordedPopulation,
		LastEditedBy
FROM WideWorldImporters.Application.Cities;


INSERT INTO Application.DeliveryMethods (
		BranchID,
		DeliveryMethodID,
		DeliveryMethodName,
		LastEditedBy
)
SELECT	
		1,
		DeliveryMethodID,
		DeliveryMethodName,
		LastEditedBy
FROM WideWorldImporters.Application.DeliveryMethods;


INSERT INTO Warehouse.Colors (
		BranchID,
		ColorID,
		ColorName,
		LastEditedBy
)
SELECT	
		1,
		ColorID,
		ColorName,
		LastEditedBy
FROM WideWorldImporters.Warehouse.Colors;

INSERT INTO Warehouse.PackageTypes (
		BranchID,
		PackageTypeID,
		PackageTypeName,
		LastEditedBy
)
SELECT	
		1,
		PackageTypeID,
		PackageTypeName,
		LastEditedBy
FROM WideWorldImporters.Warehouse.PackageTypes;


INSERT	INTO Warehouse.StockGroups (
		BranchID,
		StockGroupID,
		StockGroupName,
		LastEditedBy
)
SELECT	
		1,
		StockGroupID,
		StockGroupName,
		LastEditedBy
FROM WideWorldImporters.Warehouse.StockGroups;


INSERT INTO Sales.CustomerCategories (
		BranchID,
		CustomerCategoryID,
		CustomerCategoryName,
		LastEditedBy
)
SELECT	
		1,
		CustomerCategoryID,
		CustomerCategoryName,
		LastEditedBy
FROM WideWorldImporters.Sales.CustomerCategories;


INSERT	INTO Purchasing.SupplierCategories (
		BranchID,
		SupplierCategoryID,
		SupplierCategoryName,
		LastEditedBy
)
SELECT	
		1,
		SupplierCategoryID,
		SupplierCategoryName,
		LastEditedBy
FROM WideWorldImporters.Purchasing.SupplierCategories;


INSERT INTO Application.TransactionTypes (
		BranchID,
		TransactionTypeID,
		TransactionTypeName,
		LastEditedBy
)
SELECT	
		1,
		TransactionTypeID,
		TransactionTypeName,
		LastEditedBy
FROM WideWorldImporters.Application.TransactionTypes;


INSERT	INTO Application.PaymentMethods (
		BranchID,
		PaymentMethodID,
		PaymentMethodName,
		LastEditedBy
)
SELECT	
		1,
		PaymentMethodID,
		PaymentMethodName,
		LastEditedBy
FROM WideWorldImporters.Application.PaymentMethods;


INSERT INTO Sales.BuyingGroups (
		BranchID,
		BuyingGroupID,
		BuyingGroupName,
		LastEditedBy
)
SELECT	
		1,
		BuyingGroupID,
		BuyingGroupName,
		LastEditedBy
FROM	WideWorldImporters.Sales.BuyingGroups;


INSERT INTO Warehouse.StockItemStockGroups (
		BranchID,
		StockItemStockGroupID,
		StockItemID,
		StockGroupID,
		LastEditedBy
)
SELECT	
		1,
		StockItemStockGroupID,
		StockItemID,
		StockGroupID,
		LastEditedBy
FROM WideWorldImporters.Warehouse.StockItemStockGroups;


-- =========================================================================
-- BLOQUE B: CLIENTES Y PROVEEDORES
-- =========================================================================
INSERT	INTO Sales.Customers_Public (
		BranchID,
		CustomerID,
		CustomerName,
		BillToCustomerID,
		CustomerCategoryID,
		BuyingGroupID,
		DeliveryMethodID,
		DeliveryRun,
		RunPosition,
		CreditLimit,
		AccountOpenedDate,
		StandardDiscountPercentage,
		IsStatementSent,
		IsOnCreditHold,
		PaymentDays,
		LastEditedBy
)
SELECT	
		1,
		CustomerID,
		CustomerName,
		BillToCustomerID,
		CustomerCategoryID,
		BuyingGroupID,
		DeliveryMethodID,
		DeliveryRun,
		RunPosition,
		CreditLimit,
		AccountOpenedDate,
		StandardDiscountPercentage,
		IsStatementSent,
		IsOnCreditHold,
		PaymentDays,
		LastEditedBy
FROM WideWorldImporters.Sales.Customers;


INSERT INTO Sales.Customers_Private (
		BranchID,
		CustomerID,
		PrimaryContactPersonID,
		AlternateContactPersonID,
		DeliveryCityID,
		PostalCityID,
		PhoneNumber,
		FaxNumber,
		WebsiteURL,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		DeliveryPostalCode,
		DeliveryLocation,
		PostalAddressLine1,
		PostalAddressLine2,
		PostalPostalCode
)
SELECT	
		1,
		CustomerID,
		PrimaryContactPersonID,
		AlternateContactPersonID,
		DeliveryCityID,
		PostalCityID,
		PhoneNumber,
		FaxNumber,
		WebsiteURL,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		DeliveryPostalCode,
		DeliveryLocation,
		PostalAddressLine1,
		PostalAddressLine2,
		PostalPostalCode
FROM WideWorldImporters.Sales.Customers;

INSERT INTO Purchasing.Suppliers_Public (
		BranchID,
		SupplierID,
		SupplierName,
		SupplierCategoryID,
		SupplierReference,
		DeliveryMethodID,
		PaymentDays,
		LastEditedBy
)
SELECT	
		1,
		SupplierID,
		SupplierName,
		SupplierCategoryID,
		SupplierReference,
		DeliveryMethodID,
		PaymentDays,
		LastEditedBy
FROM WideWorldImporters.Purchasing.Suppliers;


INSERT INTO Purchasing.Suppliers_Private (
		BranchID,
		SupplierID,
		PrimaryContactPersonID,
		AlternateContactPersonID,
		DeliveryCityID,
		PostalCityID,
		PhoneNumber,
		FaxNumber,
		WebsiteURL,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		DeliveryPostalCode,
		DeliveryLocation,
		PostalAddressLine1,
		PostalAddressLine2,
		PostalPostalCode,
		BankAccountName,
		BankAccountBranch,
		BankAccountCode,
		BankAccountNumber,
		BankInternationalCode,
		InternalComments
)
SELECT	
		1,
		SupplierID,
		PrimaryContactPersonID,
		AlternateContactPersonID,
		DeliveryCityID,
		PostalCityID,
		PhoneNumber,
		FaxNumber,
		WebsiteURL,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		DeliveryPostalCode,
		DeliveryLocation,
		PostalAddressLine1,
		PostalAddressLine2,
		PostalPostalCode,
		BankAccountName,
		BankAccountBranch,
		BankAccountCode,
		BankAccountNumber,
		BankInternationalCode,
		InternalComments
FROM WideWorldImporters.Purchasing.Suppliers;


-- =========================================================================
-- BLOQUE C: PARAMETROS DEL SISTEMA Y PRODUCTOS
-- =========================================================================
INSERT INTO Application.SystemParameters (
		BranchID,
		SystemParameterID,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		DeliveryCityID,
		DeliveryPostalCode,
		DeliveryLocation,
		PostalAddressLine1,
		PostalAddressLine2,
		PostalCityID,
		PostalPostalCode,
		ApplicationSettings,
		LastEditedBy,
		LastEditedWhen
)
SELECT	
		1,
		SystemParameterID,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		DeliveryCityID,
		DeliveryPostalCode,
		DeliveryLocation,
		PostalAddressLine1,
		PostalAddressLine2,
		PostalCityID,
		PostalPostalCode,
		ApplicationSettings,
		LastEditedBy,
		LastEditedWhen
FROM WideWorldImporters.Application.SystemParameters;


INSERT INTO Warehouse.StockItems (
		BranchID,
		StockItemID,
		StockItemName,
		SupplierID,
		ColorID,
		UnitPackageID,
		OuterPackageID,
		Brand,
		Size,
		LeadTimeDays,
		QuantityPerOuter,
		IsChillerStock,
		Barcode,
		TaxRate,
		UnitPrice,
		RecommendedRetailPrice,
		TypicalWeightPerUnit,
		MarketingComments,
		InternalComments,
		CustomFields,
		LastEditedBy,
		ValidFrom
)
SELECT	
		1,
		StockItemID,
		StockItemName,
		SupplierID,
		ColorID,
		UnitPackageID,
		OuterPackageID,
		Brand,
		Size,
		LeadTimeDays,
		QuantityPerOuter,
		IsChillerStock,
		Barcode,
		TaxRate,
		UnitPrice,
		RecommendedRetailPrice,
		TypicalWeightPerUnit,
		MarketingComments,
		InternalComments,
		CustomFields,
		LastEditedBy,
		ValidFrom
FROM WideWorldImporters.Warehouse.StockItems;
