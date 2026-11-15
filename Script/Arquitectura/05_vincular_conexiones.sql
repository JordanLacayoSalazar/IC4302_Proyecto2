-- =========================================================================
-- 05_vincular_conexiones.sql
-- Ejecutar en CADA nodo (conectado a master), crea linked servers hacia los
-- otros dos nodos
-- =========================================================================
USE master;
GO

IF OBJECT_ID('tempdb..#cfg') IS NOT NULL DROP TABLE #cfg;
CREATE TABLE #cfg (Pwd NVARCHAR(128) NOT NULL);
INSERT #cfg VALUES (N'<<SA_PASSWORD>>');   -- <-- editar por una password la cual no se le vaya a olvidar

IF (SELECT Pwd FROM #cfg) = N'<<SA_PASSWORD>>'
BEGIN
    RAISERROR(N'Edita la contrasena de SA en la tabla #cfg antes de ejecutar.', 16, 1);
    SET NOEXEC ON;
END
GO

DECLARE @pwd  NVARCHAR(128) = (SELECT Pwd FROM #cfg);
DECLARE @self SYSNAME = @@SERVERNAME;
DECLARE @nodes TABLE (NodeName SYSNAME PRIMARY KEY);
INSERT @nodes VALUES (N'nodo_corporativo'), (N'nodo_sucursal_sj'), (N'nodo_sucursal_limon');

IF NOT EXISTS (SELECT 1 FROM @nodes WHERE NodeName = @self)
BEGIN
    RAISERROR(N'@@SERVERNAME (%s) no es ninguno de los 3 nodos. Ejecuta 00_fix_servername.sql y reinicia.', 16, 1, @self);
    SET NOEXEC ON;
END
GO

DECLARE @pwd  NVARCHAR(128) = (SELECT Pwd FROM #cfg);
DECLARE @self SYSNAME = @@SERVERNAME;
DECLARE @n SYSNAME;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT v.NodeName FROM (VALUES (N'nodo_corporativo'), (N'nodo_sucursal_sj'), (N'nodo_sucursal_limon')) AS v(NodeName)
    WHERE v.NodeName <> @self;
OPEN cur;
FETCH NEXT FROM cur INTO @n;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.servers WHERE name = @n)
        EXEC sp_dropserver @server = @n, @droplogins = 'droplogins';

    EXEC sp_addlinkedserver
         @server     = @n,
         @srvproduct = N'',
         @provider   = N'MSOLEDBSQL',
         @datasrc    = @n,
         @provstr    = N'Encrypt=Optional;TrustServerCertificate=Yes';

    EXEC sp_addlinkedsrvlogin
         @rmtsrvname  = @n,
         @useself     = 'false',
         @locallogin  = NULL,
         @rmtuser     = N'sa',
         @rmtpassword = @pwd;

    EXEC sp_serveroption @server = @n, @optname = 'rpc',         @optvalue = 'true';
    EXEC sp_serveroption @server = @n, @optname = 'rpc out',     @optvalue = 'true';
    EXEC sp_serveroption @server = @n, @optname = 'data access', @optvalue = 'true';
    EXEC sp_serveroption @server = @n, @optname = 'remote proc transaction promotion', @optvalue = 'false';

    PRINT CONCAT(N'Linked server creado: ', @n);
    FETCH NEXT FROM cur INTO @n;
END
CLOSE cur; DEALLOCATE cur;
GO

-- prueba de conectividad
DECLARE @n2 SYSNAME;
DECLARE c2 CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.servers WHERE name LIKE N'nodo[_]%' AND name <> @@SERVERNAME;
OPEN c2; FETCH NEXT FROM c2 INTO @n2;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC sp_testlinkedserver @n2;
        PRINT CONCAT(N'OK conexion -> ', @n2);
    END TRY
    BEGIN CATCH
        PRINT CONCAT(N'FALLO conexion -> ', @n2, N': ', ERROR_MESSAGE());
    END CATCH
    FETCH NEXT FROM c2 INTO @n2;
END
CLOSE c2; DEALLOCATE c2;
SET NOEXEC OFF;
GO


/* Requisito de SQL Server en Linux para futuras replicaciones nativas */
USE msdb;
GO
BEGIN TRY
    EXEC sys.sp_MSrepl_createdatatypemappings;
    PRINT 'Mapeos de tipos de datos para replicacion en Linux registrados correctamente.';
END TRY
BEGIN CATCH
    PRINT 'El mapeo ya existia o hubo un error.';
END CATCH
GO