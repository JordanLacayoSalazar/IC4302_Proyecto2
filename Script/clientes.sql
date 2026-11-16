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
============================================
  PROCEDIMIENTO: ObtenerClientes
  Obtiene clientes con categoría y método de entrega, con filtros y paginación.
============================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerClientes
    @NombreBusqueda NVARCHAR(100) = NULL,
    @CategoriaBusqueda NVARCHAR(100) = NULL,
    @MetodoEntregaBusqueda NVARCHAR(100) = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;
    SELECT
        c.CustomerID,
        c.CustomerName AS NombreCliente,
        cc.CustomerCategoryName AS Categoria,
        dm.DeliveryMethodName AS MetodoEntrega
    FROM syn_Clientes AS c
    INNER JOIN syn_CategoriasCliente AS cc ON c.CustomerCategoryID = cc.CustomerCategoryID
    INNER JOIN syn_MetodosEntrega AS dm ON c.DeliveryMethodID = dm.DeliveryMethodID
    WHERE (NULLIF(LTRIM(RTRIM(@NombreBusqueda)), '') IS NULL
           OR c.CustomerName LIKE '%' + LTRIM(RTRIM(@NombreBusqueda)) + '%')
      AND (NULLIF(LTRIM(RTRIM(@CategoriaBusqueda)), '') IS NULL
           OR cc.CustomerCategoryName LIKE '%' + LTRIM(RTRIM(@CategoriaBusqueda)) + '%')
      AND (NULLIF(LTRIM(RTRIM(@MetodoEntregaBusqueda)), '') IS NULL
           OR dm.DeliveryMethodName LIKE '%' + LTRIM(RTRIM(@MetodoEntregaBusqueda)) + '%')
    ORDER BY c.CustomerName ASC, c.CustomerID ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO


