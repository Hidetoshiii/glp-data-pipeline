-- ============================================================
-- Proyecto    : glp-data-pipeline
-- Archivo     : sql/01_setup/01_create_database.sql
-- Descripcion : Crea la base de datos VijostranDWH y sus tres
--               schemas que organizan el pipeline por capas.
--
-- SCHEMAS:
--   staging  → datos crudos del Excel, sin transformar
--   core     → datos limpios con logica de negocio aplicada
--   register → log de cada ejecucion del pipeline
--
-- ADVERTENCIA: Ejecutar una sola vez al iniciar el proyecto.
-- Autor       : Hidetoshi
-- Fecha       : 2026-03-17
-- ============================================================

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
