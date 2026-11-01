USE WideWorldImporters;
GO

/*
Lista de códigos de errores:
- 50015: El nombre del proveedor es obligatorio.
- 50016: La referencia del proveedor es obligatoria.
- 50017: La categoría del proveedor es obligatoria.
- 50018: El contacto primario es obligatorio.
- 50019: El método de entrega es obligatorio.
- 50020: La ciudad de entrega es obligatoria.
- 50021: Los días de gracia no pueden ser negativos.
- 50022: La latitud debe estar entre -90 y 90.
- 50023: La longitud debe estar entre -180 y 180.
- 50024: La ciudad indicada no existe en la base de datos.
- 50025: El contacto primario indicado no existe en la base de datos.
- 50026: El contacto alternativo indicado no existe en la base de datos.
- 50027: El proveedor indicado no existe.
*/

/*
============================================
  PROCEDIMIENTO: ObtenerProveedores
  Obtiene proveedores y permite filtrar por nombre, categoría y método de entrega.
============================================
*/
CREATE OR ALTER PROCEDURE ObtenerProveedores
    @NombreBusqueda NVARCHAR(100) = NULL,
    @CategoriaID INT = NULL,
    @MetodoEntregaID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT p.SupplierID,
           p.SupplierName AS NombreProveedor,
           c.SupplierCategoryName AS Categoria,
           m.DeliveryMethodName AS MetodoEntrega
    FROM syn_Proveedores AS p
    LEFT JOIN syn_CategoriasProveedor AS c ON p.SupplierCategoryID = c.SupplierCategoryID
    LEFT JOIN syn_MetodosEntrega AS m ON p.DeliveryMethodID = m.DeliveryMethodID
    WHERE (NULLIF(LTRIM(RTRIM(@NombreBusqueda)), '') IS NULL
           OR p.SupplierName LIKE '%' + LTRIM(RTRIM(@NombreBusqueda)) + '%')
      AND (@CategoriaID IS NULL OR p.SupplierCategoryID = @CategoriaID)
      AND (@MetodoEntregaID IS NULL OR p.DeliveryMethodID = @MetodoEntregaID)
    ORDER BY p.SupplierName ASC, p.SupplierID ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE ObtenerDetalleProveedor
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.SupplierID,
           p.SupplierReference AS CodigoProveedor,
           p.SupplierName AS NombreProveedor,
           p.SupplierCategoryID,
           c.SupplierCategoryName AS Categoria,
           p.PrimaryContactPersonID,
           Contact1.FullName AS ContactoPrimario,
           p.AlternateContactPersonID,
           Contact2.FullName AS ContactoAlternativo,
           p.DeliveryMethodID,
           m.DeliveryMethodName AS MetodoEntrega,
           p.DeliveryCityID,
           ci.CityName AS CiudadEntrega,
           p.DeliveryPostalCode AS CodigoPostal,
           p.PhoneNumber AS Telefono,
           p.FaxNumber AS Fax,
           p.WebsiteURL AS SitioWeb,
           CONCAT_WS(' | ', p.DeliveryAddressLine1, p.DeliveryAddressLine2) AS Direccion,
           CONCAT_WS(' | ', p.PostalAddressLine1, p.PostalAddressLine2) AS DireccionPostal,
           p.DeliveryAddressLine1,
           p.DeliveryAddressLine2,
           p.PostalAddressLine1,
           p.PostalAddressLine2,
           p.PostalPostalCode AS CodigoPostalPostal,
           p.DeliveryLocation.Lat AS Latitud,
           p.DeliveryLocation.Long AS Longitud,
           p.BankAccountName AS NombreBanco,
           p.BankAccountNumber AS CuentaCorriente,
           p.PaymentDays AS DiasGracia
    FROM syn_Proveedores AS p
    LEFT JOIN syn_CategoriasProveedor AS c ON p.SupplierCategoryID = c.SupplierCategoryID
    LEFT JOIN syn_MetodosEntrega AS m ON p.DeliveryMethodID = m.DeliveryMethodID
    LEFT JOIN syn_Ciudades AS ci ON p.DeliveryCityID = ci.CityID
    LEFT JOIN syn_Personas AS Contact1 ON p.PrimaryContactPersonID = Contact1.PersonID
    LEFT JOIN syn_Personas AS Contact2 ON p.AlternateContactPersonID = Contact2.PersonID
    WHERE p.SupplierID = @SupplierID;
