# Pruebas — Caso 5: Gestión deportiva

Todas las pruebas de este documento se **ejecutaron realmente** sobre SQL Server 2022 (16.0, edición
Developer, en contenedor Docker) y MongoDB 7.0. Los resultados obtenidos se copiaron de la salida de los
scripts, guardada en [`evidencias/resultados/`](../evidencias/resultados/).

## 1. Construcción desde una base vacía

| # | Qué se verificó | Cómo | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| C1 | Reinicio seguro | `00_reinicio_entorno.sql` sin base existente y con base existente | Mensaje "no existe" o base eliminada, sin errores | Correcto en ambos casos |
| C2 | Creación de base y tablas | `01_crear_base_y_tablas.sql` | 12 tablas | `tablas_creadas = 12` |
| C3 | Protección contra doble ejecución | Ejecutar `01` otra vez sobre la base ya creada | Error controlado sin modificar nada | "Las tablas ya existen. Ejecute 00_reinicio_entorno.sql…" (sin cambios) |
| C4 | Restricciones, índices y triggers | `02_restricciones_y_reglas.sql` | Sin errores | Sin errores; 5 triggers creados (ver `07_metadatos_resultado.txt`) |
| C5 | Carga de datos semilla | `03_datos_semilla.sql` (pasa por todas las FK, CHECK y triggers) | ≥ 1.000 registros por tabla, sin errores | Sin errores; conteos abajo |
| C6 | Datos reproducibles | Ejecutar el generador dos veces y comparar MD5 | Archivos idénticos | Mismo hash MD5 en ambas ejecuciones |
| C7 | Vistas | `04_vistas.sql` | 3 vistas | Creadas sin errores |
| C8 | Consultas | `05_consultas_negocio.sql` | 10 consultas ejecutan sin error | Sin errores (ver sección 4) |
| C9 | Las pruebas no alteran los datos | Conteos antes y después de `06` | Iguales | Iguales (encuentro 12.289, inscripcion 6.310, integrante_equipo 20.063) |

### Conteo de registros por tabla (C5)

| Tabla | Registros | ¿≥ 1.000? |
|---|---:|:---:|
| disciplina | 1.035 | Sí |
| persona | 9.000 | Sí |
| deportista | 8.000 | Sí |
| entrenador | 1.200 | Sí |
| equipo | 1.200 | Sí |
| entrenador_equipo | 6.490 | Sí |
| integrante_equipo | 20.063 | Sí |
| escenario | 1.100 | Sí |
| torneo | 1.000 | Sí |
| inscripcion | 6.310 | Sí |
| encuentro | 12.289 | Sí |
| participacion_encuentro | 112.506 | Sí |

### Calidad de los datos

| Verificación | Resultado obtenido |
|---|---|
| Referencias huérfanas | Imposibles: todas las FK están activas y la carga no produjo errores |
| Deportistas cuyo sexo no corresponde a la rama de su disciplina | 0 |
| Integrantes en equipos de otra disciplina | 0 |
| Encuentros fuera de las fechas de su torneo | 0 |
| Cruces repetidos en un mismo torneo (todos contra todos a una vuelta) | 0 |
| Escenarios sin encuentros / equipos sin partidos (regla 8) | 285 / 101 |
| Personas que son deportista y entrenador (sin duplicar datos) | 200 |
| Estados de encuentro | FINALIZADO 10.918 · PROGRAMADO 813 · CANCELADO 289 · SUSPENDIDO 269 |

## 2. Pruebas de restricciones y reglas de negocio (SQL Server)

Script: [`scripts/sqlserver/06_pruebas_restricciones.sql`](../scripts/sqlserver/06_pruebas_restricciones.sql)
· Evidencia: [`06_pruebas_restricciones_resultado.txt`](../evidencias/resultados/06_pruebas_restricciones_resultado.txt)

**Cómo se probó:** cada caso es una instrucción `INSERT`, `UPDATE` o `DELETE` que el procedimiento
temporal `#probar` ejecuta dentro de una transacción. Si SQL Server la rechaza se guarda el mensaje de
error; si la acepta, se deshace con `ROLLBACK`. Así las pruebas no cambian los datos y se pueden repetir.
Los casos válidos además comprueban que el `DEFAULT` se aplicó (si no, lanzan un error propio). Los
identificadores usados se buscan con consultas, no se escriben a mano.

