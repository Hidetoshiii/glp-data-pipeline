-- ============================================================
-- Proyecto    : glp-data-pipeline
-- Archivo     : 04_register/01_ddl_register.sql
-- Descripcion : Crea la tabla register.files que actua como
--               log de cada ejecucion del pipeline.
--               Registra que archivo se cargo, cuando, cuantas
--               filas tenia y si hubo algun error.
--
-- Uso tipico:
--   Consultar despues de cada carga para verificar el estado:
--   SELECT TOP 10 * FROM register.files ORDER BY fecha DESC
--
-- Autor       : Hidetoshi
-- Fecha       : 2026-03-17
-- ============================================================

IF OBJECT_ID('register.files', 'U') IS NOT NULL
    DROP TABLE register.files;
GO

CREATE TABLE register.files (
    id         INT IDENTITY(1,1) PRIMARY KEY,
    fecha      DATETIME DEFAULT GETDATE(), -- fecha y hora exacta de la carga
    nombre     NVARCHAR(100),              -- nombre del archivo cargado
    extension  NVARCHAR(10),              -- xlsx, csv, etc.
    filas      INT,                       -- cantidad de filas procesadas
    estado     BIT,                       -- 1 = exitoso | 0 = error
    error      NVARCHAR(500),             -- mensaje de error si estado = 0
    fila_error INT                        -- fila donde ocurrio el error
);
GO
