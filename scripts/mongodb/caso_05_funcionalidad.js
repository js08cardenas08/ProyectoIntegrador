/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   MongoDB - colección perfil_deportivo
   ---------------------------------------------------------------------
   Guarda características COMPLEMENTARIAS y VARIABLES de un deportista
   según su disciplina (posición, categoría, preferencias de entrenamiento,
   marcas personales, atributos propios de cada deporte).
   Los registros oficiales (deportistas, equipos, torneos, encuentros y
   resultados) siguen en SQL Server, base GestionDeportiva.

   Ejecución:
       mongosh "mongodb://localhost:27017" scripts/mongodb/caso_05_funcionalidad.js

   Pasos: 1) crear colección con validación  2) insertMany (5 documentos)
          3) find con filtros  4) insertOne del documento de prueba
          5) updateOne + verificación  6) deleteOne del documento de prueba
          + verificación  7) intento de documento inválido (validador)

   Todos los datos son sintéticos. Los valores de id_deportista_sql
   existen en dbo.deportista porque los datos semilla de SQL Server son
   reproducibles (semilla 2026).
   ===================================================================== */

const baseDatos = db.getSiblingDB("gestion_deportiva");
const NOMBRE = "perfil_deportivo";

function titulo(texto) {
  print("\n==================================================================");
  print(texto);
  print("==================================================================");
}

/* ---------------------------------------------------------------------
   1. CREACIÓN DE LA COLECCIÓN
   Reinicio controlado: solo se elimina ESTA colección del proyecto para
   que el script se pueda ejecutar varias veces con el mismo resultado.
   --------------------------------------------------------------------- */
titulo("1. Creación de la colección perfil_deportivo");
if (baseDatos.getCollectionNames().includes(NOMBRE)) {
  print("La colección ya existía: se elimina para reconstruirla (solo perfil_deportivo).");
  baseDatos.getCollection(NOMBRE).drop();
}

