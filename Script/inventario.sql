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
Lista de códigos de errores:
- 50000: El nombre del producto es obligatorio.
- 50001: El grupo del producto es obligatorio.
- 50002: El proveedor es obligatorio.
- 50003: La unidad de empaque es obligatoria.
- 50004: El empaque exterior es obligatorio.
- 50005: La cantidad por empaque debe ser mayor que cero.
- 50006: El impuesto no puede ser negativo.
- 50007: Los precios y el peso no pueden ser negativos.
- 50008: El proveedor indicado no existe.
- 50009: El producto indicado no existe.
- 50010: Los valores numéricos no pueden ser negativos.
- 50028: Las existencias no pueden ser negativas y son obligatorias.
- 50029: Los niveles de reorden y objetivo son obligatorios y no pueden ser negativos.
*/

/*
============================================
  PROCEDIMIENTO: ObtenerProductos
  Obtiene productos, grupo principal y existencias, con filtros y paginación.
============================================
*/
CREATE OR ALTER PROCEDURE dbo.ObtenerProductos
    @NombreBusqueda NVARCHAR(100) = NULL,
    @GrupoID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT si.StockItemID AS ProductoID,
           si.StockItemName AS NombreProducto,
           grupo.StockGroupID AS GrupoID,
           grupo.StockGroupName AS Grupo,
           ISNULL(holdings.QuantityOnHand, 0) AS CantidadInventario
    FROM syn_Productos AS si
    OUTER APPLY (
        SELECT TOP (1) sg.StockGroupID, sg.StockGroupName
        FROM syn_ProductoGrupos AS pig
        INNER JOIN syn_GruposProducto AS sg ON sg.StockGroupID = pig.StockGroupID
        WHERE pig.StockItemID = si.StockItemID
        ORDER BY sg.StockGroupName ASC
    ) AS grupo
    OUTER APPLY (
        SELECT SUM(h.QuantityOnHand) AS QuantityOnHand,
               MAX(h.ReorderLevel) AS ReorderLevel,
               MAX(h.TargetStockLevel) AS TargetStockLevel,
               CASE WHEN COUNT(*) = 1 THEN MAX(h.BinLocation) END AS BinLocation
        FROM syn_Inventario AS h
        WHERE h.StockItemID = si.StockItemID
          AND (@BranchID IS NULL OR h.BranchID = @BranchID)
          AND (dbo.fn_BranchIDLocal() = 1 OR h.BranchID = dbo.fn_BranchIDLocal())
    ) AS holdings
    WHERE (NULLIF(LTRIM(RTRIM(@NombreBusqueda)), '') IS NULL
           OR si.StockItemName LIKE '%' + LTRIM(RTRIM(@NombreBusqueda)) + '%')
      AND (@GrupoID IS NULL OR grupo.StockGroupID = @GrupoID)
    ORDER BY si.StockItemName ASC, si.StockItemID ASC
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.ObtenerDetalleProducto
    @ProductoID INT,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT si.StockItemID AS ProductoID,
           si.StockItemName AS NombreProducto,
           proveedor.SupplierName AS Proveedor,
           grupo.StockGroupName AS NombreGrupo,
           color.ColorName AS Color,
           unitPackage.PackageTypeName AS UnidadEmpaque,
           outerPackage.PackageTypeName AS EmpaqueExterior,
           si.QuantityPerOuter AS CantidadEmpaque,
           si.Brand AS Marca,
           si.Size AS Talla,
           si.TaxRate AS Impuesto,
           si.UnitPrice AS PrecioUnitario,
           si.RecommendedRetailPrice AS PrecioVenta,
           si.TypicalWeightPerUnit AS Peso,
           si.SearchDetails AS PalabrasClaves,
           ISNULL(holdings.QuantityOnHand, 0) AS CantidadDisponible,
           holdings.ReorderLevel AS NivelReorden,
           holdings.TargetStockLevel AS NivelObjetivo,
           holdings.BinLocation AS Ubicacion
    FROM syn_Productos AS si
    LEFT JOIN syn_Proveedores AS proveedor ON proveedor.SupplierID = si.SupplierID
    LEFT JOIN syn_Colores AS color ON color.ColorID = si.ColorID
    LEFT JOIN syn_TiposEmpaque AS unitPackage ON unitPackage.PackageTypeID = si.UnitPackageID
    LEFT JOIN syn_TiposEmpaque AS outerPackage ON outerPackage.PackageTypeID = si.OuterPackageID
    OUTER APPLY (
        SELECT SUM(h.QuantityOnHand) AS QuantityOnHand,
               MAX(h.ReorderLevel) AS ReorderLevel,
               MAX(h.TargetStockLevel) AS TargetStockLevel,
               CASE WHEN COUNT(*) = 1 THEN MAX(h.BinLocation) END AS BinLocation
        FROM syn_Inventario AS h
        WHERE h.StockItemID = si.StockItemID
          AND (@BranchID IS NULL OR h.BranchID = @BranchID)
          AND (dbo.fn_BranchIDLocal() = 1 OR h.BranchID = dbo.fn_BranchIDLocal())
    ) AS holdings
    OUTER APPLY (
        SELECT TOP (1) sg.StockGroupName
        FROM syn_ProductoGrupos AS pig
        INNER JOIN syn_GruposProducto AS sg ON sg.StockGroupID = pig.StockGroupID
        WHERE pig.StockItemID = si.StockItemID
        ORDER BY sg.StockGroupName ASC
    ) AS grupo
    WHERE si.StockItemID = @ProductoID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.ObtenerGruposProducto
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SELECT StockGroupID AS GrupoID, StockGroupName AS NombreGrupo
    FROM syn_GruposProducto
    ORDER BY StockGroupName ASC;