**Resultado global: 48 de 48 pruebas PASAN**: 40 casos inválidos que SQL Server rechazó con la
restricción esperada y 8 casos válidos que se aceptaron (incluidas las verificaciones de DEFAULT). La columna *Mecanismo* muestra la restricción o
el trigger que produjo el rechazo, tomado del mensaje real de SQL Server.

| Código | Regla | Prueba | Esperado | Obtenido | Veredicto | Mecanismo que actuó |
|---|---|---|---|---|---|---|
| P01 | Regla 1 - identificador único | Disciplina con código duplicado | RECHAZADO | RECHAZADO | **PASA** | `uq_disciplina_codigo` |
| P02 | Regla 1 - identificador único | Persona con documento duplicado | RECHAZADO | RECHAZADO | **PASA** | `uq_persona_documento` |
| P03 | Regla 1 - identificador único | Persona con correo duplicado | RECHAZADO | RECHAZADO | **PASA** | `uq_persona_correo` |
| P04 | Regla 1 - identificador único | Equipo con código duplicado | RECHAZADO | RECHAZADO | **PASA** | `uq_equipo_codigo` |
| P05 | Regla 1 - identificador único | Misma persona registrada dos veces como deportista | RECHAZADO | RECHAZADO | **PASA** | `uq_deportista_persona` |
| P06 | Inscripciones | Inscribir dos veces el mismo equipo en el mismo torneo | RECHAZADO | RECHAZADO | **PASA** | `uq_inscripcion_torneo_equipo` |
| P07 | Integridad referencial | Deportista con disciplina inexistente (FK) | RECHAZADO | RECHAZADO | **PASA** | `fk_deportista_disciplina` |
| P08 | Integridad referencial | Encuentro con torneo inexistente (FK) | RECHAZADO | RECHAZADO | **PASA** | `fk_encuentro_torneo` |
| P09 | Integridad referencial | Integrante en equipo inexistente (FK) | RECHAZADO | RECHAZADO | **PASA** | `fk_integrante_equipo_equipo` |
| P10 | Integridad referencial | Borrar una disciplina que tiene torneos y deportistas | RECHAZADO | RECHAZADO | **PASA** | `fk_torneo_disciplina` |
| P11 | NOT NULL | Equipo sin nombre | RECHAZADO | RECHAZADO | **PASA** | `NOT NULL` en `nombre` |
| P12 | Regla 4 - capacidad positiva | Escenario con capacidad 0 | RECHAZADO | RECHAZADO | **PASA** | `ck_escenario_capacidad` |
| P13 | Regla 4 - capacidad positiva | Escenario con capacidad negativa | RECHAZADO | RECHAZADO | **PASA** | `ck_escenario_capacidad` |
| P14 | Regla 4 / Regla 8 | Escenario válido (capacidad 500, estado DEFAULT DISPONIBLE, sin encuentros) | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |
| P15 | Regla 4 - fechas coherentes | Torneo con fecha final anterior a la inicial | RECHAZADO | RECHAZADO | **PASA** | `ck_torneo_fechas` |
| P16 | Regla 4 - fechas coherentes | Torneo válido (estado DEFAULT PROGRAMADO) | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |
| P17 | Dominio de estados | Deportista con estado no permitido | RECHAZADO | RECHAZADO | **PASA** | `ck_deportista_estado` |
| P18 | Formato de datos | Correo sin formato válido | RECHAZADO | RECHAZADO | **PASA** | `ck_persona_correo` |
| P19 | Fechas coherentes | Persona con fecha de nacimiento futura | RECHAZADO | RECHAZADO | **PASA** | `ck_persona_fecha_nacimiento` |
| P20 | Valores fuera de rango | Número de camiseta 120 (permitido 0-99) | RECHAZADO | RECHAZADO | **PASA** | `ck_integrante_equipo_camiseta` |
| P21 | Valores fuera de rango | Calificación 11,5 (permitido 0-10) | RECHAZADO | RECHAZADO | **PASA** | `ck_participacion_calificacion` |
| P22 | Regla 2 - vigencia | Asignación con fecha fin anterior a fecha inicio | RECHAZADO | RECHAZADO | **PASA** | `ck_entrenador_equipo_fechas` |
| P23 | Regla 2 - vigencia | Segundo entrenador PRINCIPAL con periodo cruzado en el mismo equipo | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Regla 2: el periodo se cruza con otra asignación (dos entrenadores principales a la vez o el mismo entrenador repetido en el equipo).» |
| P24 | Regla 2 - vigencia | Entrenador ASISTENTE con periodo válido | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |
| P25 | Regla 2 - vigencia | Asignación que empieza antes de la fundación del equipo | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Regla 2: la asignación del entrenador no puede iniciar antes de la fundación del equipo.» |
| P26 | Regla 3 - función y fechas | Deportista con dos periodos cruzados en el mismo equipo | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Regla 3: el deportista ya integra este equipo en un periodo que se cruza con el nuevo.» |
| P27 | Regla 3 - función y fechas | Función no permitida para un integrante | RECHAZADO | RECHAZADO | **PASA** | `ck_integrante_equipo_funcion` |
| P28 | Regla 3 - función y fechas | Participación con fecha fin anterior a fecha inicio | RECHAZADO | RECHAZADO | **PASA** | `ck_integrante_equipo_fechas` |
| P29 | Regla 3 - función y fechas | Nueva participación válida (función RESERVA, vigente) | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |
| P30 | Inscripciones | Inscribir un equipo de otra disciplina | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Inscripción inválida: la disciplina del equipo no coincide con la del torneo.» |
| P31 | Regla 7 - DEFAULT de inscripción | Inscripción válida sin indicar estado queda PENDIENTE | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |
| P32 | Regla 5 - no enfrentarse a sí mismo | Encuentro de un equipo contra sí mismo | RECHAZADO | RECHAZADO | **PASA** | `ck_encuentro_equipos_distintos` |
| P33 | Regla 5 - fechas del torneo | Encuentro con fecha fuera del torneo | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Regla 5: la fecha del encuentro está fuera de las fechas del torneo.» |
| P34 | Regla 5 - participantes válidos | Encuentro con un equipo sin inscripción aprobada | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Regla 5: ambos equipos deben tener inscripción APROBADA en el torneo del encuentro.» |
| P35 | Asignación de escenarios | Dos encuentros en el mismo escenario a la misma fecha y hora | RECHAZADO | RECHAZADO | **PASA** | `uq_encuentro_escenario_fecha` |
| P36 | Regla 5 y Regla 7 - DEFAULT de encuentro | Encuentro válido: queda PROGRAMADO y no definitivo | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |
| P37 | Regla 6 - resultado definitivo | Declarar definitivo un encuentro que no ha finalizado (EN_JUEGO) | RECHAZADO | RECHAZADO | **PASA** | `ck_encuentro_resultado_definitivo` |
| P38 | Regla 6 - resultado definitivo | Declarar definitivo un encuentro PROGRAMADO sin marcador | RECHAZADO | RECHAZADO | **PASA** | `ck_encuentro_resultado_definitivo` |
| P39 | Coherencia de resultados | Registrar marcador a un encuentro PROGRAMADO | RECHAZADO | RECHAZADO | **PASA** | `ck_encuentro_puntajes_segun_estado` |
| P40 | Coherencia de resultados | Marcador incompleto (solo un puntaje) | RECHAZADO | RECHAZADO | **PASA** | `ck_encuentro_puntajes_completos` |
| P41 | Valores fuera de rango | Marcador negativo | RECHAZADO | RECHAZADO | **PASA** | `ck_encuentro_puntajes_no_negativos` |
| P42 | Regla 6 - resultado definitivo | Finalizar el encuentro y declarar el resultado definitivo | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |
| P43 | Regla 6 - resultado definitivo | Modificar el marcador de un resultado ya definitivo | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Regla 6: el resultado del encuentro ya es definitivo y no puede modificarse.» |
| P44 | Regla 5 - participantes válidos | Deportista que no integraba el equipo en la fecha del encuentro | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Participación inválida: el deportista no integraba ese equipo en la fecha del encuentro.» |
| P45 | Regla 5 - participantes válidos | Participación con un equipo que no juega el encuentro | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Participación inválida: el equipo no juega este encuentro.» |
| P46 | Regla 5 - participantes válidos | Participación en un encuentro que aún no se juega | RECHAZADO | RECHAZADO | **PASA** | Trigger: «Participación inválida: el encuentro no se ha jugado (está programado o cancelado).» |
| P47 | Identificador único | Registrar dos veces al mismo deportista en el mismo encuentro | RECHAZADO | RECHAZADO | **PASA** | `uq_participacion_encuentro_deportista` |
| P48 | Regla 8 | Existen escenarios sin encuentros y equipos sin partidos | ACEPTADO | ACEPTADO | **PASA** | Aceptada y revertida con ROLLBACK |