END;
GO

CREATE OR ALTER PROCEDURE ObtenerCategoriasProveedor
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SupplierCategoryID, SupplierCategoryName
    FROM syn_CategoriasProveedor
    ORDER BY SupplierCategoryName ASC;
END;
GO


-- ================================================================
-- CREAR PROVEEDOR
-- Parámetros : datos generales, contactos, logística, dirección y
--              datos bancarios.
-- Retorno    : SupplierID creado.
-- Descripción: Crea un provedor
-- ================================================================
CREATE OR ALTER PROCEDURE CrearProveedor
    @SupplierName NVARCHAR(100),
    @SupplierCategoryName NVARCHAR(50),
    @PrimaryContactPersonName NVARCHAR(100),
    @AlternateContactPersonName NVARCHAR(100) = NULL,
    @DeliveryMethodName NVARCHAR(100),
    @CityName NVARCHAR(100),
    @SupplierReference NVARCHAR(20),
    @DeliveryAddressLine1 NVARCHAR(60) = NULL,
    @DeliveryAddressLine2 NVARCHAR(60) = NULL,
    @DeliveryPostalCode NVARCHAR(10) = NULL,
    @PostalAddressLine1 NVARCHAR(60) = NULL,
    @PostalAddressLine2 NVARCHAR(60) = NULL,
    @PostalPostalCode NVARCHAR(10) = NULL,
    @Latitud FLOAT = NULL,
    @Longitud FLOAT = NULL,
    @PhoneNumber NVARCHAR(20) = NULL,
    @FaxNumber NVARCHAR(20) = NULL,
    @WebsiteURL NVARCHAR(256) = NULL,
    @BankAccountName NVARCHAR(50) = NULL,
    @BankAccountNumber NVARCHAR(20) = NULL,
    @PaymentDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @CategoryID INT,
        @DeliveryMethodID INT,
        @CityID INT,
        @PrimaryContactPersonID INT,
        @AlternateContactPersonID INT,
        @Location GEOGRAPHY,
        @NuevoSupplierID INT;

    IF NULLIF(LTRIM(RTRIM(@SupplierName)), '') IS NULL
        THROW 50015, 'El nombre del proveedor es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@SupplierReference)), '') IS NULL
        THROW 50016, 'La referencia del proveedor es obligatoria.', 1;

    IF NULLIF(LTRIM(RTRIM(@SupplierCategoryName)), '') IS NULL
        THROW 50017, 'La categoría del proveedor es obligatoria.', 1;

    IF NULLIF(LTRIM(RTRIM(@PrimaryContactPersonName)), '') IS NULL
        THROW 50018, 'El contacto primario es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@DeliveryMethodName)), '') IS NULL
        THROW 50019, 'El método de entrega es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@CityName)), '') IS NULL
        THROW 50020, 'La ciudad de entrega es obligatoria.', 1;

    IF @PaymentDays < 0
        THROW 50021, 'Los días de gracia no pueden ser negativos.', 1;

    IF @Latitud IS NOT NULL AND (@Latitud < -90 OR @Latitud > 90)
        THROW 50022, 'La latitud debe estar entre -90 y 90.', 1;

    IF @Longitud IS NOT NULL AND (@Longitud < -180 OR @Longitud > 180)
        THROW 50023, 'La longitud debe estar entre -180 y 180.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP (1)
            @CategoryID = SupplierCategoryID
        FROM syn_CategoriasProveedor
        WHERE LTRIM(RTRIM(SupplierCategoryName)) = LTRIM(RTRIM(@SupplierCategoryName));

        IF @CategoryID IS NULL
        BEGIN
            INSERT INTO syn_CategoriasProveedor
                (SupplierCategoryName, LastEditedBy)
            VALUES
                (LTRIM(RTRIM(@SupplierCategoryName)), 1);

            SET @CategoryID = SCOPE_IDENTITY();
        END;

        SELECT TOP (1)
            @DeliveryMethodID = DeliveryMethodID
        FROM syn_MetodosEntrega
        WHERE LTRIM(RTRIM(DeliveryMethodName)) = LTRIM(RTRIM(@DeliveryMethodName));

        IF @DeliveryMethodID IS NULL
        BEGIN
            INSERT INTO syn_MetodosEntrega
                (DeliveryMethodName, LastEditedBy)
            VALUES
                (LTRIM(RTRIM(@DeliveryMethodName)), 1);

            SET @DeliveryMethodID = SCOPE_IDENTITY();
        END;

        SELECT TOP (1)
            @CityID = CityID
        FROM syn_Ciudades
        WHERE LTRIM(RTRIM(CityName)) = LTRIM(RTRIM(@CityName));

        IF @CityID IS NULL
            THROW 50024, 'La ciudad indicada no existe en la base de datos.', 1;

        SELECT TOP (1)
            @PrimaryContactPersonID = PersonID
        FROM syn_Personas
        WHERE LTRIM(RTRIM(FullName)) = LTRIM(RTRIM(@PrimaryContactPersonName));

        IF @PrimaryContactPersonID IS NULL
            THROW 50025, 'El contacto primario indicado no existe en la base de datos.', 1;

        SET @AlternateContactPersonID = @PrimaryContactPersonID;

        IF NULLIF(LTRIM(RTRIM(@AlternateContactPersonName)), '') IS NOT NULL
        BEGIN
            SELECT TOP (1)
                @AlternateContactPersonID = PersonID
            FROM syn_Personas
            WHERE LTRIM(RTRIM(FullName)) = LTRIM(RTRIM(@AlternateContactPersonName));

            IF @AlternateContactPersonID IS NULL
                THROW 50026, 'El contacto alternativo indicado no existe en la base de datos.', 1;
        END;

        IF @Latitud IS NOT NULL AND @Longitud IS NOT NULL
            SET @Location = geography::Point(@Latitud, @Longitud, 4326);
        ELSE
            SET @Location = geography::Point(0, 0, 4326);

        INSERT INTO syn_Proveedores
        (
            SupplierName,
            SupplierCategoryID,
            PrimaryContactPersonID,
            AlternateContactPersonID,
            DeliveryMethodID,
            DeliveryCityID,
            PostalCityID,
            SupplierReference,
            BankAccountName,
            BankAccountBranch,
            BankAccountCode,
            BankAccountNumber,
            BankInternationalCode,
            PaymentDays,
            InternalComments,
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
            LastEditedBy
        )
        VALUES
        (
            LTRIM(RTRIM(@SupplierName)),
            @CategoryID,
            @PrimaryContactPersonID,
            @AlternateContactPersonID,
            @DeliveryMethodID,
            @CityID,
            @CityID,
            LTRIM(RTRIM(@SupplierReference)),
            ISNULL(NULLIF(LTRIM(RTRIM(@BankAccountName)), ''), 'N/A'),
            'N/A',
            'N/A',
            ISNULL(NULLIF(LTRIM(RTRIM(@BankAccountNumber)), ''), 'N/A'),
            'N/A',
            @PaymentDays,
            '',
            ISNULL(NULLIF(LTRIM(RTRIM(@PhoneNumber)), ''), 'N/A'),
            ISNULL(NULLIF(LTRIM(RTRIM(@FaxNumber)), ''), 'N/A'),
            ISNULL(NULLIF(LTRIM(RTRIM(@WebsiteURL)), ''), ''),
            ISNULL(NULLIF(LTRIM(RTRIM(@DeliveryAddressLine1)), ''), 'N/A'),
            ISNULL(NULLIF(LTRIM(RTRIM(@DeliveryAddressLine2)), ''), 'N/A'),
            ISNULL(NULLIF(LTRIM(RTRIM(@DeliveryPostalCode)), ''), 'N/A'),
            @Location,
            ISNULL(NULLIF(LTRIM(RTRIM(@PostalAddressLine1)), ''), 'N/A'),
            ISNULL(NULLIF(LTRIM(RTRIM(@PostalAddressLine2)), ''), 'N/A'),
            ISNULL(NULLIF(LTRIM(RTRIM(@PostalPostalCode)), ''), 'N/A'),
            1
        );

        SET @NuevoSupplierID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoSupplierID AS SupplierID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- ================================================================
