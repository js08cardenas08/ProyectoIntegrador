# Diccionario de datos — Caso 5: Gestión deportiva

Base de datos: **GestionDeportiva** (Microsoft SQL Server). 12 tablas.

> Este diccionario se generó a partir del catálogo real de SQL Server (`scripts/sqlserver/07_metadatos_diccionario.sql`) con `scripts/generador/generar_diccionario_y_relacional.py`; por eso los tipos, longitudes, nulabilidad, DEFAULT y restricciones coinciden exactamente con la implementación. Las descripciones y reglas de negocio se redactaron para el caso.

**Convenciones:** `pk_` clave primaria · `fk_` clave foránea · `uq_` único · `ck_` verificación · `df_` valor por defecto · `tr_` trigger. Todas las PK son `INT IDENTITY(1,1)` (claves sustitutas). Los textos con nombres de personas, lugares o deportes usan `NVARCHAR` para soportar tildes y eñes; los códigos y estados usan `VARCHAR`.

## Resumen de tablas

| # | Tabla | Descripción | Columnas |
|---|---|---|---|
| 1 | [`disciplina`](#disciplina) | Catálogo de disciplinas deportivas. Una disciplina es la combinación de deporte, modalidad, rama y categoría en la que se compite (ej.: Fútbol / Fútbol 11 / FEMENINA / ELITE). | 7 |
| 2 | [`persona`](#persona) | Datos personales comunes a deportistas y entrenadores. Se registran una sola vez aunque la persona cumpla los dos roles (evita duplicar información de personas). | 10 |
| 3 | [`deportista`](#deportista) | Rol de deportista de una persona (subtipo de PERSONA, relación 1:1 opcional). | 5 |
| 4 | [`entrenador`](#entrenador) | Rol de entrenador de una persona (subtipo de PERSONA, relación 1:1 opcional). | 7 |
| 5 | [`equipo`](#equipo) | Equipos de la organización; cada equipo compite en una disciplina. | 7 |
| 6 | [`entrenador_equipo`](#entrenador_equipo) | Asignación de un entrenador a un equipo en un periodo (resuelve la relación M:N DIRIGE y conserva la vigencia). Regla 2. | 6 |
| 7 | [`integrante_equipo`](#integrante_equipo) | Participación de un deportista en un equipo a lo largo del tiempo, con función y fechas (resuelve la relación M:N INTEGRA). Regla 3. | 7 |
| 8 | [`escenario`](#escenario) | Escenarios deportivos donde se juegan los encuentros. Regla 4 (capacidad positiva) y regla 8 (pueden no tener encuentros). | 8 |
| 9 | [`torneo`](#torneo) | Torneos de una disciplina con fechas coherentes. Regla 4. | 7 |
| 10 | [`inscripcion`](#inscripcion) | Inscripción de un equipo en un torneo (resuelve la relación M:N SE INSCRIBE). Regla 7: estado inicial por defecto PENDIENTE. | 5 |
| 11 | [`encuentro`](#encuentro) | Partido entre dos equipos dentro de un torneo, en un escenario, con su marcador (el resultado es 1:1 con el encuentro). Reglas 5, 6 y 7. | 11 |
| 12 | [`participacion_encuentro`](#participacion_encuentro) | Deportistas que jugaron un encuentro con su equipo; base de los reportes de participación y desempeño (resuelve la relación M:N PARTICIPA). | 7 |

## disciplina

Catálogo de disciplinas deportivas. Una disciplina es la combinación de deporte, modalidad, rama y categoría en la que se compite (ej.: Fútbol / Fútbol 11 / FEMENINA / ELITE).

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_disciplina` | Identificador único de la disciplina (sustituto). | INT | No | **PK** | — | IDENTITY(1,1) |
| `codigo` | Código legible: DEPORTE-modalidad-rama-categoría (ej. FUT-1-F-ELI). | VARCHAR(20) | No | — | — | `uq_disciplina_codigo` |
| `deporte` | Nombre del deporte (Fútbol, Baloncesto, Natación…). | NVARCHAR(40) | No | — | — | `uq_disciplina_combinacion` (deporte, modalidad, rama, categoria) |
| `modalidad` | Modalidad del deporte (Fútbol 11, 3x3, Playa, Por equipos…). | NVARCHAR(40) | No | — | — | `uq_disciplina_combinacion` (deporte, modalidad, rama, categoria) |
| `rama` | Rama de competencia: MASCULINA, FEMENINA o MIXTA. | VARCHAR(10) | No | — | — | `ck_disciplina_rama`, `uq_disciplina_combinacion` (deporte, modalidad, rama, categoria) |
| `categoria` | Nivel competitivo: RECREATIVA, AFICIONADA, INTERMEDIA, AVANZADA o ELITE. | VARCHAR(12) | No | — | — | `ck_disciplina_categoria`, `uq_disciplina_combinacion` (deporte, modalidad, rama, categoria) |
| `tipo_participacion` | CONJUNTO (equipos) o INDIVIDUAL. | VARCHAR(10) | No | — | — | `ck_disciplina_tipo` |

**Restricciones de la tabla:**

- `ck_disciplina_categoria` (CHECK): `([categoria]='ELITE' OR [categoria]='AVANZADA' OR [categoria]='INTERMEDIA' OR [categoria]='AFICIONADA' OR [categoria]='RECREATIVA')`
- `ck_disciplina_rama` (CHECK): `([rama]='MIXTA' OR [rama]='FEMENINA' OR [rama]='MASCULINA')`
- `ck_disciplina_tipo` (CHECK): `([tipo_participacion]='INDIVIDUAL' OR [tipo_participacion]='CONJUNTO')`
- `uq_disciplina_codigo` (UNIQUE): `codigo`
- `uq_disciplina_combinacion` (UNIQUE): `deporte, modalidad, rama, categoria`

## persona

Datos personales comunes a deportistas y entrenadores. Se registran una sola vez aunque la persona cumpla los dos roles (evita duplicar información de personas).

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_persona` | Identificador único de la persona (sustituto). | INT | No | **PK** | — | IDENTITY(1,1) |
| `tipo_documento` | Tipo de documento: CC, TI, CE o PAS. | VARCHAR(3) | No | — | — | `ck_persona_tipo_documento`, `uq_persona_documento` (tipo_documento, numero_documento) |
| `numero_documento` | Número del documento (solo dígitos o letras mayúsculas, mínimo 5 caracteres). | VARCHAR(20) | No | — | — | `ck_persona_numero_documento`, `uq_persona_documento` (tipo_documento, numero_documento) |
| `nombres` | Nombres de la persona. | NVARCHAR(60) | No | — | — | — |
| `apellidos` | Apellidos de la persona. | NVARCHAR(60) | No | — | — | — |
| `fecha_nacimiento` | Fecha de nacimiento (entre 1940-01-01 y la fecha actual). | DATE | No | — | — | `ck_persona_fecha_nacimiento` |
| `sexo` | Sexo registrado para efectos de la rama de competencia: F o M. | CHAR(1) | No | — | — | `ck_persona_sexo` |
| `correo` | Correo electrónico de contacto (único, formato texto@dominio.ext). | VARCHAR(100) | No | — | — | `ck_persona_correo`, `uq_persona_correo` |
| `telefono` | Teléfono de contacto (opcional). | VARCHAR(15) | Sí | — | — | — |
| `fecha_registro` | Fecha y hora en que se registró la persona en el sistema. | DATETIME2(0) | No | — | `SYSDATETIME()` | — |

**Restricciones de la tabla:**

- `ck_persona_correo` (CHECK): `([correo] like '%_@_%._%')`
- `ck_persona_fecha_nacimiento` (CHECK): `([fecha_nacimiento]>='1940-01-01' AND [fecha_nacimiento]<=CONVERT([date],getdate()))`
- `ck_persona_numero_documento` (CHECK): `(NOT [numero_documento] like '%[^0-9A-Z]%' AND len([numero_documento])>=(5))`
- `ck_persona_sexo` (CHECK): `([sexo]='M' OR [sexo]='F')`
- `ck_persona_tipo_documento` (CHECK): `([tipo_documento]='PAS' OR [tipo_documento]='CE' OR [tipo_documento]='TI' OR [tipo_documento]='CC')`
- `uq_persona_correo` (UNIQUE): `correo`
- `uq_persona_documento` (UNIQUE): `tipo_documento, numero_documento`

## deportista

Rol de deportista de una persona (subtipo de PERSONA, relación 1:1 opcional).

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_deportista` | Identificador único del deportista. | INT | No | **PK** | — | IDENTITY(1,1) |
| `id_persona` | Persona a la que corresponde el rol de deportista (una persona = un registro de deportista). | INT | No | FK → `persona.id_persona` | — | `uq_deportista_persona` |
| `id_disciplina` | Disciplina principal del deportista. | INT | No | FK → `disciplina.id_disciplina` | — | — |
| `estado` | Estado deportivo: ACTIVO, LESIONADO, SUSPENDIDO o RETIRADO. | VARCHAR(12) | No | — | `'ACTIVO'` | `ck_deportista_estado` |
| `fecha_ingreso` | Fecha de afiliación a la organización. | DATE | No | — | `CAST(GETDATE() AS DATE)` | — |

**Restricciones de la tabla:**

- `ck_deportista_estado` (CHECK): `([estado]='RETIRADO' OR [estado]='SUSPENDIDO' OR [estado]='LESIONADO' OR [estado]='ACTIVO')`
- `uq_deportista_persona` (UNIQUE): `id_persona`

## entrenador

Rol de entrenador de una persona (subtipo de PERSONA, relación 1:1 opcional).

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_entrenador` | Identificador único del entrenador. | INT | No | **PK** | — | IDENTITY(1,1) |
| `id_persona` | Persona a la que corresponde el rol de entrenador. | INT | No | FK → `persona.id_persona` | — | `uq_entrenador_persona` |
| `numero_licencia` | Número de la licencia de entrenador (único). | VARCHAR(20) | No | — | — | `uq_entrenador_licencia` |
| `nivel_licencia` | Nivel de la licencia: BASICO, INTERMEDIO, AVANZADO o PROFESIONAL. | VARCHAR(12) | No | — | — | `ck_entrenador_nivel` |
| `anios_experiencia` | Años de experiencia como entrenador (0 a 60). | TINYINT | No | — | `0` | `ck_entrenador_anios_experiencia` |
| `estado` | Estado del entrenador en la organización: ACTIVO o INACTIVO. | VARCHAR(10) | No | — | `'ACTIVO'` | `ck_entrenador_estado` |
| `fecha_ingreso` | Fecha de vinculación a la organización. | DATE | No | — | `CAST(GETDATE() AS DATE)` | — |

**Restricciones de la tabla:**

- `ck_entrenador_anios_experiencia` (CHECK): `([anios_experiencia]>=(0) AND [anios_experiencia]<=(60))`
- `ck_entrenador_estado` (CHECK): `([estado]='INACTIVO' OR [estado]='ACTIVO')`
- `ck_entrenador_nivel` (CHECK): `([nivel_licencia]='PROFESIONAL' OR [nivel_licencia]='AVANZADO' OR [nivel_licencia]='INTERMEDIO' OR [nivel_licencia]='BASICO')`
- `uq_entrenador_licencia` (UNIQUE): `numero_licencia`
- `uq_entrenador_persona` (UNIQUE): `id_persona`

## equipo

Equipos de la organización; cada equipo compite en una disciplina.

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_equipo` | Identificador único del equipo. | INT | No | **PK** | — | IDENTITY(1,1) |
| `codigo` | Código del equipo (EQ-00001). | VARCHAR(20) | No | — | — | `uq_equipo_codigo` |
| `nombre` | Nombre del equipo (no se repite dentro de la misma disciplina). | NVARCHAR(80) | No | — | — | `uq_equipo_nombre_disciplina` (nombre, id_disciplina) |
| `id_disciplina` | Disciplina en la que compite el equipo. | INT | No | FK → `disciplina.id_disciplina` | — | `uq_equipo_nombre_disciplina` (nombre, id_disciplina) |
| `ciudad` | Ciudad sede del equipo. | NVARCHAR(50) | No | — | — | — |
| `fecha_fundacion` | Fecha de fundación; ninguna asignación de entrenador o deportista puede ser anterior. | DATE | No | — | — | — |
| `estado` | ACTIVO o INACTIVO. | VARCHAR(10) | No | — | `'ACTIVO'` | `ck_equipo_estado` |

**Restricciones de la tabla:**

- `ck_equipo_estado` (CHECK): `([estado]='INACTIVO' OR [estado]='ACTIVO')`
- `uq_equipo_codigo` (UNIQUE): `codigo`
- `uq_equipo_nombre_disciplina` (UNIQUE): `nombre, id_disciplina`

## entrenador_equipo

Asignación de un entrenador a un equipo en un periodo (resuelve la relación M:N DIRIGE y conserva la vigencia). Regla 2.

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_asignacion` | Identificador único de la asignación. | INT | No | **PK** | — | IDENTITY(1,1) |
| `id_entrenador` | Entrenador asignado. | INT | No | FK → `entrenador.id_entrenador` | — | `uq_entrenador_equipo_inicio` (id_entrenador, id_equipo, fecha_inicio) |
| `id_equipo` | Equipo dirigido. | INT | No | FK → `equipo.id_equipo` | — | `uq_entrenador_equipo_inicio` (id_entrenador, id_equipo, fecha_inicio) |
| `rol` | Rol en el cuerpo técnico: PRINCIPAL, ASISTENTE o PREPARADOR_FISICO. | VARCHAR(20) | No | — | `'PRINCIPAL'` | `ck_entrenador_equipo_rol` |
| `fecha_inicio` | Inicio de la vigencia de la asignación. | DATE | No | — | — | `ck_entrenador_equipo_fechas`, `uq_entrenador_equipo_inicio` (id_entrenador, id_equipo, fecha_inicio) |
| `fecha_fin` | Fin de la vigencia; NULL = asignación vigente. | DATE | Sí | — | — | `ck_entrenador_equipo_fechas` |

**Restricciones de la tabla:**

- `ck_entrenador_equipo_fechas` (CHECK): `([fecha_fin] IS NULL OR [fecha_fin]>=[fecha_inicio])`
- `ck_entrenador_equipo_rol` (CHECK): `([rol]='PREPARADOR_FISICO' OR [rol]='ASISTENTE' OR [rol]='PRINCIPAL')`
- `uq_entrenador_equipo_inicio` (UNIQUE): `id_entrenador, id_equipo, fecha_inicio`
- `tr_entrenador_equipo_validar` (TRIGGER AFTER INSERT, UPDATE): Regla 2: la asignación no inicia antes de la fundación del equipo; no hay dos entrenadores PRINCIPALES con periodos cruzados en un equipo ni el mismo entrenador con periodos cruzados en el mismo equipo.

## integrante_equipo

Participación de un deportista en un equipo a lo largo del tiempo, con función y fechas (resuelve la relación M:N INTEGRA). Regla 3.

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_integrante` | Identificador único del periodo de participación. | INT | No | **PK** | — | IDENTITY(1,1) |
| `id_deportista` | Deportista que integra el equipo. | INT | No | FK → `deportista.id_deportista` | — | `uq_integrante_equipo_inicio` (id_deportista, id_equipo, fecha_inicio) |
| `id_equipo` | Equipo que integra. | INT | No | FK → `equipo.id_equipo` | — | `uq_integrante_equipo_inicio` (id_deportista, id_equipo, fecha_inicio) |
| `funcion` | Función en el equipo: CAPITAN, TITULAR, SUPLENTE o RESERVA. | VARCHAR(10) | No | — | `'TITULAR'` | `ck_integrante_equipo_funcion` |
| `numero_camiseta` | Número de camiseta (0 a 99, opcional). | TINYINT | Sí | — | — | `ck_integrante_equipo_camiseta` |
| `fecha_inicio` | Fecha en que empieza a integrar el equipo. | DATE | No | — | — | `ck_integrante_equipo_fechas`, `uq_integrante_equipo_inicio` (id_deportista, id_equipo, fecha_inicio) |
| `fecha_fin` | Fecha en que deja el equipo; NULL = sigue vigente. | DATE | Sí | — | — | `ck_integrante_equipo_fechas` |

**Restricciones de la tabla:**

- `ck_integrante_equipo_camiseta` (CHECK): `([numero_camiseta] IS NULL OR [numero_camiseta]>=(0) AND [numero_camiseta]<=(99))`
- `ck_integrante_equipo_fechas` (CHECK): `([fecha_fin] IS NULL OR [fecha_fin]>=[fecha_inicio])`
- `ck_integrante_equipo_funcion` (CHECK): `([funcion]='RESERVA' OR [funcion]='SUPLENTE' OR [funcion]='TITULAR' OR [funcion]='CAPITAN')`
- `uq_integrante_equipo_inicio` (UNIQUE): `id_deportista, id_equipo, fecha_inicio`
- `tr_integrante_equipo_validar` (TRIGGER AFTER INSERT, UPDATE): Regla 3: la participación no inicia antes de la fundación del equipo; un deportista no tiene dos periodos cruzados en el mismo equipo.

## escenario

Escenarios deportivos donde se juegan los encuentros. Regla 4 (capacidad positiva) y regla 8 (pueden no tener encuentros).

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_escenario` | Identificador único del escenario. | INT | No | **PK** | — | IDENTITY(1,1) |
| `codigo` | Código del escenario (ESC-0001). | VARCHAR(20) | No | — | — | `uq_escenario_codigo` |
| `nombre` | Nombre del escenario (no se repite en la misma ciudad). | NVARCHAR(80) | No | — | — | `uq_escenario_nombre_ciudad` (nombre, ciudad) |
| `tipo` | ESTADIO, COLISEO, CANCHA, PISCINA, PISTA, VELODROMO o GIMNASIO. | VARCHAR(12) | No | — | — | `ck_escenario_tipo` |
| `ciudad` | Ciudad donde está el escenario. | NVARCHAR(50) | No | — | — | `uq_escenario_nombre_ciudad` (nombre, ciudad) |
| `direccion` | Dirección del escenario. | NVARCHAR(100) | No | — | — | — |
| `capacidad` | Capacidad de espectadores (debe ser positiva). | INT | No | — | — | `ck_escenario_capacidad` |
| `estado` | DISPONIBLE, MANTENIMIENTO o INACTIVO. | VARCHAR(15) | No | — | `'DISPONIBLE'` | `ck_escenario_estado` |

**Restricciones de la tabla:**

- `ck_escenario_capacidad` (CHECK): `([capacidad]>(0))`
- `ck_escenario_estado` (CHECK): `([estado]='INACTIVO' OR [estado]='MANTENIMIENTO' OR [estado]='DISPONIBLE')`
- `ck_escenario_tipo` (CHECK): `([tipo]='GIMNASIO' OR [tipo]='VELODROMO' OR [tipo]='PISTA' OR [tipo]='PISCINA' OR [tipo]='CANCHA' OR [tipo]='COLISEO' OR [tipo]='ESTADIO')`
- `uq_escenario_codigo` (UNIQUE): `codigo`
- `uq_escenario_nombre_ciudad` (UNIQUE): `nombre, ciudad`

## torneo

Torneos de una disciplina con fechas coherentes. Regla 4.

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_torneo` | Identificador único del torneo. | INT | No | **PK** | — | IDENTITY(1,1) |
| `codigo` | Código del torneo (TOR-0001). | VARCHAR(20) | No | — | — | `uq_torneo_codigo` |
| `nombre` | Nombre del torneo. | NVARCHAR(100) | No | — | — | — |
| `id_disciplina` | Disciplina del torneo; solo se inscriben equipos de esta disciplina. | INT | No | FK → `disciplina.id_disciplina` | — | — |
| `fecha_inicio` | Fecha de inicio del torneo. | DATE | No | — | — | `ck_torneo_fechas` |
| `fecha_fin` | Fecha de finalización (no anterior a fecha_inicio). | DATE | No | — | — | `ck_torneo_fechas` |
| `estado` | PROGRAMADO, EN_CURSO, FINALIZADO o CANCELADO. | VARCHAR(12) | No | — | `'PROGRAMADO'` | `ck_torneo_estado` |

**Restricciones de la tabla:**

- `ck_torneo_estado` (CHECK): `([estado]='CANCELADO' OR [estado]='FINALIZADO' OR [estado]='EN_CURSO' OR [estado]='PROGRAMADO')`
- `ck_torneo_fechas` (CHECK): `([fecha_fin]>=[fecha_inicio])`
- `uq_torneo_codigo` (UNIQUE): `codigo`

## inscripcion

Inscripción de un equipo en un torneo (resuelve la relación M:N SE INSCRIBE). Regla 7: estado inicial por defecto PENDIENTE.

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_inscripcion` | Identificador único de la inscripción. | INT | No | **PK** | — | IDENTITY(1,1) |
| `id_torneo` | Torneo en el que se inscribe el equipo. | INT | No | FK → `torneo.id_torneo` | — | `uq_inscripcion_torneo_equipo` (id_torneo, id_equipo) |
| `id_equipo` | Equipo inscrito. | INT | No | FK → `equipo.id_equipo` | — | `uq_inscripcion_torneo_equipo` (id_torneo, id_equipo) |
| `fecha_inscripcion` | Fecha de la inscripción (no posterior al fin del torneo). | DATE | No | — | `CAST(GETDATE() AS DATE)` | — |
| `estado` | PENDIENTE (inicial), APROBADA, RECHAZADA o RETIRADA. Solo los equipos APROBADOS pueden jugar. | VARCHAR(10) | No | — | `'PENDIENTE'` | `ck_inscripcion_estado` |

**Restricciones de la tabla:**

- `ck_inscripcion_estado` (CHECK): `([estado]='RETIRADA' OR [estado]='RECHAZADA' OR [estado]='APROBADA' OR [estado]='PENDIENTE')`
- `uq_inscripcion_torneo_equipo` (UNIQUE): `id_torneo, id_equipo`
- `tr_inscripcion_validar` (TRIGGER AFTER INSERT, UPDATE): El equipo debe ser de la misma disciplina del torneo; la inscripción no puede ser posterior al fin del torneo.

## encuentro

Partido entre dos equipos dentro de un torneo, en un escenario, con su marcador (el resultado es 1:1 con el encuentro). Reglas 5, 6 y 7.

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_encuentro` | Identificador único del encuentro. | INT | No | **PK** | — | IDENTITY(1,1) |
| `id_torneo` | Torneo al que pertenece el encuentro. | INT | No | FK → `torneo.id_torneo` | — | — |
| `id_escenario` | Escenario asignado. | INT | No | FK → `escenario.id_escenario` | — | `uq_encuentro_escenario_fecha` (id_escenario, fecha_hora) |
| `id_equipo_local` | Equipo local. | INT | No | FK → `equipo.id_equipo` | — | `ck_encuentro_equipos_distintos` |
| `id_equipo_visitante` | Equipo visitante (distinto del local). | INT | No | FK → `equipo.id_equipo` | — | `ck_encuentro_equipos_distintos` |
| `fecha_hora` | Fecha y hora programada (dentro de las fechas del torneo). | DATETIME2(0) | No | — | — | `uq_encuentro_escenario_fecha` (id_escenario, fecha_hora) |
| `jornada` | Número de jornada o ronda dentro del torneo (mayor que 0). | SMALLINT | No | — | `1` | `ck_encuentro_jornada` |
| `estado` | PROGRAMADO (inicial), EN_JUEGO, FINALIZADO, SUSPENDIDO o CANCELADO. | VARCHAR(12) | No | — | `'PROGRAMADO'` | `ck_encuentro_estado`, `ck_encuentro_puntajes_segun_estado`, `ck_encuentro_resultado_definitivo` |
| `puntaje_local` | Puntos/goles/sets del equipo local; NULL mientras no se juega. | SMALLINT | Sí | — | — | `ck_encuentro_puntajes_completos`, `ck_encuentro_puntajes_no_negativos`, `ck_encuentro_puntajes_segun_estado`, `ck_encuentro_resultado_definitivo` |
| `puntaje_visitante` | Puntos/goles/sets del equipo visitante; NULL mientras no se juega. | SMALLINT | Sí | — | — | `ck_encuentro_puntajes_completos`, `ck_encuentro_puntajes_no_negativos`, `ck_encuentro_puntajes_segun_estado` |
| `resultado_definitivo` | 1 = resultado oficial (homologado); 0 = no definitivo. Solo puede ser 1 si el encuentro está FINALIZADO. | BIT | No | — | `0` | `ck_encuentro_resultado_definitivo` |

**Restricciones de la tabla:**

- `ck_encuentro_equipos_distintos` (CHECK): `([id_equipo_local]<>[id_equipo_visitante])`
- `ck_encuentro_estado` (CHECK): `([estado]='CANCELADO' OR [estado]='SUSPENDIDO' OR [estado]='FINALIZADO' OR [estado]='EN_JUEGO' OR [estado]='PROGRAMADO')`
- `ck_encuentro_jornada` (CHECK): `([jornada]>(0))`
- `ck_encuentro_puntajes_completos` (CHECK): `([puntaje_local] IS NULL AND [puntaje_visitante] IS NULL OR [puntaje_local] IS NOT NULL AND [puntaje_visitante] IS NOT NULL)`
- `ck_encuentro_puntajes_no_negativos` (CHECK): `([puntaje_local]>=(0) AND [puntaje_visitante]>=(0))`
- `ck_encuentro_puntajes_segun_estado` (CHECK): `([estado]='SUSPENDIDO' OR [estado]='FINALIZADO' OR [estado]='EN_JUEGO' OR [puntaje_local] IS NULL AND [puntaje_visitante] IS NULL)`
- `ck_encuentro_resultado_definitivo` (CHECK): `([resultado_definitivo]=(0) OR [estado]='FINALIZADO' AND [puntaje_local] IS NOT NULL)`
- `uq_encuentro_escenario_fecha` (UNIQUE): `id_escenario, fecha_hora`
- `tr_encuentro_validar` (TRIGGER AFTER INSERT, UPDATE): Regla 5: la fecha del encuentro está dentro del torneo y ambos equipos tienen inscripción APROBADA. Regla 6: un resultado definitivo no se puede modificar.

## participacion_encuentro

Deportistas que jugaron un encuentro con su equipo; base de los reportes de participación y desempeño (resuelve la relación M:N PARTICIPA).

| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |
|---|---|---|---|---|---|---|
| `id_participacion` | Identificador único de la participación. | INT | No | **PK** | — | IDENTITY(1,1) |
| `id_encuentro` | Encuentro jugado. | INT | No | FK → `encuentro.id_encuentro` | — | `uq_participacion_encuentro_deportista` (id_encuentro, id_deportista) |
| `id_deportista` | Deportista que jugó. | INT | No | FK → `deportista.id_deportista` | — | `uq_participacion_encuentro_deportista` (id_encuentro, id_deportista) |
| `id_equipo` | Equipo con el que jugó (debe ser el local o el visitante). | INT | No | FK → `equipo.id_equipo` | — | — |
| `es_titular` | 1 = inició como titular; 0 = ingresó como suplente. | BIT | No | — | `1` | — |
| `minutos_jugados` | Minutos jugados (0 a 300); NULL en deportes sin reloj (voleibol, béisbol…). | SMALLINT | Sí | — | — | `ck_participacion_minutos` |
| `calificacion` | Calificación de desempeño del deportista en el encuentro (0,0 a 10,0). | DECIMAL(3,1) | Sí | — | — | `ck_participacion_calificacion` |

**Restricciones de la tabla:**

- `ck_participacion_calificacion` (CHECK): `([calificacion] IS NULL OR [calificacion]>=(0) AND [calificacion]<=(10))`
- `ck_participacion_minutos` (CHECK): `([minutos_jugados] IS NULL OR [minutos_jugados]>=(0) AND [minutos_jugados]<=(300))`
- `uq_participacion_encuentro_deportista` (UNIQUE): `id_encuentro, id_deportista`
- `tr_participacion_validar` (TRIGGER AFTER INSERT, UPDATE): El equipo del deportista juega el encuentro, el encuentro se jugó (EN_JUEGO, FINALIZADO o SUSPENDIDO) y el deportista integraba el equipo en esa fecha.

## Relaciones (claves foráneas)

| Tabla hija | Columna | Tabla padre | Cardinalidad |
|---|---|---|---|
| `deportista` | `id_persona` | `persona` | 1:1 (UNIQUE) |
| `deportista` | `id_disciplina` | `disciplina` | N:1 |
| `entrenador` | `id_persona` | `persona` | 1:1 (UNIQUE) |
| `equipo` | `id_disciplina` | `disciplina` | N:1 |
| `entrenador_equipo` | `id_entrenador` | `entrenador` | N:1 |
| `entrenador_equipo` | `id_equipo` | `equipo` | N:1 |
| `integrante_equipo` | `id_deportista` | `deportista` | N:1 |
| `integrante_equipo` | `id_equipo` | `equipo` | N:1 |
| `torneo` | `id_disciplina` | `disciplina` | N:1 |
| `inscripcion` | `id_torneo` | `torneo` | N:1 |
| `inscripcion` | `id_equipo` | `equipo` | N:1 |
| `encuentro` | `id_torneo` | `torneo` | N:1 |
| `encuentro` | `id_escenario` | `escenario` | N:1 |
| `encuentro` | `id_equipo_local` | `equipo` | N:1 |
| `encuentro` | `id_equipo_visitante` | `equipo` | N:1 |
| `participacion_encuentro` | `id_encuentro` | `encuentro` | N:1 |
| `participacion_encuentro` | `id_deportista` | `deportista` | N:1 |
| `participacion_encuentro` | `id_equipo` | `equipo` | N:1 |
