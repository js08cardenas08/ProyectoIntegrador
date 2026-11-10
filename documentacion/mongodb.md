# MongoDB — colección `perfil_deportivo` (Caso 5)

Script: [`scripts/mongodb/caso_05_funcionalidad.js`](../scripts/mongodb/caso_05_funcionalidad.js)
Evidencia de ejecución: [`evidencias/resultados/mongodb_caso_05_resultado.txt`](../evidencias/resultados/mongodb_caso_05_resultado.txt)

## 1. Qué guarda y por qué en MongoDB

La colección `perfil_deportivo` (base `gestion_deportiva`) guarda **características complementarias y
variables** de cada deportista según su disciplina: posición, categoría, preferencias de entrenamiento,
marcas personales y atributos propios de cada deporte.

Estos datos **no son uniformes**: un futbolista tiene pie dominante y posición; un basquetbolista,
envergadura y mano dominante; un voleibolista, alcance de ataque y de bloqueo; una atleta, posta preferida
y marcas en segundos; un nadador, estilo principal y volumen semanal en km. En SQL Server esto obligaría a:

* una tabla con decenas de columnas casi siempre nulas, o
* una tabla por deporte, o
* un esquema clave–valor difícil de consultar.

En un documento cada perfil tiene solo los campos que le corresponden, con objetos anidados
(`preferencias_entrenamiento`, `medidas`) y arreglos (`marcas_personales`, `posiciones_alternas`). Por eso
se representa mejor como documento complementario.

## 2. Qué sigue siendo responsabilidad de SQL Server

| Información | Dónde vive | Motivo |
|---|---|---|
| Datos personales (documento, nombres, correo) | SQL Server: `persona` | Se registran una sola vez; no se copian a MongoDB |
| Deportistas, estado, disciplina principal | SQL Server: `deportista`, `disciplina` | Registro oficial con PK, FK y CHECK |
| Equipos, integrantes, entrenadores | SQL Server | Relaciones M:N con fechas de vigencia y triggers |
| Torneos, inscripciones, encuentros, resultados, participación | SQL Server | Reglas de negocio (fechas, participantes válidos, resultado definitivo) y consultas de negocio |
| Perfil variable del deportista | **MongoDB: `perfil_deportivo`** | Estructura flexible por deporte |

MongoDB **no** reemplaza ninguna tabla ni se usa para las 10 consultas de negocio.

## 3. Esquema lógico del documento

| Campo | Tipo BSON | Obligatorio | Descripción |
|---|---|---|---|
| `_id` | ObjectId | Sí (automático) | Identificador interno del documento |
| `id_deportista_sql` | int (≥ 1) | **Sí** | Referencia a `dbo.deportista.id_deportista` en SQL Server. Índice **único**: un perfil por deportista |
| `id_disciplina_sql` | int (≥ 1) | No | Referencia a `dbo.disciplina.id_disciplina` (disciplina del perfil) |
| `deporte` | string | **Sí** | Deporte del perfil; indica cómo interpretar los campos variables. Índice `ix_deporte` |
| `fecha_actualizacion` | date | **Sí** | Fecha y hora de la última actualización del perfil |
| `marcas_personales` | array de objetos | No | Cada elemento exige `prueba` (string), `valor` (int/double), `unidad` (string) y `fecha` (date) |
| `preferencias_entrenamiento` | object | No | Ejemplos: `jornada`, `dias_semana` (array), `enfoque` (array), `superficie`, `volumen_semanal_km` |
| `posicion`, `posiciones_alternas` | string / array | No | Deportes de conjunto |
| `categoria`, `categoria_edad` | string | No | Categoría deportiva del perfil |
| Campos variables por deporte | varios | No | `pie_dominante`, `mano_dominante`, `medidas{estatura_cm, envergadura_cm}`, `alcance_ataque_cm`, `alcance_bloqueo_cm`, `especialidad`, `posta_preferida`, `estilo_principal`, `batea`, `lanza`, `restricciones_temporales{tipo, hasta}` |
| `es_prueba` | bool | No | Solo en el documento de prueba controlado, para borrarlo sin tocar los demás |

La colección se crea con un validador `$jsonSchema` (`validationLevel: strict`) que exige la referencia a
SQL Server, el deporte y la fecha de actualización, y valida la estructura de `marcas_personales`. El resto
de campos queda libre a propósito.

### Ejemplo de documento

```json
{
  "id_deportista_sql": 421,
  "id_disciplina_sql": 49,
  "deporte": "Baloncesto",
  "fecha_actualizacion": ISODate("2026-10-28T15:00:00Z"),
  "posicion": "Base",
  "mano_dominante": "izquierda",
  "medidas": { "estatura_cm": 184, "envergadura_cm": 191 },
  "preferencias_entrenamiento": { "jornada": "tarde", "dias_semana": ["martes", "jueves", "sábado"],
                                  "enfoque": ["tiro exterior", "manejo de balón"] },
  "marcas_personales": [ { "prueba": "Salto vertical", "valor": 68, "unidad": "cm", "fecha": ISODate("2026-09-02") } ]
}
```

