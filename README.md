# Proyecto integrador — Caso 5: Gestión deportiva

**Primera entrega: modelo de la base de datos** (modelo entidad-relación, modelo relacional con normalización
hasta 3FN y diccionario de datos).

**Integrantes:** Juan Sebastián Cárdenas y Juan David Segura.

## Contenido de la primera entrega

| Entregable | Archivo |
|---|---|
| Modelo entidad-relación | [`modelo/modelo_er.png`](modelo/modelo_er.png) · [`modelo/modelo_er.pdf`](modelo/modelo_er.pdf) |
| Modelo relacional | [`modelo/modelo_relacional.png`](modelo/modelo_relacional.png) · [`modelo/modelo_relacional.pdf`](modelo/modelo_relacional.pdf) |
| Diccionario de datos | [`modelo/diccionario_datos.xlsx`](modelo/diccionario_datos.xlsx) · [`modelo/diccionario_datos.md`](modelo/diccionario_datos.md) |
| Modelo editable de MySQL Workbench | [`modelo/modelo_gestion_deportiva.mwb`](modelo/modelo_gestion_deportiva.mwb) |
| Análisis del caso, entidades, relaciones, cardinalidad y participación, paso a relacional y normalización 3FN | [`documentacion/decisiones_diseno.md`](documentacion/decisiones_diseno.md) |
| Bitácora del proyecto y declaración de uso de IA | [`documentacion/bitacora.md`](documentacion/bitacora.md) |

## Resumen del modelo

* 12 tablas: `disciplina`, `persona`, `deportista`, `entrenador`, `equipo`, `entrenador_equipo`,
  `integrante_equipo`, `escenario`, `torneo`, `inscripcion`, `encuentro`, `participacion_encuentro`.
* `persona` es la superentidad; `deportista` y `entrenador` son subtipos (relación 1:1 con FK única), así una
  persona se registra una sola vez aunque cumpla los dos roles.
* Las relaciones muchos a muchos se resuelven con tablas asociativas: `entrenador_equipo` (con fechas de
  vigencia), `integrante_equipo` (con función y fechas), `inscripcion` y `participacion_encuentro`.
* Cada `encuentro` pertenece a un torneo, usa un escenario y tiene un equipo local y uno visitante distintos.
* Todas las claves primarias son sustitutas (`INT`); las claves naturales se protegen con restricciones `UNIQUE`.

## Notas sobre los diagramas

* Los diagramas se hicieron en **MySQL Workbench**. El relacional muestra todas las columnas con su tipo; el
  E-R muestra las entidades con sus identificadores y claves, y las relaciones con su cardinalidad (pata de gallo).
* Workbench usa los tipos de MySQL. Equivalencias con el diccionario (SQL Server):
  `VARCHAR` ↔ `NVARCHAR`/`VARCHAR`, `DATETIME` ↔ `DATETIME2`, `TINYINT(1)` ↔ `BIT`. Las reglas `CHECK` y los
  `DEFAULT` están descritos en el diccionario.

## Siguientes entregas

La implementación en SQL Server (scripts, datos semilla, consultas y pruebas) y la funcionalidad de MongoDB
corresponden a las siguientes entregas. El trabajo avanzado se conserva en la rama
[`desarrollo-completo`](https://github.com/js08cardenas08/ProyectoIntegrador/tree/desarrollo-completo).

## Uso de herramientas de IA

Usamos Claude (Anthropic) como apoyo para el desarrollo y la documentación del proyecto. Detalle en la
[bitácora](documentacion/bitacora.md).
