# DAX Measures — Margenes Vijostran

Todas las medidas viven en la tabla `costo_promedio_dinamico`.
Organizadas por carpeta (Display Folder).

---

## Carpeta: Ventas

### Total Ventas
```dax
Total Ventas = SUM(costo_promedio_dinamico[total_venta])
```
Suma total de ventas en soles. Formato: `S/ #,0.00`

---

### Cantidad KG Vendidos
```dax
Cantidad KG Vendidos = SUM(costo_promedio_dinamico[cantidad_kg])
```
Total de kilos vendidos. Galones ya convertidos a kilos (1 GAL = 2.01 KG). Formato: `#,0`

---

### Precio Venta Promedio KG
```dax
Precio Venta Promedio KG = DIVIDE([Total Ventas], [Cantidad KG Vendidos], 0)
```
Precio de venta promedio por kilo en el período seleccionado. Formato: `0.00`

---

## Carpeta: Costos

### Total Costo
```dax
Total Costo = SUM(costo_promedio_dinamico[total_costo])
```
Costo total asignado usando CPP Móvil de 7 días.
El costo ya viene calculado desde la vista `core.costo_promedio_dinamico` en SQL Server.
Formato: `S/ #,0.00`

---

### Precio Costo Promedio KG
```dax
Precio Costo Promedio KG = DIVIDE([Total Costo], [Cantidad KG Vendidos], 0)
```
Costo promedio ponderado por kilo en el período seleccionado. Formato: `#,0.00`

---

### Total Gastos
```dax
Total gastos = SUM('core gastos'[total])
```
Total de gastos operativos de la tabla `core.gastos`.

---

## Carpeta: Margen

### Margen Bruto
```dax
Margen Bruto = [Total Ventas] - [Total Costo]
```
Margen bruto en soles (Ventas − Costo de ventas). Formato: `S/ #,0.00`

---

### % Margen Bruto
```dax
% Margen Bruto = DIVIDE([Margen Bruto], [Total Ventas], 0)
```
Porcentaje de margen bruto sobre las ventas totales. Formato: `0.00%`

---

### Margen Unitario KG
```dax
Margen Unitario KG = [Precio Venta Promedio KG] - [Precio Costo Promedio KG]
```
Margen en soles por kilo vendido. Formato: `S/ #,0.00`

---

### % Margen Unitario
```dax
% Margen Unitario = DIVIDE([Margen Unitario KG], [Precio Venta Promedio KG], 0)
```
Porcentaje de margen unitario sobre el precio de venta por kilo. Formato: `0.00%`

---

### Utilidad Operativa
```dax
Utilidad Operativa = [Margen Bruto] - [Total gastos]
```
Utilidad operativa = Margen Bruto menos gastos operativos.

---

### Margen Operativo
```dax
Margen operativo = [Utilidad Operativa] / [Total Ventas]
```
Porcentaje de utilidad operativa sobre las ventas totales. Formato: `0.00 %`

---

## Carpeta: Time Intelligence

> Requieren relación activa entre `costo_promedio_dinamico[fecha]`
> y `core calendario[fecha]`.

### Total Ventas MTD
```dax
Total Ventas MTD = TOTALMTD([Total Ventas], 'core calendario'[fecha])
```
Total ventas acumuladas en el mes hasta la fecha seleccionada. Formato: `S/ #,##0.00`

---

### Margen Bruto MTD
```dax
Margen Bruto MTD = TOTALMTD([Margen Bruto], 'core calendario'[fecha])
```
Margen bruto acumulado en el mes hasta la fecha seleccionada. Formato: `S/ #,##0.00`

---

### Total Ventas YTD
```dax
Total Ventas YTD = TOTALYTD([Total Ventas], 'core calendario'[fecha])
```
Total ventas acumuladas en el año hasta la fecha seleccionada. Formato: `S/ #,##0.00`

---

### Margen Bruto YTD
```dax
Margen Bruto YTD = TOTALYTD([Margen Bruto], 'core calendario'[fecha])
```
Margen bruto acumulado en el año hasta la fecha seleccionada. Formato: `S/ #,##0.00`

---

### Total Ventas MES ANT
```dax
Total Ventas MES ANT = CALCULATE([Total Ventas], DATEADD('core calendario'[fecha], -1, MONTH))
```
Total ventas del mes anterior al período seleccionado. Formato: `S/ #,##0.00`

---

### Margen Bruto MES ANT
```dax
Margen Bruto MES ANT = CALCULATE([Margen Bruto], DATEADD('core calendario'[fecha], -1, MONTH))
```
Margen bruto del mes anterior al período seleccionado. Formato: `S/ #,##0.00`

---

### Variacion Ventas vs MES ANT
```dax
Variacion Ventas vs MES ANT = 
    DIVIDE([Total Ventas] - [Total Ventas MES ANT], [Total Ventas MES ANT], 0)
```
Variación porcentual de ventas respecto al mes anterior. Formato: `0.00%`

---

### Variacion Margen vs MES ANT
```dax
Variacion Margen vs MES ANT = 
    DIVIDE([Margen Bruto] - [Margen Bruto MES ANT], [Margen Bruto MES ANT], 0)
```
Variación porcentual del margen bruto respecto al mes anterior. Formato: `0.00%`

---

## Carpeta: Tarjetas HTML

> Requieren el visual **HTML Viewer** de AppSource.
> Arrastrar al canvas y seleccionar la medida correspondiente.

| Medida | Descripción | Color |
|---|---|---|
| `HTML Total Ventas` | Tarjeta de ventas totales | Azul `#2E86AB` |
| `HTML Total Costo` | Tarjeta de costo total | Rojo `#E84855` |
| `HTML Utilidad Bruta` | Tarjeta de margen bruto | Verde `#69AF66` |
| `HTML % Margen Bruto` | Tarjeta de % margen bruto | Naranja `#F4A261` |
| `HTML Cantidad KG` | Tarjeta de kilos vendidos | Marrón `#6B4226` |
| `HTML Margen Unitario KG` | Tarjeta de margen por kilo | Azul oscuro `#457B9D` |
| `HTML Total gastos` | Tarjeta de gastos operativos | — |
| `HTML Tarjeta Utilidad Operativa` | Tarjeta de utilidad operativa | — |
| `HTML Tarjeta Unificada` | Tarjeta consolidada con múltiples KPIs | — |

---

## Configuración del Calendario

Las siguientes columnas de `core calendario` deben tener **Sort By Column** configurado
para evitar orden alfabético en visualizaciones:

| Columna | Ordenar por |
|---|---|
| `nombre_mes` | `mes` |
| `nombre_dia` | `dia` |

**Cómo configurarlo:** Vista Modelo → seleccionar columna →
pestaña Herramientas de columna → Ordenar por columna.

---

## Tablas del Modelo

| Tabla | Tipo | Descripción |
|---|---|---|
| `costo_promedio_dinamico` | Vista SQL / Hechos | Ventas con costo CPP calculado — tabla principal |
| `core ventas` | Tabla SQL | Ventas limpias normalizadas a KG |
| `core compras` | Tabla SQL | Compras de GLP filtradas |
| `core clientes` | Tabla SQL | Dimensión de clientes |
| `core proveedores` | Tabla SQL | Dimensión de proveedores |
| `core calendario` | Tabla SQL | Dimensión de fechas 2026 |
| `core gastos` | Tabla SQL | Gastos operativos |
