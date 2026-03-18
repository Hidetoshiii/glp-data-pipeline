-- ============================================================
-- Proyecto    : glp-data-pipeline
-- Archivo     : script/setup/setup.sql
-- Descripcion : Crea la base de datos VijostranDWH con todos
--               sus schemas, tablas y dimensiones.
--               Ejecutar una sola vez al iniciar el proyecto.
-- Autor       : Hidetoshi
-- Fecha       : 2026-03-17
-- ============================================================
-- ADVERTENCIA: Este script elimina y recrea la base de datos
--              si ya existe. Hacer backup antes de ejecutar.
-- ============================================================


-- ============================================================
-- PARTE 1: BASE DE DATOS Y SCHEMAS
-- ============================================================
-- Tres schemas organizan el pipeline por capas:
--   staging  → datos crudos del Excel, sin transformar
--   core     → datos limpios con lógica de negocio
--   register → log de cada ejecución del pipeline

CREATE DATABASE VijostranDWH;
GO

USE VijostranDWH;
GO

CREATE SCHEMA staging;
GO

CREATE SCHEMA core;
GO

CREATE SCHEMA register;
GO


-- ============================================================
-- PARTE 2: CAPA REGISTER
-- ============================================================
-- Registra cada ejecución del pipeline.
-- Guarda qué archivo se cargó, cuándo, cuántas filas tuvo
-- y si ocurrió algún error.

IF OBJECT_ID('register.files', 'U') IS NOT NULL
    DROP TABLE register.files;
GO

CREATE TABLE register.files (
    id         INT IDENTITY(1,1) PRIMARY KEY,
    fecha      DATETIME DEFAULT GETDATE(), -- fecha y hora de la carga
    nombre     NVARCHAR(100),              -- nombre del archivo cargado
    extension  NVARCHAR(10),              -- xlsx, csv, etc.
    filas      INT,                       -- cantidad de filas procesadas
    estado     BIT,                       -- 1 = exitoso | 0 = error
    error      NVARCHAR(500),             -- mensaje de error si falló
    fila_error INT                        -- fila donde ocurrió el error
);
GO


-- ============================================================
-- PARTE 3: CAPA STAGING
-- ============================================================
-- Réplica exacta de los archivos Excel.
-- Se trunca y recarga completamente en cada actualización.
-- No se aplica ninguna transformación ni limpieza aquí.

-- Tabla: staging.ventas
-- Fuente: ReporteVentas.xlsx (Hoja1, desde fila 9)

IF OBJECT_ID('staging.ventas', 'U') IS NOT NULL
    DROP TABLE staging.ventas;
GO

CREATE TABLE staging.ventas (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    vendedor     NVARCHAR(100),
    moneda       NVARCHAR(20),
    fecha        DATE,
    cod_cli      NVARCHAR(20),
    num_cli      NVARCHAR(100),    -- nombre del cliente
    td           NVARCHAR(10),     -- tipo de documento
    num_doc      NVARCHAR(20),
    clasificador NVARCHAR(50),
    cod_art      NVARCHAR(20),     -- M0002 = KIL | M0003 = GAL
    descripcion  NVARCHAR(100),
    und_med      NVARCHAR(5),      -- KIL o GAL
    cantidad     DECIMAL(18,2),
    pre_vent     DECIMAL(5,2),
    total        DECIMAL(18,2),
    tip_cam      DECIMAL(5,2),
    oc           NVARCHAR(50)
);
GO

-- Tabla: staging.compras
-- Fuente: ComprasAgrupadoProveedor.xlsx (Hoja1, desde fila 11)

IF OBJECT_ID('staging.compras', 'U') IS NOT NULL
    DROP TABLE staging.compras;
GO

CREATE TABLE staging.compras (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    fecha        DATE,
    ruc          NVARCHAR(11),
    proveedor    NVARCHAR(100),
    doc_num_ot   NVARCHAR(50),
    cod_fac      NVARCHAR(10),
    num_fac      NVARCHAR(20),
    moneda       NVARCHAR(10),
    soles        DECIMAL(18,2),
    dolares      DECIMAL(18,2),
    total        DECIMAL(18,2),
    tip_cam      DECIMAL(5,2),
    a_sol        DECIMAL(18,2),
    igv          DECIMAL(18,2),
    tot_sol      DECIMAL(18,2),
    cod_num_oc   NVARCHAR(50),
    n_real_oc    NVARCHAR(50),
    codigo       NVARCHAR(20),     -- M0002 = KIL | M0003 = GAL
    producto     NVARCHAR(100),
    um           NVARCHAR(10),
    cantidad     DECIMAL(18,2),
    precio       DECIMAL(10,2),
    dscto        DECIMAL(10,2),
    subtotal     DECIMAL(18,2),
    igv_oc       DECIMAL(18,2),
    total_oc     DECIMAL(18,2),
    referencia   NVARCHAR(50)
);
GO


