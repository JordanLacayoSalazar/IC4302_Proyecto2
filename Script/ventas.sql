USE WideWorldImporters;
GO

/*
Lista de códigos de errores:
- 50011: No existe la factura indicada.
- 50012: No existe el producto o no tiene un costo de inventario disponible.
- 50013: No se puede cambiar el cliente o la fecha porque la factura ya tiene movimientos asociados.
- 50014: No existe la línea de factura indicada.
- 50039: La línea de factura no pertenece a la factura indicada.
*/

/*
================================================================================
PROCEDIMIENTO: ObtenerVentas

Obtiene el listado de facturas con nombre del cliente, método de entrega y
monto total. Permite filtros opcionales y acumulativos por número de factura,
cliente, método de entrega, rango de fechas y rango de monto.
================================================================================
*/
CREATE OR ALTER PROCEDURE ObtenerVentas
    @NumeroFactura INT = NULL,
    @NombreCliente NVARCHAR(100) = NULL,
    @MetodoEntregaID INT = NULL,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @MontoMinimo DECIMAL(18, 2) = NULL,
    @MontoMaximo DECIMAL(18, 2) = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    -- Se calcula el monto total de cada factura sumando los precios extendidos y los impuestos de sus líneas
    WITH TotalesFactura AS (
        SELECT
            il.InvoiceID,
            SUM(ISNULL(il.ExtendedPrice, 0) + ISNULL(il.TaxAmount, 0)) AS Monto
        FROM syn_LineasFactura AS il
        GROUP BY il.InvoiceID
    )
    SELECT
        i.InvoiceID AS NumeroFactura,
        i.InvoiceDate AS FechaFactura,
        i.CustomerID,
        c.CustomerName AS Cliente,
        i.DeliveryMethodID,
        dm.DeliveryMethodName AS MetodoEntrega,
        ISNULL(tf.Monto, 0) AS Monto
    FROM syn_Facturas AS i
    INNER JOIN syn_Clientes AS c
        ON i.CustomerID = c.CustomerID
    INNER JOIN syn_MetodosEntrega AS dm
        ON i.DeliveryMethodID = dm.DeliveryMethodID
    LEFT JOIN TotalesFactura AS tf -- Se hace LEFT JOIN para incluir facturas sin líneas
        ON i.InvoiceID = tf.InvoiceID
    WHERE -- Filtros opcionales y acumulativos
        (@NumeroFactura IS NULL OR i.InvoiceID = @NumeroFactura)
        AND (@MetodoEntregaID IS NULL OR i.DeliveryMethodID = @MetodoEntregaID)
        AND (NULLIF(LTRIM(RTRIM(@NombreCliente)), '') IS NULL
            OR c.CustomerName LIKE '%' + LTRIM(RTRIM(@NombreCliente)) + '%')
        AND (@FechaInicio IS NULL OR i.InvoiceDate >= @FechaInicio)
        AND (@FechaFin IS NULL OR i.InvoiceDate < DATEADD(DAY, 1, @FechaFin))
        AND (@MontoMinimo IS NULL OR ISNULL(tf.Monto, 0) >= @MontoMinimo)
        AND (@MontoMaximo IS NULL OR ISNULL(tf.Monto, 0) <= @MontoMaximo)
    ORDER BY c.CustomerName ASC, i.InvoiceID DESC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO

