# ============================================================
# Proyecto    : glp-data-pipeline
# Archivo     : 02_staging/load_staging.py
# Descripcion : Carga los archivos Excel de ventas y compras
#               a las tablas staging en SQL Server.
#               Trunca y recarga completamente en cada ejecucion.
#
# USO:
#   python 02_staging/load_staging.py
#
# REQUISITOS:
#   pip install pandas sqlalchemy pyodbc openpyxl
#   ODBC Driver 17 for SQL Server instalado
#
# ACTUALIZACION MENSUAL:
#   1. Reemplazar los archivos Excel con la data actualizada
#      manteniendo el mismo nombre y estructura
#   2. Ejecutar este script
#   3. Ejecutar en SSMS: EXEC core.cargar_core
#
# RUTAS DE ARCHIVOS:
#   Ventas  → E:\Proyecto Vijostran\Vijostran Ventas\ReporteVentas.xlsx
#   Compras → E:\Proyecto Vijostran\Vijostran Compras\ComprasAgrupadoProveedor.xlsx
# ============================================================

import pandas as pd
from sqlalchemy import create_engine
import urllib


# ------------------------------------------------------------
# CONEXION A SQL SERVER
# ------------------------------------------------------------
# Autenticacion Windows (Trusted_Connection)
# Modificar SERVER si el equipo cambia de nombre

params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=DESKTOP-PULD60B\\SQLEXPRESS;"
    "DATABASE=VijostranDWH;"
    "Trusted_Connection=yes;"
)

engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")
print("Conexion establecida con VijostranDWH")


# ------------------------------------------------------------
# CARGA: staging.ventas
# ------------------------------------------------------------
# skiprows=8 → salta las primeras 8 filas del Excel
# La data real empieza en la fila 9 (Python cuenta desde 0)

print("\n>> Cargando staging.ventas...")

df_ventas = pd.read_excel(
    r"E:\Proyecto Vijostran\Vijostran Ventas\ReporteVentas.xlsx",
    sheet_name="Hoja1",
    header=None,
    skiprows=8
)

df_ventas.columns = [
    'vendedor', 'moneda', 'fecha', 'cod_cli', 'num_cli',
    'td', 'num_doc', 'clasificador', 'cod_art', 'descripcion',
    'und_med', 'cantidad', 'pre_vent', 'total', 'tip_cam', 'oc'
]

# if_exists='replace' → equivale a TRUNCATE + INSERT
# index=False → no insertar el índice de pandas como columna
df_ventas.to_sql(
    name='ventas',
    schema='staging',
    con=engine,
    if_exists='replace',
    index=False
)

print(f"   staging.ventas: {len(df_ventas)} filas cargadas")


# ------------------------------------------------------------
# CARGA: staging.compras
# ------------------------------------------------------------
# skiprows=10 → la data real empieza en la fila 11
# dayfirst=True → corrige fechas en formato peruano DD/MM/YYYY
#                 sin esto Python interpreta el día como mes

print("\n>> Cargando staging.compras...")

df_compras = pd.read_excel(
    r"E:\Proyecto Vijostran\Vijostran Compras\ComprasAgrupadoProveedor.xlsx",
    sheet_name="Hoja1",
    header=None,
    skiprows=10
)

df_compras.columns = [
    'fecha', 'ruc', 'proveedor', 'doc_num_ot', 'cod_fac', 'num_fac', 'moneda',
    'soles', 'dolares', 'total', 'tip_cam', 'a_sol', 'igv', 'tot_sol', 'cod_num_oc',
    'n_real_oc', 'codigo', 'producto', 'um', 'cantidad', 'precio', 'dscto', 'subtotal',
    'igv_oc', 'total_oc', 'referencia'
]

# Corrección de fechas formato peruano DD/MM/YYYY
df_compras['fecha'] = pd.to_datetime(df_compras['fecha'], dayfirst=True)

df_compras.to_sql(
    name='compras',
    schema='staging',
    con=engine,
    if_exists='replace',
    index=False
)

print(f"   staging.compras: {len(df_compras)} filas cargadas")
print("\n>> Staging listo. Ejecutar en SSMS: EXEC core.cargar_core")
