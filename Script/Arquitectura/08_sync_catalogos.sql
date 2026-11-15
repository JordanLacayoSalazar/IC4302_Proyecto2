-- =========================================================================
-- 08_sync_catalogos_multimaster.sql
-- Replicacion bidireccional entre los 3 nodos
-- Ejecutar en WWI_Corporativo, WWI_SanJose y WWI_Limon
-- =========================================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF DB_NAME() NOT IN (N'WWI_Corporativo', N'WWI_SanJose', N'WWI_Limon')
BEGIN
    RAISERROR(N'Ejecuta este script conectado a WWI_Corporativo, WWI_SanJose o WWI_Limon', 16, 1);
    SET NOEXEC ON;
END
GO

IF SCHEMA_ID(N'Repl') IS NULL EXEC (N'CREATE SCHEMA Repl');
GO

-- ------------------------------------------------------------------ tablas de control
IF OBJECT_ID(N'Repl.NodeInfo') IS NULL
CREATE TABLE Repl.NodeInfo (BranchID INT NOT NULL PRIMARY KEY, NodeName SYSNAME NOT NULL);

IF OBJECT_ID(N'Repl.Peers') IS NULL
CREATE TABLE Repl.Peers (PeerBranchID INT NOT NULL PRIMARY KEY, LinkedServer SYSNAME NOT NULL, DbName SYSNAME NOT NULL);

IF OBJECT_ID(N'Repl.PeerState') IS NULL
CREATE TABLE Repl.PeerState (
    PeerBranchID INT NOT NULL PRIMARY KEY,
    LastChangeID BIGINT NOT NULL DEFAULT 0,
    LastSyncAt   DATETIME2(7) NULL,
    LastStatus   NVARCHAR(500) NULL);

IF OBJECT_ID(N'Repl.ChangeLog') IS NULL
CREATE TABLE Repl.ChangeLog (
    ChangeID       BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Repl_ChangeLog PRIMARY KEY,
    OriginBranchID INT NOT NULL,
    TableName      SYSNAME NOT NULL,
    Op             CHAR(1) NOT NULL CONSTRAINT CK_Repl_ChangeLog_Op CHECK (Op IN ('I','U','D')),
    PKKey          NVARCHAR(200) NOT NULL,
    RowData        NVARCHAR(MAX) NOT NULL,
    ChangedAt      DATETIME2(7) NOT NULL);

IF OBJECT_ID(N'Repl.RowStamp') IS NULL
CREATE TABLE Repl.RowStamp (
    TableName      SYSNAME NOT NULL,
    PKKey          NVARCHAR(200) NOT NULL,
    ChangedAt      DATETIME2(7) NOT NULL,
    OriginBranchID INT NOT NULL,
    OriginChangeID BIGINT NOT NULL,
    IsDeleted      BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_Repl_RowStamp PRIMARY KEY (TableName, PKKey));

IF OBJECT_ID(N'Repl.ConflictLog') IS NULL
CREATE TABLE Repl.ConflictLog (
    ConflictID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    DetectedAt        DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    TableName         SYSNAME NOT NULL,
    PKKey             NVARCHAR(200) NOT NULL,
    WinnerBranchID    INT NOT NULL,
    WinnerChangedAt   DATETIME2(7) NOT NULL,
    LoserBranchID     INT NOT NULL,
    LoserChangedAt    DATETIME2(7) NOT NULL,
    IncomingOp        CHAR(1) NOT NULL,
    IncomingRowData   NVARCHAR(MAX) NULL,
    Resolution        NVARCHAR(100) NOT NULL);
IF OBJECT_ID(N'Repl.SyncErrors') IS NULL

CREATE TABLE Repl.SyncErrors (
    PeerBranchID INT NOT NULL,
    ChangeID     BIGINT NOT NULL,
    TableName    SYSNAME NULL,
    Attempts     INT NOT NULL,
    LastError    NVARCHAR(2000) NULL,
    LastAt       DATETIME2(7) NOT NULL,
    Skipped      BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_Repl_SyncErrors PRIMARY KEY (PeerBranchID, ChangeID));
GO

-- ------------------------------------------------------------------ identidad del nodo y pares
DECLARE @b INT = CASE DB_NAME() WHEN N'WWI_Corporativo' THEN 1 WHEN N'WWI_SanJose' THEN 2 WHEN N'WWI_Limon' THEN 3 END;

DELETE Repl.NodeInfo;

INSERT Repl.NodeInfo (BranchID, NodeName) VALUES (@b, DB_NAME());

DELETE Repl.Peers;

INSERT Repl.Peers (PeerBranchID, LinkedServer, DbName) VALUES
    (1, N'nodo_corporativo',   N'WWI_Corporativo'),
    (2, N'nodo_sucursal_sj',   N'WWI_SanJose'),
    (3, N'nodo_sucursal_limon', N'WWI_Limon');

INSERT Repl.PeerState (PeerBranchID) SELECT p.PeerBranchID FROM Repl.Peers p
 WHERE p.PeerBranchID <> @b AND NOT EXISTS (SELECT 1 FROM Repl.PeerState s WHERE s.PeerBranchID = p.PeerBranchID);
GO

-- ------------------------------------------------------------------ secuencias por nodo
DECLARE @b2 INT = (SELECT BranchID FROM Repl.NodeInfo);
DECLARE @start NVARCHAR(20) = CAST(@b2 * 1000000 AS NVARCHAR(20));

IF OBJECT_ID(N'Repl.seq_DeliveryMethods') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_DeliveryMethods AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_CustomerCategories') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_CustomerCategories AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_BuyingGroups') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_BuyingGroups AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_SupplierCategories') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_SupplierCategories AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_Colors') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_Colors AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_PackageTypes') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_PackageTypes AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_StockGroups') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_StockGroups AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_StockItemStockGroups') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_StockItemStockGroups AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_StockItems') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_StockItems AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_Customers_Public') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_Customers_Public AS INT START WITH ' + @start + N' INCREMENT BY 1');
IF OBJECT_ID(N'Repl.seq_Suppliers_Public') IS NULL EXEC (N'CREATE SEQUENCE Repl.seq_Suppliers_Public AS INT START WITH ' + @start + N' INCREMENT BY 1');
GO

