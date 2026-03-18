# glp-data-pipeline

Pipeline de datos end-to-end para análisis de márgenes brutos y utilidad operativa
de una empresa distribuidora de GLP. Integra Python, SQL Server y Power BI para
transformar datos transaccionales de ventas, compras y gastos en métricas de
rentabilidad usando Costo Promedio Ponderado Móvil de 7 días.

---

## Arquitectura
```
Excel (Ventas + Compras)
        ↓
   Python — 02_staging/load_staging.py
        ↓
   SQL Server — VijostranDWH
   ├── staging  ← datos crudos tal cual llegan del Excel
   ├── core     ← datos limpios + lógica de negocio
   └── register ← log de cargas
        ↓
   Vista SQL — core.costo_promedio_dinamico
   (CPP Móvil 7 días calculado en SQL)
        ↓
   Power BI Desktop — DirectQuery
   (29 medidas DAX + tarjetas HTML)
        ↓
   Power BI Service — vía On-premises Gateway
```

---

## Estructura del Repositorio
```
glp-data-pipeline/
│
├── README.md
│
├── 01_setup/
│   └── 01_create_database.sql     ← base de datos VijostranDWH + schemas
│
├── 02_staging/
│   ├── 01_ddl_staging.sql         ← tablas staging.ventas y staging.compras
│   └── 02_load_staging.py         ← script Python de ingesta desde Excel
│
├── 03_core/
│   ├── 01_ddl_core.sql            ← tablas core (ventas, compras, clientes,
│   │                                 proveedores, gastos, calendario)
│   ├── 02_sp_load_core.sql        ← SP de transformación staging → core
│   └── 03_view_margen.sql         ← vista CPP Móvil + márgenes
│
├── 04_register/
│   └── 01_ddl_register.sql        ← tabla de log de cargas
│
└── 05_dashboard/
    └── dax_measures.md            ← 29 medidas DAX documentadas
```

---

## Tecnologías

| Herramienta | Versión | Uso |
|---|---|---|
| Python | 3.14 | Ingesta desde Excel a SQL Server |
| pandas | latest | Lectura y procesamiento de Excel |
| SQLAlchemy + pyodbc | latest | Conexión a SQL Server |
| SQL Server Express | 2022 | Almacenamiento y transformación |
| Power BI Desktop | latest | Modelo semántico y visualización |
| On-premises Data Gateway | 3000.306.4 | Conexión a Power BI Service |

---

## Modelo de Datos en Power BI

| Tabla | Tipo | Descripción |
|---|---|---|
| `costo_promedio_dinamico` | Vista SQL — Hechos | Ventas con CPP Móvil calculado. Tabla principal del modelo. |
| `core ventas` | Tabla SQL | Ventas limpias normalizadas a KG |
| `core compras` | Tabla SQL | Compras de GLP filtradas |
| `core clientes` | Tabla SQL | Dimensión de clientes |
| `core proveedores` | Tabla SQL | Dimensión de proveedores |
| `core gastos` | Tabla SQL | Gastos operativos |
| `core calendario` | Tabla SQL | Dimensión de fechas 2026 |

**Medidas DAX:** 29 medidas organizadas en 5 carpetas —
Ventas, Costos, Margen, Time Intelligence, Tarjetas HTML.
Ver `docs/dax_measures.md` para el detalle completo.

---

## Lógica de Negocio

La empresa compra GLP en bulk y lo vende en ruta a múltiples clientes.
Sin inventario ni enlace directo entre compras y ventas, el costo
se calcula usando **Costo Promedio Ponderado Móvil de 7 días**:
```
Costo Promedio = SUM(cantidad_compra × precio_unit)
                 / SUM(cantidad_compra)
                 → para compras en los 7 días anteriores a cada venta

Margen Bruto      = Total Venta − (Cantidad KG × Costo Promedio)
Utilidad Operativa = Margen Bruto − Total Gastos
```

Todas las unidades se normalizan a **kilos** antes del cálculo.
Factor de conversión: `1 GAL = 2.01 KG`

Si no hay compras en la ventana de 7 días, se usa el promedio
de todas las compras disponibles como fallback.

---

## Orden de Ejecución

### Primera vez — setup completo
```sql
-- 1. Ejecutar en SSMS en orden:
01_setup/01_create_database.sql
04_register/01_ddl_register.sql
02_staging/01_ddl_staging.sql
03_core/01_ddl_core.sql
03_core/02_sp_load_core.sql
03_core/03_view_margen.sql
```
```bash
# 2. Ejecutar en terminal:
python 02_staging/load_staging.py
```
```sql
-- 3. Ejecutar en SSMS:
EXEC core.cargar_core
```
```
-- 4. Conectar Power BI Desktop a VijostranDWH via DirectQuery
-- 5. Publicar en Power BI Service usando Vijostran-Gateway
```

### Actualización mensual
```bash
# 1. Reemplazar los archivos Excel con la data actualizada
#    (mismo nombre, misma estructura, data acumulada)

# 2. Ejecutar:
python 02_staging/load_staging.py
```
```sql
-- 3. Ejecutar en SSMS:
EXEC core.cargar_core
```
```
-- 4. Power BI Service refresca automáticamente via DirectQuery
```

---

## Prerrequisitos

- SQL Server Express con ODBC Driver 17 instalado
- Python 3.x con: `pip install pandas sqlalchemy pyodbc openpyxl`
- Power BI Desktop
- On-premises Data Gateway configurado (`Vijostran-Gateway`)

---

## Rutas de Archivos Fuente
```
Ventas  → E:\Proyecto Vijostran\Vijostran Ventas\ReporteVentas.xlsx
Compras → E:\Proyecto Vijostran\Vijostran Compras\ComprasAgrupadoProveedor.xlsx
```

> Si cambian las rutas, actualizar en `02_staging/load_staging.py`

---

## Autor

Hidetoshi — Business Intelligence & Data Analytics Consultant