// Validación mínima: campos obligatorios y tipos de la referencia y la fecha.
// El resto de campos es libre (estructura flexible según disciplina).
baseDatos.createCollection(NOMBRE, {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_deportista_sql", "deporte", "fecha_actualizacion"],
      properties: {
        id_deportista_sql: {
          bsonType: "int", minimum: 1,
          description: "Referencia obligatoria a dbo.deportista.id_deportista (SQL Server)"
        },
        id_disciplina_sql: {
          bsonType: "int", minimum: 1,
          description: "Referencia a dbo.disciplina.id_disciplina (SQL Server)"
        },
        deporte: { bsonType: "string", description: "Deporte, usado para interpretar los campos variables" },
        fecha_actualizacion: { bsonType: "date", description: "Fecha de la última actualización del perfil" },
        marcas_personales: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["prueba", "valor", "unidad", "fecha"],
            properties: {
              prueba: { bsonType: "string" },
              valor: { bsonType: ["double", "int"] },
              unidad: { bsonType: "string" },
              fecha: { bsonType: "date" }
            }
          }
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

const perfiles = baseDatos.getCollection(NOMBRE);
// Un perfil por deportista y búsqueda rápida por deporte
perfiles.createIndex({ id_deportista_sql: 1 }, { unique: true, name: "uq_id_deportista_sql" });
perfiles.createIndex({ deporte: 1 }, { name: "ix_deporte" });
print("Colección creada con validador $jsonSchema e índices: " +
      perfiles.getIndexes().map(i => i.name).join(", "));

/* ---------------------------------------------------------------------
   2. INSERCIÓN (insertMany): 5 perfiles sintéticos coherentes con SQL
   Cada deporte tiene campos distintos: eso es lo que justifica MongoDB.
   --------------------------------------------------------------------- */
titulo("2. insertMany: perfiles deportivos");
const resultadoInsercion = perfiles.insertMany([
  {
    id_deportista_sql: 1,                 // Felipe Díaz Quintero - Fútbol 11 Masculino Intermedia
    id_disciplina_sql: 3,
    deporte: "Fútbol",
    fecha_actualizacion: new Date("2026-10-20T09:30:00Z"),
    posicion: "Mediocampista central",
    posiciones_alternas: ["Volante de marca", "Lateral derecho"],
    pie_dominante: "derecho",
    categoria: "Intermedia",
    preferencias_entrenamiento: {
      jornada: "mañana",
      dias_semana: ["lunes", "miércoles", "viernes"],
      enfoque: ["resistencia aeróbica", "pase largo"]
    },
    marcas_personales: [
      { prueba: "Test de Cooper", valor: 3150, unidad: "m", fecha: new Date("2026-08-14") },
      { prueba: "Sprint 30 m", valor: 4.21, unidad: "s", fecha: new Date("2026-08-14") }
    ]
  },
  {
    id_deportista_sql: 421,               // Óscar Salazar Sánchez - Baloncesto 5x5 Masculino Avanzada
    id_disciplina_sql: 49,
    deporte: "Baloncesto",
    fecha_actualizacion: new Date("2026-10-28T15:00:00Z"),
    posicion: "Base",
    mano_dominante: "izquierda",
    medidas: { estatura_cm: 184, envergadura_cm: 191 },
    preferencias_entrenamiento: {
      jornada: "tarde",
      dias_semana: ["martes", "jueves", "sábado"],
      enfoque: ["tiro exterior", "manejo de balón"]
    },
    marcas_personales: [
      { prueba: "Salto vertical", valor: 68, unidad: "cm", fecha: new Date("2026-09-02") },
      { prueba: "Tiros libres consecutivos", valor: 27, unidad: "aciertos", fecha: new Date("2026-09-02") }
    ]
  },
  {
    id_deportista_sql: 1126,              // Daniel Cristian García Patiño - Voleibol Sala Masculino Aficionada
    id_disciplina_sql: 92,
    deporte: "Voleibol",
    fecha_actualizacion: new Date("2026-10-05T11:15:00Z"),
    posicion: "Opuesto",
    alcance_ataque_cm: 331,
    alcance_bloqueo_cm: 312,
    restricciones_temporales: { tipo: "carga reducida", hasta: new Date("2026-11-30") },
    preferencias_entrenamiento: { jornada: "noche", enfoque: ["técnica de bloqueo"] }
  },
  {
    id_deportista_sql: 7001,              // Andrea Sara Restrepo Aguilar - Atletismo Relevos Femenina Aficionada
    id_disciplina_sql: 712,
    deporte: "Atletismo",
    fecha_actualizacion: new Date("2026-09-18T08:00:00Z"),
    especialidad: "velocidad",
    posta_preferida: 2,
    preferencias_entrenamiento: {
      jornada: "mañana",
      superficie: "pista sintética",
      enfoque: ["salida de tacos", "entrega del testigo"]
    },
    marcas_personales: [
      { prueba: "100 m planos", valor: 12.48, unidad: "s", fecha: new Date("2026-07-12") },
      { prueba: "200 m planos", valor: 25.91, unidad: "s", fecha: new Date("2026-06-21") }
    ]
  },
  {
    id_deportista_sql: 7041,              // Mauricio Diego Rodríguez García - Natación Aguas abiertas Mixta Élite
    id_disciplina_sql: 765,
    deporte: "Natación",
    fecha_actualizacion: new Date("2026-10-30T07:45:00Z"),
    estilo_principal: "libre",
    categoria_edad: "Mayores",
    preferencias_entrenamiento: {
      jornada: "madrugada",
      volumen_semanal_km: 42,
      enfoque: ["fondo", "navegación en mar abierto"]
    },
    marcas_personales: [
      { prueba: "5 km aguas abiertas", valor: 61.35, unidad: "min", fecha: new Date("2026-05-09") },
      { prueba: "1500 m libre", valor: 17.42, unidad: "min", fecha: new Date("2026-03-15") }
    ]
  }
]);
print("Documentos insertados: " + Object.keys(resultadoInsercion.insertedIds).length);
print("Total en la colección: " + perfiles.countDocuments());

/* ---------------------------------------------------------------------
   3. CONSULTAS (find) CON FILTROS
   --------------------------------------------------------------------- */
titulo("3a. find con filtro simple: perfiles de Fútbol");
printjson(perfiles.find(
  { deporte: "Fútbol" },
  { _id: 0, id_deportista_sql: 1, deporte: 1, posicion: 1, pie_dominante: 1 }
).toArray());

titulo("3b. find sobre objeto anidado: prefieren entrenar en la mañana");
printjson(perfiles.find(
  { "preferencias_entrenamiento.jornada": "mañana" },
  { _id: 0, id_deportista_sql: 1, deporte: 1, "preferencias_entrenamiento.enfoque": 1 }
).toArray());

titulo("3c. find sobre arreglo ($elemMatch): marcas en segundos menores a 13");
printjson(perfiles.find(
  { marcas_personales: { $elemMatch: { unidad: "s", valor: { $lt: 13 } } } },
  { _id: 0, id_deportista_sql: 1, deporte: 1, marcas_personales: 1 }
).toArray());

titulo("3d. find con campo variable ($exists): perfiles que registran posición");
printjson(perfiles.find(
  { posicion: { $exists: true } },
  { _id: 0, id_deportista_sql: 1, deporte: 1, posicion: 1 }
).sort({ id_deportista_sql: 1 }).toArray());

/* ---------------------------------------------------------------------
   4. DOCUMENTO DE PRUEBA CONTROLADO (insertOne)
   Marcado con es_prueba: true para poder borrarlo sin afectar a los demás.
   --------------------------------------------------------------------- */
titulo("4. insertOne: documento de prueba controlado");
perfiles.insertOne({
  id_deportista_sql: 2871,              // David Mora Peña - Béisbol Masculino Avanzada
  id_disciplina_sql: 274,
  deporte: "Béisbol",
  fecha_actualizacion: new Date("2026-11-01T10:00:00Z"),
  posicion: "Jardinero central",
  batea: "zurdo",
  lanza: "derecho",
  es_prueba: true
});
printjson(perfiles.findOne({ id_deportista_sql: 2871 }, { _id: 0 }));

/* ---------------------------------------------------------------------
   5. ACTUALIZACIÓN (updateOne) Y VERIFICACIÓN
   --------------------------------------------------------------------- */
titulo("5. updateOne: se cambia la posición y se agrega una marca personal");
const resultadoUpdate = perfiles.updateOne(
  { id_deportista_sql: 2871, es_prueba: true },
  {
    $set: { posicion: "Primera base", fecha_actualizacion: new Date("2026-11-10T12:00:00Z") },
    $push: { marcas_personales: { prueba: "Velocidad de lanzamiento", valor: 128.5, unidad: "km/h", fecha: new Date("2026-11-08") } }
  }
);
print("Coincidencias: " + resultadoUpdate.matchedCount + " | Modificados: " + resultadoUpdate.modifiedCount);
const verificado = perfiles.findOne({ id_deportista_sql: 2871 }, { _id: 0 });
printjson(verificado);
print("Verificación de la actualización: " +
      (verificado.posicion === "Primera base" && verificado.marcas_personales.length === 1 ? "CORRECTA" : "INCORRECTA"));

/* ---------------------------------------------------------------------
   6. ELIMINACIÓN (deleteOne) SOLO DEL DOCUMENTO DE PRUEBA Y VERIFICACIÓN
   --------------------------------------------------------------------- */
titulo("6. deleteOne: se elimina únicamente el documento de prueba");
const resultadoDelete = perfiles.deleteOne({ id_deportista_sql: 2871, es_prueba: true });
print("Documentos eliminados: " + resultadoDelete.deletedCount);
const quedaPrueba = perfiles.countDocuments({ id_deportista_sql: 2871 });
print("¿El documento de prueba sigue existiendo? " + (quedaPrueba === 0 ? "NO (eliminado)" : "SÍ"));
print("Documentos restantes (deben ser 5): " + perfiles.countDocuments());

/* ---------------------------------------------------------------------
   7. VALIDACIÓN: un documento sin referencia a SQL Server se rechaza
   --------------------------------------------------------------------- */
titulo("7. Validación: documento sin id_deportista_sql (debe rechazarse)");
try {
  perfiles.insertOne({ deporte: "Fútbol", fecha_actualizacion: new Date(), posicion: "Portero" });
  print("ERROR: el documento inválido fue aceptado");
} catch (e) {
  print("Rechazado correctamente por el validador: " + (e.errmsg || e.message));
}
try {
  perfiles.insertOne({ id_deportista_sql: 1, deporte: "Fútbol", fecha_actualizacion: new Date() });
  print("ERROR: se aceptó un segundo perfil para el mismo deportista");
} catch (e) {
  print(e.code === 11000
        ? "Rechazado correctamente por el índice único: ya existe un perfil para id_deportista_sql = 1"
        : "Rechazado por otro motivo: " + e.message);
}

titulo("Resumen final");
printjson(perfiles.find({}, { _id: 0, id_deportista_sql: 1, deporte: 1, fecha_actualizacion: 1 })
                  .sort({ id_deportista_sql: 1 }).toArray());

/* ---------------------------------------------------------------------
   Consistencia con SQL Server: no existe FK entre motores, por eso se
   listan las referencias para comprobarlas en GestionDeportiva con:
   SELECT id_deportista FROM dbo.deportista WHERE id_deportista IN (...);
   --------------------------------------------------------------------- */
const ids = perfiles.distinct("id_deportista_sql");
print("\nReferencias a verificar en SQL Server (dbo.deportista): " + ids.join(", "));
print("Tipo BSON de id_deportista_sql (debe ser int): " +
      perfiles.countDocuments({ id_deportista_sql: { $type: "int" } }) + " de " + perfiles.countDocuments() + " documentos");