/*
================================================================================
PROCEDIMIENTO: ObtenerDetalleVenta
================================================================================
*/
CREATE OR ALTER PROCEDURE ObtenerDetalleVenta
    @InvoiceID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Encabezado de la factura
    SELECT
        i.InvoiceID AS NumeroFactura,
        i.CustomerID,
        i.BillToCustomerID,
        c.CustomerName AS Cliente,
        facturacion.CustomerName AS ClienteFacturacion,
        i.DeliveryMethodID,
        dm.DeliveryMethodName AS MetodoEntrega,
        i.CustomerPurchaseOrderNumber AS NumeroOrdenCompra,
        i.ContactPersonID,
        contacto.FullName AS PersonaContacto,
        i.AccountsPersonID,
        cuentas.FullName AS PersonaCuentas,
        i.SalespersonPersonID,
        vendedor.FullName AS Vendedor,
        i.PackedByPersonID,
        preparado.FullName AS PreparadoPor,
        i.InvoiceDate AS FechaFactura,
        i.DeliveryInstructions AS InstruccionesEntrega
    FROM syn_Facturas AS i
    INNER JOIN syn_Clientes AS c
        ON i.CustomerID = c.CustomerID
    INNER JOIN syn_Clientes AS facturacion
        ON i.BillToCustomerID = facturacion.CustomerID
    INNER JOIN syn_MetodosEntrega AS dm
        ON i.DeliveryMethodID = dm.DeliveryMethodID
    INNER JOIN syn_Personas AS contacto
        ON i.ContactPersonID = contacto.PersonID
    INNER JOIN syn_Personas AS vendedor
        ON i.SalespersonPersonID = vendedor.PersonID
    INNER JOIN syn_Personas AS cuentas
        ON i.AccountsPersonID = cuentas.PersonID
    INNER JOIN syn_Personas AS preparado
        ON i.PackedByPersonID = preparado.PersonID
    WHERE i.InvoiceID = @InvoiceID;

    -- Detalle de la factura (líneas)
    SELECT
        il.InvoiceLineID,
        il.StockItemID,
        il.PackageTypeID,
        si.StockItemName AS Producto,
        il.Quantity AS Cantidad,
        il.UnitPrice AS PrecioUnitario,
        il.TaxRate AS ImpuestoAplicado,
        il.TaxAmount AS MontoImpuesto,
        il.ExtendedPrice AS TotalLinea
    FROM syn_LineasFactura AS il
    INNER JOIN syn_Productos AS si
        ON il.StockItemID = si.StockItemID
    WHERE il.InvoiceID = @InvoiceID
    ORDER BY il.InvoiceLineID ASC;
END;
GO

