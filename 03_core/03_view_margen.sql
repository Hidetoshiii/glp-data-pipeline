-- ============================================================
-- Proyecto    : glp-data-pipeline
-- Archivo     : 03_core/03_view_margen.sql
-- Descripcion : Vista que calcula el Costo Promedio Ponderado
--               Movil (CPP) de 7 dias y los margenes brutos.
--               Es la capa que consume Power BI via DirectQuery.
--
-- LOGICA DE NEGOCIO:
--   La empresa compra GLP y lo vende en ruta a multiples clientes.
--   No existe inventario ni enlace directo entre compras y ventas.
--   Por eso se usa el CPP Movil:
--
--   Costo Promedio = SUM(cantidad_compra x precio_unit)
--                   / SUM(cantidad_compra)
--                   para todas las compras en los 7 dias anteriores
--                   a cada venta (incluyendo el dia de la venta).
--
--   Si no hay compras en esa ventana de 7 dias, se usa el promedio
--   de todas las compras disponibles como fallback.
--
-- COLUMNAS:
--   fecha            → fecha de la venta
--   cod_cli          → codigo del cliente (llave a core.clientes)
--   descripcion      → descripcion del producto
--   cantidad_kg      → kilos vendidos (GAL ya convertidos a KG)
--   precio_venta_kg  → precio de venta por kilo
--   precio_costo_kg  → costo promedio ponderado movil por kilo
--   total_venta      → total en soles de la venta
--   total_costo      → costo asignado en soles
--   margen_unitario  → precio_venta_kg - precio_costo_kg
--   margen_total     → total_venta - total_costo
--
-- NOTA: nombre_mes y nombre_dia en core.calendario
--       deben estar configurados con Sort By Column en Power BI
--       para evitar orden alfabetico en visualizaciones.
-- Autor       : Hidetoshi
-- Fecha       : 2026-03-17
-- ============================================================

CREATE OR ALTER VIEW core.costo_promedio_dinamico AS
SELECT
    v.fecha,
    v.cod_cli,
    v.descripcion,
    v.cantidad_kg,
    v.pre_vent_kg                                        AS precio_venta_kg,

    -- --------------------------------------------------------
    -- Costo Promedio Ponderado Movil — ventana 7 dias
    -- --------------------------------------------------------
    -- Busca compras en los 7 dias anteriores a cada venta.
    -- Si no encuentra ninguna, usa el promedio de todas las
    -- compras disponibles (fallback para ventas al inicio
    -- del periodo donde aun no hay compras registradas).
    -- --------------------------------------------------------
    COALESCE(
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c
         WHERE c.fecha BETWEEN DATEADD(DAY, -7, v.fecha) AND v.fecha),
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c)
    )                                                    AS precio_costo_kg,

    -- Total de la venta en soles
    v.total                                              AS total_venta,

    -- Costo asignado = kilos vendidos x costo promedio
    v.cantidad_kg *
    COALESCE(
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c
         WHERE c.fecha BETWEEN DATEADD(DAY, -7, v.fecha) AND v.fecha),
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c)
    )                                                    AS total_costo,

    -- Margen unitario por kilo
    v.pre_vent_kg -
    COALESCE(
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c
         WHERE c.fecha BETWEEN DATEADD(DAY, -7, v.fecha) AND v.fecha),
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c)
    )                                                    AS margen_unitario,

    -- Margen total en soles
    v.total - (v.cantidad_kg *
    COALESCE(
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c
         WHERE c.fecha BETWEEN DATEADD(DAY, -7, v.fecha) AND v.fecha),
        (SELECT SUM(c.cantidad * c.precio_unit) / NULLIF(SUM(c.cantidad), 0)
         FROM core.compras c)
    ))                                                   AS margen_total

FROM core.ventas v;
