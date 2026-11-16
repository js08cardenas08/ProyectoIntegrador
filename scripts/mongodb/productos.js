/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Integrantes: Juan Sebastián Cárdenas, Juan David Segura
   MongoDB - ejercicios de la guía: colección productos
   ---------------------------------------------------------------------
   Nivel básico:     crear la colección, insertar 5 productos, consulta
                     con $in y consulta por rango de precios ($gte/$lte).
   Nivel intermedio: objeto embebido "detalles" (garantia_meses, peso_kg)
                     y consulta con el operador punto.
   Nivel avanzado:   índice sobre categoria, agregación $group (stock
                     total por categoría) y explain("executionStats").

   Ejecución:
       mongosh "mongodb://localhost:27017" scripts/mongodb/productos.js

   El script es repetible: al inicio elimina solo la colección productos
   de la base caso05_mongodb y la vuelve a crear.
   ===================================================================== */

const base = db.getSiblingDB("caso05_mongodb");

function titulo(texto) {
  print("\n==== " + texto + " ====");
}

/* ---------------------------------------------------------------------
   NIVEL BÁSICO
   --------------------------------------------------------------------- */
titulo("BÁSICO 1. Crear la colección productos");
base.productos.drop();
base.createCollection("productos");
print("Colecciones en caso05_mongodb: " + base.getCollectionNames().join(", "));

titulo("BÁSICO 2. Insertar cinco productos (nombre, precio, stock, categoria)");
const insercion = base.productos.insertMany([
  { nombre: "Balón de fútbol N.º 5",     precio: 120000, stock: 40, categoria: "Balones" },
  { nombre: "Balón de baloncesto N.º 7", precio: 150000, stock: 25, categoria: "Balones" },
  { nombre: "Guayos de fútbol",          precio: 280000, stock: 15, categoria: "Calzado" },
  { nombre: "Tenis de running",          precio: 350000, stock: 10, categoria: "Calzado" },
  { nombre: "Raqueta de tenis",          precio: 420000, stock: 8,  categoria: "Raquetas" }
]);
print("Documentos insertados: " + Object.keys(insercion.insertedIds).length);
printjson(base.productos.find({}, { _id: 0 }).toArray());

titulo("BÁSICO 3. $in: productos de las categorías Balones y Raquetas");
printjson(base.productos.find(
  { categoria: { $in: ["Balones", "Raquetas"] } },
  { _id: 0, nombre: 1, categoria: 1, precio: 1 }
).toArray());

titulo("BÁSICO 4. Rango de precios entre 150.000 y 350.000 ($gte y $lte)");
printjson(base.productos.find(
  { precio: { $gte: 150000, $lte: 350000 } },
  { _id: 0, nombre: 1, precio: 1 }
).sort({ precio: 1 }).toArray());

/* ---------------------------------------------------------------------
   NIVEL INTERMEDIO
   --------------------------------------------------------------------- */
titulo("INTERMEDIO 1. Agregar el objeto embebido detalles (garantia_meses, peso_kg)");
const detalles = [
  { nombre: "Balón de fútbol N.º 5",     garantia_meses: 6,  peso_kg: 0.43 },
  { nombre: "Balón de baloncesto N.º 7", garantia_meses: 6,  peso_kg: 0.62 },
  { nombre: "Guayos de fútbol",          garantia_meses: 12, peso_kg: 0.9 },
  { nombre: "Tenis de running",          garantia_meses: 18, peso_kg: 0.6 },
  { nombre: "Raqueta de tenis",          garantia_meses: 24, peso_kg: 0.3 }
];
detalles.forEach(function (d) {
  base.productos.updateOne(
    { nombre: d.nombre },
    { $set: { detalles: { garantia_meses: d.garantia_meses, peso_kg: d.peso_kg } } }
  );
});
print("Productos con el campo detalles: " + base.productos.countDocuments({ detalles: { $exists: true } }));
printjson(base.productos.find({}, { _id: 0, nombre: 1, detalles: 1 }).toArray());

titulo("INTERMEDIO 2. Operador punto: productos con garantía superior a 12 meses");
printjson(base.productos.find(
  { "detalles.garantia_meses": { $gt: 12 } },
  { _id: 0, nombre: 1, "detalles.garantia_meses": 1 }
).toArray());

/* ---------------------------------------------------------------------
   NIVEL AVANZADO
   --------------------------------------------------------------------- */
titulo("AVANZADO 1. Índice sobre el campo categoria");
print("Índice creado: " + base.productos.createIndex({ categoria: 1 }));
printjson(base.productos.getIndexes().map(function (i) { return { nombre: i.name, campos: i.key }; }));

titulo("AVANZADO 2. Agregación $group: stock total por categoría");
printjson(base.productos.aggregate([
  { $group: { _id: "$categoria", stock_total: { $sum: "$stock" } } },
  { $sort: { stock_total: -1 } }
]).toArray());

titulo("AVANZADO 3. explain(\"executionStats\") de la consulta por categoría");
const plan = base.productos.find({ categoria: "Calzado" }).explain("executionStats");
const etapas = [];
let etapa = plan.queryPlanner.winningPlan;
while (etapa) {
  etapas.push(etapa.stage + (etapa.indexName ? " (" + etapa.indexName + ")" : ""));
  etapa = etapa.inputStage;
}
printjson({
  etapas_del_plan: etapas,
  documentos_devueltos: plan.executionStats.nReturned,
  claves_de_indice_revisadas: plan.executionStats.totalKeysExamined,
  documentos_revisados: plan.executionStats.totalDocsExamined,
  tiempo_ms: plan.executionStats.executionTimeMillis
});