-- ACTUALIZAR PROVEEDOR
-- Parámetros : @SupplierID + mismos datos editables de creación
-- Retorno    : ninguno
-- Descripción: Actualización del proveedor
-- ================================================================
CREATE OR ALTER PROCEDURE ActualizarProveedor
    @SupplierID INT,
    @SupplierName NVARCHAR(100),
    @SupplierCategoryName NVARCHAR(50),
    @PrimaryContactPersonName NVARCHAR(100),
    @AlternateContactPersonName NVARCHAR(100) = NULL,
    @DeliveryMethodName NVARCHAR(100),
    @CityName NVARCHAR(100),
    @SupplierReference NVARCHAR(20),
    @DeliveryAddressLine1 NVARCHAR(60) = NULL,
    @DeliveryAddressLine2 NVARCHAR(60) = NULL,
    @DeliveryPostalCode NVARCHAR(10) = NULL,
    @PostalAddressLine1 NVARCHAR(60) = NULL,
    @PostalAddressLine2 NVARCHAR(60) = NULL,
    @PostalPostalCode NVARCHAR(10) = NULL,
    @Latitud FLOAT = NULL,
    @Longitud FLOAT = NULL,
    @PhoneNumber NVARCHAR(20) = NULL,
    @FaxNumber NVARCHAR(20) = NULL,
    @WebsiteURL NVARCHAR(256) = NULL,
    @BankAccountName NVARCHAR(50) = NULL,
    @BankAccountNumber NVARCHAR(20) = NULL,
    @PaymentDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @CategoryID INT,
        @DeliveryMethodID INT,
        @CityID INT,
        @PrimaryContactPersonID INT,
        @AlternateContactPersonID INT,
        @Location GEOGRAPHY;

    IF NOT EXISTS (
        SELECT 1
        FROM syn_Proveedores
        WHERE SupplierID = @SupplierID
    )
        THROW 50027, 'El proveedor indicado no existe.', 1;

    IF NULLIF(LTRIM(RTRIM(@SupplierName)), '') IS NULL
        THROW 50015, 'El nombre del proveedor es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@SupplierReference)), '') IS NULL
        THROW 50016, 'La referencia del proveedor es obligatoria.', 1;

    IF @PaymentDays < 0
        THROW 50021, 'Los días de gracia no pueden ser negativos.', 1;

    IF @Latitud IS NOT NULL AND (@Latitud < -90 OR @Latitud > 90)
        THROW 50022, 'La latitud debe estar entre -90 y 90.', 1;

    IF @Longitud IS NOT NULL AND (@Longitud < -180 OR @Longitud > 180)
        THROW 50023, 'La longitud debe estar entre -180 y 180.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP (1)
            @CategoryID = SupplierCategoryID
        FROM syn_CategoriasProveedor
        WHERE LTRIM(RTRIM(SupplierCategoryName)) = LTRIM(RTRIM(@SupplierCategoryName));

        IF @CategoryID IS NULL
        BEGIN
            INSERT INTO syn_CategoriasProveedor
                (SupplierCategoryName, LastEditedBy)
            VALUES
                (LTRIM(RTRIM(@SupplierCategoryName)), 1);

            SET @CategoryID = SCOPE_IDENTITY();
        END;

        SELECT TOP (1)
            @DeliveryMethodID = DeliveryMethodID
        FROM syn_MetodosEntrega
        WHERE LTRIM(RTRIM(DeliveryMethodName)) = LTRIM(RTRIM(@DeliveryMethodName));

        IF @DeliveryMethodID IS NULL
        BEGIN
            INSERT INTO syn_MetodosEntrega
                (DeliveryMethodName, LastEditedBy)
            VALUES
                (LTRIM(RTRIM(@DeliveryMethodName)), 1);

            SET @DeliveryMethodID = SCOPE_IDENTITY();
        END;

        SELECT TOP (1)
            @CityID = CityID
        FROM syn_Ciudades
        WHERE LTRIM(RTRIM(CityName)) = LTRIM(RTRIM(@CityName));

        IF @CityID IS NULL
            THROW 50024, 'La ciudad indicada no existe en la base de datos.', 1;

        SELECT TOP (1)
            @PrimaryContactPersonID = PersonID
        FROM syn_Personas
        WHERE LTRIM(RTRIM(FullName)) = LTRIM(RTRIM(@PrimaryContactPersonName));

        IF @PrimaryContactPersonID IS NULL
            THROW 50025, 'El contacto primario indicado no existe en la base de datos.', 1;

        SET @AlternateContactPersonID = @PrimaryContactPersonID;

        IF NULLIF(LTRIM(RTRIM(@AlternateContactPersonName)), '') IS NOT NULL
        BEGIN
            SELECT TOP (1)
                @AlternateContactPersonID = PersonID
            FROM syn_Personas
            WHERE LTRIM(RTRIM(FullName)) = LTRIM(RTRIM(@AlternateContactPersonName));

            IF @AlternateContactPersonID IS NULL
                THROW 50026, 'El contacto alternativo indicado no existe en la base de datos.', 1;
        END;

        IF @Latitud IS NOT NULL AND @Longitud IS NOT NULL
            SET @Location = geography::Point(@Latitud, @Longitud, 4326);
        ELSE
            SET @Location = geography::Point(0, 0, 4326);

        UPDATE syn_Proveedores
        SET
            SupplierName = LTRIM(RTRIM(@SupplierName)),
            SupplierCategoryID = @CategoryID,
            PrimaryContactPersonID = @PrimaryContactPersonID,
            AlternateContactPersonID = @AlternateContactPersonID,
            DeliveryMethodID = @DeliveryMethodID,
            DeliveryCityID = @CityID,
            PostalCityID = @CityID,
            SupplierReference = LTRIM(RTRIM(@SupplierReference)),
            PhoneNumber = ISNULL(NULLIF(LTRIM(RTRIM(@PhoneNumber)), ''), 'N/A'),
            FaxNumber = ISNULL(NULLIF(LTRIM(RTRIM(@FaxNumber)), ''), 'N/A'),
            WebsiteURL = ISNULL(NULLIF(LTRIM(RTRIM(@WebsiteURL)), ''), ''),
            BankAccountName = ISNULL(NULLIF(LTRIM(RTRIM(@BankAccountName)), ''), 'N/A'),
            BankAccountNumber = ISNULL(NULLIF(LTRIM(RTRIM(@BankAccountNumber)), ''), 'N/A'),
            PaymentDays = @PaymentDays,
            DeliveryAddressLine1 = ISNULL(NULLIF(LTRIM(RTRIM(@DeliveryAddressLine1)), ''), 'N/A'),
            DeliveryAddressLine2 = ISNULL(NULLIF(LTRIM(RTRIM(@DeliveryAddressLine2)), ''), 'N/A'),
            DeliveryPostalCode = ISNULL(NULLIF(LTRIM(RTRIM(@DeliveryPostalCode)), ''), 'N/A'),
            DeliveryLocation = @Location,
            PostalAddressLine1 = ISNULL(NULLIF(LTRIM(RTRIM(@PostalAddressLine1)), ''), 'N/A'),
            PostalAddressLine2 = ISNULL(NULLIF(LTRIM(RTRIM(@PostalAddressLine2)), ''), 'N/A'),
            PostalPostalCode = ISNULL(NULLIF(LTRIM(RTRIM(@PostalPostalCode)), ''), 'N/A'),
            LastEditedBy = 1
        WHERE SupplierID = @SupplierID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- ================================================================
-- ELIMINAR PROVEEDOR
-- Parámetros : @SupplierID
-- Retorno    : ninguno
-- ================================================================
CREATE OR ALTER PROCEDURE EliminarProveedor
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM syn_Proveedores
        WHERE SupplierID = @SupplierID
    )
        THROW 50027, 'El proveedor indicado no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM syn_Proveedores
        WHERE SupplierID = @SupplierID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
