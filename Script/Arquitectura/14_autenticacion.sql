-- Ejecutar este script en WWI_Corporativo, WWI_Limon y WWI_SanJose.
IF DB_NAME() NOT IN (N'WWI_Corporativo', N'WWI_Limon', N'WWI_SanJose')
BEGIN
    ;THROW 50000, N'Ejecuta este script en una de las tres bases WWI.', 1;
END;
GO

-- Se encarga de comparar el nombre y la contraseña ingresadas con las almacenadas. También verifica si el usuario está activo.
CREATE OR ALTER PROCEDURE dbo.sp_AuthenticateUser
    @Username VARCHAR(50),
    @PasswordText VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.UserID,
        u.BranchID,
        u.Username,
        u.FullName,
        u.Role,
        b.BranchName,
        b.ConnectionPort,
        b.HostServer
    FROM dbo.Users AS u
    INNER JOIN dbo.Branches AS b ON b.BranchID = u.BranchID
    WHERE u.Username = @Username
      AND u.PasswordHash = HASHBYTES('SHA2_512', @PasswordText)
      AND u.IsActive = 1;
END;
GO