-- ------------------------------------------------------------------ triggers de captura
CREATE OR ALTER TRIGGER Application.trg_Repl_DeliveryMethods
ON Application.DeliveryMethods
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.DeliveryMethodID),
           (SELECT i.BranchID AS BranchID, i.DeliveryMethodID AS DeliveryMethodID, i.DeliveryMethodName AS DeliveryMethodName, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.DeliveryMethodID = i.DeliveryMethodID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.DeliveryMethodID),
           (SELECT d.BranchID AS BranchID, d.DeliveryMethodID AS DeliveryMethodID, d.DeliveryMethodName AS DeliveryMethodName, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.DeliveryMethodID = d.DeliveryMethodID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Application.DeliveryMethods', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Application.DeliveryMethods' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Application.DeliveryMethods', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Sales.trg_Repl_CustomerCategories
ON Sales.CustomerCategories
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.CustomerCategoryID),
           (SELECT i.BranchID AS BranchID, i.CustomerCategoryID AS CustomerCategoryID, i.CustomerCategoryName AS CustomerCategoryName, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.CustomerCategoryID = i.CustomerCategoryID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.CustomerCategoryID),
           (SELECT d.BranchID AS BranchID, d.CustomerCategoryID AS CustomerCategoryID, d.CustomerCategoryName AS CustomerCategoryName, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.CustomerCategoryID = d.CustomerCategoryID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Sales.CustomerCategories', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Sales.CustomerCategories' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Sales.CustomerCategories', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Sales.trg_Repl_BuyingGroups
ON Sales.BuyingGroups
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.BuyingGroupID),
           (SELECT i.BranchID AS BranchID, i.BuyingGroupID AS BuyingGroupID, i.BuyingGroupName AS BuyingGroupName, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.BuyingGroupID = i.BuyingGroupID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.BuyingGroupID),
           (SELECT d.BranchID AS BranchID, d.BuyingGroupID AS BuyingGroupID, d.BuyingGroupName AS BuyingGroupName, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.BuyingGroupID = d.BuyingGroupID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Sales.BuyingGroups', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Sales.BuyingGroups' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Sales.BuyingGroups', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Purchasing.trg_Repl_SupplierCategories
ON Purchasing.SupplierCategories
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.SupplierCategoryID),
           (SELECT i.BranchID AS BranchID, i.SupplierCategoryID AS SupplierCategoryID, i.SupplierCategoryName AS SupplierCategoryName, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.SupplierCategoryID = i.SupplierCategoryID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.SupplierCategoryID),
           (SELECT d.BranchID AS BranchID, d.SupplierCategoryID AS SupplierCategoryID, d.SupplierCategoryName AS SupplierCategoryName, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.SupplierCategoryID = d.SupplierCategoryID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Purchasing.SupplierCategories', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Purchasing.SupplierCategories' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Purchasing.SupplierCategories', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Warehouse.trg_Repl_Colors
ON Warehouse.Colors
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.ColorID),
           (SELECT i.BranchID AS BranchID, i.ColorID AS ColorID, i.ColorName AS ColorName, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.ColorID = i.ColorID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.ColorID),
           (SELECT d.BranchID AS BranchID, d.ColorID AS ColorID, d.ColorName AS ColorName, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.ColorID = d.ColorID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Warehouse.Colors', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Warehouse.Colors' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Warehouse.Colors', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Warehouse.trg_Repl_PackageTypes
ON Warehouse.PackageTypes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.PackageTypeID),
           (SELECT i.BranchID AS BranchID, i.PackageTypeID AS PackageTypeID, i.PackageTypeName AS PackageTypeName, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.PackageTypeID = i.PackageTypeID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.PackageTypeID),
           (SELECT d.BranchID AS BranchID, d.PackageTypeID AS PackageTypeID, d.PackageTypeName AS PackageTypeName, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.PackageTypeID = d.PackageTypeID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Warehouse.PackageTypes', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Warehouse.PackageTypes' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Warehouse.PackageTypes', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Warehouse.trg_Repl_StockGroups
ON Warehouse.StockGroups
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.StockGroupID),
           (SELECT i.BranchID AS BranchID, i.StockGroupID AS StockGroupID, i.StockGroupName AS StockGroupName, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.StockGroupID = i.StockGroupID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.StockGroupID),
           (SELECT d.BranchID AS BranchID, d.StockGroupID AS StockGroupID, d.StockGroupName AS StockGroupName, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.StockGroupID = d.StockGroupID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Warehouse.StockGroups', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Warehouse.StockGroups' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Warehouse.StockGroups', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Warehouse.trg_Repl_StockItemStockGroups
ON Warehouse.StockItemStockGroups
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.StockItemStockGroupID),
           (SELECT i.BranchID AS BranchID, i.StockItemStockGroupID AS StockItemStockGroupID, i.StockItemID AS StockItemID, i.StockGroupID AS StockGroupID, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.StockItemStockGroupID = i.StockItemStockGroupID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.StockItemStockGroupID),
           (SELECT d.BranchID AS BranchID, d.StockItemStockGroupID AS StockItemStockGroupID, d.StockItemID AS StockItemID, d.StockGroupID AS StockGroupID, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.StockItemStockGroupID = d.StockItemStockGroupID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Warehouse.StockItemStockGroups', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Warehouse.StockItemStockGroups' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Warehouse.StockItemStockGroups', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Warehouse.trg_Repl_StockItems
ON Warehouse.StockItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.StockItemID),
           (SELECT i.BranchID AS BranchID, i.StockItemID AS StockItemID, i.StockItemName AS StockItemName, i.SupplierID AS SupplierID, i.ColorID AS ColorID, i.UnitPackageID AS UnitPackageID, i.OuterPackageID AS OuterPackageID, i.Brand AS Brand, i.Size AS Size, i.LeadTimeDays AS LeadTimeDays, i.QuantityPerOuter AS QuantityPerOuter, i.IsChillerStock AS IsChillerStock, i.Barcode AS Barcode, i.TaxRate AS TaxRate, i.UnitPrice AS UnitPrice, i.RecommendedRetailPrice AS RecommendedRetailPrice, i.TypicalWeightPerUnit AS TypicalWeightPerUnit, i.MarketingComments AS MarketingComments, i.InternalComments AS InternalComments, i.CustomFields AS CustomFields, i.LastEditedBy AS LastEditedBy, i.ValidFrom AS ValidFrom FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.StockItemID = i.StockItemID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.StockItemID),
           (SELECT d.BranchID AS BranchID, d.StockItemID AS StockItemID, d.StockItemName AS StockItemName, d.SupplierID AS SupplierID, d.ColorID AS ColorID, d.UnitPackageID AS UnitPackageID, d.OuterPackageID AS OuterPackageID, d.Brand AS Brand, d.Size AS Size, d.LeadTimeDays AS LeadTimeDays, d.QuantityPerOuter AS QuantityPerOuter, d.IsChillerStock AS IsChillerStock, d.Barcode AS Barcode, d.TaxRate AS TaxRate, d.UnitPrice AS UnitPrice, d.RecommendedRetailPrice AS RecommendedRetailPrice, d.TypicalWeightPerUnit AS TypicalWeightPerUnit, d.MarketingComments AS MarketingComments, d.InternalComments AS InternalComments, d.CustomFields AS CustomFields, d.LastEditedBy AS LastEditedBy, d.ValidFrom AS ValidFrom FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.StockItemID = d.StockItemID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Warehouse.StockItems', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Warehouse.StockItems' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Warehouse.StockItems', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Sales.trg_Repl_Customers_Public
ON Sales.Customers_Public
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.CustomerID),
           (SELECT i.BranchID AS BranchID, i.CustomerID AS CustomerID, i.CustomerName AS CustomerName, i.BillToCustomerID AS BillToCustomerID, i.CustomerCategoryID AS CustomerCategoryID, i.BuyingGroupID AS BuyingGroupID, i.DeliveryMethodID AS DeliveryMethodID, i.DeliveryRun AS DeliveryRun, i.RunPosition AS RunPosition, i.CreditLimit AS CreditLimit, i.AccountOpenedDate AS AccountOpenedDate, i.StandardDiscountPercentage AS StandardDiscountPercentage, i.IsStatementSent AS IsStatementSent, i.IsOnCreditHold AS IsOnCreditHold, i.PaymentDays AS PaymentDays, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.CustomerID = i.CustomerID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.CustomerID),
           (SELECT d.BranchID AS BranchID, d.CustomerID AS CustomerID, d.CustomerName AS CustomerName, d.BillToCustomerID AS BillToCustomerID, d.CustomerCategoryID AS CustomerCategoryID, d.BuyingGroupID AS BuyingGroupID, d.DeliveryMethodID AS DeliveryMethodID, d.DeliveryRun AS DeliveryRun, d.RunPosition AS RunPosition, d.CreditLimit AS CreditLimit, d.AccountOpenedDate AS AccountOpenedDate, d.StandardDiscountPercentage AS StandardDiscountPercentage, d.IsStatementSent AS IsStatementSent, d.IsOnCreditHold AS IsOnCreditHold, d.PaymentDays AS PaymentDays, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.CustomerID = d.CustomerID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Sales.Customers_Public', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Sales.Customers_Public' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Sales.Customers_Public', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER Purchasing.trg_Repl_Suppliers_Public
ON Purchasing.Suppliers_Public
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.SupplierID),
           (SELECT i.BranchID AS BranchID, i.SupplierID AS SupplierID, i.SupplierName AS SupplierName, i.SupplierCategoryID AS SupplierCategoryID, i.SupplierReference AS SupplierReference, i.DeliveryMethodID AS DeliveryMethodID, i.PaymentDays AS PaymentDays, i.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.SupplierID = i.SupplierID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.SupplierID),
           (SELECT d.BranchID AS BranchID, d.SupplierID AS SupplierID, d.SupplierName AS SupplierName, d.SupplierCategoryID AS SupplierCategoryID, d.SupplierReference AS SupplierReference, d.DeliveryMethodID AS DeliveryMethodID, d.PaymentDays AS PaymentDays, d.LastEditedBy AS LastEditedBy FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.SupplierID = d.SupplierID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'Purchasing.Suppliers_Public', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'Purchasing.Suppliers_Public' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'Purchasing.Suppliers_Public', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Repl_Branches
ON dbo.Branches
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONVERT(NVARCHAR(200), i.BranchID),
           (SELECT i.BranchID AS BranchID, i.BranchName AS BranchName, i.ConnectionPort AS ConnectionPort, i.HostServer AS HostServer FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID
    UNION ALL
    SELECT 'D',
           CONVERT(NVARCHAR(200), d.BranchID),
           (SELECT d.BranchID AS BranchID, d.BranchName AS BranchName, d.ConnectionPort AS ConnectionPort, d.HostServer AS HostServer FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'dbo.Branches', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'dbo.Branches' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'dbo.Branches', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Repl_Users
ON dbo.Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CONVERT(INT, SESSION_CONTEXT(N'repl_apply')), 0) = 1 RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) RETURN;

    DECLARE @b   INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
    DECLARE @chg TABLE (Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL);
    DECLARE @ids TABLE (ChangeID BIGINT NOT NULL, PKKey NVARCHAR(200) NOT NULL, Op CHAR(1) NOT NULL);

    INSERT @chg (Op, PKKey, RowData)
    SELECT CASE WHEN d.BranchID IS NULL THEN 'I' ELSE 'U' END,
           CONCAT(i.BranchID, N'|', i.UserID),
           (SELECT i.BranchID AS BranchID, i.UserID AS UserID, i.Username AS Username, CONVERT(NVARCHAR(200), i.PasswordHash, 1) AS PasswordHash, i.FullName AS FullName, i.IsActive AS IsActive, i.Role AS Role, i.Email AS Email, i.HireDate AS HireDate FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.BranchID = i.BranchID AND d.UserID = i.UserID
    UNION ALL
    SELECT 'D',
           CONCAT(d.BranchID, N'|', d.UserID),
           (SELECT d.BranchID AS BranchID, d.UserID AS UserID, d.Username AS Username, CONVERT(NVARCHAR(200), d.PasswordHash, 1) AS PasswordHash, d.FullName AS FullName, d.IsActive AS IsActive, d.Role AS Role, d.Email AS Email, d.HireDate AS HireDate FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM deleted AS d
    WHERE NOT EXISTS (SELECT 1 FROM inserted AS i WHERE i.BranchID = d.BranchID AND i.UserID = d.UserID);

    INSERT Repl.ChangeLog (OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt)
    OUTPUT inserted.ChangeID, inserted.PKKey, inserted.Op INTO @ids (ChangeID, PKKey, Op)
    SELECT @b, N'dbo.Users', Op, PKKey, RowData, @now FROM @chg;

    MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
    USING @ids AS x ON s.TableName = N'dbo.Users' AND s.PKKey = x.PKKey
    WHEN MATCHED THEN UPDATE SET ChangedAt = @now, OriginBranchID = @b, OriginChangeID = x.ChangeID,
                                 IsDeleted = CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END
    WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
         VALUES (N'dbo.Users', x.PKKey, @now, @b, x.ChangeID, CASE WHEN x.Op = 'D' THEN 1 ELSE 0 END);
END;
GO

-- ------------------------------------------------------------------ aplicar un cambio
CREATE OR ALTER PROCEDURE Repl.sp_ApplyChange
    @TableName SYSNAME,
    @Op        CHAR(1),
    @RowData   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF @TableName = N'Application.DeliveryMethods'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Application.DeliveryMethods AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, DeliveryMethodID INT) AS j ON t.BranchID = j.BranchID AND t.DeliveryMethodID = j.DeliveryMethodID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                ;WITH s AS (SELECT BranchID, DeliveryMethodID, DeliveryMethodName, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, DeliveryMethodID INT, DeliveryMethodName NVARCHAR(50), LastEditedBy INT))
                MERGE Application.DeliveryMethods WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.DeliveryMethodID = s.DeliveryMethodID
                WHEN MATCHED THEN UPDATE SET t.DeliveryMethodName = s.DeliveryMethodName, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, DeliveryMethodID, DeliveryMethodName, LastEditedBy) VALUES (s.BranchID, s.DeliveryMethodID, s.DeliveryMethodName, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Sales.CustomerCategories'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Sales.CustomerCategories AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, CustomerCategoryID INT) AS j ON t.BranchID = j.BranchID AND t.CustomerCategoryID = j.CustomerCategoryID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, CustomerCategoryID, CustomerCategoryName, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, CustomerCategoryID INT, CustomerCategoryName NVARCHAR(50), LastEditedBy INT))
                MERGE Sales.CustomerCategories WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.CustomerCategoryID = s.CustomerCategoryID
                WHEN MATCHED THEN UPDATE SET t.CustomerCategoryName = s.CustomerCategoryName, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, CustomerCategoryID, CustomerCategoryName, LastEditedBy) VALUES (s.BranchID, s.CustomerCategoryID, s.CustomerCategoryName, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Sales.BuyingGroups'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Sales.BuyingGroups AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, BuyingGroupID INT) AS j ON t.BranchID = j.BranchID AND t.BuyingGroupID = j.BuyingGroupID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, BuyingGroupID, BuyingGroupName, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, BuyingGroupID INT, BuyingGroupName NVARCHAR(50), LastEditedBy INT))
                MERGE Sales.BuyingGroups WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.BuyingGroupID = s.BuyingGroupID
                WHEN MATCHED THEN UPDATE SET t.BuyingGroupName = s.BuyingGroupName, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, BuyingGroupID, BuyingGroupName, LastEditedBy) VALUES (s.BranchID, s.BuyingGroupID, s.BuyingGroupName, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Purchasing.SupplierCategories'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Purchasing.SupplierCategories AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, SupplierCategoryID INT) AS j ON t.BranchID = j.BranchID AND t.SupplierCategoryID = j.SupplierCategoryID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, SupplierCategoryID, SupplierCategoryName, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, SupplierCategoryID INT, SupplierCategoryName NVARCHAR(50), LastEditedBy INT))
                MERGE Purchasing.SupplierCategories WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.SupplierCategoryID = s.SupplierCategoryID
                WHEN MATCHED THEN UPDATE SET t.SupplierCategoryName = s.SupplierCategoryName, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, SupplierCategoryID, SupplierCategoryName, LastEditedBy) VALUES (s.BranchID, s.SupplierCategoryID, s.SupplierCategoryName, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Warehouse.Colors'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Warehouse.Colors AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, ColorID INT) AS j ON t.BranchID = j.BranchID AND t.ColorID = j.ColorID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, ColorID, ColorName, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, ColorID INT, ColorName NVARCHAR(20), LastEditedBy INT))
                MERGE Warehouse.Colors WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.ColorID = s.ColorID
                WHEN MATCHED THEN UPDATE SET t.ColorName = s.ColorName, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, ColorID, ColorName, LastEditedBy) VALUES (s.BranchID, s.ColorID, s.ColorName, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Warehouse.PackageTypes'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Warehouse.PackageTypes AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, PackageTypeID INT) AS j ON t.BranchID = j.BranchID AND t.PackageTypeID = j.PackageTypeID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, PackageTypeID, PackageTypeName, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, PackageTypeID INT, PackageTypeName NVARCHAR(50), LastEditedBy INT))
                MERGE Warehouse.PackageTypes WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.PackageTypeID = s.PackageTypeID
                WHEN MATCHED THEN UPDATE SET t.PackageTypeName = s.PackageTypeName, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, PackageTypeID, PackageTypeName, LastEditedBy) VALUES (s.BranchID, s.PackageTypeID, s.PackageTypeName, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Warehouse.StockGroups'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Warehouse.StockGroups AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, StockGroupID INT) AS j ON t.BranchID = j.BranchID AND t.StockGroupID = j.StockGroupID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, StockGroupID, StockGroupName, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, StockGroupID INT, StockGroupName NVARCHAR(50), LastEditedBy INT))
                MERGE Warehouse.StockGroups WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.StockGroupID = s.StockGroupID
                WHEN MATCHED THEN UPDATE SET t.StockGroupName = s.StockGroupName, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, StockGroupID, StockGroupName, LastEditedBy) VALUES (s.BranchID, s.StockGroupID, s.StockGroupName, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Warehouse.StockItemStockGroups'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Warehouse.StockItemStockGroups AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, StockItemStockGroupID INT) AS j ON t.BranchID = j.BranchID AND t.StockItemStockGroupID = j.StockItemStockGroupID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, StockItemStockGroupID INT, StockItemID INT, StockGroupID INT, LastEditedBy INT))
                MERGE Warehouse.StockItemStockGroups WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.StockItemStockGroupID = s.StockItemStockGroupID
                WHEN MATCHED THEN UPDATE SET t.StockItemID = s.StockItemID, t.StockGroupID = s.StockGroupID, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, StockItemStockGroupID, StockItemID, StockGroupID, LastEditedBy) VALUES (s.BranchID, s.StockItemStockGroupID, s.StockItemID, s.StockGroupID, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Warehouse.StockItems'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Warehouse.StockItems AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, StockItemID INT) AS j ON t.BranchID = j.BranchID AND t.StockItemID = j.StockItemID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, CustomFields, LastEditedBy, ValidFrom FROM OPENJSON(@RowData) WITH (BranchID INT, StockItemID INT, StockItemName NVARCHAR(100), SupplierID INT, ColorID INT, UnitPackageID INT, OuterPackageID INT, Brand NVARCHAR(50), Size NVARCHAR(20), LeadTimeDays INT, QuantityPerOuter INT, IsChillerStock BIT, Barcode NVARCHAR(50), TaxRate DECIMAL(18,3), UnitPrice DECIMAL(18,2), RecommendedRetailPrice DECIMAL(18,2), TypicalWeightPerUnit DECIMAL(18,3), MarketingComments NVARCHAR(MAX), InternalComments NVARCHAR(MAX), CustomFields NVARCHAR(MAX), LastEditedBy INT, ValidFrom DATETIME2(7)))
                MERGE Warehouse.StockItems WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.StockItemID = s.StockItemID
                WHEN MATCHED THEN UPDATE SET t.StockItemName = s.StockItemName, t.SupplierID = s.SupplierID, t.ColorID = s.ColorID, t.UnitPackageID = s.UnitPackageID, t.OuterPackageID = s.OuterPackageID, t.Brand = s.Brand, t.Size = s.Size, t.LeadTimeDays = s.LeadTimeDays, t.QuantityPerOuter = s.QuantityPerOuter, t.IsChillerStock = s.IsChillerStock, t.Barcode = s.Barcode, t.TaxRate = s.TaxRate, t.UnitPrice = s.UnitPrice, t.RecommendedRetailPrice = s.RecommendedRetailPrice, t.TypicalWeightPerUnit = s.TypicalWeightPerUnit, t.MarketingComments = s.MarketingComments, t.InternalComments = s.InternalComments, t.CustomFields = s.CustomFields, t.LastEditedBy = s.LastEditedBy, t.ValidFrom = s.ValidFrom
                WHEN NOT MATCHED THEN INSERT (BranchID, StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, CustomFields, LastEditedBy, ValidFrom) VALUES (s.BranchID, s.StockItemID, s.StockItemName, s.SupplierID, s.ColorID, s.UnitPackageID, s.OuterPackageID, s.Brand, s.Size, s.LeadTimeDays, s.QuantityPerOuter, s.IsChillerStock, s.Barcode, s.TaxRate, s.UnitPrice, s.RecommendedRetailPrice, s.TypicalWeightPerUnit, s.MarketingComments, s.InternalComments, s.CustomFields, s.LastEditedBy, s.ValidFrom);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Sales.Customers_Public'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Sales.Customers_Public AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, CustomerID INT) AS j ON t.BranchID = j.BranchID AND t.CustomerID = j.CustomerID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, DeliveryMethodID, DeliveryRun, RunPosition, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, CustomerID INT, CustomerName NVARCHAR(100), BillToCustomerID INT, CustomerCategoryID INT, BuyingGroupID INT, DeliveryMethodID INT, DeliveryRun NVARCHAR(5), RunPosition NVARCHAR(5), CreditLimit DECIMAL(18,2), AccountOpenedDate DATE, StandardDiscountPercentage DECIMAL(18,3), IsStatementSent BIT, IsOnCreditHold BIT, PaymentDays INT, LastEditedBy INT))
                MERGE Sales.Customers_Public WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.CustomerID = s.CustomerID
                WHEN MATCHED THEN UPDATE SET t.CustomerName = s.CustomerName, t.BillToCustomerID = s.BillToCustomerID, t.CustomerCategoryID = s.CustomerCategoryID, t.BuyingGroupID = s.BuyingGroupID, t.DeliveryMethodID = s.DeliveryMethodID, t.DeliveryRun = s.DeliveryRun, t.RunPosition = s.RunPosition, t.CreditLimit = s.CreditLimit, t.AccountOpenedDate = s.AccountOpenedDate, t.StandardDiscountPercentage = s.StandardDiscountPercentage, t.IsStatementSent = s.IsStatementSent, t.IsOnCreditHold = s.IsOnCreditHold, t.PaymentDays = s.PaymentDays, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, DeliveryMethodID, DeliveryRun, RunPosition, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, LastEditedBy) VALUES (s.BranchID, s.CustomerID, s.CustomerName, s.BillToCustomerID, s.CustomerCategoryID, s.BuyingGroupID, s.DeliveryMethodID, s.DeliveryRun, s.RunPosition, s.CreditLimit, s.AccountOpenedDate, s.StandardDiscountPercentage, s.IsStatementSent, s.IsOnCreditHold, s.PaymentDays, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'Purchasing.Suppliers_Public'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM Purchasing.Suppliers_Public AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, SupplierID INT) AS j ON t.BranchID = j.BranchID AND t.SupplierID = j.SupplierID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, SupplierID, SupplierName, SupplierCategoryID, SupplierReference, DeliveryMethodID, PaymentDays, LastEditedBy FROM OPENJSON(@RowData) WITH (BranchID INT, SupplierID INT, SupplierName NVARCHAR(100), SupplierCategoryID INT, SupplierReference NVARCHAR(20), DeliveryMethodID INT, PaymentDays INT, LastEditedBy INT))
                MERGE Purchasing.Suppliers_Public WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.SupplierID = s.SupplierID
                WHEN MATCHED THEN UPDATE SET t.SupplierName = s.SupplierName, t.SupplierCategoryID = s.SupplierCategoryID, t.SupplierReference = s.SupplierReference, t.DeliveryMethodID = s.DeliveryMethodID, t.PaymentDays = s.PaymentDays, t.LastEditedBy = s.LastEditedBy
                WHEN NOT MATCHED THEN INSERT (BranchID, SupplierID, SupplierName, SupplierCategoryID, SupplierReference, DeliveryMethodID, PaymentDays, LastEditedBy) VALUES (s.BranchID, s.SupplierID, s.SupplierName, s.SupplierCategoryID, s.SupplierReference, s.DeliveryMethodID, s.PaymentDays, s.LastEditedBy);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'dbo.Branches'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM dbo.Branches AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT) AS j ON t.BranchID = j.BranchID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                
                ;WITH s AS (SELECT BranchID, BranchName, ConnectionPort, HostServer FROM OPENJSON(@RowData) WITH (BranchID INT, BranchName VARCHAR(50), ConnectionPort INT, HostServer VARCHAR(100)))
                MERGE dbo.Branches WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID
                WHEN MATCHED THEN UPDATE SET t.BranchName = s.BranchName, t.ConnectionPort = s.ConnectionPort, t.HostServer = s.HostServer
                WHEN NOT MATCHED THEN INSERT (BranchID, BranchName, ConnectionPort, HostServer) VALUES (s.BranchID, s.BranchName, s.ConnectionPort, s.HostServer);
                
            END TRY
            BEGIN CATCH
                
                THROW;
            END CATCH
        END
        RETURN;
    END

    IF @TableName = N'dbo.Users'
    BEGIN
        IF @Op = 'D'
        BEGIN
            DELETE t FROM dbo.Users AS t
            JOIN OPENJSON(@RowData) WITH (BranchID INT, UserID INT) AS j ON t.BranchID = j.BranchID AND t.UserID = j.UserID;
        END
        ELSE
        BEGIN
            BEGIN TRY
                SET IDENTITY_INSERT dbo.Users ON;
                ;WITH s AS (SELECT BranchID, UserID, Username, CONVERT(VARBINARY(64), PasswordHash, 1) AS PasswordHash, FullName, IsActive, Role, Email, HireDate FROM OPENJSON(@RowData) WITH (BranchID INT, UserID INT, Username VARCHAR(50), PasswordHash NVARCHAR(200), FullName VARCHAR(100), IsActive BIT, Role VARCHAR(20), Email VARCHAR(100), HireDate DATE))
                MERGE dbo.Users WITH (HOLDLOCK) AS t
                USING s ON t.BranchID = s.BranchID AND t.UserID = s.UserID
                WHEN MATCHED THEN UPDATE SET t.Username = s.Username, t.PasswordHash = s.PasswordHash, t.FullName = s.FullName, t.IsActive = s.IsActive, t.Role = s.Role, t.Email = s.Email, t.HireDate = s.HireDate
                WHEN NOT MATCHED THEN INSERT (BranchID, UserID, Username, PasswordHash, FullName, IsActive, Role, Email, HireDate) VALUES (s.BranchID, s.UserID, s.Username, s.PasswordHash, s.FullName, s.IsActive, s.Role, s.Email, s.HireDate);
                SET IDENTITY_INSERT dbo.Users OFF;
            END TRY
            BEGIN CATCH
                SET IDENTITY_INSERT dbo.Users OFF;
                THROW;
            END CATCH
        END
        RETURN;
    END

    RAISERROR(N'Repl.sp_ApplyChange: tabla no soportada: %s', 16, 1, @TableName);
