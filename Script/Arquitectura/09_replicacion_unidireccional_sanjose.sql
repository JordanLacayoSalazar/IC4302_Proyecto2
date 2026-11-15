-- ==========================================================================
-- 09_replicacion_unidireccional_SJ_corregido.sql
-- Replicacion transaccional unidireccional: San Jose -> Corporativo
-- ==========================================================================

IF OBJECT_ID('tempdb..#cfg') IS NOT NULL DROP TABLE #cfg;
CREATE TABLE #cfg
(
    SAPwd  NVARCHAR(128) NOT NULL,
    DMKPwd NVARCHAR(128) NOT NULL
);
INSERT INTO #cfg (SAPwd, DMKPwd)
VALUES (N'<SA_PASSWORD>', N'<DMK_PASSWORD>'); -- <-- ingresar una passwrod para ambos campos

IF (SELECT SAPwd FROM #cfg) = N'<SA_PASSWORD>'
   OR (SELECT DMKPwd FROM #cfg) = N'<DMK_PASSWORD>'
BEGIN
    RAISERROR(N'Reemplaza SA_PASSWORD y DMK_PASSWORD en #cfg antes de ejecutar.', 16, 1);
    SET NOEXEC ON;
END;

IF @@SERVERNAME <> N'nodo_sucursal_sj'
BEGIN
    RAISERROR(N'Este script debe ejecutarse en nodo_sucursal_sj. @@SERVERNAME actual: %s.', 16, 1, @@SERVERNAME);
    SET NOEXEC ON;
END;

IF DB_ID(N'WWI_SanJose') IS NULL
BEGIN
    RAISERROR(N'No existe WWI_SanJose en este servidor.', 16, 1);
    SET NOEXEC ON;
END;
GO

USE master;
GO
DECLARE @pwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);
DECLARE @ok BIT = 1, @msg NVARCHAR(500) = N'';

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'tmp_pwdtest_self') EXEC sp_dropserver N'tmp_pwdtest_self', 'droplogins';
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'tmp_pwdtest_corp') EXEC sp_dropserver N'tmp_pwdtest_corp', 'droplogins';

EXEC sp_addlinkedserver @server = N'tmp_pwdtest_self', @srvproduct = N'', @provider = N'MSOLEDBSQL',
     @datasrc = @@SERVERNAME, @provstr = N'Encrypt=Optional;TrustServerCertificate=Yes';
EXEC sp_addlinkedsrvlogin @rmtsrvname = N'tmp_pwdtest_self', @useself = 'false', @locallogin = NULL, @rmtuser = N'sa', @rmtpassword = @pwd;
EXEC sp_addlinkedserver @server = N'tmp_pwdtest_corp', @srvproduct = N'', @provider = N'MSOLEDBSQL',
     @datasrc = N'nodo_corporativo', @provstr = N'Encrypt=Optional;TrustServerCertificate=Yes';
EXEC sp_addlinkedsrvlogin @rmtsrvname = N'tmp_pwdtest_corp', @useself = 'false', @locallogin = NULL, @rmtuser = N'sa', @rmtpassword = @pwd;

BEGIN TRY
    EXEC sp_testlinkedserver N'tmp_pwdtest_self';
END TRY
BEGIN CATCH
    SET @ok = 0; SET @msg += N' [login sa en ESTE nodo: ' + LEFT(ERROR_MESSAGE(), 150) + N']';
END CATCH;
BEGIN TRY
    EXEC sp_testlinkedserver N'tmp_pwdtest_corp';
END TRY
BEGIN CATCH
    SET @ok = 0; SET @msg += N' [login sa en nodo_corporativo: ' + LEFT(ERROR_MESSAGE(), 150) + N']';
END CATCH;

EXEC sp_dropserver N'tmp_pwdtest_self', 'droplogins';
EXEC sp_dropserver N'tmp_pwdtest_corp', 'droplogins';