-- ============================================================
-- PARTE 4: CAPA CORE
-- ============================================================
-- Data limpia con lógica de negocio aplicada.
-- Es la capa que consume Power BI.
-- Se trunca y recarga con cada actualización.

-- Tabla: core.ventas
-- Diferencias vs staging:
--   - Solo incluye ventas de GLP (cod_art M0002, M0003)
--   - fecha sin hora
--   - cod_cli convertido a texto limpio (sin notación científica)
--   - cantidad_kg: cantidad normalizada a kilos (1 GAL = 2.01 KG)
--   - pre_vent_kg: precio por kilo

IF OBJECT_ID('core.ventas', 'U') IS NOT NULL
    DROP TABLE core.ventas;
GO

CREATE TABLE core.ventas (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    fecha       DATE,
    cod_cli     NVARCHAR(20),
    descripcion NVARCHAR(50),
    moneda      NVARCHAR(10),
    tip_cam     DECIMAL(5,2),
    und_med     NVARCHAR(10),
    cantidad    DECIMAL(18,2),
    cantidad_kg DECIMAL(18,2),  -- cantidad normalizada a kilos
    pre_vent    DECIMAL(5,2),
    pre_vent_kg DECIMAL(18,4),  -- precio por kilo
    total       DECIMAL(18,2)
);
GO

-- Tabla: core.clientes
-- Dimensión extraída de staging.ventas
-- Llave: cod_cli (RUC del cliente)

IF OBJECT_ID('core.clientes', 'U') IS NOT NULL
    DROP TABLE core.clientes;
GO

CREATE TABLE core.clientes (
    cod_cli NVARCHAR(11) PRIMARY KEY,
    nom_cli NVARCHAR(100)
);
GO

-- Tabla: core.compras
-- Solo incluye compras de GLP (codigo M0002, M0003)
-- Base para el cálculo del Costo Promedio Ponderado Móvil

IF OBJECT_ID('core.compras', 'U') IS NOT NULL
    DROP TABLE core.compras;
GO

CREATE TABLE core.compras (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    fecha         DATE,
    ruc_proveedor NVARCHAR(50),
    producto      NVARCHAR(100),
    und_med       NVARCHAR(10),
    moneda        NVARCHAR(10),
    cantidad      DECIMAL(18,2),
    precio_unit   DECIMAL(5,2),
    total         DECIMAL(18,2)
);
GO

-- Tabla: core.proveedores
-- Dimensión extraída de staging.compras
-- Llave: ruc (RUC del proveedor)

IF OBJECT_ID('core.proveedores', 'U') IS NOT NULL
    DROP TABLE core.proveedores;
GO

CREATE TABLE core.proveedores (
    ruc      NVARCHAR(11) PRIMARY KEY,
    nom_prov NVARCHAR(100)
);
GO

-- Tabla: core.calendario
-- Dimensión de fechas para Time Intelligence en Power BI
-- Cubre todo el año 2026
-- NOTA: En Power BI, nombre_mes ordena por columna mes
--       y nombre_dia ordena por columna dia

IF OBJECT_ID('core.calendario', 'U') IS NOT NULL
    DROP TABLE core.calendario;
GO

CREATE TABLE core.calendario (
    fecha      DATE PRIMARY KEY,
    anio       INT,
    trimestre  INT,
    mes        INT,
    nombre_mes NVARCHAR(20),
    semana     INT,
    dia        INT,
    nombre_dia NVARCHAR(20)
);
GO

-- Llenar calendario con todas las fechas de 2026 en español
SET LANGUAGE Spanish;

DECLARE @fecha DATE = '2026-01-01';
WHILE @fecha <= '2026-12-31'
BEGIN
    INSERT INTO core.calendario VALUES (
        @fecha,
        YEAR(@fecha),
        DATEPART(QUARTER, @fecha),
        MONTH(@fecha),
        DATENAME(MONTH, @fecha),
        DATEPART(WEEK, @fecha),
        DAY(@fecha),
        DATENAME(WEEKDAY, @fecha)
    );
    SET @fecha = DATEADD(DAY, 1, @fecha);
END
GO