END;
GO

-- ------------------------------------------------------------------ leer y aplicar cambios de UN par
CREATE OR ALTER PROCEDURE Repl.sp_PullFromPeer
    @PeerBranchID           INT,
    @MaxRows                INT = 2000,
    @ConflictWindowSeconds  INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @self INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    IF @PeerBranchID = @self RETURN;

    DECLARE @link SYSNAME, @db SYSNAME, @last BIGINT, @sql NVARCHAR(MAX);
    SELECT @link = LinkedServer, @db = DbName FROM Repl.Peers WHERE PeerBranchID = @PeerBranchID;
    IF @link IS NULL
    BEGIN
        RAISERROR(N'El par %d no existe en Repl.Peers.', 16, 1, @PeerBranchID);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM Repl.PeerState WHERE PeerBranchID = @PeerBranchID)
        INSERT Repl.PeerState (PeerBranchID) VALUES (@PeerBranchID);
    SELECT @last = LastChangeID FROM Repl.PeerState WHERE PeerBranchID = @PeerBranchID;

    CREATE TABLE #stage (
        ChangeID BIGINT NOT NULL PRIMARY KEY, OriginBranchID INT NOT NULL, TableName SYSNAME NOT NULL,
        Op CHAR(1) NOT NULL, PKKey NVARCHAR(200) NOT NULL, RowData NVARCHAR(MAX) NOT NULL, ChangedAt DATETIME2(7) NOT NULL);

    SET @sql = N'INSERT #stage (ChangeID, OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt) '
             + N'SELECT TOP (' + CAST(@MaxRows AS NVARCHAR(12)) + N') ChangeID, OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt '
             + N'FROM ' + QUOTENAME(@link) + N'.' + QUOTENAME(@db) + N'.[Repl].[ChangeLog] '
             + N'WHERE ChangeID > ' + CAST(@last AS NVARCHAR(20))
             + N' AND OriginBranchID = ' + CAST(@PeerBranchID AS NVARCHAR(12))
             + N' ORDER BY ChangeID;';
    EXEC (@sql);

    DECLARE @id BIGINT, @ob INT, @t SYSNAME, @op CHAR(1), @k NVARCHAR(200), @row NVARCHAR(MAX), @at DATETIME2(7);
    DECLARE @cs DATETIME2(7), @co INT, @cc BIGINT, @win BIT, @attempts INT, @err NVARCHAR(2000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT ChangeID, OriginBranchID, TableName, Op, PKKey, RowData, ChangedAt FROM #stage ORDER BY ChangeID;
    OPEN cur;
    FETCH NEXT FROM cur INTO @id, @ob, @t, @op, @k, @row, @at;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
            EXEC sys.sp_set_session_context @key = N'repl_apply', @value = 1;

            SET @cs = NULL; SET @co = NULL; SET @cc = NULL; SET @win = 1;
            SELECT @cs = ChangedAt, @co = OriginBranchID, @cc = OriginChangeID
            FROM Repl.RowStamp WITH (UPDLOCK, HOLDLOCK)
            WHERE TableName = @t AND PKKey = @k;

            IF @cs IS NOT NULL AND (@cs > @at OR (@cs = @at AND (@co > @ob OR (@co = @ob AND @cc >= @id))))
                SET @win = 0;

            IF @cs IS NOT NULL AND @co <> @ob AND ABS(DATEDIFF(SECOND, @cs, @at)) <= @ConflictWindowSeconds
                INSERT Repl.ConflictLog (TableName, PKKey, WinnerBranchID, WinnerChangedAt, LoserBranchID, LoserChangedAt, IncomingOp, IncomingRowData, Resolution)
                VALUES (@t, @k,
                        CASE WHEN @win = 1 THEN @ob ELSE @co END, CASE WHEN @win = 1 THEN @at ELSE @cs END,
                        CASE WHEN @win = 1 THEN @co ELSE @ob END, CASE WHEN @win = 1 THEN @cs ELSE @at END,
                        @op, @row, N'LWW (ultimo escritor gana)');

            IF @win = 1
            BEGIN
                EXEC Repl.sp_ApplyChange @TableName = @t, @Op = @op, @RowData = @row;

                MERGE Repl.RowStamp WITH (HOLDLOCK) AS s
                USING (SELECT @t AS TableName, @k AS PKKey) AS x ON s.TableName = x.TableName AND s.PKKey = x.PKKey
                WHEN MATCHED THEN UPDATE SET ChangedAt = @at, OriginBranchID = @ob, OriginChangeID = @id,
                                             IsDeleted = CASE WHEN @op = 'D' THEN 1 ELSE 0 END
                WHEN NOT MATCHED THEN INSERT (TableName, PKKey, ChangedAt, OriginBranchID, OriginChangeID, IsDeleted)
                     VALUES (@t, @k, @at, @ob, @id, CASE WHEN @op = 'D' THEN 1 ELSE 0 END);
            END

            UPDATE Repl.PeerState
               SET LastChangeID = @id, LastSyncAt = SYSUTCDATETIME(), LastStatus = N'OK'
             WHERE PeerBranchID = @PeerBranchID;
            DELETE Repl.SyncErrors WHERE PeerBranchID = @PeerBranchID AND ChangeID = @id;

            COMMIT TRANSACTION;
            EXEC sys.sp_set_session_context @key = N'repl_apply', @value = 0;
        END TRY
        BEGIN CATCH
            SET @err = LEFT(ERROR_MESSAGE(), 2000);
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            EXEC sys.sp_set_session_context @key = N'repl_apply', @value = 0;

            SET @attempts = ISNULL((SELECT Attempts FROM Repl.SyncErrors WHERE PeerBranchID = @PeerBranchID AND ChangeID = @id), 0) + 1;
            MERGE Repl.SyncErrors AS e
            USING (SELECT @PeerBranchID AS PeerBranchID, @id AS ChangeID) AS x ON e.PeerBranchID = x.PeerBranchID AND e.ChangeID = x.ChangeID
            WHEN MATCHED THEN UPDATE SET Attempts = @attempts, LastError = @err, LastAt = SYSUTCDATETIME(), TableName = @t,
                                         Skipped = CASE WHEN @attempts >= 5 THEN 1 ELSE 0 END
            WHEN NOT MATCHED THEN INSERT (PeerBranchID, ChangeID, TableName, Attempts, LastError, LastAt, Skipped)
                 VALUES (@PeerBranchID, @id, @t, @attempts, @err, SYSUTCDATETIME(), CASE WHEN @attempts >= 5 THEN 1 ELSE 0 END);

            IF @attempts >= 5
            BEGIN
                UPDATE Repl.PeerState
                   SET LastChangeID = @id, LastSyncAt = SYSUTCDATETIME(),
                       LastStatus = CONCAT(N'Cambio ', @id, N' omitido tras 5 intentos: ', LEFT(@err, 300))
                 WHERE PeerBranchID = @PeerBranchID;
            END
            ELSE
            BEGIN
                UPDATE Repl.PeerState
                   SET LastSyncAt = SYSUTCDATETIME(), LastStatus = CONCAT(N'Error en cambio ', @id, N' (intento ', @attempts, N'): ', LEFT(@err, 300))
                 WHERE PeerBranchID = @PeerBranchID;
                BREAK;
            END
        END CATCH
        FETCH NEXT FROM cur INTO @id, @ob, @t, @op, @k, @row, @at;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- ------------------------------------------------------------------ sincronizar con todos los pares
CREATE OR ALTER PROCEDURE Repl.sp_SyncAllPeers
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @rc INT;
    EXEC @rc = sys.sp_getapplock @Resource = N'Repl_SyncAllPeers', @LockMode = N'Exclusive', @LockOwner = N'Session', @LockTimeout = 0;
    IF @rc < 0 RETURN;

    DECLARE @p INT, @self INT = (SELECT TOP (1) BranchID FROM Repl.NodeInfo);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT PeerBranchID FROM Repl.Peers WHERE PeerBranchID <> @self ORDER BY PeerBranchID;
    OPEN cur;
    FETCH NEXT FROM cur INTO @p;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC Repl.sp_PullFromPeer @PeerBranchID = @p;
        END TRY
        BEGIN CATCH
            IF NOT EXISTS (SELECT 1 FROM Repl.PeerState WHERE PeerBranchID = @p) INSERT Repl.PeerState (PeerBranchID) VALUES (@p);
            UPDATE Repl.PeerState SET LastSyncAt = SYSUTCDATETIME(), LastStatus = CONCAT(N'PAR NO DISPONIBLE: ', LEFT(ERROR_MESSAGE(), 400)) WHERE PeerBranchID = @p;
        END CATCH
        FETCH NEXT FROM cur INTO @p;
    END
    CLOSE cur; DEALLOCATE cur;
    EXEC sys.sp_releaseapplock @Resource = N'Repl_SyncAllPeers', @LockOwner = N'Session';
END;
GO

-- ------------------------------------------------------------------ utilidades
CREATE OR ALTER PROCEDURE Repl.sp_PublicarTodo
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t SET t.DeliveryMethodName = t.DeliveryMethodName FROM Application.DeliveryMethods AS t;
    UPDATE t SET t.CustomerCategoryName = t.CustomerCategoryName FROM Sales.CustomerCategories AS t;
    UPDATE t SET t.BuyingGroupName = t.BuyingGroupName FROM Sales.BuyingGroups AS t;
    UPDATE t SET t.SupplierCategoryName = t.SupplierCategoryName FROM Purchasing.SupplierCategories AS t;
    UPDATE t SET t.ColorName = t.ColorName FROM Warehouse.Colors AS t;
    UPDATE t SET t.PackageTypeName = t.PackageTypeName FROM Warehouse.PackageTypes AS t;
    UPDATE t SET t.StockGroupName = t.StockGroupName FROM Warehouse.StockGroups AS t;
    UPDATE t SET t.StockItemID = t.StockItemID FROM Warehouse.StockItemStockGroups AS t;
    UPDATE t SET t.StockItemName = t.StockItemName FROM Warehouse.StockItems AS t;
    UPDATE t SET t.CustomerName = t.CustomerName FROM Sales.Customers_Public AS t;
    UPDATE t SET t.SupplierName = t.SupplierName FROM Purchasing.Suppliers_Public AS t;
    UPDATE t SET t.BranchName = t.BranchName FROM dbo.Branches AS t;
    UPDATE t SET t.Username = t.Username FROM dbo.Users AS t;
END;
GO

CREATE OR ALTER PROCEDURE Repl.sp_EstadoSync
AS
BEGIN
    SET NOCOUNT ON;
    SELECT N'Nodo' AS Seccion, BranchID, NodeName FROM Repl.NodeInfo;
    SELECT s.PeerBranchID, p.LinkedServer, s.LastChangeID, s.LastSyncAt, s.LastStatus,
           (SELECT COUNT(*) FROM Repl.SyncErrors e WHERE e.PeerBranchID = s.PeerBranchID) AS ErroresPendientes
    FROM Repl.PeerState s JOIN Repl.Peers p ON p.PeerBranchID = s.PeerBranchID;
    SELECT TOP (20) * FROM Repl.ConflictLog ORDER BY ConflictID DESC;
    SELECT TOP (20) * FROM Repl.SyncErrors ORDER BY LastAt DESC;
END;
GO

CREATE OR ALTER PROCEDURE Repl.sp_PurgeChangeLog @Dias INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    DELETE Repl.ChangeLog WHERE ChangedAt < DATEADD(DAY, -@Dias, SYSUTCDATETIME());
    DELETE Repl.RowStamp WHERE IsDeleted = 1 AND ChangedAt < DATEADD(DAY, -@Dias, SYSUTCDATETIME());
END;
GO

-- ------------------------------------------------------------------ job del Agente SQL
DECLARE @job SYSNAME = N'Repl_Sync_Catalogos_' + DB_NAME();
DECLARE @dbn SYSNAME = DB_NAME();
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @job) EXEC msdb.dbo.sp_delete_job @job_name = @job;
EXEC msdb.dbo.sp_add_job @job_name = @job, @enabled = 1,
     @description = N'Sincronizacion bidireccional de catalogos con los otros nodos (Repl.sp_SyncAllPeers)';
EXEC msdb.dbo.sp_add_jobstep @job_name = @job, @step_name = N'Sync', @subsystem = N'TSQL',
     @database_name = @dbn, @command = N'EXEC Repl.sp_SyncAllPeers;';
EXEC msdb.dbo.sp_add_jobschedule @job_name = @job, @name = N'Cada 10 segundos',
     @freq_type = 4, @freq_interval = 1, @freq_subday_type = 2, @freq_subday_interval = 10;
EXEC msdb.dbo.sp_add_jobserver @job_name = @job, @server_name = N'(local)';
PRINT CONCAT(N'Job creado: ', @job, N'. Sincronizacion manual: EXEC Repl.sp_SyncAllPeers;');
GO
SET NOEXEC OFF;
GO