END;
GO


-- ================================================================
-- CREAR PRODUCTO
-- Parámetros : datos principales y comerciales del producto
-- Retorno    : StockItemID del producto creado
-- Descripción: Crea un prodcuto 
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.CrearProducto
    @NombreProducto NVARCHAR(100),
    @NombreGrupo NVARCHAR(50),
    @NombreProveedor NVARCHAR(100),
    @Color NVARCHAR(20) = NULL,
    @UnidadEmpaque NVARCHAR(50),
    @EmpaqueExterior NVARCHAR(50),
    @CantidadEmpaque INT,
    @CantidadInventario INT,
    @NivelReorden INT,
    @NivelObjetivo INT,
    @Marca NVARCHAR(50) = NULL,
    @Talla NVARCHAR(20) = NULL,
    @Impuesto DECIMAL(18,3),
    @PrecioUnitario DECIMAL(18,2),
    @PrecioVenta DECIMAL(18,2),
    @Peso DECIMAL(18,3),
    @PalabrasClaves NVARCHAR(MAX) = NULL,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Destino INT = COALESCE(@BranchID, dbo.fn_BranchIDLocal());
    IF @Destino NOT IN (1, 2, 3) OR @Destino IS NULL
        THROW 50045, 'La sucursal indicada no es valida o el registro no existe.', 1;
    IF dbo.fn_BranchIDLocal() <> 1 AND @Destino <> dbo.fn_BranchIDLocal()
        THROW 50046, 'Opere desde el nodo propietario o desde Corporativo.', 1;
    IF @Destino <> dbo.fn_BranchIDLocal()
    BEGIN
        IF @@TRANCOUNT <> 0
            THROW 50041, 'Ejecute la operacion remota fuera de una transaccion local.', 1;
        IF @Destino = 2
            EXEC [nodo_sucursal_sj].[WWI_SanJose].[dbo].[CrearProducto] @NombreProducto = @NombreProducto, @NombreGrupo = @NombreGrupo, @NombreProveedor = @NombreProveedor, @Color = @Color, @UnidadEmpaque = @UnidadEmpaque, @EmpaqueExterior = @EmpaqueExterior, @CantidadEmpaque = @CantidadEmpaque, @CantidadInventario = @CantidadInventario, @NivelReorden = @NivelReorden, @NivelObjetivo = @NivelObjetivo, @Marca = @Marca, @Talla = @Talla, @Impuesto = @Impuesto, @PrecioUnitario = @PrecioUnitario, @PrecioVenta = @PrecioVenta, @Peso = @Peso, @PalabrasClaves = @PalabrasClaves;
        ELSE IF @Destino = 3
            EXEC [nodo_sucursal_limon].[WWI_Limon].[dbo].[CrearProducto] @NombreProducto = @NombreProducto, @NombreGrupo = @NombreGrupo, @NombreProveedor = @NombreProveedor, @Color = @Color, @UnidadEmpaque = @UnidadEmpaque, @EmpaqueExterior = @EmpaqueExterior, @CantidadEmpaque = @CantidadEmpaque, @CantidadInventario = @CantidadInventario, @NivelReorden = @NivelReorden, @NivelObjetivo = @NivelObjetivo, @Marca = @Marca, @Talla = @Talla, @Impuesto = @Impuesto, @PrecioUnitario = @PrecioUnitario, @PrecioVenta = @PrecioVenta, @Peso = @Peso, @PalabrasClaves = @PalabrasClaves;
        RETURN;
    END;


    DECLARE
        @GrupoID INT,
        @ProveedorID INT,
        @ColorID INT,
        @UnitPkgID INT,
        @OuterPkgID INT,
        @NuevoProductoID INT;

    IF NULLIF(LTRIM(RTRIM(@NombreProducto)), '') IS NULL
        THROW 50000, 'El nombre del producto es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@NombreGrupo)), '') IS NULL
        THROW 50001, 'El grupo del producto es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@NombreProveedor)), '') IS NULL
        THROW 50002, 'El proveedor es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@UnidadEmpaque)), '') IS NULL
        THROW 50003, 'La unidad de empaque es obligatoria.', 1;

    IF NULLIF(LTRIM(RTRIM(@EmpaqueExterior)), '') IS NULL
        THROW 50004, 'El empaque exterior es obligatorio.', 1;

    IF @CantidadEmpaque < 1
        THROW 50005, 'La cantidad por empaque debe ser mayor que cero.', 1;

    IF @CantidadInventario IS NULL OR @CantidadInventario < 0
        THROW 50028, 'Las existencias no pueden ser negativas y son obligatorias.', 1;

    IF @NivelReorden IS NULL OR @NivelReorden < 0 OR @NivelObjetivo IS NULL OR @NivelObjetivo < 0
        THROW 50029, 'Los niveles de reorden y objetivo son obligatorios y no pueden ser negativos.', 1;

    IF @Impuesto < 0
        THROW 50006, 'El impuesto no puede ser negativo.', 1;

    IF @PrecioUnitario < 0 OR @PrecioVenta < 0 OR @Peso < 0
        THROW 50007, 'Los precios y el peso no pueden ser negativos.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP (1)
            @GrupoID = StockGroupID
        FROM syn_GruposProducto
        WHERE LTRIM(RTRIM(StockGroupName)) = LTRIM(RTRIM(@NombreGrupo));

        IF @GrupoID IS NULL
        BEGIN
            SET @GrupoID = NEXT VALUE FOR Repl.seq_StockGroups;
        INSERT INTO syn_GruposProducto (
            BranchID, StockGroupID, StockGroupName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @GrupoID,
            LTRIM(RTRIM(@NombreGrupo)),
            1
        );
        END;

        SELECT TOP (1)
            @ProveedorID = SupplierID
        FROM syn_Proveedores
        WHERE LTRIM(RTRIM(SupplierName)) = LTRIM(RTRIM(@NombreProveedor));

        IF @ProveedorID IS NULL
            THROW 50008, 'El proveedor indicado no existe. Seleccione un proveedor válido.', 1;

        IF NULLIF(LTRIM(RTRIM(@Color)), '') IS NOT NULL
        BEGIN
            SELECT TOP (1)
                @ColorID = ColorID
            FROM syn_Colores
            WHERE LTRIM(RTRIM(ColorName)) = LTRIM(RTRIM(@Color));

            IF @ColorID IS NULL
            BEGIN
                SET @ColorID = NEXT VALUE FOR Repl.seq_Colors;
        INSERT INTO syn_Colores (
            BranchID, ColorID, ColorName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @ColorID,
            LTRIM(RTRIM(@Color)),
            1
        );
            END;
        END;

        SELECT TOP (1)
            @UnitPkgID = PackageTypeID
        FROM syn_TiposEmpaque
        WHERE LTRIM(RTRIM(PackageTypeName)) = LTRIM(RTRIM(@UnidadEmpaque));

        IF @UnitPkgID IS NULL
        BEGIN
            SET @UnitPkgID = NEXT VALUE FOR Repl.seq_PackageTypes;
        INSERT INTO syn_TiposEmpaque (
            BranchID, PackageTypeID, PackageTypeName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @UnitPkgID,
            LTRIM(RTRIM(@UnidadEmpaque)),
            1
        );
        END;

        SELECT TOP (1)
            @OuterPkgID = PackageTypeID
        FROM syn_TiposEmpaque
        WHERE LTRIM(RTRIM(PackageTypeName)) = LTRIM(RTRIM(@EmpaqueExterior));

        IF @OuterPkgID IS NULL
        BEGIN
            SET @OuterPkgID = NEXT VALUE FOR Repl.seq_PackageTypes;
        INSERT INTO syn_TiposEmpaque (
            BranchID, PackageTypeID, PackageTypeName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @OuterPkgID,
            LTRIM(RTRIM(@EmpaqueExterior)),
            1
        );
        END;

        SET @NuevoProductoID = NEXT VALUE FOR Repl.seq_StockItems;
        INSERT INTO syn_Productos (
            BranchID, StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @NuevoProductoID,
            LTRIM(RTRIM(@NombreProducto)),
            @ProveedorID,
            @ColorID,
            @UnitPkgID,
            @OuterPkgID,
            NULLIF(LTRIM(RTRIM(@Marca)), ''),
            NULLIF(LTRIM(RTRIM(@Talla)), ''),
            14,
            @CantidadEmpaque,
            0,
            @Impuesto,
            @PrecioUnitario,
            @PrecioVenta,
            @Peso,
            NULLIF(LTRIM(RTRIM(@PalabrasClaves)), ''),
            1
        );


        IF @NuevoProductoID IS NULL
            THROW 50030, 'No se pudo obtener el identificador del producto creado.', 1;

        INSERT INTO syn_ProductoGrupos (
            BranchID, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            NEXT VALUE FOR Repl.seq_StockItemStockGroups,
            @NuevoProductoID,
            @GrupoID,
            1
        );

        INSERT INTO syn_Inventario (
            BranchID, StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @NuevoProductoID,
            @CantidadInventario,
            'N/A',
            @CantidadInventario,
            @PrecioUnitario,
            @NivelReorden,
            @NivelObjetivo,
            1
        );

        COMMIT TRANSACTION;

        SELECT @NuevoProductoID AS ProductoID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- ================================================================