/*
================================================================================
PROCEDIMIENTO: InsertarEncabezadoVenta

Inserta el encabezado de una factura.
InvoiceID, los contadores y los campos de auditoría se generan/establecen
desde el sistema. Este procedimiento no inserta líneas de factura.
================================================================================
*/
CREATE OR ALTER PROCEDURE InsertarEncabezadoVenta
    @CustomerID INT,
    @BillToCustomerID INT,
    @DeliveryMethodID INT,
    @ContactPersonID INT,
    @AccountsPersonID INT,
    @SalespersonPersonID INT,
    @PackedByPersonID INT,
    @InvoiceDate DATE,
    @CustomerPurchaseOrderNumber NVARCHAR(20) = NULL,
    @DeliveryInstructions NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InvoiceID INT;

    BEGIN TRY
        SELECT @InvoiceID = NEXT VALUE FOR Sequences.InvoiceID;

        BEGIN TRANSACTION;

        INSERT INTO syn_Facturas (
            InvoiceID,
            CustomerID,
            BillToCustomerID,
            DeliveryMethodID,
            ContactPersonID,
            AccountsPersonID,
            SalespersonPersonID,
            PackedByPersonID,
            InvoiceDate,
            CustomerPurchaseOrderNumber,
            IsCreditNote,
            TotalDryItems,
            TotalChillerItems,
            DeliveryInstructions,
            LastEditedBy
        )
        VALUES (
            @InvoiceID,
            @CustomerID,
            @BillToCustomerID,
            @DeliveryMethodID,
            @ContactPersonID,
            @AccountsPersonID,
            @SalespersonPersonID,
            @PackedByPersonID,
            @InvoiceDate,
            @CustomerPurchaseOrderNumber,
            0,
            0,
            0,
            @DeliveryInstructions,
            1
        );

        COMMIT TRANSACTION;
        SELECT @InvoiceID AS NumeroFactura;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/*
================================================================================
PROCEDIMIENTO: InsertarLineaVenta

Inserta una línea en una factura existente. La descripción del producto, el
impuesto monetario, la ganancia y el total se calculan en el procedimiento.
La escritura se limita a Sales.InvoiceLines.
================================================================================
*/
CREATE OR ALTER PROCEDURE InsertarLineaVenta
    @InvoiceID INT,
    @StockItemID INT,
    @PackageTypeID INT,
    @Cantidad INT,
    @PrecioUnitario DECIMAL(18, 2),
    @ImpuestoAplicado DECIMAL(18, 3)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    -- Para que no se pueda eliminar la factura mientras se inserta la línea, especialmente al verificar que la factura existe 

    DECLARE @Descripcion NVARCHAR(100);
    DECLARE @UltimoCosto DECIMAL(18, 2);
    DECLARE @MontoImpuesto DECIMAL(18, 2);
    DECLARE @GananciaLinea DECIMAL(18, 2);
    DECLARE @PrecioExtendido DECIMAL(18, 2);
    DECLARE @InvoiceLineID INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM syn_Facturas
            WHERE InvoiceID = @InvoiceID
        )
        BEGIN
            ;THROW 50011, 'No existe la factura indicada.', 1;
        END;

        -- Se obtiene la descripción del producto y el último costo de inventario
        SELECT
            @Descripcion = si.StockItemName,
            @UltimoCosto = sih.LastCostPrice
        FROM syn_Productos AS si
        INNER JOIN syn_Inventario AS sih
            ON si.StockItemID = sih.StockItemID
        WHERE si.StockItemID = @StockItemID;

        IF @Descripcion IS NULL OR @UltimoCosto IS NULL
        BEGIN
            ;THROW 50012, 'No existe el producto o no tiene un costo de inventario disponible.', 1;
        END;

        SET @MontoImpuesto =
            @Cantidad * @PrecioUnitario * @ImpuestoAplicado / 100.0;
        SET @GananciaLinea = @Cantidad * (@PrecioUnitario - @UltimoCosto);
        SET @PrecioExtendido = @Cantidad * @PrecioUnitario + @MontoImpuesto;

        SELECT @InvoiceLineID = NEXT VALUE FOR Sequences.InvoiceLineID;

        INSERT INTO syn_LineasFactura (
            InvoiceLineID,
            InvoiceID,
            StockItemID,
            [Description],
            PackageTypeID,
            Quantity,
            UnitPrice,
            TaxRate,
            TaxAmount,
            LineProfit,
            ExtendedPrice,
            LastEditedBy
        )
        VALUES (
            @InvoiceLineID,
            @InvoiceID,
            @StockItemID,
            @Descripcion,
            @PackageTypeID,
            @Cantidad,
            @PrecioUnitario,
            @ImpuestoAplicado,
            @MontoImpuesto,
            @GananciaLinea,
            @PrecioExtendido,
            1
        );

        COMMIT TRANSACTION;
        SELECT
            @InvoiceLineID AS InvoiceLineID,
            @InvoiceID AS InvoiceID;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/*
================================================================================
PROCEDIMIENTO: ModificarEncabezadoVenta

Actualiza los campos de encabezado enviados por la interfaz. No modifica
InvoiceID, contadores, tipo de factura ni otros campos creados por el
sistema. Rechaza cambios de cliente o fecha si ya existen transacciones
contables o de inventario asociadas a la factura.
================================================================================
*/
CREATE OR ALTER PROCEDURE ModificarEncabezadoVenta
    @InvoiceID INT,
    @CustomerID INT = NULL,
    @BillToCustomerID INT = NULL,
    @DeliveryMethodID INT = NULL,
    @ContactPersonID INT = NULL,
    @AccountsPersonID INT = NULL,
    @SalespersonPersonID INT = NULL,
    @PackedByPersonID INT = NULL,
    @InvoiceDate DATE = NULL,
    @CustomerPurchaseOrderNumber NVARCHAR(20) = NULL,
    @DeliveryInstructions NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    -- Para que no se pueda eliminar la factura mientras se modifica el encabezado, especialmente al verificar que la factura existe

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS ( -- Si no existe la factura, se lanza un error
            SELECT 1
            FROM syn_Facturas
            WHERE InvoiceID = @InvoiceID
        )
        BEGIN
            ;THROW 50011, 'No existe la factura indicada.', 1;
        END;

        IF EXISTS ( -- Si la factura está asociada a otras tablas, no se permite cambiar cliente ni fecha
            SELECT 1
            FROM syn_Facturas AS i
            WHERE i.InvoiceID = @InvoiceID
                AND ( -- Se verifica si se intenta cambiar el cliente o la fecha
                    i.CustomerID <> ISNULL(@CustomerID, i.CustomerID)
                    OR i.InvoiceDate <> ISNULL(@InvoiceDate, i.InvoiceDate)
                )
                AND (
                    EXISTS (
                        SELECT 1
                        FROM syn_TransaccionesCliente AS ct
                        WHERE ct.InvoiceID = i.InvoiceID
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM syn_TransaccionesInventario AS sit
                        WHERE sit.InvoiceID = i.InvoiceID
                    )
                )
        )
        BEGIN
            ;THROW 50013, 'No se puede cambiar el cliente o la fecha porque la factura ya tiene movimientos asociados.', 1;
        END;

        UPDATE syn_Facturas
        SET CustomerID = ISNULL(@CustomerID, CustomerID),
            BillToCustomerID = ISNULL(@BillToCustomerID, BillToCustomerID),
            DeliveryMethodID = ISNULL(@DeliveryMethodID, DeliveryMethodID),
            ContactPersonID = ISNULL(@ContactPersonID, ContactPersonID),
            AccountsPersonID = ISNULL(@AccountsPersonID, AccountsPersonID),
            SalespersonPersonID = ISNULL(@SalespersonPersonID, SalespersonPersonID),
            PackedByPersonID = ISNULL(@PackedByPersonID, PackedByPersonID),
            InvoiceDate = ISNULL(@InvoiceDate, InvoiceDate),
            CustomerPurchaseOrderNumber = ISNULL(
                LTRIM(RTRIM(@CustomerPurchaseOrderNumber)),
                CustomerPurchaseOrderNumber
            ),
            DeliveryInstructions = ISNULL(
                LTRIM(RTRIM(@DeliveryInstructions)),
                DeliveryInstructions
            )
        WHERE InvoiceID = @InvoiceID;

        COMMIT TRANSACTION;
        SELECT @InvoiceID AS NumeroFactura;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


