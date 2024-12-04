--creacion de tablas 
-- Tabla de Desarrolladores
CREATE TABLE Developers (
    DeveloperID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL
);

-- Tabla de Proyectos
CREATE TABLE Projects (
    ProjectID INT PRIMARY KEY IDENTITY(1,1),
    ProjectName NVARCHAR(100) NOT NULL
);

-- Tabla de Entradas de Líneas de Código
CREATE TABLE LOCEntries (
    LOCID INT PRIMARY KEY IDENTITY(1,1),
    DeveloperID INT FOREIGN KEY REFERENCES Developers(DeveloperID),
    ProjectID INT FOREIGN KEY REFERENCES Projects(ProjectID),
    LOCWritten INT NOT NULL,
    EntryDate DATETIME DEFAULT GETDATE()
);

-- Tabla de Auditoría
CREATE TABLE Audit_Log (
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(50),
    Operation NVARCHAR(10),
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    OperationDate DATETIME DEFAULT GETDATE()
);


--creacion de trigger validacion 
CREATE TRIGGER trg_Validate_LOC
ON LOCEntries
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT * FROM INSERTED WHERE LOCWritten < 0)
    BEGIN
        RAISERROR('LOC no puede ser negativo.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;


--crecion trigger auditoria
 CREATE TRIGGER trg_Audit_LOCEntries
ON LOCEntries
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @OldValues NVARCHAR(MAX), @NewValues NVARCHAR(MAX);

    -- Capturar valores antiguos
    IF EXISTS (SELECT * FROM DELETED)
    BEGIN
        SET @OldValues = (SELECT STRING_AGG(CONCAT('LOCID=', LOCID, ', LOCWritten=', LOCWritten), '; ')
                          FROM DELETED);
    END

    -- Capturar valores nuevos
    IF EXISTS (SELECT * FROM INSERTED)
    BEGIN
        SET @NewValues = (SELECT STRING_AGG(CONCAT('LOCID=', LOCID, ', LOCWritten=', LOCWritten), '; ')
                          FROM INSERTED);
    END

    -- Insertar en la tabla de auditoría
    INSERT INTO Audit_Log (TableName, Operation, OldValues, NewValues)
    VALUES ('LOCEntries',
            CASE 
                WHEN EXISTS (SELECT * FROM INSERTED) AND EXISTS (SELECT * FROM DELETED) THEN 'UPDATE'
                WHEN EXISTS (SELECT * FROM INSERTED) THEN 'INSERT'
                WHEN EXISTS (SELECT * FROM DELETED) THEN 'DELETE'
            END,
            @OldValues, @NewValues);
END;


--insercion de datos 
-- Insertar desarrolladores
INSERT INTO Developers (Name)
VALUES ('Alice Johnson'), ('Bob Smith'), ('Carol Williams');

-- Insertar proyectos
INSERT INTO Projects (ProjectName)
VALUES ('Project Alpha'), ('Project Beta');

-- Insertar líneas de código válidas
INSERT INTO LOCEntries (DeveloperID, ProjectID, LOCWritten)
VALUES (1, 1, 500),  -- Alice en Project Alpha
       (2, 1, 300),  -- Bob en Project Alpha
       (3, 2, 200);  -- Carol en Project Beta

-- Insertar líneas de código negativas (causará error)
INSERT INTO LOCEntries (DeveloperID, ProjectID, LOCWritten)
VALUES (1, 1, -100);  -- Generará un error de validación


--consulta de reporte 
SELECT D.Name AS DeveloperName, SUM(LOCWritten) AS TotalLOC
FROM LOCEntries LE
JOIN Developers D ON LE.DeveloperID = D.DeveloperID
GROUP BY D.Name;


--hyistortial de auditoria 
SELECT * FROM Audit_Log ORDER BY OperationDate DESC;



--prueba de insercion 
INSERT INTO LOCEntries (DeveloperID, ProjectID, LOCWritten)
VALUES (1, 1, 400);  -- Nueva inserción


--prueba de actualizacion 
UPDATE LOCEntries
SET LOCWritten = 600
WHERE LOCID = 1;  -- Cambia el valor para Alice


--prueba de eliminacion 
DELETE FROM LOCEntries
WHERE LOCID = 3;  -- Borra la entrada de Carol
