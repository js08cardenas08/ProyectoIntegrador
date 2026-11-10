# Reglas de negocio — Caso 5: Gestión deportiva

Cada regla del documento oficial, el mecanismo que la implementa en SQL Server y las pruebas que la
verifican (ver [`pruebas.md`](pruebas.md) y [`06_pruebas_restricciones.sql`](../scripts/sqlserver/06_pruebas_restricciones.sql)).

| # | Regla del caso | Mecanismo de implementación | Tipo | Pruebas |
|---|---|---|---|---|
| 1 | Registrar disciplinas, deportistas, entrenadores y equipos con identificadores únicos | PK `IDENTITY` en todas las tablas; `uq_disciplina_codigo`, `uq_disciplina_combinacion`, `uq_persona_documento`, `uq_persona_correo`, `uq_deportista_persona`, `uq_entrenador_persona`, `uq_entrenador_licencia`, `uq_equipo_codigo`, `uq_equipo_nombre_disciplina` | PK + UNIQUE | P01–P05 |
| 2 | Un entrenador puede dirigir equipos en distintos periodos; conservar fechas de vigencia | Tabla `entrenador_equipo` (M:N con `fecha_inicio`, `fecha_fin`; NULL = vigente); `ck_entrenador_equipo_fechas` (fin ≥ inicio); `uq_entrenador_equipo_inicio`; trigger `tr_entrenador_equipo_validar`: no hay dos PRINCIPALES cruzados en un equipo, el mismo entrenador no se cruza consigo mismo en el equipo y no inicia antes de la fundación | Tabla asociativa + CHECK + UNIQUE + trigger | P22–P25 |
| 3 | Un deportista puede integrar equipos a lo largo del tiempo; registrar función y fechas | Tabla `integrante_equipo` con `funcion` (`ck_integrante_equipo_funcion`), `fecha_inicio`, `fecha_fin` (`ck_integrante_equipo_fechas`); trigger `tr_integrante_equipo_validar` (sin periodos cruzados en el mismo equipo, no antes de la fundación) | Tabla asociativa + CHECK + trigger | P20, P26–P29 |
| 4 | Escenarios con capacidad positiva y torneos con fechas coherentes | `ck_escenario_capacidad` (`capacidad > 0`); `ck_torneo_fechas` (`fecha_fin >= fecha_inicio`) | CHECK | P12–P16 |
| 5 | Cada encuentro pertenece a un torneo, usa un escenario y tiene participantes válidos; un equipo no puede enfrentarse a sí mismo | FK `NOT NULL` a `torneo`, `escenario`, `equipo` (local y visitante); `ck_encuentro_equipos_distintos`; trigger `tr_encuentro_validar` (fecha dentro del torneo y ambos equipos con inscripción `APROBADA`); `uq_encuentro_escenario_fecha` (escenario no asignado dos veces a la misma hora); trigger `tr_participacion_validar` (el deportista jugó con un equipo del encuentro y lo integraba en esa fecha) | FK + CHECK + UNIQUE + triggers | P08, P32–P36, P44–P47 |
| 6 | Los resultados solo pueden declararse definitivos cuando el encuentro haya finalizado | Columna `resultado_definitivo` (BIT); `ck_encuentro_resultado_definitivo`: `resultado_definitivo = 0 OR (estado = 'FINALIZADO' AND puntaje_local IS NOT NULL)`; `ck_encuentro_puntajes_completos`, `ck_encuentro_puntajes_segun_estado`, `ck_encuentro_puntajes_no_negativos`; trigger `tr_encuentro_validar` impide modificar un resultado ya definitivo | CHECK + trigger | P37–P43 |
| 7 | El estado inicial de una inscripción o encuentro tiene DEFAULT documentado | `df_inscripcion_estado = 'PENDIENTE'`; `df_encuentro_estado = 'PROGRAMADO'`; `df_encuentro_resultado_definitivo = 0`. También: `df_torneo_estado = 'PROGRAMADO'`, `df_deportista_estado = 'ACTIVO'`, `df_escenario_estado = 'DISPONIBLE'`, `df_entrenador_estado = 'ACTIVO'`, `df_equipo_estado = 'ACTIVO'` | DEFAULT | P14, P16, P31, P36 |
| 8 | Permitir escenarios sin encuentros y equipos sin partidos jugados | Las FK están en `encuentro` (lado N) y no hay ninguna FK obligatoria desde `escenario` o `equipo` hacia `encuentro`; participación (0,N). Datos semilla con 285 escenarios sin encuentros y 101 equipos sin partidos. Consultas 6 y 7 los listan | Diseño de cardinalidad | P14, P48 |

## Reglas adicionales derivadas del caso

| Regla | Mecanismo | Pruebas |
|---|---|---|
| Una inscripción solo puede ser de un equipo de la misma disciplina del torneo, y no posterior a su fin | Trigger `tr_inscripcion_validar` | P30 |
| Un equipo no se inscribe dos veces en el mismo torneo | `uq_inscripcion_torneo_equipo` | P06 |
| Un deportista no se registra dos veces en el mismo encuentro | `uq_participacion_encuentro_deportista` | P47 |
| Estados con valores válidos | `ck_*_estado` en deportista, entrenador, equipo, escenario, torneo, inscripción y encuentro | P17 |
| Datos con formato y rango válido | `ck_persona_correo`, `ck_persona_fecha_nacimiento`, `ck_persona_numero_documento`, `ck_integrante_equipo_camiseta` (0–99), `ck_participacion_minutos` (0–300), `ck_participacion_calificacion` (0–10), `ck_entrenador_anios_experiencia` (0–60) | P18–P21 |
| No se borran datos con historial | FK sin `ON DELETE CASCADE` | P10 |

## Por qué algunas reglas usan triggers

El documento pide no afirmar que un `CHECK` valida otras filas. Un `CHECK` en SQL Server solo evalúa los
valores **de la fila** que se inserta o actualiza. Las reglas que comparan con otras filas o tablas se
implementan con triggers `AFTER INSERT, UPDATE`:

| Trigger | Qué compara con otras filas |
|---|---|
| `tr_entrenador_equipo_validar` | Otras asignaciones del mismo equipo (solapamiento de periodos) y la fecha de fundación en `equipo` |
| `tr_integrante_equipo_validar` | Otros periodos del mismo deportista en el mismo equipo y la fundación del equipo |
| `tr_inscripcion_validar` | La disciplina del equipo contra la del torneo y la fecha fin del torneo |
| `tr_encuentro_validar` | Las fechas del torneo, las inscripciones aprobadas y el valor anterior del resultado (tabla `deleted`) |
| `tr_participacion_validar` | Los equipos y el estado del encuentro y los periodos de `integrante_equipo` |

Funcionamiento: cada trigger busca filas de `inserted` que incumplen la regla con `IF EXISTS (...)`; si
encuentra alguna ejecuta `THROW` con un mensaje en español. El error deshace toda la instrucción (también
cuando se insertan muchas filas a la vez, porque las comprobaciones son por conjuntos, no fila a fila).
