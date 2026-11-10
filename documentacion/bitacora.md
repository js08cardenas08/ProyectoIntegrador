# Bitácora del proyecto — Caso 5: Gestión deportiva

## Registro de avances

| Fecha | Avance | Evidencia (commit / archivo) |
|---|---|---|
| 2026-11-10 | Lectura del documento base y del Caso 5; revisión del repositorio (vacío) | — |
| 2026-11-10 | Estructura inicial del repositorio | commit "Estructura inicial del proyecto" |
| 2026-11-10 | Diseño de tablas y DDL: 12 tablas con PK, NOT NULL y DEFAULT; FK, UNIQUE, CHECK con nombres explícitos; 5 triggers de reglas entre filas; script de reinicio con advertencia | `scripts/sqlserver/00`, `01`, `02` |
| 2026-11-10 | Generador de datos semilla con semilla fija y carga de 180.193 registros (≥ 1.000 por tabla) pasando por todas las restricciones | `scripts/generador/generar_datos_semilla.py`, `03_datos_semilla.sql` |
| 2026-11-10 | Revisión de calidad de datos: se detectó que el calendario "todos contra todos" repetía cruces y que modalidades de sala usaban estadios; se corrigió el generador y se recargó | commit "Vistas y 10 consultas…" |
| 2026-11-10 | Vistas y 10 consultas de negocio, ejecución y documentación de resultados | `04_vistas.sql`, `05_consultas_negocio.sql`, `consultas_negocio.md` |
| 2026-11-10 | 48 pruebas de restricciones válidas e inválidas (48/48 PASA) | `06_pruebas_restricciones.sql`, `pruebas.md` |
| 2026-11-10 | MongoDB: colección `perfil_deportivo`, validador, índices y CRUD verificado | `caso_05_funcionalidad.js`, `mongodb.md` |
| 2026-11-10 | Diagramas E-R y relacional; diccionario de datos generado desde el catálogo real | `diagramas/`, `diccionario_datos.md`, `07_metadatos_diccionario.sql` |
| 2026-11-10 | Documentación de decisiones (normalización 3FN), reglas de negocio, README | `documentacion/` |
| 2026-11-10 | Validación final: reconstrucción completa desde base vacía y re-ejecución de todas las pruebas | `evidencias/resultados/` |

## Problemas encontrados y cómo se resolvieron

| Problema | Causa | Solución |
|---|---|---|
| En un torneo los mismos equipos se enfrentaban varias veces | El generador no rotaba los equipos entre jornadas | Método del círculo: un equipo fijo y los demás rotan una posición por jornada. Verificado: 0 cruces repetidos |
| Encuentros de hockey sala y fútbol sala en estadios abiertos | El tipo de escenario se elegía por deporte y no por modalidad | Las modalidades de sala usan coliseos o gimnasios |
| Casi todos los torneos quedaban en el pasado | Los torneos se encadenaban con intervalos aleatorios | Un torneo por semestre (2022-II a 2027-I): hay torneos finalizados, en curso y programados |
| Una regla que compara filas no se puede validar con CHECK | Un CHECK solo ve la fila actual | Triggers `AFTER INSERT, UPDATE` con `THROW` |
| Tildes y eñes | Codificación de los scripts | Archivos UTF-8, columnas `NVARCHAR` y `sqlcmd -f 65001` |

## Declaración de uso de herramientas de IA

Se utilizó un asistente de IA (Claude, de Anthropic) para: proponer y redactar el diseño, escribir los
scripts T-SQL, el script de MongoDB y los generadores en Python, ejecutar los scripts en SQL Server 2022 y
MongoDB 7 (en contenedores Docker), depurar los errores encontrados y redactar la documentación. Todas las
cifras y resultados de pruebas de la documentación provienen de ejecuciones reales guardadas en
`evidencias/resultados/`.

El uso de IA no reemplaza la comprensión del trabajo: cada integrante debe poder explicar el modelo, las
restricciones, las consultas y las decisiones durante la sustentación.

## Aporte individual de cada integrante

_(Cada integrante completa esta sección con lo que realizó, revisó y estudió para la sustentación.)_

| Integrante | Actividades realizadas | Partes que puede explicar |
|---|---|---|
| | | |
| | | |