IF @ok = 0
BEGIN
    RAISERROR(N'PRE-VUELO FALLIDO: la contrasena de SA en #cfg no funciona o el nodo no es alcanzable.%s', 16, 1, @msg);
    SET NOEXEC ON;
END
ELSE PRINT N'Pre-vuelo OK: la contrasena de SA funciona en este nodo y en nodo_corporativo.';
GO


USE master;
GO
DECLARE @SAPwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE is_distributor = 1)
BEGIN
    EXEC sys.sp_adddistributor @distributor = @@SERVERNAME;
END;

IF DB_ID(N'distribution') IS NULL
BEGIN
    EXEC sys.sp_adddistributiondb
        @database = N'distribution',
        @log_file_size = 2,
        @min_distretention = 0,
        @max_distretention = 168,
        @history_retention = 48,
        @deletebatchsize_xact = 5000,
        @deletebatchsize_cmd = 2000,
        @security_mode = 0,
        @login = N'sa',
        @password = @SAPwd;
END;
GO


USE distribution;
GO
DECLARE @DMKPwd NVARCHAR(128) = (SELECT DMKPwd FROM #cfg);

IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = N'##MS_DatabaseMasterKey##'
)
BEGIN
    DECLARE @CreateDmkSql NVARCHAR(MAX) =
        N'CREATE MASTER KEY ENCRYPTION BY PASSWORD = ' + QUOTENAME(@DMKPwd, N'''') + N';';
    EXEC (@CreateDmkSql);
    ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;
END;
ELSE IF EXISTS
(
    SELECT 1
    FROM sys.databases
    WHERE database_id = DB_ID()
      AND is_master_key_encrypted_by_server = 0
)
BEGIN
    RAISERROR(N'La DMK ya existe pero no esta protegida por la Service Master Key. Revisar y abrir la DMK con su contrasena antes de continuar.', 16, 1);
    SET NOEXEC ON;
END;

IF OBJECT_ID(N'dbo.UIProperties', N'U') IS NULL
    CREATE TABLE dbo.UIProperties (id INT NULL);

IF EXISTS
(
    SELECT 1
    FROM sys.extended_properties
    WHERE name = N'SnapshotFolder'
      AND major_id = OBJECT_ID(N'dbo.UIProperties')
      AND minor_id = 0
)
BEGIN
    EXEC sys.sp_updateextendedproperty
        @name = N'SnapshotFolder',
        @value = N'/var/opt/mssql/ReplData/',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE',  @level1name = N'UIProperties';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
        @name = N'SnapshotFolder',
        @value = N'/var/opt/mssql/ReplData/',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE',  @level1name = N'UIProperties';
END;
GO


USE master;
GO
DECLARE @SAPwd2 NVARCHAR(128) = (SELECT SAPwd FROM #cfg);

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.MSdistpublishers
    WHERE name = @@SERVERNAME
)
BEGIN
    EXEC sys.sp_adddistpublisher
        @publisher = @@SERVERNAME,
        @distribution_db = N'distribution',
        @security_mode = 0,
        @login = N'sa',
        @password = @SAPwd2,
        @working_directory = N'/var/opt/mssql/ReplData',
        @trusted = N'false',
        @thirdparty_flag = 0,
        @publisher_type = N'MSSQLSERVER';
END;
GO


USE [WWI_SanJose];
GO
DECLARE @SAPwd3 NVARCHAR(128) = (SELECT SAPwd FROM #cfg);

EXEC sys.sp_replicationdboption
    @dbname = N'WWI_SanJose',
    @optname = N'publish',
    @value = N'true';

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id
    WHERE c.name = N'REPL-LogReader'
      AND j.name LIKE N'%WWI_SanJose%'
)
BEGIN
    EXEC sys.sp_addlogreader_agent
        @publisher_security_mode = 0,
        @publisher_login = N'sa',
        @publisher_password = @SAPwd3;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.syspublications
    WHERE name = N'PUB_SJ_Transaccional'
)
BEGIN
    EXEC sys.sp_addpublication
        @publication = N'PUB_SJ_Transaccional',
        @description = N'Transaccional San Jose -> Corporativo',
        @sync_method = N'concurrent',
        @retention = 0,
        @allow_push = N'true',
        @allow_pull = N'false',
        @allow_anonymous = N'false',
        @enabled_for_internet = N'false',
        @snapshot_in_defaultfolder = N'true',
        @repl_freq = N'continuous',
        @status = N'active',
        @independent_agent = N'true',
        @immediate_sync = N'true',
        @allow_sync_tran = N'false',
        @allow_queued_tran = N'false',
        @allow_dts = N'false',
        @replicate_ddl = 0,
        @allow_initialize_from_backup = N'false',
        @enabled_for_p2p = N'false',
        @enabled_for_het_sub = N'false';
END;

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id
    WHERE c.name = N'REPL-Snapshot'
      AND j.name LIKE N'%PUB_SJ_Transaccional%'
)
BEGIN
    EXEC sys.sp_addpublication_snapshot
        @publication = N'PUB_SJ_Transaccional',
        @frequency_type = 1,
        @frequency_interval = 1,
        @frequency_relative_interval = 1,
        @frequency_recurrence_factor = 0,
        @frequency_subday = 8,
        @frequency_subday_interval = 1,
        @active_start_time_of_day = 0,
        @active_end_time_of_day = 235959,
        @active_start_date = 0,
        @active_end_date = 0,
        @publisher_security_mode = 0,
        @publisher_login = N'sa',
        @publisher_password = @SAPwd3;
END;
GO


USE [WWI_SanJose];
GO
DECLARE @Pub SYSNAME = N'PUB_SJ_Transaccional';
DECLARE @PubId INT = (SELECT pubid FROM dbo.syspublications WHERE name = @Pub);

IF @PubId IS NULL
BEGIN
    RAISERROR(N'No existe PUB_SJ_Transaccional; no se pueden agregar articulos.', 16, 1);
    SET NOEXEC ON;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'Invoices')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'Invoices', @source_owner=N'Sales', @source_object=N'Invoices', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'Invoices', @destination_owner=N'Sales', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'InvoiceLines')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'InvoiceLines', @source_owner=N'Sales', @source_object=N'InvoiceLines', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'InvoiceLines', @destination_owner=N'Sales', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'Orders')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'Orders', @source_owner=N'Sales', @source_object=N'Orders', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'Orders', @destination_owner=N'Sales', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'OrderLines')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'OrderLines', @source_owner=N'Sales', @source_object=N'OrderLines', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'OrderLines', @destination_owner=N'Sales', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'CustomerTransactions')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'CustomerTransactions', @source_owner=N'Sales', @source_object=N'CustomerTransactions', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'CustomerTransactions', @destination_owner=N'Sales', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'PurchaseOrders')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'PurchaseOrders', @source_owner=N'Purchasing', @source_object=N'PurchaseOrders', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'PurchaseOrders', @destination_owner=N'Purchasing', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'PurchaseOrderLines')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'PurchaseOrderLines', @source_owner=N'Purchasing', @source_object=N'PurchaseOrderLines', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'PurchaseOrderLines', @destination_owner=N'Purchasing', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'SupplierTransactions')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'SupplierTransactions', @source_owner=N'Purchasing', @source_object=N'SupplierTransactions', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'SupplierTransactions', @destination_owner=N'Purchasing', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'StockItemTransactions')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'StockItemTransactions', @source_owner=N'Warehouse', @source_object=N'StockItemTransactions', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'StockItemTransactions', @destination_owner=N'Warehouse', @vertical_partition=N'false';

IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles WHERE pubid = @PubId AND name = N'StockItemHoldings')
    EXEC sys.sp_addarticle @publication=@Pub, @article=N'StockItemHoldings', @source_owner=N'Warehouse', @source_object=N'StockItemHoldings', @type=N'logbased', @creation_script=NULL, @pre_creation_cmd=N'none', @schema_option=0x0000000000000002, @identityrangemanagementoption=N'none', @destination_table=N'StockItemHoldings', @destination_owner=N'Warehouse', @vertical_partition=N'false';
GO


USE [WWI_SanJose];
GO
DECLARE @SAPwd4 NVARCHAR(128) = (SELECT SAPwd FROM #cfg);
DECLARE @SubscriptionExists BIT = 0;

IF EXISTS
(
    SELECT 1
    FROM dbo.syssubscriptions
    WHERE srvname = N'nodo_corporativo'
      AND dest_db = N'WWI_Corporativo'
      AND subscription_type = 0
)
    SET @SubscriptionExists = 1;

IF @SubscriptionExists = 0
BEGIN
    EXEC sys.sp_addsubscription
        @publication = N'PUB_SJ_Transaccional',
        @subscriber = N'nodo_corporativo',
        @destination_db = N'WWI_Corporativo',
        @subscription_type = N'Push',
        @sync_type = N'automatic',
        @article = N'all',
        @update_mode = N'read only',
        @subscriber_type = 0;
END
ELSE
BEGIN
    PRINT N'La suscripcion push ya existe; no se vuelve a crear.';
END;

IF @SubscriptionExists = 0
   OR NOT EXISTS
   (
       SELECT 1
       FROM msdb.dbo.sysjobs j
       INNER JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id
       WHERE c.name = N'REPL-Distribution'
         AND j.name LIKE N'%PUB_SJ_Transaccional%'
         AND j.name LIKE N'%nodo_corporativo%'
   )
BEGIN
    EXEC sys.sp_addpushsubscription_agent
        @publication = N'PUB_SJ_Transaccional',
        @subscriber = N'nodo_corporativo',
        @subscriber_db = N'WWI_Corporativo',
        @subscriber_security_mode = 0,
        @subscriber_login = N'sa',
        @subscriber_password = @SAPwd4,
        @frequency_type = 64,
        @frequency_interval = 1,
        @frequency_relative_interval = 1,
        @frequency_recurrence_factor = 0,
        @frequency_subday = 4,
        @frequency_subday_interval = 5,
        @active_start_time_of_day = 0,
        @active_end_time_of_day = 235959,
        @active_start_date = 0,
        @active_end_date = 0;
END
ELSE
BEGIN
    PRINT N'El trabajo del Distribution Agent ya existe; no se duplica.';
END;
GO


USE [WWI_SanJose];
GO
DECLARE @SnapshotJobId UNIQUEIDENTIFIER;
DECLARE @CurrentAgentSession INT = (SELECT MAX(session_id) FROM msdb.dbo.syssessions);

SELECT TOP (1) @SnapshotJobId = j.job_id
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id
WHERE c.name = N'REPL-Snapshot'
  AND j.name LIKE N'%PUB_SJ_Transaccional%'
ORDER BY j.date_created DESC;

IF @SnapshotJobId IS NULL
BEGIN
    PRINT N'No se encontro el trabajo Snapshot. Revisa la creacion del agente.';
END
ELSE IF EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobactivity a
    WHERE a.session_id = @CurrentAgentSession
      AND a.job_id = @SnapshotJobId
      AND a.start_execution_date IS NOT NULL
      AND a.stop_execution_date IS NULL
)
BEGIN
    PRINT N'El Snapshot Agent ya esta ejecutandose; no se envia otra solicitud.';
END
ELSE IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobhistory h
    WHERE h.job_id = @SnapshotJobId
      AND h.step_id = 0
      AND h.run_status = 1
)
BEGIN
    EXEC sys.sp_startpublication_snapshot
        @publication = N'PUB_SJ_Transaccional';
END
ELSE
BEGIN
    PRINT N'Ya existe una ejecucion exitosa del Snapshot; no se vuelve a iniciar.';
END;

SET NOEXEC OFF;
GO