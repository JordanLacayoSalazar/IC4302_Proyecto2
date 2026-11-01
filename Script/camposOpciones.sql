USE WideWorldImporters;
GO

/*
  En casi todos los procedimientos, deben retornarse OpcionID y Etiqueta porque el componente AutocompletePaginado 
  espera estas propiedades con estos nombres.

  Algunos procedimientos no están paginados porque devuelven muy pocas filas.
*/

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesCiudades
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesCiudades
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    -- Al editar el campo de ciudad de entrega, devuelve el ID exacto asignado.
    IF @ID IS NOT NULL
    BEGIN
        SELECT CityID AS OpcionID, CityName AS Etiqueta
        FROM syn_Ciudades
        WHERE CityID = @ID;
        RETURN;
    END;

    -- Agrupa las ciudades por nombre y conserva un ID representativo.
    WITH CiudadesUnicas AS (
        SELECT MIN(CityID) AS OpcionID, CityName AS Etiqueta
        FROM syn_Ciudades
        WHERE @Busqueda IS NULL OR CityName LIKE '%' + @Busqueda + '%'
        GROUP BY CityName
    )
    SELECT
        OpcionID,
        Etiqueta
    FROM CiudadesUnicas
    ORDER BY Etiqueta, OpcionID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesMetodosEntrega
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesMetodosEntrega
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        DeliveryMethodID AS OpcionID,
        DeliveryMethodName AS Etiqueta
    FROM syn_MetodosEntrega
    WHERE (@ID IS NOT NULL AND DeliveryMethodID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR DeliveryMethodName LIKE '%' + @Busqueda + '%'))
    ORDER BY DeliveryMethodName, DeliveryMethodID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesGruposCompra
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesGruposCompra
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        BuyingGroupID AS OpcionID,
        BuyingGroupName AS Etiqueta
    FROM syn_GruposCompra
    WHERE (@ID IS NOT NULL AND BuyingGroupID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR BuyingGroupName LIKE '%' + @Busqueda + '%'))
    ORDER BY BuyingGroupName, BuyingGroupID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesCategoriasClientes
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesCategoriasClientes
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        CustomerCategoryID AS OpcionID,
        CustomerCategoryName AS Etiqueta
    FROM syn_CategoriasCliente
    WHERE (@ID IS NOT NULL AND CustomerCategoryID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR CustomerCategoryName LIKE '%' + @Busqueda + '%'))
    ORDER BY CustomerCategoryName, CustomerCategoryID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesContactos
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesContactos
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        PersonID AS OpcionID,
        FullName AS Etiqueta
    FROM syn_Personas
    WHERE (@ID IS NOT NULL AND PersonID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR FullName LIKE '%' + @Busqueda + '%'))
    ORDER BY FullName, PersonID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesClientes
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesClientes
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        CustomerID AS OpcionID,
        CustomerName AS Etiqueta
    FROM syn_Clientes
    WHERE (@ID IS NOT NULL AND CustomerID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR CustomerName LIKE '%' + @Busqueda + '%'))
    ORDER BY CustomerName, CustomerID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
============================================
PROCEDIMIENTO: ObtenerOpcionesFormularioCliente
Devuelve las categorías y los métodos de entrega usados en filtros.
============================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesFormularioCliente
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CustomerCategoryID, CustomerCategoryName
    FROM syn_CategoriasCliente
    ORDER BY CustomerCategoryName;

    SELECT DeliveryMethodID, DeliveryMethodName
    FROM syn_MetodosEntrega
    ORDER BY DeliveryMethodName;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesCategoriasProveedor
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesCategoriasProveedor
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        SupplierCategoryID AS OpcionID,
        SupplierCategoryName AS Etiqueta
    FROM syn_CategoriasProveedor
    WHERE (@ID IS NOT NULL AND SupplierCategoryID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR SupplierCategoryName LIKE '%' + @Busqueda + '%'))
    ORDER BY SupplierCategoryName, SupplierCategoryID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
