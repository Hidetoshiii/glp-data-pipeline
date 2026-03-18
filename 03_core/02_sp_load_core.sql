-- ============================================================
-- Proyecto    : glp-data-pipeline
-- Archivo     : 03_core/02_sp_load_core.sql
-- Descripcion : Stored Procedure que mueve la data de staging
--               a core aplicando limpieza y logica de negocio.
--
-- Tablas que carga:
--   core.ventas      → ventas limpias normalizadas a KG
--   core.clientes    → dimension de clientes unicos
--   core.compras     → compras de GLP filtradas
--   core.proveedores → dimension de proveedores unicos
--
-- PREREQUISITO: Ejecutar 02_staging/load_staging.py primero
-- USO: EXEC core.cargar_core
-- Autor       : Hidetoshi
-- Fecha       : 2026-03-17
-- ============================================================

CREATE OR ALTER PROCEDURE core.cargar_core AS
BEGIN
    DECLARE @start_time DATETIME, @batch_start_time DATETIME;

    BEGIN TRY

        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Cargando Core Layer';
        PRINT '================================================';


        -- ============================================================
        -- core.ventas
        -- ============================================================
        -- Transformaciones aplicadas vs staging.ventas:
        --   1. CAST(fecha AS DATE)          → elimina la hora (00:00:00)
        --   2. TRY_CAST(cod_cli AS BIGINT)  → limpia notacion cientifica
        --   3. ROUND(pre_vent, 2)           → elimina decimales de float
        --   4. cantidad_kg                  → normaliza GAL a KG (x 2.01)
        --   5. pre_vent_kg                  → precio por kilo
        --
        -- Filtros aplicados:
        --   - cod_art IN ('M0002','M0003')  → solo ventas de GLP
        --   - cantidad IS NOT NULL          → excluye filas de totales
        --   - TRY_CAST(cod_cli AS BIGINT)   → excluye filas con texto
        --     IS NOT NULL                     en cod_cli (ej: 'OFICINA')
        -- ============================================================

        SET @start_time = GETDATE();
        PRINT '>> Truncando core.ventas';
        TRUNCATE TABLE core.ventas;
        PRINT '>> Insertando datos en core.ventas';

        INSERT INTO core.ventas (
            fecha, cod_cli, descripcion, moneda,
            tip_cam, und_med, cantidad, cantidad_kg,
            pre_vent, pre_vent_kg, total
        )
        SELECT
            CAST(fecha AS DATE),
            TRY_CAST(TRY_CAST(cod_cli AS BIGINT) AS NVARCHAR(20)),
            descripcion,
            moneda,
            tip_cam,
            und_med,
            cantidad,
            -- Normalizacion a kilos: 1 GAL = 2.01 KG
            CASE WHEN und_med = 'KIL' THEN cantidad
                 ELSE ROUND(cantidad * 2.01, 2)
            END,
            ROUND(pre_vent, 2),
            -- Precio por kilo
            CASE WHEN und_med = 'KIL' THEN ROUND(pre_vent, 4)
                 ELSE ROUND(pre_vent / 2.01, 4)
            END,
            ROUND(total, 2)
        FROM staging.ventas
        WHERE cantidad IS NOT NULL
        AND cod_art IN ('M0002', 'M0003')
        AND TRY_CAST(cod_cli AS BIGINT) IS NOT NULL;

        PRINT '>> Duracion: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' segundos';


        -- ============================================================
        -- core.clientes
        -- ============================================================
        -- Extrae clientes unicos de staging.ventas.
        -- Aplica los mismos filtros que core.ventas para consistencia.
        -- DISTINCT asegura un registro por cliente.
        -- ============================================================

        SET @start_time = GETDATE();
        PRINT '>> Truncando core.clientes';
        TRUNCATE TABLE core.clientes;
        PRINT '>> Insertando datos en core.clientes';

        INSERT INTO core.clientes (cod_cli, nom_cli)
        SELECT DISTINCT
            TRY_CAST(TRY_CAST(cod_cli AS BIGINT) AS NVARCHAR(20)),
            num_cli
        FROM staging.ventas
        WHERE cantidad IS NOT NULL
        AND cod_art IN ('M0002', 'M0003')
        AND TRY_CAST(cod_cli AS BIGINT) IS NOT NULL;

        PRINT '>> Duracion: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' segundos';


        -- ============================================================
        -- core.compras
        -- ============================================================
        -- Transformaciones aplicadas vs staging.compras:
        --   1. CAST(fecha AS DATE) → elimina la hora
        --   2. ROUND(precio, 2)    → elimina decimales de float
        --   3. ROUND(total_oc, 2)  → elimina decimales de float
        --
        -- Filtros aplicados:
        --   - codigo IN ('M0002','M0003') → solo compras de GLP
        --   - cantidad IS NOT NULL        → excluye filas vacias
        --   - cantidad != 0               → excluye filas con cantidad cero
        --
        -- NOTA: core.compras es la base del calculo del
        --       Costo Promedio Ponderado Movil de 7 dias.
        --       Ver 03_core/03_view_margen.sql para el calculo completo.
        -- ============================================================

        SET @start_time = GETDATE();
        PRINT '>> Truncando core.compras';
        TRUNCATE TABLE core.compras;
        PRINT '>> Insertando datos en core.compras';

        INSERT INTO core.compras (
            fecha, ruc_proveedor, producto, und_med,
            moneda, cantidad, precio_unit, total
        )
        SELECT
            CAST(fecha AS DATE),
            ruc,
            producto,
            um,
            moneda,
            cantidad,
            ROUND(precio, 2),
            ROUND(total_oc, 2)
        FROM staging.compras
        WHERE cantidad IS NOT NULL
        AND cantidad != 0
        AND codigo IN ('M0002', 'M0003');

        PRINT '>> Duracion: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' segundos';


        -- ============================================================
        -- core.proveedores
        -- ============================================================
        -- Extrae proveedores unicos de staging.compras.
        -- DISTINCT asegura un registro por proveedor.
        -- ============================================================

        SET @start_time = GETDATE();
        PRINT '>> Truncando core.proveedores';
        TRUNCATE TABLE core.proveedores;
        PRINT '>> Insertando datos en core.proveedores';

        INSERT INTO core.proveedores (ruc, nom_prov)
        SELECT DISTINCT
            ruc,
            proveedor
        FROM staging.compras
        WHERE ruc IS NOT NULL;

        PRINT '>> Duracion: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' segundos';

        PRINT '================================================';
        PRINT 'Core cargado correctamente';
        PRINT '>> Duracion total: ' + CAST(DATEDIFF(SECOND, @batch_start_time, GETDATE()) AS NVARCHAR) + ' segundos';
        PRINT '================================================';

    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR AL CARGAR CORE';
        PRINT '>> ' + ERROR_MESSAGE();
        PRINT '================================================';
    END CATCH
END
