# glp-data-pipeline

Pipeline de datos end-to-end para análisis de márgenes brutos en una empresa distribuidora de GLP.
Integra Python, SQL Server y Power BI para transformar datos transaccionales de ventas y compras
en métricas de rentabilidad usando Costo Promedio Ponderado Móvil de 7 días.

---

## Arquitectura
```
Excel (Ventas + Compras)
        ↓
   Python (cargar_staging.py)
        ↓
   SQL Server - VijostranDWH
   ├── staging  ← datos crudos tal cual llegan del Excel
   ├── core     ← datos limpios + lógica de negocio
   └── register ← log de cargas
        ↓
   Power BI
        ↓
   Dashboard de Márgenes
```

---

## Estructura del Repositorio
```
glp-data-pipeline/
│
├── README.md
│
├── script/
│   ├── setup/
│   │   └── setup.sql              ← base de datos, schemas
│   ├── staging/
│   │   └── staging.sql            ← tablas staging.ventas y staging.compras
│   ├── core/
│   │   └── core.sql               ← tablas core + SP cargar_core + vista CPP
│   └── register/
│       └── register.sql           ← tabla register.files
│
├── docs/
│   ├── 01_setup.md
│   ├── 02_ingesta.md
│   ├── 03_transformacion.md
│   └── 04_powerbi.md
│
└── cargar_staging.py              ← script de ingesta Python
```

---

## Tecnologías

| Herramienta       | Versión       | Uso                              |
|-------------------|---------------|----------------------------------|
| Python            | 3.14          | Ingesta desde Excel a SQL Server |
| pandas            | latest        | Lectura y procesamiento de Excel |
| SQLAlchemy        | latest        | Conexión a SQL Server            |
| SQL Server Express| 2022          | Almacenamiento y transformación  |
| Power BI Desktop  | latest        | Visualización y métricas DAX     |
| Power BI Gateway  | 3000.306.4    | Conexión Power BI Service        |

---

## Orden de Ejecución

### Primera vez (setup completo)
```bash
# 1. Ejecutar en SSMS
script/setup/setup.sql
script/register/register.sql
script/staging/staging.sql
script/core/core.sql

# 2. Ejecutar en terminal
python cargar_staging.py

# 3. Ejecutar en SSMS
EXEC core.cargar_core

# 4. Conectar Power BI Desktop a VijostranDWH via DirectQuery
```

### Actualización mensual
```bash
# 1. Reemplazar los archivos Excel con la data actualizada
# 2. Ejecutar en terminal
python cargar_staging.py

# 3. Ejecutar en SSMS
EXEC core.cargar_core
```

---

## Lógica de Negocio

La empresa compra GLP en bulk y lo vende en ruta a múltiples clientes.
Como no existe un sistema de inventario, el costo de cada venta se calcula usando
**Costo Promedio Ponderado Móvil con ventana de 7 días**:
```
Costo Promedio = SUM(cantidad_compra × precio_unit) / SUM(cantidad_compra)
                 para todas las compras en los 7 días anteriores a cada venta

Margen Bruto = Total Venta − (Cantidad KG Vendidos × Costo Promedio)
```

Todas las unidades se normalizan a **kilos** antes del cálculo.
Factor de conversión: `1 GAL = 2.01 KG`

---

## Prerrequisitos

- SQL Server Express instalado y corriendo
- Python 3.x con librerías: `pandas`, `sqlalchemy`, `pyodbc`, `openpyxl`
- ODBC Driver 17 for SQL Server
- Power BI Desktop
- On-premises Data Gateway (para Power BI Service)

---

## Autor

Hidetoshi — Business Intelligence & Data Analytics Consultant
