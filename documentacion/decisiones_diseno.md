# Decisiones de diseño — Caso 5: Gestión deportiva

Este documento explica cómo se pasó del caso de negocio al modelo E-R, del E-R al modelo relacional, cómo
se justificó la normalización hasta 3FN y por qué se tomó cada decisión técnica.

* Diagrama E-R: [`modelo/modelo_er.png`](../modelo/modelo_er.png) (también `.pdf`)
* Diagrama relacional: [`modelo/modelo_relacional.png`](../modelo/modelo_relacional.png) (también `.pdf`)
* Los dos diagramas se hicieron en MySQL Workbench; el modelo editable es
  [`modelo/modelo_gestion_deportiva.mwb`](../modelo/modelo_gestion_deportiva.mwb).
* Diccionario de datos: [`modelo/diccionario_datos.md`](../modelo/diccionario_datos.md) (también en Excel: `modelo/diccionario_datos.xlsx`)

---

## 1. Análisis del caso

> Una organización deportiva administra disciplinas, deportistas, entrenadores, equipos, escenarios,
> torneos y encuentros. Necesita controlar inscripciones, conformación de equipos, asignación de
> escenarios y resultados. Los reportes deben mostrar participación y desempeño **sin duplicar la
> información de personas y competencias**.

De los sustantivos del caso salen las entidades; de los verbos (dirige, integra, se inscribe, juega,
participa) salen las relaciones; de las reglas salen cardinalidades y restricciones.

| Concepto del caso | Decisión en el modelo |
|---|---|
| Disciplinas | Entidad `DISCIPLINA` |
| Deportistas y entrenadores | Superentidad `PERSONA` con dos subtipos `DEPORTISTA` y `ENTRENADOR` (no duplicar personas) |
| Equipos | Entidad `EQUIPO` |
| Escenarios | Entidad `ESCENARIO` |
| Torneos | Entidad `TORNEO` |
| Encuentros y resultados | Entidad `ENCUENTRO` (el marcador es atributo del encuentro) |
| Inscripciones | Relación M:N `SE INSCRIBE` entre `EQUIPO` y `TORNEO` → tabla `inscripcion` |
| Conformación de equipos | Relación M:N `INTEGRA` entre `DEPORTISTA` y `EQUIPO` con función y fechas → tabla `integrante_equipo` |
| Dirección técnica | Relación M:N `DIRIGE` entre `ENTRENADOR` y `EQUIPO` con fechas de vigencia → tabla `entrenador_equipo` |
| Participación y desempeño | Relación M:N `PARTICIPA` entre `DEPORTISTA` y `ENCUENTRO` (con el equipo con el que jugó) → tabla `participacion_encuentro` |

## 2. Modelo entidad-relación

### 2.1 Entidades e identificadores

| Entidad | Identificador (PK) | Identificadores alternos (únicos) | Atributos principales |
|---|---|---|---|
| PERSONA | `id_persona` | (`tipo_documento`, `numero_documento`); `correo` | nombres, apellidos, fecha_nacimiento, sexo, teléfono |
| DEPORTISTA | `id_deportista` | `id_persona` | estado, fecha_ingreso |
| ENTRENADOR | `id_entrenador` | `id_persona`; `numero_licencia` | nivel_licencia, anios_experiencia, estado |
| DISCIPLINA | `id_disciplina` | `codigo`; (deporte, modalidad, rama, categoria) | tipo_participacion |
| EQUIPO | `id_equipo` | `codigo`; (nombre, disciplina) | ciudad, fecha_fundacion, estado |
| ESCENARIO | `id_escenario` | `codigo`; (nombre, ciudad) | tipo, dirección, capacidad, estado |
| TORNEO | `id_torneo` | `codigo` | nombre, fecha_inicio, fecha_fin, estado |
| ENCUENTRO | `id_encuentro` | (escenario, fecha_hora) | jornada, estado, puntajes, resultado_definitivo |

### 2.2 Relaciones, cardinalidad y participación

Notación (mín,máx): cuántas veces participa **cada ocurrencia de la entidad** en la relación.

