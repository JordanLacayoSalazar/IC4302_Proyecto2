-- =========================================================================
-- 02_tablas_seguridad.sql
-- Ejecutar en las 3 bases (WWI_Corporativo, WWI_SanJose, WWI_Limon).
-- IMPORTANTE: los usuarios se insertan en UN solo nodo, el sync multi-master
-- los propaga a los demas. Insertar el mismo Username en dos nodos
-- genera un conflicto UNIQUE.
-- =========================================================================


-- eliminacion de tablas y procedimientos
DROP PROCEDURE IF EXISTS sp_InsertUser;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Branches;
GO

-- tabla de sucursales
CREATE TABLE Branches (
    BranchID INT PRIMARY KEY,
    BranchName VARCHAR(50) NOT NULL,
    ConnectionPort INT NOT NULL,
    HostServer VARCHAR(100) NOT NULL
);
GO

-- inserta los nodos
INSERT INTO Branches (BranchID, BranchName, ConnectionPort, HostServer)
VALUES 
    (1, 'Corporativo', 1433, 'localhost'),
    (2, 'San Jose', 1434, 'localhost'),
    (3, 'Limon', 1435, 'localhost');
GO

-- tabla de usuarios
CREATE TABLE Users (
    UserID INT IDENTITY(1,1),
    BranchID INT NOT NULL, 
    Username VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL, 
    FullName VARCHAR(100) NOT NULL,
    IsActive BIT DEFAULT 1,
    Role VARCHAR(20) NOT NULL CHECK (Role IN ('Administrador', 'Corporativo')),
    Email VARCHAR(100),
    HireDate DATE,
    CONSTRAINT PK_Users PRIMARY KEY (BranchID, UserID), 
    CONSTRAINT FK_Users_Branches FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
);
GO

-- procedimiento almacenado para insertar un usuario
CREATE PROCEDURE sp_InsertUser
    @BranchID INT,
    @Username VARCHAR(50),
    @PasswordText VARCHAR(100),
    @FullName VARCHAR(100),
    @Role VARCHAR(20),
    @Email VARCHAR(100),
    @HireDate DATE
AS
BEGIN
    INSERT INTO Users (BranchID, Username, PasswordHash, FullName, IsActive, Role, Email, HireDate)
    VALUES (
        @BranchID, 
        @Username, 
        HASHBYTES('SHA2_512', @PasswordText), 
        @FullName, 
        1, 
        @Role, 
        @Email, 
        @HireDate
    );
END;
GO