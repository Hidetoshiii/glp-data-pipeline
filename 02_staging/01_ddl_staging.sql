-- ============================================================
-- Proyecto    : glp-data-pipeline
-- Archivo     : 02_staging/01_ddl_staging.sql
-- Descripcion : Crea las tablas de la capa staging.
--               Replica exacta de los archivos Excel de origen.
--               Sin transformaciones ni limpieza — datos crudos.
--               Se truncan y recargan completamente en cada
--               actualización mensual.
--
-- Tablas:
--   staging.ventas   → ReporteVentas.xlsx (Hoja1, fila 9)
--   staging.compras  → ComprasAgrupadoProveedor.xlsx (Hoja1, fila 11)
--
-- NOTA: La carga de datos la realiza cargar_staging.py
-- Autor       : Hidetoshi
-- Fecha       : 2026-03-17
-- ============================================================


-- ============================================================
-- staging.ventas
-- ============================================================
-- Columnas conocidas con datos sucios:
--   cod_cli  → puede llegar en notación científica (se corrige en core)
--   fecha    → llega con hora 00:00:00 (se limpia en core)
--   pre_vent → puede tener decimales largos por float de Python
--              (se redondea en core)
-- Filas excluidas en core:
--   - Filas de totales al final (TOTAL SOLES, TOTAL DOLARES)
--   - Filas con cod_art distinto de M0002 o M0003 (no son GLP)
-- ============================================================

IF OBJECT_ID('staging.ventas', 'U') IS NOT NULL
    DROP TABLE staging.ventas;
GO

CREATE TABLE staging.ventas (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    vendedor     NVARCHAR(100),
    moneda       NVARCHAR(20),
    fecha        DATE,
    cod_cli      NVARCHAR(20),
    num_cli      NVARCHAR(100),   -- nombre del cliente
    td           NVARCHAR(10),    -- tipo de documento
    num_doc      NVARCHAR(20),    -- número de documento
    clasificador NVARCHAR(50),
    cod_art      NVARCHAR(20),    -- M0002 = KIL | M0003 = GAL
    descripcion  NVARCHAR(100),
    und_med      NVARCHAR(5),     -- KIL o GAL
    cantidad     DECIMAL(18,2),
    pre_vent     DECIMAL(5,2),    -- precio de venta
    total        DECIMAL(18,2),   -- total en soles
    tip_cam      DECIMAL(5,2),    -- tipo de cambio
    oc           NVARCHAR(50)     -- orden de compra del cliente
);
GO


-- ============================================================
-- staging.compras
-- ============================================================
-- Columnas conocidas con datos sucios:
--   fecha → algunas filas llegan como texto DD/MM/YYYY
--            se corrige en cargar_staging.py con dayfirst=True
-- Filas excluidas en core:
--   - Filas con cantidad = 0 o NULL
--   - Filas con codigo distinto de M0002 o M0003 (no son GLP)
-- ============================================================

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
    codigo       NVARCHAR(20),    -- M0002 = KIL | M0003 = GAL
    producto     NVARCHAR(100),
    um           NVARCHAR(10),    -- unidad de medida
    cantidad     DECIMAL(18,2),
    precio       DECIMAL(10,2),   -- precio unitario de compra
    dscto        DECIMAL(10,2),
    subtotal     DECIMAL(18,2),
    igv_oc       DECIMAL(18,2),
    total_oc     DECIMAL(18,2),
    referencia   NVARCHAR(50)
);
GO
