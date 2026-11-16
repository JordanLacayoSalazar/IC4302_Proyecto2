-- ¡¡¡ ADVERTENCIA !!! --
/*
    Primero se deben ejecutar los primeros 11 archivos SQL de la carpeta Arquitectura para
    crear la tabla de usuarios y poder agregarlos correctamente.
    Una vez ejecutados, se puede ejecutar lo siguiente:
*/

-- UBÍQUESE EN EL NODO CORPORATIVO.

USE WWI_Corporativo;
GO

EXEC dbo.sp_InsertUser
    @BranchID = 1, -- Corporativo
    @Username = 'Prof. Cristian',
    @PasswordText = 'clave789',
    @FullName = 'Cristian Campos Aguero',
    @Role = 'Administrador',
    @Email = 'cristian@email.com',
    @HireDate = '2024-09-13';

EXEC dbo.sp_InsertUser
    @BranchID = 2, -- San José
    @Username = 'JJLS09',
    @PasswordText = 'contrasena123',
    @FullName = 'Jordan Lacayo Salazar',
    @Role = 'Corporativo',
    @Email = 'jordan@email.com',
    @HireDate = '2026-11-15';


EXEC dbo.sp_InsertUser
    @BranchID = 3, -- Limón
    @Username = 'Tony',
    @PasswordText = 'password456',
    @FullName = 'Antony Campbell Ortega',
    @Role = 'Corporativo',
    @Email = 'antony@email.com',
    @HireDate = '2025-10-14';