-- ACTUALIZAR PRODUCTO
-- Parámetros : @ProductoID + datos editables
-- Retorno    : mensaje implícito de éxito
-- Descripción: Actualiza producto
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.ActualizarProducto
    @ProductoID INT,
    @NombreProducto NVARCHAR(100),
    @NombreGrupo NVARCHAR(50),
    @NombreProveedor NVARCHAR(100),
    @Color NVARCHAR(20) = NULL,
    @UnidadEmpaque NVARCHAR(50),
    @EmpaqueExterior NVARCHAR(50),
    @CantidadEmpaque INT,
    @CantidadInventario INT,
    @NivelReorden INT,
    @NivelObjetivo INT,
    @Marca NVARCHAR(50) = NULL,
    @Talla NVARCHAR(20) = NULL,
    @Impuesto DECIMAL(18,3),
    @PrecioUnitario DECIMAL(18,2),
    @PrecioVenta DECIMAL(18,2),
    @Peso DECIMAL(18,3),
    @PalabrasClaves NVARCHAR(MAX) = NULL,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Destino INT = COALESCE(@BranchID, dbo.fn_BranchIDLocal());
    IF @Destino NOT IN (1, 2, 3) OR @Destino IS NULL
        THROW 50045, 'La sucursal indicada no es valida o el registro no existe.', 1;
    IF dbo.fn_BranchIDLocal() <> 1 AND @Destino <> dbo.fn_BranchIDLocal()
        THROW 50046, 'Opere desde el nodo propietario o desde Corporativo.', 1;
    IF @Destino <> dbo.fn_BranchIDLocal()
    BEGIN
        IF @@TRANCOUNT <> 0
            THROW 50041, 'Ejecute la operacion remota fuera de una transaccion local.', 1;
        IF @Destino = 2
            EXEC [nodo_sucursal_sj].[WWI_SanJose].[dbo].[ActualizarProducto] @ProductoID = @ProductoID, @NombreProducto = @NombreProducto, @NombreGrupo = @NombreGrupo, @NombreProveedor = @NombreProveedor, @Color = @Color, @UnidadEmpaque = @UnidadEmpaque, @EmpaqueExterior = @EmpaqueExterior, @CantidadEmpaque = @CantidadEmpaque, @CantidadInventario = @CantidadInventario, @NivelReorden = @NivelReorden, @NivelObjetivo = @NivelObjetivo, @Marca = @Marca, @Talla = @Talla, @Impuesto = @Impuesto, @PrecioUnitario = @PrecioUnitario, @PrecioVenta = @PrecioVenta, @Peso = @Peso, @PalabrasClaves = @PalabrasClaves;
        ELSE IF @Destino = 3
            EXEC [nodo_sucursal_limon].[WWI_Limon].[dbo].[ActualizarProducto] @ProductoID = @ProductoID, @NombreProducto = @NombreProducto, @NombreGrupo = @NombreGrupo, @NombreProveedor = @NombreProveedor, @Color = @Color, @UnidadEmpaque = @UnidadEmpaque, @EmpaqueExterior = @EmpaqueExterior, @CantidadEmpaque = @CantidadEmpaque, @CantidadInventario = @CantidadInventario, @NivelReorden = @NivelReorden, @NivelObjetivo = @NivelObjetivo, @Marca = @Marca, @Talla = @Talla, @Impuesto = @Impuesto, @PrecioUnitario = @PrecioUnitario, @PrecioVenta = @PrecioVenta, @Peso = @Peso, @PalabrasClaves = @PalabrasClaves;
        RETURN;
    END;


    DECLARE
        @GrupoID INT,
        @ProveedorID INT,
        @ColorID INT,
        @UnitPkgID INT,
        @OuterPkgID INT;

    IF NOT EXISTS (
        SELECT 1
        FROM syn_Productos
        WHERE StockItemID = @ProductoID
    )
        THROW 50009, 'El producto indicado no existe.', 1;

    IF NULLIF(LTRIM(RTRIM(@NombreProducto)), '') IS NULL
        THROW 50000, 'El nombre del producto es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@NombreGrupo)), '') IS NULL
        THROW 50001, 'El grupo del producto es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@NombreProveedor)), '') IS NULL
        THROW 50002, 'El proveedor es obligatorio.', 1;

    IF NULLIF(LTRIM(RTRIM(@UnidadEmpaque)), '') IS NULL
        THROW 50003, 'La unidad de empaque es obligatoria.', 1;

    IF NULLIF(LTRIM(RTRIM(@EmpaqueExterior)), '') IS NULL
        THROW 50004, 'El empaque exterior es obligatorio.', 1;

    IF @CantidadEmpaque < 1
        THROW 50005, 'La cantidad por empaque debe ser mayor que cero.', 1;

    IF @CantidadInventario IS NULL OR @CantidadInventario < 0
        THROW 50028, 'Las existencias no pueden ser negativas y son obligatorias.', 1;

    IF @NivelReorden IS NULL OR @NivelReorden < 0 OR @NivelObjetivo IS NULL OR @NivelObjetivo < 0
        THROW 50029, 'Los niveles de reorden y objetivo son obligatorios y no pueden ser negativos.', 1;

    IF @Impuesto < 0 OR @PrecioUnitario < 0 OR @PrecioVenta < 0 OR @Peso < 0
        THROW 50010, 'Los valores numéricos no pueden ser negativos.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP (1)
            @GrupoID = StockGroupID
        FROM syn_GruposProducto
        WHERE LTRIM(RTRIM(StockGroupName)) = LTRIM(RTRIM(@NombreGrupo));

        IF @GrupoID IS NULL
        BEGIN
            SET @GrupoID = NEXT VALUE FOR Repl.seq_StockGroups;
        INSERT INTO syn_GruposProducto (
            BranchID, StockGroupID, StockGroupName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @GrupoID,
            LTRIM(RTRIM(@NombreGrupo)),
            1
        );
        END;

        SELECT TOP (1)
            @ProveedorID = SupplierID
        FROM syn_Proveedores
        WHERE LTRIM(RTRIM(SupplierName)) = LTRIM(RTRIM(@NombreProveedor));

        IF @ProveedorID IS NULL
            THROW 50008, 'El proveedor indicado no existe. Seleccione un proveedor válido.', 1;

        IF NULLIF(LTRIM(RTRIM(@Color)), '') IS NOT NULL
        BEGIN
            SELECT TOP (1)
                @ColorID = ColorID
            FROM syn_Colores
            WHERE LTRIM(RTRIM(ColorName)) = LTRIM(RTRIM(@Color));

            IF @ColorID IS NULL
            BEGIN
                SET @ColorID = NEXT VALUE FOR Repl.seq_Colors;
        INSERT INTO syn_Colores (
            BranchID, ColorID, ColorName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @ColorID,
            LTRIM(RTRIM(@Color)),
            1
        );
            END;
        END;

        SELECT TOP (1)
            @UnitPkgID = PackageTypeID
        FROM syn_TiposEmpaque
        WHERE LTRIM(RTRIM(PackageTypeName)) = LTRIM(RTRIM(@UnidadEmpaque));

        IF @UnitPkgID IS NULL
        BEGIN
            SET @UnitPkgID = NEXT VALUE FOR Repl.seq_PackageTypes;
        INSERT INTO syn_TiposEmpaque (
            BranchID, PackageTypeID, PackageTypeName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @UnitPkgID,
            LTRIM(RTRIM(@UnidadEmpaque)),
            1
        );
        END;

        SELECT TOP (1)
            @OuterPkgID = PackageTypeID
        FROM syn_TiposEmpaque
        WHERE LTRIM(RTRIM(PackageTypeName)) = LTRIM(RTRIM(@EmpaqueExterior));

        IF @OuterPkgID IS NULL
        BEGIN
            SET @OuterPkgID = NEXT VALUE FOR Repl.seq_PackageTypes;
        INSERT INTO syn_TiposEmpaque (
            BranchID, PackageTypeID, PackageTypeName, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @OuterPkgID,
            LTRIM(RTRIM(@EmpaqueExterior)),
            1
        );
        END;

        UPDATE syn_Productos
        SET
            StockItemName = LTRIM(RTRIM(@NombreProducto)),
            SupplierID = @ProveedorID,
            ColorID = @ColorID,
            UnitPackageID = @UnitPkgID,
            OuterPackageID = @OuterPkgID,
            Brand = NULLIF(LTRIM(RTRIM(@Marca)), ''),
            Size = NULLIF(LTRIM(RTRIM(@Talla)), ''),
            QuantityPerOuter = @CantidadEmpaque,
            TaxRate = @Impuesto,
            UnitPrice = @PrecioUnitario,
            RecommendedRetailPrice = @PrecioVenta,
            TypicalWeightPerUnit = @Peso,
            MarketingComments = NULLIF(LTRIM(RTRIM(@PalabrasClaves)), ''),
            LastEditedBy = 1
        WHERE StockItemID = @ProductoID;

        DELETE FROM syn_ProductoGrupos
        WHERE StockItemID = @ProductoID;

        INSERT INTO syn_ProductoGrupos (
            BranchID, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            NEXT VALUE FOR Repl.seq_StockItemStockGroups,
            @ProductoID,
            @GrupoID,
            1
        );

        UPDATE syn_Inventario
        SET
            QuantityOnHand = @CantidadInventario,
            LastStocktakeQuantity = @CantidadInventario,
            ReorderLevel = @NivelReorden,
            TargetStockLevel = @NivelObjetivo,
            LastEditedBy = 1
        WHERE StockItemID = @ProductoID AND BranchID = dbo.fn_BranchIDLocal();

        -- @@ROWCOUNT indica cuántas filas actualizó la sentencia anterior.
        -- Si no había una fila de inventario, se inserta una con los nuevos valores.
        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO syn_Inventario (
            BranchID, StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy
        ) VALUES (
            dbo.fn_BranchIDLocal(),
            @ProductoID,
            @CantidadInventario,
            'N/A',
            @CantidadInventario,
            @PrecioUnitario,
            @NivelReorden,
            @NivelObjetivo,
            1
        );
        END;

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
-- ELIMINAR PRODUCTO
-- Parámetros : @ProductoID
-- Retorno    : ninguno
-- Descripción: Elimina un producto de la base de datos
-- ================================================================
CREATE OR ALTER PROCEDURE dbo.EliminarProducto
    @ProductoID INT,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Destino INT = COALESCE(@BranchID, dbo.fn_BranchIDLocal());
    IF @Destino NOT IN (1, 2, 3) OR @Destino IS NULL
        THROW 50045, 'La sucursal indicada no es valida o el registro no existe.', 1;
    IF dbo.fn_BranchIDLocal() <> 1 AND @Destino <> dbo.fn_BranchIDLocal()
        THROW 50046, 'Opere desde el nodo propietario o desde Corporativo.', 1;
    IF @Destino <> dbo.fn_BranchIDLocal()
    BEGIN
        IF @@TRANCOUNT <> 0
            THROW 50041, 'Ejecute la operacion remota fuera de una transaccion local.', 1;
        IF @Destino = 2
            EXEC [nodo_sucursal_sj].[WWI_SanJose].[dbo].[EliminarProducto] @ProductoID = @ProductoID;
        ELSE IF @Destino = 3
            EXEC [nodo_sucursal_limon].[WWI_Limon].[dbo].[EliminarProducto] @ProductoID = @ProductoID;
        RETURN;
    END;


    IF NOT EXISTS (
        SELECT 1
        FROM syn_Productos
        WHERE StockItemID = @ProductoID
    )
        THROW 50009, 'El producto indicado no existe.', 1;

    EXEC dbo.sp_ValidarEliminacionGlobal @Entidad = 'Producto', @ID = @ProductoID, @SucursalInventario = @Destino;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRANSACTION;
        EXEC dbo.sp_ValidarEliminacionLocal @Entidad = 'Producto', @ID = @ProductoID, @SucursalInventario = @Destino;

        DELETE FROM syn_Inventario
        WHERE StockItemID = @ProductoID AND BranchID = dbo.fn_BranchIDLocal();

        DELETE FROM syn_ProductoGrupos
        WHERE StockItemID = @ProductoID;

        DELETE FROM syn_Productos
        WHERE StockItemID = @ProductoID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
