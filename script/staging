-- =============================================
-- Proyecto  : VijostranDWH
-- Descripcion: Creacion de base de datos y schemas
-- Capas     : staging | core | register
-- Autor     : Hidetoshi Grados
-- Fecha     : 2026-03-17
-- =============================================


CREATE TABLE register.files (
	id INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATETIME DEFAULT GETDATE(),
	nombre NVARCHAR(100),
	extension NVARCHAR(10),
	filas INT,
	estado BIT,
	error NVARCHAR(500),
	fila_error INT
)



CREATE TABLE staging.ventas(
	id INT IDENTITY(1,1) PRIMARY KEY,
	vendedor NVARCHAR(100),
	moneda NVARCHAR(20),
	fecha DATE,
	cod_cli NVARCHAR(11),
	num_cli NVARCHAR(100),
	td NVARCHAR(10),
	num_doc NVARCHAR(20),
	clasificador NVARCHAR(50),
	cod_art NVARCHAR(20),
	descripcion NVARCHAR(100),
	und_med NVARCHAR (5),
	cantidad DECIMAL(20,2),
	pre_vent DECIMAL(5,2),
	total DECIMAL(18,2),
	tip_cam DECIMAL(5,2),
	oc NVARCHAR(50)
	
)

CREATE TABLE staging.compras(
	id INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATE,
	ruc NVARCHAR(11),
	proveedor NVARCHAR(100),
	doc_num_ot NVARCHAR(50),
	cod_fac NVARCHAR(10),
	num_fac NVARCHAR(20),
	moneda NVARCHAR(10),
	soles DECIMAL(18,2),
	dolares DECIMAL(18,2),
	total DECIMAL(18,2),
	tip_cam DECIMAL(5,2),
	a_sol DECIMAL(18,2),
	igv DECIMAL(18,2),
	tot_sol DECIMAL(18,2),
	cod_num_oc NVARCHAR(50),
	n_real_oc NVARCHAR(50),
	codigo NVARCHAR(20),
	producto NVARCHAR(100),
	um NVARCHAR(10),
	cantidad DECIMAL(18,2),
	precio DECIMAL(10,2),
	dscto DECIMAL(10,2),
	subtotal DECIMAL(18,2),
	igv_oc DECIMAL(18,2),
	total_oc DECIMAL(18,2),
	referencia NVARCHAR(50)
)