| Relación | Entidad A (mín,máx) | Entidad B (mín,máx) | Tipo | Lectura |
|---|---|---|---|---|
| ES UN (especialización) | PERSONA | DEPORTISTA (0,1) / ENTRENADOR (0,1) | 1:1 | Una persona puede ser deportista, entrenador, ambos o ninguno (solapada y parcial) |
| PRACTICA | DEPORTISTA (1,1) | DISCIPLINA (0,N) | N:1 | Cada deportista tiene una disciplina principal; una disciplina puede no tener deportistas |
| COMPITE EN | EQUIPO (1,1) | DISCIPLINA (0,N) | N:1 | Cada equipo compite en una disciplina |
| ES DE | TORNEO (1,1) | DISCIPLINA (0,N) | N:1 | Cada torneo es de una disciplina |
| DIRIGE | ENTRENADOR (0,N) | EQUIPO (0,N) | M:N | Un entrenador dirige varios equipos en distintos periodos y un equipo tiene varios entrenadores a lo largo del tiempo |
| INTEGRA | DEPORTISTA (0,N) | EQUIPO (0,N) | M:N | Un deportista integra equipos a lo largo del tiempo; un equipo puede no tener integrantes todavía |
| SE INSCRIBE | EQUIPO (0,N) | TORNEO (0,N) | M:N | Un equipo puede no inscribirse nunca (regla 8) |
| CONTIENE | TORNEO (0,N) | ENCUENTRO (1,1) | 1:N | Cada encuentro pertenece a un torneo (regla 5) |
| ES SEDE DE | ESCENARIO (0,N) | ENCUENTRO (1,1) | 1:N | Cada encuentro usa un escenario; un escenario puede no tener encuentros (regla 8) |
| JUEGA DE LOCAL | EQUIPO (0,N) | ENCUENTRO (1,1) | 1:N | Cada encuentro tiene exactamente un local |
| JUEGA DE VISITANTE | EQUIPO (0,N) | ENCUENTRO (1,1) | 1:N | Cada encuentro tiene exactamente un visitante; un equipo puede no haber jugado (regla 8) |
| PARTICIPA | DEPORTISTA (0,N) | ENCUENTRO (0,N) | M:N | Un deportista juega muchos encuentros; cada participación indica con qué equipo jugó |

**¿Por qué dos relaciones (local y visitante) y no una M:N "equipo juega encuentro"?** Porque cada
encuentro tiene **exactamente dos** participantes con papeles distintos. Con dos FK en `encuentro` se puede
exigir con un simple `CHECK` que el local sea distinto del visitante (regla 5) y el marcador queda en la
misma fila. Una tabla intermedia permitiría encuentros con 1 o 3 equipos y obligaría a usar triggers para
algo que un `CHECK` resuelve.

### 2.3 Resolución de las relaciones muchos a muchos

| Relación M:N | Tabla asociativa | Atributos propios | Por qué tiene PK sustituta |
|---|---|---|---|
| DIRIGE | `entrenador_equipo` | rol, fecha_inicio, fecha_fin | El mismo entrenador puede volver al mismo equipo en otro periodo, así que (entrenador, equipo) **no** es único. Se usa `id_asignacion` y `UNIQUE (id_entrenador, id_equipo, fecha_inicio)` |
| INTEGRA | `integrante_equipo` | funcion, numero_camiseta, fecha_inicio, fecha_fin | Igual: un deportista puede salir y regresar al equipo. `UNIQUE (id_deportista, id_equipo, fecha_inicio)` |
| SE INSCRIBE | `inscripcion` | fecha_inscripcion, estado | (torneo, equipo) sí es único: `UNIQUE (id_torneo, id_equipo)` |
| PARTICIPA | `participacion_encuentro` | id_equipo, es_titular, minutos_jugados, calificacion | `UNIQUE (id_encuentro, id_deportista)` |

Se eligieron PK sustitutas `INT IDENTITY` en todas las tablas para que las FK sean cortas y simples de
explicar; las claves naturales se protegen con `UNIQUE`.

## 3. Modelo relacional

```
disciplina (id_disciplina PK, codigo UQ, deporte, modalidad, rama, categoria, tipo_participacion)
           UQ(deporte, modalidad, rama, categoria)
persona    (id_persona PK, tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento,
            sexo, correo UQ, telefono, fecha_registro)   UQ(tipo_documento, numero_documento)
deportista (id_deportista PK, id_persona FK UQ → persona, id_disciplina FK → disciplina, estado, fecha_ingreso)
entrenador (id_entrenador PK, id_persona FK UQ → persona, numero_licencia UQ, nivel_licencia,
            anios_experiencia, estado, fecha_ingreso)
equipo     (id_equipo PK, codigo UQ, nombre, id_disciplina FK → disciplina, ciudad, fecha_fundacion, estado)
            UQ(nombre, id_disciplina)
entrenador_equipo (id_asignacion PK, id_entrenador FK → entrenador, id_equipo FK → equipo, rol,
                   fecha_inicio, fecha_fin)   UQ(id_entrenador, id_equipo, fecha_inicio)
integrante_equipo (id_integrante PK, id_deportista FK → deportista, id_equipo FK → equipo, funcion,
                   numero_camiseta, fecha_inicio, fecha_fin)   UQ(id_deportista, id_equipo, fecha_inicio)
escenario  (id_escenario PK, codigo UQ, nombre, tipo, ciudad, direccion, capacidad, estado)  UQ(nombre, ciudad)
torneo     (id_torneo PK, codigo UQ, nombre, id_disciplina FK → disciplina, fecha_inicio, fecha_fin, estado)
inscripcion (id_inscripcion PK, id_torneo FK → torneo, id_equipo FK → equipo, fecha_inscripcion, estado)
            UQ(id_torneo, id_equipo)
encuentro  (id_encuentro PK, id_torneo FK → torneo, id_escenario FK → escenario,
            id_equipo_local FK → equipo, id_equipo_visitante FK → equipo, fecha_hora, jornada, estado,
            puntaje_local, puntaje_visitante, resultado_definitivo)   UQ(id_escenario, fecha_hora)
participacion_encuentro (id_participacion PK, id_encuentro FK → encuentro, id_deportista FK → deportista,
            id_equipo FK → equipo, es_titular, minutos_jugados, calificacion)  UQ(id_encuentro, id_deportista)
```