/*
============================================
  PROCEDIMIENTO: ObtenerDetalleCliente
  Obtiene el detalle completo de un cliente específico.
============================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerDetalleCliente
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF dbo.fn_BranchIDLocal() <> 1
    BEGIN
        IF @@TRANCOUNT <> 0
            THROW 50041, 'Ejecute la operacion remota fuera de una transaccion local.', 1;
        EXEC [nodo_corporativo].[WWI_Corporativo].[dbo].[ObtenerDetalleCliente]
            @CustomerID = @CustomerID;
        RETURN;
    END;

    SELECT
        c.CustomerID,
        c.BillToCustomerID,
        c.CustomerCategoryID,
        c.BuyingGroupID,
        c.PrimaryContactPersonID,
        c.AlternateContactPersonID,
        c.DeliveryMethodID,
        c.DeliveryCityID,
        c.PostalCityID,
        c.CustomerName AS NombreCliente,
        c.PhoneNumber,
        c.FaxNumber,
        c.PaymentDays,
        c.CreditLimit,
        c.StandardDiscountPercentage,
        c.WebsiteURL,
        c.DeliveryAddressLine1,
        c.DeliveryAddressLine2,
        c.DeliveryPostalCode,
        c.PostalAddressLine1,
        c.PostalAddressLine2,
        c.PostalPostalCode,
        cc.CustomerCategoryName AS Categoria,
        bg.BuyingGroupName AS GrupoCompra,
        contactoPrimario.FullName AS ContactoPrimario,
        contactoAlternativo.FullName AS ContactoAlternativo,
        clienteFacturacion.CustomerName AS ClienteFacturacion,
        dm.DeliveryMethodName AS MetodoEntrega,
        ciudadEntrega.CityName AS CiudadEntrega,
        c.DeliveryPostalCode AS CodigoPostal,
        c.PhoneNumber AS Telefono,
        c.FaxNumber AS Fax,
        c.PaymentDays AS DiasGracia,
        c.WebsiteURL AS SitioWeb,

        CASE
            WHEN ISNULL(c.DeliveryAddressLine1, '') = ''
                AND ISNULL(c.DeliveryAddressLine2, '') = ''
            THEN ''

            WHEN ISNULL(c.DeliveryAddressLine2, '') = ''
            THEN ISNULL(c.DeliveryAddressLine1, '')

            WHEN ISNULL(c.DeliveryAddressLine1, '') = ''
            THEN ISNULL(c.DeliveryAddressLine2, '')

            ELSE c.DeliveryAddressLine1 + ', ' + c.DeliveryAddressLine2
        END AS DireccionEntrega,

        CASE
            WHEN ISNULL(c.PostalAddressLine1, '') = ''
                AND ISNULL(c.PostalAddressLine2, '') = ''
            THEN ''

            WHEN ISNULL(c.PostalAddressLine2, '') = ''
            THEN ISNULL(c.PostalAddressLine1, '')

            WHEN ISNULL(c.PostalAddressLine1, '') = ''
            THEN ISNULL(c.PostalAddressLine2, '')

            ELSE c.PostalAddressLine1 + ', ' + c.PostalAddressLine2
        END AS DireccionPostal,

        CASE
            WHEN c.DeliveryLocation IS NULL THEN NULL
            ELSE
                CONVERT(VARCHAR(50), c.DeliveryLocation.Lat) +
                ', ' +
                CONVERT(VARCHAR(50), c.DeliveryLocation.Long)
        END AS LocalizacionEntrega,

        c.DeliveryLocation.Lat AS Latitud,
        c.DeliveryLocation.Long AS Longitud

    FROM syn_Clientes AS c

    INNER JOIN syn_CategoriasCliente AS cc
        ON c.CustomerCategoryID = cc.CustomerCategoryID

    LEFT JOIN syn_GruposCompra AS bg -- Se hace LEFT JOIN para incluir clientes sin grupo de compra
        ON c.BuyingGroupID = bg.BuyingGroupID

    INNER JOIN syn_Personas AS contactoPrimario
        ON c.PrimaryContactPersonID = contactoPrimario.PersonID

    LEFT JOIN syn_Personas AS contactoAlternativo -- Se hace LEFT JOIN para incluir clientes sin contacto alternativo
        ON c.AlternateContactPersonID = contactoAlternativo.PersonID

    INNER JOIN syn_Clientes AS clienteFacturacion
        ON c.BillToCustomerID = clienteFacturacion.CustomerID

    INNER JOIN syn_MetodosEntrega AS dm
        ON c.DeliveryMethodID = dm.DeliveryMethodID

    INNER JOIN syn_Ciudades AS ciudadEntrega
        ON c.DeliveryCityID = ciudadEntrega.CityID

    WHERE c.CustomerID = @CustomerID;
END;
GO

/*
==========================================
    PROCEDIMIENTO: CrearCliente
    Inserta un nuevo cliente en la base de datos.
==========================================
*/
CREATE OR ALTER PROCEDURE dbo.CrearCliente
    @CustomerName NVARCHAR(100),
    @BillToCustomerID INT,
    @CustomerCategoryID INT,
    @PrimaryContactPersonID INT,
    @DeliveryMethodID INT,
    @DeliveryCityID INT,
    @BuyingGroupID INT = NULL,
    @AlternateContactPersonID INT = NULL,
    @PostalCityID INT = NULL,
    @PhoneNumber NVARCHAR(20) = NULL,
    @FaxNumber NVARCHAR(20) = NULL,
    @WebsiteURL NVARCHAR(256) = NULL,
    @PaymentDays INT = NULL,
    @DeliveryAddressLine1 NVARCHAR(60) = NULL,
    @DeliveryAddressLine2 NVARCHAR(60) = NULL,
    @DeliveryPostalCode NVARCHAR(10) = NULL,
    @PostalAddressLine1 NVARCHAR(60) = NULL,
    @PostalAddressLine2 NVARCHAR(60) = NULL,
    @PostalPostalCode NVARCHAR(10) = NULL,
    @Latitud FLOAT = NULL,
    @Longitud FLOAT = NULL,
    @CreditLimit DECIMAL(18, 2) = NULL,
    @StandardDiscountPercentage DECIMAL(18, 3) = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF dbo.fn_BranchIDLocal() <> 1
    BEGIN
        IF @@TRANCOUNT <> 0
            THROW 50041, 'Ejecute la operacion remota fuera de una transaccion local.', 1;
        EXEC [nodo_corporativo].[WWI_Corporativo].[dbo].[CrearCliente]
                @CustomerName = @CustomerName,
                @BillToCustomerID = @BillToCustomerID,
                @CustomerCategoryID = @CustomerCategoryID,
                @PrimaryContactPersonID = @PrimaryContactPersonID,
                @DeliveryMethodID = @DeliveryMethodID,
                @DeliveryCityID = @DeliveryCityID,
                @BuyingGroupID = @BuyingGroupID,
                @AlternateContactPersonID = @AlternateContactPersonID,
                @PostalCityID = @PostalCityID,
                @PhoneNumber = @PhoneNumber,
                @FaxNumber = @FaxNumber,
                @WebsiteURL = @WebsiteURL,
                @PaymentDays = @PaymentDays,
                @DeliveryAddressLine1 = @DeliveryAddressLine1,
                @DeliveryAddressLine2 = @DeliveryAddressLine2,
                @DeliveryPostalCode = @DeliveryPostalCode,
                @PostalAddressLine1 = @PostalAddressLine1,
                @PostalAddressLine2 = @PostalAddressLine2,
                @PostalPostalCode = @PostalPostalCode,
                @Latitud = @Latitud,
                @Longitud = @Longitud,
                @CreditLimit = @CreditLimit,
                @StandardDiscountPercentage = @StandardDiscountPercentage;
        RETURN;
    END;


    DECLARE @DeliveryLocation GEOGRAPHY = NULL;
    DECLARE @NuevoCustomerID INT;

    IF @Latitud IS NOT NULL AND @Longitud IS NOT NULL
        SET @DeliveryLocation = geography::Point(@Latitud, @Longitud, 4326);
        -- 4326 es el Spatial Reference Identifier para WGS 84, que es un sistema de coordenadas geográficas comúnmente utilizado.

    BEGIN TRY
        BEGIN TRANSACTION;

        SET @NuevoCustomerID = NEXT VALUE FOR Repl.seq_Customers_Public;
        INSERT INTO Sales.Customers_Public (
            BranchID, CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, DeliveryMethodID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, LastEditedBy
        ) VALUES (
            1,
            @NuevoCustomerID,
            @CustomerName,
            @BillToCustomerID,
            @CustomerCategoryID,
            @BuyingGroupID,
            @DeliveryMethodID,
            @CreditLimit,
            CAST(GETDATE() AS DATE),
            ISNULL(@StandardDiscountPercentage, 0),
            0,
            0,
            ISNULL(@PaymentDays, 7),
            1
        );
        INSERT INTO Sales.Customers_Private (
            BranchID, CustomerID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryCityID, PostalCityID, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode
        ) VALUES (
            1,
            @NuevoCustomerID,
            @PrimaryContactPersonID,
            @AlternateContactPersonID,
            @DeliveryCityID,
            ISNULL(@PostalCityID, @DeliveryCityID),
            ISNULL(@PhoneNumber, 'N/A'),
            ISNULL(@FaxNumber, 'N/A'),
            ISNULL(@WebsiteURL, 'N/A'),
            ISNULL(@DeliveryAddressLine1, 'N/A'),
            @DeliveryAddressLine2,
            ISNULL(@DeliveryPostalCode, 'N/A'),
            @DeliveryLocation,
            ISNULL(@PostalAddressLine1, 'N/A'),
            @PostalAddressLine2,
            ISNULL(@PostalPostalCode, 'N/A')
        );

        COMMIT TRANSACTION;
        SELECT @NuevoCustomerID AS CustomerID;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/*
==========================================
    PROCEDIMIENTO: ActualizarCliente
    Actualiza la información de un cliente existente en la base de datos.
==========================================
*/
CREATE OR ALTER PROCEDURE dbo.ActualizarCliente
    @CustomerID INT,
    @CustomerName NVARCHAR(100),
    @BillToCustomerID INT = NULL,
    @CustomerCategoryID INT = NULL,
    @BuyingGroupID INT = NULL,
    @PrimaryContactPersonID INT = NULL,
    @AlternateContactPersonID INT = NULL,
    @DeliveryMethodID INT = NULL,
    @DeliveryCityID INT = NULL,
    @PostalCityID INT = NULL,
    @PhoneNumber NVARCHAR(20) = NULL,
    @FaxNumber NVARCHAR(20) = NULL,
    @WebsiteURL NVARCHAR(256) = NULL,
    @PaymentDays INT = NULL,
    @DeliveryAddressLine1 NVARCHAR(60) = NULL,
    @DeliveryAddressLine2 NVARCHAR(60) = NULL,
    @DeliveryPostalCode NVARCHAR(10) = NULL,
    @PostalAddressLine1 NVARCHAR(60) = NULL,
    @PostalAddressLine2 NVARCHAR(60) = NULL,
    @PostalPostalCode NVARCHAR(10) = NULL,
    @Latitud FLOAT = NULL,
    @Longitud FLOAT = NULL,
    @CreditLimit DECIMAL(18, 2) = NULL,
    @StandardDiscountPercentage DECIMAL(18, 3) = NULL,
    @ActualizarCreditLimit BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF dbo.fn_BranchIDLocal() <> 1
    BEGIN
        IF @@TRANCOUNT <> 0
            THROW 50041, 'Ejecute la operacion remota fuera de una transaccion local.', 1;
        EXEC [nodo_corporativo].[WWI_Corporativo].[dbo].[ActualizarCliente]
                @CustomerID = @CustomerID,
                @CustomerName = @CustomerName,
                @BillToCustomerID = @BillToCustomerID,
                @CustomerCategoryID = @CustomerCategoryID,
                @BuyingGroupID = @BuyingGroupID,
                @PrimaryContactPersonID = @PrimaryContactPersonID,
                @AlternateContactPersonID = @AlternateContactPersonID,
                @DeliveryMethodID = @DeliveryMethodID,
                @DeliveryCityID = @DeliveryCityID,
                @PostalCityID = @PostalCityID,
                @PhoneNumber = @PhoneNumber,
                @FaxNumber = @FaxNumber,
                @WebsiteURL = @WebsiteURL,
                @PaymentDays = @PaymentDays,
                @DeliveryAddressLine1 = @DeliveryAddressLine1,
                @DeliveryAddressLine2 = @DeliveryAddressLine2,
                @DeliveryPostalCode = @DeliveryPostalCode,
                @PostalAddressLine1 = @PostalAddressLine1,
                @PostalAddressLine2 = @PostalAddressLine2,
                @PostalPostalCode = @PostalPostalCode,
                @Latitud = @Latitud,
                @Longitud = @Longitud,
                @CreditLimit = @CreditLimit,
                @StandardDiscountPercentage = @StandardDiscountPercentage,
                @ActualizarCreditLimit = @ActualizarCreditLimit;
        RETURN;
    END;


    DECLARE @DeliveryLocation GEOGRAPHY = NULL;
    IF @Latitud IS NOT NULL AND @Longitud IS NOT NULL
        SET @DeliveryLocation = geography::Point(@Latitud, @Longitud, 4326);

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Origen INT = (SELECT BranchID FROM Sales.Customers_Public WHERE CustomerID = @CustomerID);
        IF @Origen IS NULL THROW 50042, 'El registro indicado no existe.', 1;
        UPDATE Sales.Customers_Public SET CustomerName = LTRIM(RTRIM(@CustomerName)),
            BillToCustomerID = ISNULL(@BillToCustomerID, BillToCustomerID),
            CustomerCategoryID = ISNULL(@CustomerCategoryID, CustomerCategoryID),
            BuyingGroupID = ISNULL(@BuyingGroupID, BuyingGroupID),
            DeliveryMethodID = ISNULL(@DeliveryMethodID, DeliveryMethodID),
            PaymentDays = ISNULL(@PaymentDays, PaymentDays),
            CreditLimit = CASE
                WHEN @ActualizarCreditLimit = 1 THEN @CreditLimit
                ELSE CreditLimit
            END,
            StandardDiscountPercentage = ISNULL(
                @StandardDiscountPercentage,
                StandardDiscountPercentage
            ),
            LastEditedBy = 1
        WHERE BranchID = @Origen AND CustomerID = @CustomerID;
        UPDATE Sales.Customers_Private SET PrimaryContactPersonID = ISNULL(@PrimaryContactPersonID, PrimaryContactPersonID),
            AlternateContactPersonID = ISNULL(@AlternateContactPersonID, AlternateContactPersonID),
            DeliveryCityID = ISNULL(@DeliveryCityID, DeliveryCityID),
            PostalCityID = ISNULL(@PostalCityID, PostalCityID),
            PhoneNumber = ISNULL(LTRIM(RTRIM(@PhoneNumber)), PhoneNumber),
            FaxNumber = ISNULL(LTRIM(RTRIM(@FaxNumber)), FaxNumber),
            WebsiteURL = ISNULL(LTRIM(RTRIM(@WebsiteURL)), WebsiteURL),
            DeliveryAddressLine1 = ISNULL(LTRIM(RTRIM(@DeliveryAddressLine1)), DeliveryAddressLine1),
            DeliveryAddressLine2 = ISNULL(LTRIM(RTRIM(@DeliveryAddressLine2)), DeliveryAddressLine2),
            DeliveryPostalCode = ISNULL(LTRIM(RTRIM(@DeliveryPostalCode)), DeliveryPostalCode),
            PostalAddressLine1 = ISNULL(LTRIM(RTRIM(@PostalAddressLine1)), PostalAddressLine1),
            PostalAddressLine2 = ISNULL(LTRIM(RTRIM(@PostalAddressLine2)), PostalAddressLine2),
            PostalPostalCode = ISNULL(LTRIM(RTRIM(@PostalPostalCode)), PostalPostalCode),
            DeliveryLocation = ISNULL(@DeliveryLocation, DeliveryLocation)
        WHERE BranchID = @Origen AND CustomerID = @CustomerID;
        IF @@ROWCOUNT <> 1 THROW 50049, 'Falta el fragmento privado en Corporativo; revise la migracion.', 1;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/*
==========================================
    PROCEDIMIENTO: EliminarCliente
    Elimina un cliente de la base de datos.
==========================================
*/
CREATE OR ALTER PROCEDURE dbo.EliminarCliente
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF dbo.fn_BranchIDLocal() <> 1
    BEGIN
        IF @@TRANCOUNT <> 0
            THROW 50041, 'Ejecute la operacion remota fuera de una transaccion local.', 1;
        EXEC [nodo_corporativo].[WWI_Corporativo].[dbo].[EliminarCliente]
                @CustomerID = @CustomerID;
        RETURN;
    END;


    EXEC dbo.sp_ValidarEliminacionGlobal @Entidad = 'Cliente', @ID = @CustomerID;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;
        EXEC dbo.sp_ValidarEliminacionLocal @Entidad = 'Cliente', @ID = @CustomerID;
        DELETE FROM Sales.Customers_Private WHERE CustomerID = @CustomerID;
        DELETE FROM Sales.Customers_Public WHERE CustomerID = @CustomerID;
        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
