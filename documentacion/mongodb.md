# MongoDB — ejercicios de la colección `productos` (Caso 5)

Script: [`scripts/mongodb/productos.js`](../scripts/mongodb/productos.js)
· Evidencia de ejecución: [`evidencias/resultados/mongodb_productos_resultado.txt`](../evidencias/resultados/mongodb_productos_resultado.txt)

El componente de MongoDB se limita a los ejercicios básico, intermedio y avanzado de la guía de MongoDB.
Se usa la base `caso05_mongodb` y una sola colección, `productos`. Los productos son artículos deportivos
para mantener el contexto del caso; no se relacionan con las tablas de SQL Server.

## 1. Estructura de los documentos

Después de los tres niveles, cada documento queda así:

```js
{
  _id: ObjectId("..."),            // lo genera MongoDB
  nombre: "Tenis de running",
  precio: 350000,                  // pesos colombianos
  stock: 10,
  categoria: "Calzado",            // Balones, Calzado o Raquetas
  detalles: {                      // objeto embebido (nivel intermedio)
    garantia_meses: 18,
    peso_kg: 0.6
  }
}
```

## 2. Nivel básico

| Ejercicio | Comando | Resultado |
|---|---|---|
| Crear la colección | `createCollection("productos")` | Colección creada |
| Insertar cinco artículos con `nombre`, `precio`, `stock` y `categoria` | `insertMany([...])` | 5 documentos |
| Productos de dos categorías con `$in` | `find({ categoria: { $in: ["Balones", "Raquetas"] } })` | 3 productos: los dos balones y la raqueta |
| Rango de precios con `$gte` y `$lte` | `find({ precio: { $gte: 150000, $lte: 350000 } })` | 3 productos: balón de baloncesto, guayos y tenis |

`$in` compara el campo con una lista de valores y devuelve el documento si coincide con cualquiera.
`$gte` (mayor o igual) y `$lte` (menor o igual) juntos simulan un `BETWEEN` de SQL.

## 3. Nivel intermedio

| Ejercicio | Comando | Resultado |
|---|---|---|
| Agregar el objeto embebido `detalles` con `garantia_meses` y `peso_kg` | `updateOne({ nombre }, { $set: { detalles: {...} } })` para cada producto | 5 productos con `detalles` |
| Garantía superior a 12 meses con el operador punto | `find({ "detalles.garantia_meses": { $gt: 12 } })` | 2 productos: tenis (18) y raqueta (24) |

El operador punto (`"detalles.garantia_meses"`) permite filtrar por un campo que está dentro de un
objeto embebido. La comilla es obligatoria porque el nombre del campo lleva un punto.

## 4. Nivel avanzado

| Ejercicio | Comando | Resultado |
|---|---|---|
| Índice sobre `categoria` | `createIndex({ categoria: 1 })` | Índice `categoria_1` |
| Stock total por categoría con `$group` | `aggregate([{ $group: { _id: "$categoria", stock_total: { $sum: "$stock" } } }])` | Balones 65, Calzado 25, Raquetas 8 |
| Análisis de rendimiento | `find({ categoria: "Calzado" }).explain("executionStats")` | Plan `IXSCAN (categoria_1)` → `FETCH`; 2 claves de índice y 2 documentos revisados para 2 devueltos |

**Cómo leer el `explain`:** `IXSCAN` indica que MongoDB usó el índice `categoria_1` en lugar de recorrer
toda la colección (`COLLSCAN`). Como revisó solo 2 documentos para devolver 2, la consulta no leyó
documentos de más. Con 5 documentos la diferencia de tiempo no se nota, pero en una colección grande el
índice evita revisar todos los documentos.

## 5. Cómo ejecutarlo

Requisitos: MongoDB 6 o superior y `mongosh`. Probado en MongoDB 7.0.

```bash
mongosh "mongodb://localhost:27017" scripts/mongodb/productos.js
```

Con Docker:

```bash
docker run -d --name mongocaso5 -p 27017:27017 mongo:7
docker cp scripts/mongodb/productos.js mongocaso5:/tmp/
docker exec mongocaso5 mongosh --quiet /tmp/productos.js
```

El script es repetible: al inicio elimina solo la colección `productos` de la base `caso05_mongodb` y la vuelve
a crear. Se ejecutó dos veces y la salida fue la misma (salvo el tiempo en milisegundos del `explain`).
