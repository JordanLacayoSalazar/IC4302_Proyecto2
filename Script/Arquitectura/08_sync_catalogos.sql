-- =========================================================================
-- 08_replicacion_bidireccional.sql
-- Catalogos bidireccionales con replicacion transaccional
--        San Jose  <---->  Corporativo  <---->  Limon
--
-- EJECUTAR UNA VEZ EN CADA NODO, conectado a su base:
--   nodo_corporativo     -> WWI_Corporativo
--   nodo_sucursal_sj     -> WWI_SanJose
--   nodo_sucursal_limon  -> WWI_Limon
-- =========================================================================
SET NOEXEC OFF;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID('tempdb..#cfg') IS NOT NULL DROP TABLE #cfg;
CREATE TABLE #cfg (SAPwd NVARCHAR(128) NOT NULL);
INSERT #cfg VALUES (N'<<SA_PASSWORD>>');          -- <-- misma contrasena SA de los 3 nodos

DECLARE @dbn SYSNAME = DB_NAME();
IF (SELECT SAPwd FROM #cfg) = N'<<SA_PASSWORD>>'
BEGIN
    RAISERROR(N'Edita la contrasena de SA en #cfg antes de ejecutar.', 16, 1);
    SET NOEXEC ON;
END
ELSE IF @@SERVERNAME NOT IN (N'nodo_corporativo', N'nodo_sucursal_sj', N'nodo_sucursal_limon')
BEGIN
    RAISERROR(N'@@SERVERNAME (%s) no es uno de los 3 nodos.', 16, 1, @@SERVERNAME);
    SET NOEXEC ON;
END
ELSE IF DB_NAME() <> CASE @@SERVERNAME WHEN N'nodo_corporativo' THEN N'WWI_Corporativo'
                                       WHEN N'nodo_sucursal_sj'  THEN N'WWI_SanJose'
                                       ELSE N'WWI_Limon' END
BEGIN
    RAISERROR(N'Conectate a la base WWI de ESTE nodo (base actual: %s).', 16, 1, @dbn);
    SET NOEXEC ON;
END
GO


DECLARE @b INT = CASE DB_NAME() WHEN N'WWI_Corporativo' THEN 1 WHEN N'WWI_SanJose' THEN 2 ELSE 3 END;
DECLARE @seq TABLE (n SYSNAME);
INSERT @seq VALUES (N'DeliveryMethods'), (N'CustomerCategories'), (N'BuyingGroups'), (N'SupplierCategories'),
                   (N'Colors'), (N'PackageTypes'), (N'StockGroups'), (N'StockItemStockGroups'),
                   (N'StockItems'), (N'Customers_Public'), (N'Suppliers_Public');
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'CREATE SEQUENCE Repl.seq_' + n + N' AS INT START WITH ' + CAST(@b * 1000000 AS NVARCHAR(12)) + N' INCREMENT BY 1;'
FROM @seq WHERE OBJECT_ID(N'Repl.seq_' + n) IS NULL;
EXEC (@sql);
GO


IF OBJECT_ID(N'dbo.Users') IS NOT NULL
   AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.Users') AND is_not_for_replication = 0)
BEGIN
    SELECT * INTO #users_bak FROM dbo.Users;
    DROP TABLE dbo.Users;
    CREATE TABLE dbo.Users (
        UserID INT IDENTITY(1,1) NOT FOR REPLICATION,
        BranchID INT NOT NULL,
        Username VARCHAR(50) NOT NULL UNIQUE,
        PasswordHash VARBINARY(64) NOT NULL,
        FullName VARCHAR(100) NOT NULL,
        IsActive BIT DEFAULT 1,
        Role VARCHAR(20) NOT NULL CHECK (Role IN ('Administrador', 'Corporativo')),
        Email VARCHAR(100),
        HireDate DATE,
        CONSTRAINT PK_Users PRIMARY KEY (BranchID, UserID),
        CONSTRAINT FK_Users_Branches FOREIGN KEY (BranchID) REFERENCES dbo.Branches(BranchID)
    );
    SET IDENTITY_INSERT dbo.Users ON;
    INSERT dbo.Users (UserID, BranchID, Username, PasswordHash, FullName, IsActive, Role, Email, HireDate)
    SELECT UserID, BranchID, Username, PasswordHash, FullName, IsActive, Role, Email, HireDate FROM #users_bak;
    SET IDENTITY_INSERT dbo.Users OFF;
    PRINT N'dbo.Users recreada con IDENTITY NOT FOR REPLICATION.';
END
GO


CREATE OR ALTER PROCEDURE Repl.sp_ParcharAgentes
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @job UNIQUEIDENTIFIER, @step INT, @cmd NVARCHAR(MAX), @newcmd NVARCHAR(MAX), @cat SYSNAME, @i INT;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT j.job_id, s.step_id, s.command, cat.name
        FROM msdb.dbo.sysjobs j
        JOIN msdb.dbo.syscategories cat ON cat.category_id = j.category_id
        JOIN msdb.dbo.sysjobsteps s ON s.job_id = j.job_id
        WHERE cat.name IN (N'REPL-LogReader', N'REPL-Distribution', N'REPL-Snapshot')
          AND s.subsystem IN (N'LogReader', N'Distribution', N'Snapshot');
    OPEN c;
    FETCH NEXT FROM c INTO @job, @step, @cmd, @cat;
    WHILE @@FETCH_STATUS = 0
    BEGIN
    
        IF @cmd NOT LIKE N'%-EncryptionLevel%'
        BEGIN
            SET @newcmd = @cmd + N' -EncryptionLevel 1';
            EXEC msdb.dbo.sp_update_jobstep @job_id = @job, @step_id = @step, @command = @newcmd;
            IF @cat <> N'REPL-Snapshot'
            BEGIN
                BEGIN TRY EXEC msdb.dbo.sp_stop_job @job_id = @job; END TRY
                BEGIN CATCH SET @i = 0; END CATCH
            END
        END

        IF @cat <> N'REPL-Snapshot'
        BEGIN
            SET @i = 0;
            WHILE @i < 20 AND EXISTS (SELECT 1 FROM msdb.dbo.sysjobactivity a
                                      WHERE a.job_id = @job AND a.start_execution_date IS NOT NULL
                                        AND a.stop_execution_date IS NULL
                                        AND a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions))
                  AND @cmd NOT LIKE N'%-EncryptionLevel%'
            BEGIN
                WAITFOR DELAY '00:00:02';
                SET @i += 1;
            END
            IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobactivity a
                           WHERE a.job_id = @job AND a.start_execution_date IS NOT NULL
                             AND a.stop_execution_date IS NULL
                             AND a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions))
            BEGIN
                BEGIN TRY EXEC msdb.dbo.sp_start_job @job_id = @job; END TRY
                BEGIN CATCH SET @i = 0; END CATCH
            END
        END
        FETCH NEXT FROM c INTO @job, @step, @cmd, @cat;
    END
    CLOSE c; DEALLOCATE c;
