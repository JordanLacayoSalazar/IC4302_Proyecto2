-- Ejecutar este script en WWI_Corporativo, WWI_Limon y WWI_SanJose.
IF DB_NAME() NOT IN (N'WWI_Corporativo', N'WWI_Limon', N'WWI_SanJose')
BEGIN
    ;THROW 50000, N'Ejecuta este script en una de las tres bases WWI.', 1;
END;
GO

-- Averigua cuál es el servidor en el que el usuario ingresó en la aplicación.
CREATE OR ALTER PROCEDURE dbo.sp_ObtenerInfoServidorActual
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CONVERT(NVARCHAR(128), SERVERPROPERTY('ServerName')) AS servidor,
        DB_NAME() AS baseDatos;
END;
GO
