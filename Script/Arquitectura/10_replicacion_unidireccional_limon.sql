-- =========================================================================
-- 10_replicacion_unidireccional_limon.sql
-- Ejecutar en nodo_sucursal_limon conectado a WWI_Limon
-- =========================================================================
SET NOEXEC OFF;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('tempdb..#cfg') IS NOT NULL DROP TABLE #cfg;
CREATE TABLE #cfg (SAPwd NVARCHAR(128) NOT NULL);
INSERT #cfg VALUES (N'<<SA_PASSWORD>>');          -- <-- misma contrasena SA de los 3 nodos

IF (SELECT SAPwd FROM #cfg) = N'<<SA_PASSWORD>>'
BEGIN
    RAISERROR(N'Edita la contrasena de SA en #cfg antes de ejecutar.', 16, 1);
    SET NOEXEC ON;
END
ELSE IF @@SERVERNAME <> N'nodo_sucursal_limon' OR DB_NAME() <> N'WWI_Limon'
BEGIN
    RAISERROR(N'Ejecuta este script en nodo_sucursal_limon, conectado a WWI_Limon.', 16, 1);
    SET NOEXEC ON;
END
ELSE IF OBJECT_ID(N'Repl.sp_ParcharAgentes') IS NULL OR NOT EXISTS (SELECT 1 FROM sys.servers WHERE is_distributor = 1)
BEGIN
    RAISERROR(N'Falta el distribuidor local: corre primero 08_replicacion_bidireccional.sql en este nodo.', 16, 1);
    SET NOEXEC ON;
END
GO

-- Publicacion, articulos y suscripcion hacia Corporativo
DECLARE @pwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);
DECLARE @pub SYSNAME = N'PUB_LIMON_Transaccional';

IF NOT EXISTS (SELECT 1 FROM dbo.syspublications WHERE name = @pub)
BEGIN
    EXEC sys.sp_addpublication @publication = @pub, @description = N'Limon -> Corporativo (transaccional)',
         @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'false',
         @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true',
         @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true',
         @allow_sync_tran = N'false', @allow_queued_tran = N'false', @replicate_ddl = 0, @enabled_for_p2p = N'false';

    EXEC sys.sp_addpublication_snapshot @publication = @pub, @frequency_type = 1,
         @publisher_security_mode = 0, @publisher_login = N'sa', @publisher_password = @pwd;
END;


DECLARE @art TABLE (sch SYSNAME, tbl SYSNAME);
INSERT @art VALUES
    (N'Sales', N'Invoices'), (N'Sales', N'InvoiceLines'), (N'Sales', N'Orders'), (N'Sales', N'OrderLines'),
    (N'Sales', N'CustomerTransactions'), (N'Purchasing', N'PurchaseOrders'), (N'Purchasing', N'PurchaseOrderLines'),
    (N'Purchasing', N'SupplierTransactions'), (N'Warehouse', N'StockItemTransactions'), (N'Warehouse', N'StockItemHoldings');

DECLARE @sch SYSNAME, @tbl SYSNAME;
DECLARE ca CURSOR LOCAL FAST_FORWARD FOR SELECT sch, tbl FROM @art;
OPEN ca;
FETCH NEXT FROM ca INTO @sch, @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles a JOIN dbo.syspublications p ON p.pubid = a.pubid
                   WHERE p.name = @pub AND a.name = @tbl)
        EXEC sys.sp_addarticle @publication = @pub, @article = @tbl, @source_owner = @sch, @source_object = @tbl,
             @type = N'logbased', @pre_creation_cmd = N'none', @schema_option = 0x0000000000000002,
             @destination_table = @tbl, @destination_owner = @sch, @identityrangemanagementoption = N'none';
    FETCH NEXT FROM ca INTO @sch, @tbl;
END
CLOSE ca; DEALLOCATE ca;

IF NOT EXISTS (SELECT 1 FROM dbo.syssubscriptions s
               JOIN dbo.sysarticles a ON a.artid = s.artid
               JOIN dbo.syspublications p ON p.pubid = a.pubid
               WHERE p.name = @pub AND s.srvname = N'nodo_corporativo' AND s.dest_db = N'WWI_Corporativo')
BEGIN
    EXEC sys.sp_addsubscription @publication = @pub, @subscriber = N'nodo_corporativo',
         @destination_db = N'WWI_Corporativo', @subscription_type = N'Push', @sync_type = N'automatic',
         @article = N'all', @update_mode = N'read only', @subscriber_type = 0;

    EXEC sys.sp_addpushsubscription_agent @publication = @pub, @subscriber = N'nodo_corporativo',
         @subscriber_db = N'WWI_Corporativo', @subscriber_security_mode = 0,
         @subscriber_login = N'sa', @subscriber_password = @pwd,
         @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1,
         @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5,
         @active_start_time_of_day = 0, @active_end_time_of_day = 235959,
         @active_start_date = 0, @active_end_date = 0;
END;
GO


EXEC Repl.sp_ParcharAgentes;
BEGIN TRY
    EXEC sys.sp_startpublication_snapshot @publication = N'PUB_LIMON_Transaccional';
    PRINT N'Snapshot iniciado. En 1-2 minutos Corporativo tendra los datos.';
END TRY
BEGIN CATCH
    PRINT N'Snapshot no iniciado (ya corre o ya se genero): ' + ERROR_MESSAGE();
END CATCH
SET NOEXEC OFF;
GO