END;
GO


DECLARE @pwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE is_distributor = 1)
    EXEC (N'USE master; EXEC sys.sp_adddistributor @distributor = @@SERVERNAME;');

IF DB_ID(N'distribution') IS NULL
    EXEC sp_executesql
        N'USE master;
          EXEC sys.sp_adddistributiondb @database = N''distribution'', @log_file_size = 2,
               @min_distretention = 0, @max_distretention = 168, @history_retention = 48,
               @security_mode = 0, @login = N''sa'', @password = @p;',
        N'@p NVARCHAR(128)', @p = @pwd;
GO

DECLARE @pwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);

IF NOT EXISTS (SELECT 1 FROM distribution.sys.symmetric_keys WHERE name = N'##MS_DatabaseMasterKey##')
BEGIN
    BEGIN TRY
        DECLARE @k NVARCHAR(MAX) = N'USE distribution; CREATE MASTER KEY ENCRYPTION BY PASSWORD = ' + QUOTENAME(@pwd, N'''') + N';';
        EXEC (@k);
    END TRY
    BEGIN CATCH
        PRINT N'Aviso (master key de distribution): ' + ERROR_MESSAGE();
    END CATCH
END;

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.MSdistpublishers WHERE name = @@SERVERNAME)
    EXEC sp_executesql
        N'USE master;
          EXEC sys.sp_adddistpublisher @publisher = @@SERVERNAME, @distribution_db = N''distribution'',
               @security_mode = 0, @login = N''sa'', @password = @p,
               @working_directory = N''/var/opt/mssql/ReplData'', @trusted = N''false'',
               @thirdparty_flag = 0, @publisher_type = N''MSSQLSERVER'';',
        N'@p NVARCHAR(128)', @p = @pwd;
GO


DECLARE @pwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);
DECLARE @db SYSNAME = DB_NAME();

EXEC sys.sp_replicationdboption @dbname = @db, @optname = N'publish', @value = N'true';

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs j
               JOIN msdb.dbo.syscategories c ON c.category_id = j.category_id
               WHERE c.name = N'REPL-LogReader' AND j.name LIKE N'%' + @db + N'%')
    EXEC sys.sp_addlogreader_agent @publisher_security_mode = 0, @publisher_login = N'sa', @publisher_password = @pwd;
GO


DECLARE @pwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);
DECLARE @pub SYSNAME = CASE @@SERVERNAME WHEN N'nodo_corporativo' THEN N'PUB_CAT_CORP'
                                         WHEN N'nodo_sucursal_sj' THEN N'PUB_CAT_SJ' ELSE N'PUB_CAT_LIMON' END;
DECLARE @desc NVARCHAR(255) = N'Catalogos bidireccionales v2 (columnas filtradas)';

IF EXISTS (SELECT 1 FROM dbo.syspublications WHERE name = @pub AND description <> @desc)
BEGIN
    BEGIN TRY EXEC sys.sp_dropsubscription @publication = @pub, @article = N'all', @subscriber = N'all'; END TRY
    BEGIN CATCH PRINT N'dropsubscription: ' + ERROR_MESSAGE(); END CATCH
    BEGIN TRY EXEC sys.sp_droparticle @publication = @pub, @article = N'all', @force_invalidate_snapshot = 1; END TRY
    BEGIN CATCH PRINT N'droparticle: ' + ERROR_MESSAGE(); END CATCH
    EXEC sys.sp_droppublication @publication = @pub;
    PRINT CONCAT(N'Version anterior de ', @pub, N' eliminada; se recrea.');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.syspublications WHERE name = @pub)
BEGIN
    EXEC sys.sp_addpublication @publication = @pub, @description = @desc,
         @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'false',
         @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true',
         @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false',
         @allow_sync_tran = N'false', @allow_queued_tran = N'false', @replicate_ddl = 0, @enabled_for_p2p = N'false';

    EXEC sys.sp_addpublication_snapshot @publication = @pub, @frequency_type = 1,
         @publisher_security_mode = 0, @publisher_login = N'sa', @publisher_password = @pwd;
END;

DECLARE @art TABLE (sch SYSNAME, tbl SYSNAME);
INSERT @art VALUES
    (N'Application', N'DeliveryMethods'),   (N'Sales', N'CustomerCategories'), (N'Sales', N'BuyingGroups'),
    (N'Purchasing',  N'SupplierCategories'),(N'Warehouse', N'Colors'),        (N'Warehouse', N'PackageTypes'),
    (N'Warehouse',   N'StockGroups'),       (N'Warehouse', N'StockItemStockGroups'), (N'Warehouse', N'StockItems'),
    (N'Sales',       N'Customers_Public'),  (N'Purchasing', N'Suppliers_Public'),    (N'dbo', N'Users');

DECLARE @sch SYSNAME, @tbl SYSNAME, @objid INT, @artid INT, @col SYSNAME, @colid INT, @want BIT, @has BIT;
DECLARE ca CURSOR LOCAL FAST_FORWARD FOR SELECT sch, tbl FROM @art;
OPEN ca;
FETCH NEXT FROM ca INTO @sch, @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.sysarticles a JOIN dbo.syspublications p ON p.pubid = a.pubid
                   WHERE p.name = @pub AND a.name = @tbl)
        EXEC sys.sp_addarticle @publication = @pub, @article = @tbl, @source_owner = @sch, @source_object = @tbl,
             @type = N'logbased', @pre_creation_cmd = N'none', @schema_option = 0x0000000000000000,
             @destination_table = @tbl, @destination_owner = @sch,
             @ins_cmd = N'SQL', @del_cmd = N'SQL', @upd_cmd = N'SQL', @status = 24,
             @vertical_partition = N'true', @identityrangemanagementoption = N'none';

    SET @objid = OBJECT_ID(QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl));
    SELECT @artid = a.artid FROM dbo.sysarticles a JOIN dbo.syspublications p ON p.pubid = a.pubid
    WHERE p.name = @pub AND a.name = @tbl;

    DECLARE cc CURSOR LOCAL FAST_FORWARD FOR
        SELECT name, column_id,
               CASE WHEN is_computed = 0 AND system_type_id <> 189 THEN 1 ELSE 0 END
        FROM sys.columns WHERE object_id = @objid ORDER BY column_id;
    OPEN cc;
    FETCH NEXT FROM cc INTO @col, @colid, @want;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @has = CASE WHEN EXISTS (SELECT 1 FROM dbo.sysarticlecolumns WHERE artid = @artid AND colid = @colid) THEN 1 ELSE 0 END;
        IF @want = 1 AND @has = 0
            EXEC sys.sp_articlecolumn @publication = @pub, @article = @tbl, @column = @col, @operation = N'add',
                 @refresh_synctran_procs = 0, @force_invalidate_snapshot = 1, @force_reinit_subscription = 0;
        ELSE IF @want = 0 AND @has = 1
            EXEC sys.sp_articlecolumn @publication = @pub, @article = @tbl, @column = @col, @operation = N'drop',
                 @refresh_synctran_procs = 0, @force_invalidate_snapshot = 1, @force_reinit_subscription = 0;
        FETCH NEXT FROM cc INTO @col, @colid, @want;
    END
    CLOSE cc; DEALLOCATE cc;

    FETCH NEXT FROM ca INTO @sch, @tbl;
END
CLOSE ca; DEALLOCATE ca;
GO


DECLARE @pwd NVARCHAR(128) = (SELECT SAPwd FROM #cfg);
DECLARE @pub SYSNAME = CASE @@SERVERNAME WHEN N'nodo_corporativo' THEN N'PUB_CAT_CORP'
                                         WHEN N'nodo_sucursal_sj' THEN N'PUB_CAT_SJ' ELSE N'PUB_CAT_LIMON' END;

DECLARE @tgt TABLE (srv SYSNAME, db SYSNAME);
IF @@SERVERNAME = N'nodo_corporativo'
    INSERT @tgt VALUES (N'nodo_sucursal_sj', N'WWI_SanJose'), (N'nodo_sucursal_limon', N'WWI_Limon');
ELSE
    INSERT @tgt VALUES (N'nodo_corporativo', N'WWI_Corporativo');

DECLARE @srv SYSNAME, @dst SYSNAME;
DECLARE cs CURSOR LOCAL FAST_FORWARD FOR SELECT srv, db FROM @tgt;
OPEN cs;
FETCH NEXT FROM cs INTO @srv, @dst;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.syssubscriptions s
                   JOIN dbo.sysarticles a ON a.artid = s.artid
                   JOIN dbo.syspublications p ON p.pubid = a.pubid
                   WHERE p.name = @pub AND s.srvname = @srv AND s.dest_db = @dst)
    BEGIN
        EXEC sys.sp_addsubscription @publication = @pub, @subscriber = @srv, @destination_db = @dst,
             @subscription_type = N'Push', @sync_type = N'replication support only', @article = N'all',
             @update_mode = N'read only', @subscriber_type = 0, @loopback_detection = N'true';

        EXEC sys.sp_addpushsubscription_agent @publication = @pub, @subscriber = @srv, @subscriber_db = @dst,
             @subscriber_security_mode = 0, @subscriber_login = N'sa', @subscriber_password = @pwd,
             @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1,
             @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5,
             @active_start_time_of_day = 0, @active_end_time_of_day = 235959,
             @active_start_date = 0, @active_end_date = 0;
        PRINT CONCAT(N'Suscripcion creada: ', @pub, N' -> ', @srv, N'.', @dst);
    END
    ELSE PRINT CONCAT(N'Ya existia: ', @pub, N' -> ', @srv, N'.', @dst);
    FETCH NEXT FROM cs INTO @srv, @dst;
END
CLOSE cs; DEALLOCATE cs;
GO


EXEC Repl.sp_ParcharAgentes;
PRINT N'Listo. Corre este script en los otros 2 nodos y luego 09 (SJ) y 10 (Limon). Pruebas: 12_verificacion_y_pruebas.sql';
SET NOEXEC OFF;
GO