## 4. Relación con SQL Server y consistencia de referencias

No existe una clave foránea automática entre MongoDB y SQL Server. La consistencia se mantiene así:

1. **Solo se crea un perfil para un deportista que ya existe en SQL Server.** Antes de insertar, la
   aplicación (o quien ejecuta el script) verifica en SQL Server:
   `SELECT id_deportista FROM dbo.deportista WHERE id_deportista = @id;`
2. **Un perfil por deportista:** índice único `uq_id_deportista_sql`.
3. **Tipos y campos obligatorios:** validador `$jsonSchema` (rechaza documentos sin `id_deportista_sql`).
4. **No se borran deportistas en SQL Server:** las FK de SQL impiden borrar un deportista con historial;
   los retiros se manejan con `estado = 'RETIRADO'`, por lo que la referencia de MongoDB no queda huérfana.
5. **Verificación periódica:** el script imprime al final los `id_deportista_sql` existentes para
   comprobarlos en SQL Server. Resultado obtenido:

```sql
SELECT COUNT(*) AS referencias_validas
FROM dbo.deportista WHERE id_deportista IN (1, 421, 1126, 7001, 7041);
-- referencias_validas = 5  (todas existen)
```

Los perfiles usados son coherentes con la disciplina registrada en SQL Server:

| id_deportista_sql | Deportista (SQL) | Disciplina en SQL (`codigo`) |
|---|---|---|
| 1 | Felipe Díaz Quintero | `FUT-1-M-INT` Fútbol 11 masculino intermedia |
| 421 | Óscar Salazar Sánchez | `BAL-1-M-AVA` Baloncesto 5x5 masculino avanzada |
| 1126 | Daniel Cristian García Patiño (estado LESIONADO) | `VOL-1-M-AFI` Voleibol sala masculino aficionada |
| 7001 | Andrea Sara Restrepo Aguilar | `ATL-3-F-AFI` Atletismo relevos femenina aficionada |
| 7041 | Mauricio Diego Rodríguez García | `NAT-3-X-ELI` Natación aguas abiertas mixta élite |
| 2871 | David Mora Peña (documento de **prueba**, se elimina) | `BEI-1-M-AVA` Béisbol masculino avanzada |

## 5. Cómo ejecutar

Requisitos: MongoDB 6 o superior y `mongosh`. Para comprobar las referencias, la base de SQL Server
debe estar cargada (scripts 01–03).

```bash
mongosh "mongodb://localhost:27017" scripts/mongodb/caso_05_funcionalidad.js
```

Con Docker (como se probó en este proyecto):

```bash
docker run -d --name mongocaso5 -p 27017:27017 mongo:7
docker cp scripts/mongodb/caso_05_funcionalidad.js mongocaso5:/tmp/
docker exec mongocaso5 mongosh --quiet /tmp/caso_05_funcionalidad.js
```

El script es repetible: si la colección existe la elimina (solo `perfil_deportivo`) y la vuelve a crear.

## 6. Operaciones demostradas y resultados obtenidos

| Paso | Operación | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| 1 | `createCollection` con `$jsonSchema` + `createIndex` | Colección con índices `uq_id_deportista_sql` e `ix_deporte` | Creada con índices `_id_, uq_id_deportista_sql, ix_deporte` |
| 2 | `insertMany` (5 perfiles) | 5 documentos | 5 insertados, total 5 |
| 3a | `find({deporte: "Fútbol"})` (filtro simple) | Perfil del deportista 1 | 1 documento (id 1, mediocampista central) |
| 3b | `find({"preferencias_entrenamiento.jornada": "mañana"})` (objeto anidado) | Perfiles que entrenan en la mañana | 2 documentos (ids 1 y 7001) |
| 3c | `find({marcas_personales: {$elemMatch: {unidad: "s", valor: {$lt: 13}}}})` (arreglo) | Perfiles con alguna marca < 13 s | 2 documentos (sprint 4,21 s y 100 m en 12,48 s) |
| 3d | `find({posicion: {$exists: true}})` (campo variable) | Solo deportes de conjunto | 3 documentos (fútbol, baloncesto, voleibol) |
| 4 | `insertOne` documento de prueba (`es_prueba: true`) | Documento del deportista 2871 | Insertado |
| 5 | `updateOne` (`$set` posición y fecha, `$push` marca) + `findOne` | posición = "Primera base", 1 marca | matched 1, modified 1, verificación **CORRECTA** |
| 6 | `deleteOne({id_deportista_sql: 2871, es_prueba: true})` + `countDocuments` | 1 eliminado, quedan 5 | 1 eliminado, el documento ya no aparece, quedan 5 |
| 7a | `insertOne` sin `id_deportista_sql` | Rechazo del validador | "Document failed validation" |
| 7b | `insertOne` de un segundo perfil para el deportista 1 | Rechazo del índice único | Error 11000 (duplicado) |
| — | Segunda ejecución completa del script | Mismo resultado | Salida idéntica (script repetible) |
