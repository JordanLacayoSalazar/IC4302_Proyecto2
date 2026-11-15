-- =========================================================================
-- 01_restaurar_wwi.sql
-- Se usa la misma collation que WideWorldImporters para evitar conflictos
-- de collation en consultas entre bases.
-- =========================================================================

-- ======================= Nodo Corporativo ===========================
-- Copia WideWorldImporters-Full.bak a ./data_corp/backup/ antes de restaurar.
USE master;
GO
IF DB_ID(N'WideWorldImporters') IS NULL
RESTORE DATABASE WideWorldImporters
FROM DISK = N'/var/opt/mssql/backup/WideWorldImporters-Full.bak'
WITH MOVE N'WWI_Primary'            TO N'/var/opt/mssql/data/WideWorldImporters.mdf',
     MOVE N'WWI_UserData'           TO N'/var/opt/mssql/data/WideWorldImporters_UserData.ndf',
     MOVE N'WWI_Log'                TO N'/var/opt/mssql/data/WideWorldImporters.ldf',
     MOVE N'WWI_InMemory_Data_1'    TO N'/var/opt/mssql/data/WideWorldImporters_InMemory_Data_1',
     STATS = 10;
GO
