-- ============================================================
-- Proyecto    : glp-data-pipeline
-- Archivo     : 03_core/01_ddl_core.sql
-- Descripcion : Crea las tablas de la capa core.
--               Data limpia con logica de negocio aplicada.
--               Es la capa que consume Power BI via DirectQuery.
--
-- Tablas:
--   core.ventas      → ventas de GLP normalizadas a kilos
--   core.clientes    → dimension de clientes
--   core.compras     → compras de GLP para calculo de CPP
--   core.proveedores → dimension de proveedores
--   core.calendario  → dimension de fechas 2026
--
-- NOTA: La carga de datos la realiza 03_core/02_sp_load_core.sql
-- Autor       : Hidetoshi
-- Fecha       : 2026-03-17
-- ============================================================


-- ============================================================
-- core.ventas
-- ============================================================
-- Diferencias clave vs staging.ventas:
--   - Solo incluye ventas de GLP (cod_art M0002 y M0003)
--   - fecha limpia sin hora
--   - cod_cli convertido a texto sin notacion cientifica
--   - pre_vent redondeado a 2 decimales
--   - cantidad_kg: cantidad normalizada a kilos (1 GAL = 2.01 KG)
--   - pre_vent_kg: precio de venta por kilo
-- ============================================================

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
    pre_vent    DECIMAL(5,2),   -- precio de venta en unidad original
    pre_vent_kg DECIMAL(18,4),  -- precio de venta por kilo
    total       DECIMAL(18,2)
);
GO


-- ============================================================
-- core.clientes
-- ============================================================
-- Dimension de clientes extraida de staging.ventas.
-- Llave: cod_cli (RUC del cliente)
-- ============================================================

IF OBJECT_ID('core.clientes', 'U') IS NOT NULL
    DROP TABLE core.clientes;
GO

CREATE TABLE core.clientes (
    cod_cli NVARCHAR(11) PRIMARY KEY,
    nom_cli NVARCHAR(100)
);
GO


-- ============================================================
-- core.compras
-- ============================================================
-- Diferencias clave vs staging.compras:
--   - Solo incluye compras de GLP (codigo M0002 y M0003)
--   - fecha limpia sin hora
--   - Base del calculo del Costo Promedio Ponderado Movil 7 dias
-- ============================================================

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
    precio_unit   DECIMAL(5,2),  -- precio unitario de compra por kilo
    total         DECIMAL(18,2)
);
GO


-- ============================================================
-- core.proveedores
-- ============================================================
-- Dimension de proveedores extraida de staging.compras.
-- Llave: ruc (RUC del proveedor)
-- ============================================================

IF OBJECT_ID('core.proveedores', 'U') IS NOT NULL
    DROP TABLE core.proveedores;
GO

CREATE TABLE core.proveedores (
    ruc      NVARCHAR(11) PRIMARY KEY,
    nom_prov NVARCHAR(100)
);
GO


-- ============================================================
-- core.calendario
-- ============================================================
-- Dimension de fechas para Time Intelligence en Power BI.
-- Cubre todo el año 2026.
--
-- CONFIGURACION EN POWER BI:
--   nombre_mes → ordenar por columna: mes
--   nombre_dia → ordenar por columna: dia
--   Esto evita el orden alfabetico en visualizaciones.
-- ============================================================

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

-- Llenar con todas las fechas del año 2026 en español
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
