# Decisiones de diseño — Caso 5: Gestión deportiva

Este documento explica cómo se pasó del caso de negocio al modelo E-R, del E-R al modelo relacional, cómo
se justificó la normalización hasta 3FN y por qué se tomó cada decisión técnica.

* Diagrama E-R: [`diagramas/er/modelo_er.png`](../diagramas/er/modelo_er.png) (también `.pdf`, `.svg` y fuente `.dot`)
* Diagrama relacional: [`diagramas/relacional/modelo_relacional.png`](../diagramas/relacional/modelo_relacional.png)
* Diccionario de datos: [`diccionario_datos.md`](diccionario_datos.md)
* Reglas de negocio y cómo se implementan: [`reglas_negocio.md`](reglas_negocio.md)

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

## 5. Decisiones técnicas

| Decisión | Justificación |
|---|---|
| **Especialización PERSONA → DEPORTISTA / ENTRENADOR** | Cumple "sin duplicar la información de personas": una persona que es deportista y entrenador tiene un solo documento, correo y nombre. `UNIQUE (id_persona)` en cada subtipo asegura el 1:1 |
| **Marcador dentro de `encuentro`** | El resultado es 1:1 con el encuentro. Así la regla 6 se resuelve con un `CHECK` de la misma fila: `resultado_definitivo = 0 OR (estado = 'FINALIZADO' AND puntaje_local IS NOT NULL)` |
| **`resultado_definitivo` separado de `estado`** | Un encuentro puede estar FINALIZADO pero con el resultado pendiente de homologación. Las estadísticas (consultas 4 y 10) solo cuentan resultados definitivos |
| **DEFAULT documentados (regla 7)** | `inscripcion.estado = 'PENDIENTE'`, `encuentro.estado = 'PROGRAMADO'`, `encuentro.resultado_definitivo = 0`, `torneo.estado = 'PROGRAMADO'`, `deportista.estado = 'ACTIVO'`, `escenario.estado = 'DISPONIBLE'` |
| **Estados con `CHECK ... IN (...)` en vez de tablas de estados** | Son listas cortas y estables; un CHECK es más simple de explicar. Una tabla catálogo de estados obligaría además a cargar 1.000 registros sin sentido |
| **`fecha_fin` NULL = vigente** | Permite saber quién está activo hoy (`fecha_fin IS NULL`) y conservar el historial completo (reglas 2 y 3) |
| **Triggers para reglas entre filas** | Un `CHECK` solo ve la fila que se inserta. Para comparar con otras filas (solapamiento de periodos, fechas del torneo, inscripción aprobada, integrante vigente) se usan triggers `AFTER INSERT, UPDATE` que lanzan `THROW` y deshacen la operación. Se nombran `tr_<tabla>_validar` |
| **`UNIQUE (id_escenario, fecha_hora)`** | Evita asignar dos encuentros al mismo escenario a la misma hora (asignación de escenarios) con una restricción simple |
| **FK sin `ON DELETE CASCADE`** | Se prefiere impedir el borrado de datos con historial (por ejemplo, una disciplina con torneos). Los retiros se manejan con columnas `estado` |
| **Índices en columnas FK** | SQL Server no crea índices para las FK; se agregaron en las columnas usadas en JOIN y filtros |
| **`NVARCHAR` para textos con tildes** | Nombres de personas, ciudades y deportes (Muñoz, Bogotá, Fútbol). Códigos y estados en `VARCHAR` |
| **Nombres de restricciones explícitos** | Los mensajes de error indican exactamente qué regla falló (`ck_escenario_capacidad`, etc.), útil en pruebas y en la sustentación |
| **Scripts separados por responsabilidad** | 00 reinicio, 01 tablas, 02 restricciones y triggers, 03 datos, 04 vistas, 05 consultas, 06 pruebas, 07 metadatos |

## 6. Estrategia de datos semilla

* Los datos se generan con [`scripts/generador/generar_datos_semilla.py`](../scripts/generador/generar_datos_semilla.py)
  con semilla fija (`random.seed(2026)`) y fecha de referencia 2026-11-01. Ejecutarlo dos veces produce
  exactamente el mismo `03_datos_semilla.sql` (verificado con hash MD5).
* El script SQL usa `IDENTITY_INSERT` para que los identificadores (y por lo tanto las FK) sean iguales en
  cualquier servidor.
* El generador respeta las reglas: periodos de entrenadores e integrantes sin cruces, membresías después de
  la fundación del equipo, sexo coherente con la rama, encuentros dentro de las fechas del torneo y solo
  entre equipos con inscripción aprobada (calendario todos contra todos), marcadores coherentes con cada
  deporte (en voleibol no hay empates, en baloncesto siempre hay ganador), resultados definitivos solo en
  encuentros finalizados y participaciones solo de integrantes vigentes. Aun así, la carga pasa por todas
  las restricciones y triggers de SQL Server, que habrían rechazado cualquier dato inválido.
* No se repiten filas artificialmente: las 1.035 disciplinas son combinaciones distintas de deporte,
  modalidad, rama y categoría; los nombres, documentos y correos son ficticios (dominio reservado
  `.example`).
* Se dejan casos para demostrar la regla 8: 285 escenarios sin encuentros y 101 equipos sin partidos.

| Tabla | Registros |
|---|---:|
| disciplina | 1.035 |
| persona | 9.000 |
| deportista | 8.000 |
| entrenador | 1.200 |
| equipo | 1.200 |
| entrenador_equipo | 6.490 |
| integrante_equipo | 20.063 |
| escenario | 1.100 |
| torneo | 1.000 |
| inscripcion | 6.310 |
| encuentro | 12.289 |
| participacion_encuentro | 112.506 |

## 7. Limitaciones conocidas (documentadas a propósito)

* Si se cambian las fechas de un torneo después de crear sus encuentros, o las fechas de un integrante
  después de registrar sus participaciones, los triggers de `encuentro` y `participacion_encuentro` no se
  vuelven a ejecutar. En la operación normal esas fechas no se editan; si se necesitara, se agregaría un
  trigger en `torneo` e `integrante_equipo` con la misma comprobación.
* No se valida que un deportista esté en un solo equipo a la vez dentro de la misma disciplina, porque en
  la práctica un deportista puede estar en un club y en una selección simultáneamente. Sí se impide que
  tenga dos periodos cruzados en el **mismo** equipo.
* La consistencia entre MongoDB y SQL Server se mantiene por procedimiento (ver [`mongodb.md`](mongodb.md)),
  porque no existe una FK entre motores.