================================================================
PROCEDIMIENTO: ObtenerOpcionesFormularioProveedor
Obtener opciones del formulario de proveedor
================================================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesFormularioProveedor
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SupplierCategoryID,
        SupplierCategoryName
    FROM syn_CategoriasProveedor
    ORDER BY SupplierCategoryName ASC;

    SELECT
        DeliveryMethodID,
        DeliveryMethodName
    FROM syn_MetodosEntrega
    ORDER BY DeliveryMethodName ASC;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesProveedores
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesProveedores
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        SupplierID AS OpcionID,
        SupplierName AS Etiqueta
    FROM syn_Proveedores
    WHERE (@ID IS NOT NULL AND SupplierID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR SupplierName LIKE '%' + @Busqueda + '%'))
    ORDER BY SupplierName, SupplierID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesProductos
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesProductos
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        StockItemID AS OpcionID,
        StockItemName AS Etiqueta,
        UnitPrice AS Precio,
        TaxRate AS Impuesto
    FROM syn_Productos
    WHERE (@ID IS NOT NULL AND StockItemID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR StockItemName LIKE '%' + @Busqueda + '%'))
    ORDER BY StockItemName, StockItemID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesGruposProducto
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesGruposProducto
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        StockGroupID AS OpcionID,
        StockGroupName AS Etiqueta
    FROM syn_GruposProducto
    WHERE (@ID IS NOT NULL AND StockGroupID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR StockGroupName LIKE '%' + @Busqueda + '%'))
    ORDER BY StockGroupName, StockGroupID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesEmpaques
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesEmpaques
    @Busqueda NVARCHAR(100) = NULL,
    @ID INT = NULL,
    @Pagina INT = 0,
    @FilasPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FilasConIndicador INT = @FilasPorPagina + 1;

    SELECT
        PackageTypeID AS OpcionID,
        PackageTypeName AS Etiqueta
    FROM syn_TiposEmpaque
    WHERE (@ID IS NOT NULL AND PackageTypeID = @ID)
       OR (@ID IS NULL AND (@Busqueda IS NULL OR PackageTypeName LIKE '%' + @Busqueda + '%'))
    ORDER BY PackageTypeName, PackageTypeID
    OFFSET (@Pagina * @FilasPorPagina) ROWS
    FETCH NEXT @FilasConIndicador ROWS ONLY;
END;

GO

/*
================================================================================
PROCEDIMIENTO: ObtenerOpcionesFormularioVenta
Devuelve el método de entrega para filtrar la lista de ventas.
================================================================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesFormularioVenta
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DeliveryMethodID, DeliveryMethodName
    FROM syn_MetodosEntrega
    ORDER BY DeliveryMethodName;
END;

GO

/*
==========================================
PROCEDIMIENTO: ObtenerOpcionesFiltrosReportes
Se utiliza para filtrar por año en los reportes de facturas y órdenes de compra.
==========================================
*/
CREATE OR ALTER PROCEDURE ObtenerOpcionesFiltrosReportes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT YEAR(InvoiceDate) AS Anio
    FROM syn_Facturas
    WHERE InvoiceDate IS NOT NULL
    ORDER BY Anio DESC;

    SELECT DISTINCT YEAR(OrderDate) AS Anio
    FROM syn_OrdenesCompra
    WHERE OrderDate IS NOT NULL
    ORDER BY Anio DESC;

END;
GO

-- ================================================================
-- AÑOS VÁLIDOS DISPONIBLES
-- Parámetros : ninguno
-- Retorno    : años presentes en facturas u órdenes de compra.
-- Se utiliza para ver en cuáles años se pueden filtrar los reportes que agrupan por año.
-- ================================================================
CREATE OR ALTER PROCEDURE ObtenerAniosReportes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT Anio
    FROM
    (
        SELECT YEAR(InvoiceDate) AS Anio
        FROM syn_Facturas
        UNION
        SELECT YEAR(OrderDate) AS Anio
        FROM syn_OrdenesCompra
    ) AS Anios
    WHERE Anio IS NOT NULL
    ORDER BY Anio DESC;
END;
GO