/*
================================================================================
PROCEDIMIENTO: ModificarLineaVenta

Modifica únicamente los datos proporcionados de una línea existente.
Los importes derivados y la descripción se recalculan. La escritura se limita
a Sales.InvoiceLines.
================================================================================
*/
CREATE OR ALTER PROCEDURE ModificarLineaVenta
    @InvoiceLineID INT,
    @InvoiceIDEsperado INT,
    @StockItemID INT = NULL,
    @PackageTypeID INT = NULL,
    @Cantidad INT = NULL,
    @PrecioUnitario DECIMAL(18, 2) = NULL,
    @ImpuestoAplicado DECIMAL(18, 3) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    -- Para que no se pueda eliminar la factura mientras se modifica la línea, especialmente al verificar que la factura existe

    DECLARE @InvoiceID INT;
    DECLARE @StockItemIDActual INT;
    DECLARE @PackageTypeIDActual INT;
    DECLARE @CantidadActual INT;
    DECLARE @PrecioUnitarioActual DECIMAL(18, 2);
    DECLARE @ImpuestoAplicadoActual DECIMAL(18, 3);
    DECLARE @StockItemIDFinal INT;
    DECLARE @PackageTypeIDFinal INT;
    DECLARE @CantidadFinal INT;
    DECLARE @PrecioUnitarioFinal DECIMAL(18, 2);
    DECLARE @ImpuestoAplicadoFinal DECIMAL(18, 3);
    DECLARE @Descripcion NVARCHAR(100);
    DECLARE @UltimoCosto DECIMAL(18, 2);
    DECLARE @MontoImpuesto DECIMAL(18, 2);
    DECLARE @GananciaLinea DECIMAL(18, 2);
    DECLARE @PrecioExtendido DECIMAL(18, 2);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Se obtienen los valores actuales de la línea de factura
        SELECT
            @InvoiceID = InvoiceID,
            @StockItemIDActual = StockItemID,
            @PackageTypeIDActual = PackageTypeID,
            @CantidadActual = Quantity,
            @PrecioUnitarioActual = UnitPrice,
            @ImpuestoAplicadoActual = TaxRate
        FROM syn_LineasFactura
        WHERE InvoiceLineID = @InvoiceLineID;

        IF @InvoiceID IS NULL
        BEGIN
            ;THROW 50014, 'No existe la línea de factura indicada.', 1;
        END;

        IF @InvoiceID <> @InvoiceIDEsperado
        BEGIN
            ;THROW 50039, 'La línea no pertenece a la factura indicada.', 1;
        END;

        -- Se determinan los valores finales a utilizar, priorizando los proporcionados por la interfaz
        SET @StockItemIDFinal = ISNULL(@StockItemID, @StockItemIDActual);
        SET @PackageTypeIDFinal = ISNULL(@PackageTypeID, @PackageTypeIDActual);
        SET @CantidadFinal = ISNULL(@Cantidad, @CantidadActual);
        SET @PrecioUnitarioFinal = ISNULL(@PrecioUnitario, @PrecioUnitarioActual);
        SET @ImpuestoAplicadoFinal = ISNULL(@ImpuestoAplicado, @ImpuestoAplicadoActual);

        -- Se obtiene la descripción del producto y el último costo de inventario
        SELECT
            @Descripcion = si.StockItemName,
            @UltimoCosto = sih.LastCostPrice
        FROM syn_Productos AS si
        INNER JOIN syn_Inventario AS sih
            ON si.StockItemID = sih.StockItemID
        WHERE si.StockItemID = @StockItemIDFinal;

        IF @Descripcion IS NULL OR @UltimoCosto IS NULL
        BEGIN
            ;THROW 50012, 'No existe el producto o no tiene un costo de inventario disponible.', 1;
        END;

        SET @MontoImpuesto =
            @CantidadFinal * ISNULL(@PrecioUnitarioFinal, 0)
                * @ImpuestoAplicadoFinal / 100.0;
        SET @GananciaLinea =
            @CantidadFinal * (ISNULL(@PrecioUnitarioFinal, 0) - @UltimoCosto);
        SET @PrecioExtendido =
            @CantidadFinal * ISNULL(@PrecioUnitarioFinal, 0) + @MontoImpuesto;

        UPDATE syn_LineasFactura
        SET StockItemID = @StockItemIDFinal,
            [Description] = @Descripcion,
            PackageTypeID = @PackageTypeIDFinal,
            Quantity = @CantidadFinal,
            UnitPrice = @PrecioUnitarioFinal,
            TaxRate = @ImpuestoAplicadoFinal,
            TaxAmount = @MontoImpuesto,
            LineProfit = @GananciaLinea,
            ExtendedPrice = @PrecioExtendido,
            LastEditedBy = 1,
            LastEditedWhen = SYSDATETIME()
        WHERE InvoiceLineID = @InvoiceLineID;

        COMMIT TRANSACTION;
        SELECT
            @InvoiceID AS InvoiceID,
            @InvoiceLineID AS InvoiceLineID;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Las ventas no se pueden eliminar.