### Cobertura por tipo de prueba solicitada

| Tipo solicitado | Pruebas |
|---|---|
| Restricciones válidas | P14, P16, P24, P29, P31, P36, P42, P48 |
| Claves foráneas inexistentes | P07, P08, P09 (y P10: borrado con dependientes) |
| Valores fuera de rango | P12, P13, P20, P21, P41 |
| Códigos duplicados | P01, P02, P03, P04, P05, P06, P35, P47 |
| Fechas inconsistentes | P15, P19, P22, P25, P26, P28, P33 |
| DEFAULT de estados (regla 7) | P14, P16, P31, P36 |
| Resultado definitivo (regla 6) | P37, P38, P39, P40, P42, P43 |
| Participantes válidos (regla 5) | P32, P34, P44, P45, P46 |

## 3. Pruebas de MongoDB (`perfil_deportivo`)

Script: [`scripts/mongodb/caso_05_funcionalidad.js`](../scripts/mongodb/caso_05_funcionalidad.js)
· Evidencia: [`mongodb_caso_05_resultado.txt`](../evidencias/resultados/mongodb_caso_05_resultado.txt)

| # | Operación | Regla verificada | Esperado | Obtenido |
|---|---|---|---|---|
| M1 | `createCollection` + `$jsonSchema` + índices | Esquema lógico mínimo | Colección e índices creados | Índices `_id_, uq_id_deportista_sql, ix_deporte` |
| M2 | `insertMany` | ≥ 3 documentos coherentes | 5 insertados | 5 insertados |
| M3 | `find` filtro simple, objeto anidado, arreglo (`$elemMatch`) y campo variable (`$exists`) | Consultas con filtro y características documentales | 1, 2, 2 y 3 documentos | 1, 2, 2 y 3 documentos |
| M4 | `insertOne` documento de prueba | Documento controlado (`es_prueba: true`) | Insertado | Insertado |
| M5 | `updateOne` + `findOne` | Actualización verificada | matched 1, modified 1, posición "Primera base" | matched 1, modified 1, verificación CORRECTA |
| M6 | `deleteOne` + `countDocuments` | Borrar solo el documento de prueba | 1 eliminado, quedan 5 | 1 eliminado, ya no aparece, quedan 5 |
| M7 | `insertOne` sin `id_deportista_sql` | Referencia obligatoria a SQL Server | Rechazado | "Document failed validation" |
| M8 | `insertOne` perfil duplicado | Un perfil por deportista | Rechazado (11000) | Rechazado por el índice único |
| M9 | Referencias contra SQL Server | Consistencia entre motores | 5 ids existen en `dbo.deportista` | `referencias_validas = 5` |
| M10 | Ejecutar el script dos veces | Repetible | Misma salida | Salida idéntica |

