-- =========================================================================
-- Este scirpt migra los datos de WideWorldIporters, al nodo corporativo,
-- para poder ejecutarlo es necesario tener el WideWorldImporters restaurado
-- en el nodo corporativo
-- =========================================================================


INSERT	INTO Application.People (
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
SELECT	1,
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
FROM	WideWorldImporters.Application.People;



INSERT	INTO Application.Countries (
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
SELECT	1,
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
FROM	WideWorldImporters.Application.Countries;



INSERT	INTO Application.StateProvinces (
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
SELECT	1,
		StateProvinceID,
		StateProvinceCode,
		StateProvinceName,
		CountryID,
		SalesTerritory,
		Border,
		LatestRecordedPopulation,
		LastEditedBy
FROM	WideWorldImporters.Application.StateProvinces;



INSERT	INTO Application.Cities (
		BranchID,
		CityID,
		CityName,
		StateProvinceID,
		Location,
		LatestRecordedPopulation,
		LastEditedBy
)
SELECT	1,
		CityID,
		CityName,
		StateProvinceID,
		Location,
		LatestRecordedPopulation,
		LastEditedBy
FROM	WideWorldImporters.Application.Cities;



INSERT	INTO Application.DeliveryMethods (
		BranchID,
		DeliveryMethodID,
		DeliveryMethodName,
		LastEditedBy
)
SELECT	1,
		DeliveryMethodID,
		DeliveryMethodName,
		LastEditedBy
FROM	WideWorldImporters.Application.DeliveryMethods;



INSERT	INTO Warehouse.Colors (
		BranchID,
		ColorID,
		ColorName,
		LastEditedBy
)
SELECT	1,
		ColorID,
		ColorName,
		LastEditedBy
FROM	WideWorldImporters.Warehouse.Colors;



INSERT	INTO Warehouse.PackageTypes (
		BranchID,
		PackageTypeID,
		PackageTypeName,
		LastEditedBy
)
SELECT	1,
		PackageTypeID,
		PackageTypeName,
		LastEditedBy
FROM	WideWorldImporters.Warehouse.PackageTypes;



INSERT	INTO Warehouse.StockGroups (
		BranchID,
		StockGroupID,
		StockGroupName,
		LastEditedBy
)
SELECT	1,
		StockGroupID,
		StockGroupName,
		LastEditedBy
FROM	WideWorldImporters.Warehouse.StockGroups;



INSERT	INTO Sales.CustomerCategories (
		BranchID,
		CustomerCategoryID,
		CustomerCategoryName,
		LastEditedBy
)
SELECT	1,
		CustomerCategoryID,
		CustomerCategoryName,
		LastEditedBy
FROM	WideWorldImporters.Sales.CustomerCategories;



INSERT	INTO Purchasing.SupplierCategories (
		BranchID,
		SupplierCategoryID,
		SupplierCategoryName,
		LastEditedBy
)
SELECT	1,
		SupplierCategoryID,
		SupplierCategoryName,
		LastEditedBy
FROM	WideWorldImporters.Purchasing.SupplierCategories;



INSERT	INTO Application.TransactionTypes (
		BranchID,
		TransactionTypeID,
		TransactionTypeName,
		LastEditedBy
)
SELECT	1,
		TransactionTypeID,
		TransactionTypeName,
		LastEditedBy
FROM	WideWorldImporters.Application.TransactionTypes;



INSERT	INTO Application.PaymentMethods (
		BranchID,
		PaymentMethodID,
		PaymentMethodName,
		LastEditedBy
)
SELECT	1,
		PaymentMethodID,
		PaymentMethodName,
		LastEditedBy
FROM	WideWorldImporters.Application.PaymentMethods;



INSERT	INTO Sales.BuyingGroups (
		BranchID,
		BuyingGroupID,
		BuyingGroupName,
		LastEditedBy
)
SELECT	1,
		BuyingGroupID,
		BuyingGroupName,
		LastEditedBy
FROM	WideWorldImporters.Sales.BuyingGroups;



INSERT	INTO Warehouse.StockItemStockGroups (
		BranchID,
		StockItemStockGroupID,
		StockItemID,
		StockGroupID,
		LastEditedBy
)
SELECT	1,
		StockItemStockGroupID,
		StockItemID,
		StockGroupID,
		LastEditedBy
FROM	WideWorldImporters.Warehouse.StockItemStockGroups;



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
SELECT	1,
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
FROM	WideWorldImporters.Sales.Customers;



INSERT	INTO Sales.Customers_Private (
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
SELECT	1,
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
FROM	WideWorldImporters.Sales.Customers;



INSERT	INTO Purchasing.Suppliers_Public (
		BranchID,
		SupplierID,
		SupplierName,
		SupplierCategoryID,
		SupplierReference,
		DeliveryMethodID,
		PaymentDays,
		LastEditedBy
)
SELECT	1,
		SupplierID,
		SupplierName,
		SupplierCategoryID,
		SupplierReference,
		DeliveryMethodID,
		PaymentDays,
		LastEditedBy
FROM	WideWorldImporters.Purchasing.Suppliers;



INSERT	INTO Purchasing.Suppliers_Private (
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
SELECT	1,
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
FROM	WideWorldImporters.Purchasing.Suppliers;



INSERT	INTO Application.SystemParameters (
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
SELECT	1,
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
FROM	WideWorldImporters.Application.SystemParameters;



INSERT	INTO Warehouse.StockItems (
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
SELECT	1,
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
FROM	WideWorldImporters.Warehouse.StockItems;



INSERT	INTO Sales.Orders (
		BranchID,
		OrderID,
		CustomerID,
		SalespersonPersonID,
		PickedByPersonID,
		ContactPersonID,
		BackorderOrderID,
		OrderDate,
		ExpectedDeliveryDate,
		CustomerPurchaseOrderNumber,
		IsUndersupplyBackordered,
		Comments,
		DeliveryInstructions,
		InternalComments,
		PickingCompletedWhen,
		LastEditedBy,
		LastEditedWhen
)
SELECT	(CASE WHEN CustomerID % 2 = 0 THEN 2 ELSE 3 END),
		OrderID,
		CustomerID,
		SalespersonPersonID,
		PickedByPersonID,
		ContactPersonID,
		BackorderOrderID,
		OrderDate,
		ExpectedDeliveryDate,
		CustomerPurchaseOrderNumber,
		IsUndersupplyBackordered,
		Comments,
		DeliveryInstructions,
		InternalComments,
		PickingCompletedWhen,
		LastEditedBy,
		LastEditedWhen
FROM	WideWorldImporters.Sales.Orders;



INSERT	INTO Sales.Invoices (
		BranchID,
		InvoiceID,
		CustomerID,
		BillToCustomerID,
		OrderID,
		DeliveryMethodID,
		ContactPersonID,
		AccountsPersonID,
		SalespersonPersonID,
		PackedByPersonID,
		InvoiceDate,
		CustomerPurchaseOrderNumber,
		IsCreditNote,
		CreditNoteReason,
		Comments,
		DeliveryInstructions,
		InternalComments,
		TotalDryItems,
		TotalChillerItems,
		DeliveryRun,
		RunPosition,
		ReturnedDeliveryData,
		LastEditedBy,
		LastEditedWhen
)
SELECT	(CASE WHEN CustomerID % 2 = 0 THEN 2 ELSE 3 END),
		InvoiceID,
		CustomerID,
		BillToCustomerID,
		OrderID,
		DeliveryMethodID,
		ContactPersonID,
		AccountsPersonID,
		SalespersonPersonID,
		PackedByPersonID,
		InvoiceDate,
		CustomerPurchaseOrderNumber,
		IsCreditNote,
		CreditNoteReason,
		Comments,
		DeliveryInstructions,
		InternalComments,
		TotalDryItems,
		TotalChillerItems,
		DeliveryRun,
		RunPosition,
		ReturnedDeliveryData,
		LastEditedBy,
		LastEditedWhen
FROM	WideWorldImporters.Sales.Invoices;



INSERT	INTO Purchasing.PurchaseOrders (
		BranchID,
		PurchaseOrderID,
		SupplierID,
		OrderDate,
		DeliveryMethodID,
		ContactPersonID,
		ExpectedDeliveryDate,
		SupplierReference,
		IsOrderFinalized,
		Comments,
		InternalComments,
		LastEditedBy,
		LastEditedWhen
)
SELECT	(CASE WHEN SupplierID % 2 = 0 THEN 2 ELSE 3 END),
		PurchaseOrderID,
		SupplierID,
		OrderDate,
		DeliveryMethodID,
		ContactPersonID,
		ExpectedDeliveryDate,
		SupplierReference,
		IsOrderFinalized,
		Comments,
		InternalComments,
		LastEditedBy,
		LastEditedWhen
FROM	WideWorldImporters.Purchasing.PurchaseOrders;



INSERT	INTO Sales.CustomerTransactions (
		BranchID,
		CustomerTransactionID,
		CustomerID,
		TransactionTypeID,
		InvoiceID,
		PaymentMethodID,
		TransactionDate,
		AmountExcludingTax,
		TaxAmount,
		TransactionAmount,
		OutstandingBalance,
		FinalizationDate,
		LastEditedBy,
		LastEditedWhen
)
SELECT	(CASE WHEN CustomerID % 2 = 0 THEN 2 ELSE 3 END),
		CustomerTransactionID,
		CustomerID,
		TransactionTypeID,
		InvoiceID,
		PaymentMethodID,
		TransactionDate,
		AmountExcludingTax,
		TaxAmount,
		TransactionAmount,
		OutstandingBalance,
		FinalizationDate,
		LastEditedBy,
		LastEditedWhen
FROM	WideWorldImporters.Sales.CustomerTransactions;



INSERT	INTO Purchasing.SupplierTransactions (
		BranchID,
		SupplierTransactionID,
		SupplierID,
		TransactionTypeID,
		PurchaseOrderID,
		PaymentMethodID,
		SupplierInvoiceNumber,
		TransactionDate,
		AmountExcludingTax,
		TaxAmount,
		TransactionAmount,
		OutstandingBalance,
		FinalizationDate,
		LastEditedBy,
		LastEditedWhen
)
SELECT	(CASE WHEN SupplierID % 2 = 0 THEN 2 ELSE 3 END),
		SupplierTransactionID,
		SupplierID,
		TransactionTypeID,
		PurchaseOrderID,
		PaymentMethodID,
		SupplierInvoiceNumber,
		TransactionDate,
		AmountExcludingTax,
		TaxAmount,
		TransactionAmount,
		OutstandingBalance,
		FinalizationDate,
		LastEditedBy,
		LastEditedWhen
FROM	WideWorldImporters.Purchasing.SupplierTransactions;



INSERT	INTO Warehouse.StockItemTransactions (
		BranchID,
		StockItemTransactionID,
		StockItemID,
		TransactionTypeID,
		CustomerID,
		InvoiceID,
		SupplierID,
		PurchaseOrderID,
		TransactionOccurredWhen,
		Quantity,
		LastEditedBy,
		LastEditedWhen
)
SELECT	(CASE WHEN CustomerID IS NOT NULL THEN (CASE WHEN CustomerID % 2 = 0 THEN 2 ELSE 3 END) WHEN SupplierID IS NOT NULL THEN (CASE WHEN SupplierID % 2 = 0 THEN 2 ELSE 3 END) ELSE (CASE WHEN StockItemTransactionID % 2 = 0 THEN 2 ELSE 3 END) END),
		StockItemTransactionID,
		StockItemID,
		TransactionTypeID,
		CustomerID,
		InvoiceID,
		SupplierID,
		PurchaseOrderID,
		TransactionOccurredWhen,
		Quantity,
		LastEditedBy,
		LastEditedWhen
FROM	WideWorldImporters.Warehouse.StockItemTransactions;



INSERT	INTO Sales.OrderLines (
		BranchID,
		OrderLineID,
		OrderID,
		StockItemID,
		Description,
		PackageTypeID,
		Quantity,
		UnitPrice,
		TaxRate,
		PickedQuantity,
		PickingCompletedWhen,
		LastEditedBy,
		LastEditedWhen
)
SELECT	o.BranchID,
		ol.OrderLineID,
		ol.OrderID,
		ol.StockItemID,
		ol.Description,
		ol.PackageTypeID,
		ol.Quantity,
		ol.UnitPrice,
		ol.TaxRate,
		ol.PickedQuantity,
		ol.PickingCompletedWhen,
		ol.LastEditedBy,
		ol.LastEditedWhen
FROM	WideWorldImporters.Sales.OrderLines AS ol
		INNER JOIN
		Sales.Orders AS o
		ON ol.OrderID = o.OrderID;



INSERT	INTO Sales.InvoiceLines (
		BranchID,
		InvoiceLineID,
		InvoiceID,
		StockItemID,
		Description,
		PackageTypeID,
		Quantity,
		UnitPrice,
		TaxRate,
		TaxAmount,
		LineProfit,
		ExtendedPrice,
		LastEditedBy,
		LastEditedWhen
)
SELECT	i.BranchID,
		il.InvoiceLineID,
		il.InvoiceID,
		il.StockItemID,
		il.Description,
		il.PackageTypeID,
		il.Quantity,
		il.UnitPrice,
		il.TaxRate,
		il.TaxAmount,
		il.LineProfit,
		il.ExtendedPrice,
		il.LastEditedBy,
		il.LastEditedWhen
FROM	WideWorldImporters.Sales.InvoiceLines AS il
		INNER JOIN
		Sales.Invoices AS i
		ON il.InvoiceID = i.InvoiceID;



INSERT	INTO Purchasing.PurchaseOrderLines (
		BranchID,
		PurchaseOrderLineID,
		PurchaseOrderID,
		StockItemID,
		OrderedOuters,
		Description,
		ReceivedOuters,
		PackageTypeID,
		ExpectedUnitPricePerOuter,
		LastReceiptDate,
		IsOrderLineFinalized,
		LastEditedBy,
		LastEditedWhen
)
SELECT	po.BranchID,
		pol.PurchaseOrderLineID,
		pol.PurchaseOrderID,
		pol.StockItemID,
		pol.OrderedOuters,
		pol.Description,
		pol.ReceivedOuters,
		pol.PackageTypeID,
		pol.ExpectedUnitPricePerOuter,
		pol.LastReceiptDate,
		pol.IsOrderLineFinalized,
		pol.LastEditedBy,
		pol.LastEditedWhen
FROM	WideWorldImporters.Purchasing.PurchaseOrderLines AS pol
		INNER JOIN
		Purchasing.PurchaseOrders AS po
		ON pol.PurchaseOrderID = po.PurchaseOrderID;