Regla de transformación aplicada: cada entidad → tabla; cada relación 1:N → FK en el lado N; cada relación
M:N → tabla asociativa con dos FK y los atributos de la relación; la especialización → una tabla por subtipo
con FK `UNIQUE` hacia la superentidad (así se garantiza el 1:1).

## 4. Normalización

### Primera forma normal (1FN)
Todos los atributos son atómicos y no hay grupos repetidos:

* Nombres y apellidos están separados; el documento se divide en `tipo_documento` y `numero_documento`.
* Los integrantes de un equipo **no** se guardan como lista dentro de `equipo` (por ejemplo,
  "jugador1, jugador2…"); cada integración es una fila de `integrante_equipo`.
* Los dos equipos de un encuentro son dos columnas con significado distinto (local y visitante), no un
  grupo repetido: siempre son exactamente dos y cumplen papeles diferentes.
* Los atributos multivaluados y variables por deporte (marcas personales, preferencias de entrenamiento)
  se dejaron fuera del modelo relacional y se guardan en MongoDB (`perfil_deportivo`).

### Segunda forma normal (2FN)
Todas las tablas tienen PK de **una sola columna**, por lo que no puede haber dependencias parciales de una
parte de la clave. Además se revisaron las claves candidatas compuestas:

* En `inscripcion` (clave candidata `id_torneo, id_equipo`) los atributos `fecha_inscripcion` y `estado`
  dependen de la combinación completa, no solo del torneo o solo del equipo. El nombre del equipo o las fechas
  del torneo **no** se copian aquí (dependerían solo de una parte).
* En `participacion_encuentro` (clave candidata `id_encuentro, id_deportista`) los minutos y la calificación
  dependen del deportista **en ese encuentro**. La fecha del encuentro o el nombre del deportista no se
  repiten aquí.

### Tercera forma normal (3FN)
No hay dependencias transitivas (atributos no clave que dependan de otro atributo no clave):

| Posible redundancia | Decisión |
|---|---|
| Nombre, documento y correo de deportistas y entrenadores | Se guardan **una sola vez** en `persona`; `deportista` y `entrenador` solo tienen sus atributos propios. 200 personas de los datos semilla son a la vez deportistas y entrenadores sin duplicar sus datos |
| Nombre de la disciplina o del deporte en `equipo`, `torneo` o `deportista` | Solo se guarda `id_disciplina`; el deporte, la modalidad, la rama y la categoría se obtienen con JOIN |
| Disciplina del encuentro | No se guarda en `encuentro`: se deduce de `torneo.id_disciplina` (guardarla crearía la dependencia id_encuentro → id_torneo → id_disciplina) |
| Ciudad o capacidad del escenario en `encuentro` | Solo `id_escenario` |
| Nombre de la disciplina (deporte + modalidad + rama + categoría) | No se almacena como columna: es un dato derivado que se arma en las consultas |
| Victorias, derrotas, empates, puntos de cada equipo | **No se almacenan**: se calculan con la vista `vw_resultado_equipo`. Guardarlos causaría inconsistencias cuando cambia un resultado |
| Edad del deportista | No se almacena (cambia con el tiempo); se calcula en `vw_deportista_detalle` desde `fecha_nacimiento` |
| Ganador del encuentro | Se deduce comparando `puntaje_local` y `puntaje_visitante` |

**Caso discutido — `participacion_encuentro.id_equipo`:** podría pensarse que es redundante porque el
equipo del deportista se puede buscar en `integrante_equipo`. Se conserva porque es un dato propio del hecho
"jugó este encuentro con este equipo" (un deportista puede integrar varios equipos a lo largo del tiempo) y
porque el trigger `tr_participacion_validar` comprueba que sea coherente: el equipo debe ser el local o el
visitante y el deportista debía integrarlo en la fecha del encuentro. Así no hay contradicciones.

**Caso discutido — `disciplina.deporte` como texto:** el deporte se repite en las filas de sus
disciplinas (23 deportes en 1.035 disciplinas). Se dejó como atributo porque cada disciplina es una
combinación única y el deporte no tiene atributos propios en este caso; separar una tabla `deporte` no
eliminaría ninguna dependencia transitiva relevante y, además, el documento exige 1.000 registros por
tabla, lo que obligaría a inventar deportes. Si en el futuro el deporte tuviera atributos propios
(reglamento, federación), se crearía la tabla `deporte` y `disciplina` pasaría a tener una FK.