## 4. Consultas de negocio

Las 10 consultas (13 conjuntos de resultados) se ejecutaron sin errores. Filas obtenidas y su
interpretación: [`consultas_negocio.md`](consultas_negocio.md). Salida completa:
[`05_consultas_negocio_resultado.txt`](../evidencias/resultados/05_consultas_negocio_resultado.txt).

| Consulta | Filas | Comprobación de coherencia |
|---|---:|---|
| 1a / 1b | 70 / 23 | Los 70 lesionados de baloncesto de 1a coinciden con la columna "lesionados" de baloncesto en 1b |
| 2 | 128 | Todas las fechas están entre 2026-10-01 y 2026-10-07 |
| 3 | 11.322 | 978 torneos con encuentros × escenarios usados |
| 4 | 1.200 | Igual al total de equipos (LEFT JOIN conserva los 101 sin partidos) |
| 5 | 10 | Torneo de 5 equipos: 5·4/2 = 10 encuentros |
| 6a / 6b | 285 / 7 | 285 coincide con los escenarios sin encuentros de la verificación de calidad |
| 7 | 101 | Coincide con los equipos sin partidos |
| 8 | 465 | Todos con más de 12,29 encuentros |
| 9 | 3.367 | Todos con más de 16,96 encuentros jugados |
| 10a / 10b | 5 / 1.380 | 882 torneos con líder; 364 con empate en el primer lugar |
