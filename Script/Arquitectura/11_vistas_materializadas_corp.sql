-- =========================================================================
-- 11_vistas_materializadas_corp.sql  (solo en WWI_Corporativo)
-- Vistas materializadas
-- =========================================================================
USE WWI_Corporativo;
GO
SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON;
SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF;
GO
IF SCHEMA_ID(N'Reporting') IS NULL EXEC (N'CREATE SCHEMA Reporting');
GO
IF NOT EXISTS (SELECT 1 FROM Sales.Invoices WHERE BranchID IN (2, 3))
    PRINT N'AVISO: Corporativo aun no recibio facturas de las sucursales (el snapshot de 09/10 no ha llegado).';
GO

-- Ventas por sucursal / mes
DROP VIEW IF EXISTS Reporting.vw_VentasMensuales;
GO
CREATE VIEW Reporting.vw_VentasMensuales WITH SCHEMABINDING AS
SELECT i.BranchID,
       YEAR(i.InvoiceDate)   AS Anio,
       MONTH(i.InvoiceDate)  AS Mes,
       COUNT_BIG(*)          AS Lineas,
       SUM(il.ExtendedPrice) AS MontoTotal,
       SUM(il.LineProfit)    AS Ganancia,
       SUM(il.Quantity)      AS Unidades
FROM Sales.Invoices AS i
JOIN Sales.InvoiceLines AS il ON il.BranchID = i.BranchID AND il.InvoiceID = i.InvoiceID
GROUP BY i.BranchID, YEAR(i.InvoiceDate), MONTH(i.InvoiceDate);
GO
CREATE UNIQUE CLUSTERED INDEX IX_vw_VentasMensuales ON Reporting.vw_VentasMensuales (BranchID, Anio, Mes);
GO

-- Compras por sucursal / mes
DROP VIEW IF EXISTS Reporting.vw_ComprasMensuales;
GO
CREATE VIEW Reporting.vw_ComprasMensuales WITH SCHEMABINDING AS
SELECT po.BranchID,
       YEAR(po.OrderDate)  AS Anio,
       MONTH(po.OrderDate) AS Mes,
       COUNT_BIG(*)        AS Lineas,
       SUM(ISNULL(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter, 0)) AS MontoEstimado,
       SUM(pol.OrderedOuters) AS BultosOrdenados
FROM Purchasing.PurchaseOrders AS po
JOIN Purchasing.PurchaseOrderLines AS pol ON pol.BranchID = po.BranchID AND pol.PurchaseOrderID = po.PurchaseOrderID
GROUP BY po.BranchID, YEAR(po.OrderDate), MONTH(po.OrderDate);
GO
CREATE UNIQUE CLUSTERED INDEX IX_vw_ComprasMensuales ON Reporting.vw_ComprasMensuales (BranchID, Anio, Mes);
GO

-- Estadisticas con filtro por sucursal o consolidado
CREATE OR ALTER PROCEDURE Reporting.sp_EstadisticasVentas
    @BranchID INT = NULL, @AnioDesde INT = NULL, @AnioHasta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CASE WHEN @BranchID IS NULL THEN N'Consolidado' ELSE b.BranchName END AS Sucursal,
           v.Anio, v.Mes, SUM(v.Lineas) AS Lineas, SUM(v.MontoTotal) AS MontoTotal,
           SUM(v.Ganancia) AS Ganancia, SUM(v.Unidades) AS Unidades
    FROM Reporting.vw_VentasMensuales AS v WITH (NOEXPAND)
    JOIN dbo.Branches AS b ON b.BranchID = v.BranchID
    WHERE (@BranchID IS NULL OR v.BranchID = @BranchID)
      AND (@AnioDesde IS NULL OR v.Anio >= @AnioDesde)
      AND (@AnioHasta IS NULL OR v.Anio <= @AnioHasta)
    GROUP BY CASE WHEN @BranchID IS NULL THEN N'Consolidado' ELSE b.BranchName END, v.Anio, v.Mes
    ORDER BY v.Anio, v.Mes;
END;
GO
CREATE OR ALTER PROCEDURE Reporting.sp_EstadisticasCompras
    @BranchID INT = NULL, @AnioDesde INT = NULL, @AnioHasta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CASE WHEN @BranchID IS NULL THEN N'Consolidado' ELSE b.BranchName END AS Sucursal,
           v.Anio, v.Mes, SUM(v.Lineas) AS Lineas, SUM(v.MontoEstimado) AS MontoEstimado, SUM(v.BultosOrdenados) AS Bultos
    FROM Reporting.vw_ComprasMensuales AS v WITH (NOEXPAND)
    JOIN dbo.Branches AS b ON b.BranchID = v.BranchID
    WHERE (@BranchID IS NULL OR v.BranchID = @BranchID)
      AND (@AnioDesde IS NULL OR v.Anio >= @AnioDesde)
      AND (@AnioHasta IS NULL OR v.Anio <= @AnioHasta)
    GROUP BY CASE WHEN @BranchID IS NULL THEN N'Consolidado' ELSE b.BranchName END, v.Anio, v.Mes
    ORDER BY v.Anio, v.Mes;
END;
GO

-- la suma de las dos sucursales debe igualar al consolidado
SELECT (SELECT SUM(MontoTotal) FROM Reporting.vw_VentasMensuales WITH (NOEXPAND) WHERE BranchID = 2) AS Ventas_SJ,
       (SELECT SUM(MontoTotal) FROM Reporting.vw_VentasMensuales WITH (NOEXPAND) WHERE BranchID = 3) AS Ventas_Limon,
       (SELECT SUM(MontoTotal) FROM Reporting.vw_VentasMensuales WITH (NOEXPAND))                    AS Ventas_Consolidado;
GO