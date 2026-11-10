# Proyecto integrador de Bases de Datos — Caso 5: Gestión deportiva

Diseño e implementación de una base de datos relacional en **Microsoft SQL Server** y una funcionalidad
documental complementaria en **MongoDB** para una organización deportiva que administra disciplinas,
deportistas, entrenadores, equipos, escenarios, torneos y encuentros.

| | |
|---|---|
| **Caso asignado** | Caso 5 — Gestión deportiva |
| **Asignatura** | Bases de Datos — Ingeniería de Datos e Inteligencia Artificial |
| **Integrantes** | _(completar con nombre y código de cada integrante)_ |
| **Base SQL Server** | `GestionDeportiva` (12 tablas, 3 vistas, 5 triggers) |
| **Colección MongoDB** | `gestion_deportiva.perfil_deportivo` |

## Contexto y reglas del caso

La organización necesita controlar inscripciones, conformación de equipos, asignación de escenarios y
resultados, y producir reportes de participación y desempeño **sin duplicar la información de personas y
competencias**. Reglas implementadas (detalle en [`documentacion/reglas_negocio.md`](documentacion/reglas_negocio.md)):

1. Disciplinas, deportistas, entrenadores y equipos con identificadores únicos.
2. Un entrenador dirige equipos en distintos periodos, conservando fechas de vigencia.
3. Un deportista integra equipos a lo largo del tiempo con función y fechas de participación.
4. Escenarios con capacidad positiva y torneos con fechas coherentes.
5. Cada encuentro pertenece a un torneo, usa un escenario y tiene participantes válidos; un equipo no se enfrenta a sí mismo.
6. Los resultados solo pueden ser definitivos cuando el encuentro finalizó.
7. Estado inicial con DEFAULT documentado: inscripción `PENDIENTE`, encuentro `PROGRAMADO`.
8. Se permiten escenarios sin encuentros y equipos sin partidos jugados.

## Estructura del repositorio

```
├── README.md
├── diagramas/
│   ├── er/                  modelo_er.png / .pdf / .svg / .dot   (modelo entidad-relación)
│   └── relacional/          modelo_relacional.png / .pdf / .svg / .dot
├── documentacion/
│   ├── diccionario_datos.md     diccionario completo (generado desde el catálogo de SQL Server)
│   ├── decisiones_diseno.md     E-R, paso a relacional, normalización 3FN y decisiones técnicas
│   ├── reglas_negocio.md        cada regla → mecanismo (PK, FK, CHECK, DEFAULT, trigger) → pruebas
│   ├── consultas_negocio.md     las 10 consultas con su propósito e interpretación de resultados
│   ├── pruebas.md               pruebas con regla, esperado y obtenido
│   ├── mongodb.md               colección perfil_deportivo: esquema, relación con SQL Server, CRUD
│   └── bitacora.md              bitácora del desarrollo y declaración de uso de IA
├── scripts/
│   ├── sqlserver/
│   │   ├── 00_reinicio_entorno.sql          ⚠ BORRA la base GestionDeportiva (reinicio)
│   │   ├── 01_crear_base_y_tablas.sql       base y 12 tablas (PK, NOT NULL, DEFAULT)
│   │   ├── 02_restricciones_y_reglas.sql    FK, UNIQUE, CHECK, índices y triggers
│   │   ├── 03_datos_semilla.sql             datos sintéticos (generado, ≥ 1.000 por tabla)
│   │   ├── 04_vistas.sql                    3 vistas usadas por las consultas
│   │   ├── 05_consultas_negocio.sql         10 consultas de negocio
│   │   ├── 06_pruebas_restricciones.sql     48 pruebas válidas e inválidas
│   │   └── 07_metadatos_diccionario.sql     metadatos para verificar el diccionario
│   ├── mongodb/
│   │   └── caso_05_funcionalidad.js         colección perfil_deportivo y CRUD
│   └── generador/
│       ├── generar_datos_semilla.py         genera 03_datos_semilla.sql (semilla fija 2026)
│       └── generar_diccionario_y_relacional.py
└── evidencias/resultados/       salidas reales de la ejecución de los scripts
```

## Requisitos

* **SQL Server 2019 o superior** (Developer o Express) y una herramienta para ejecutar scripts:
  SQL Server Management Studio (SSMS), Azure Data Studio o `sqlcmd`. Probado en SQL Server 2022 (16.0).
* **MongoDB 6 o superior** y `mongosh`. Probado en MongoDB 7.0.
* *(Opcional)* Python 3.10+ solo si se quieren regenerar los datos semilla o el diccionario; no necesita
  librerías externas. El archivo `03_datos_semilla.sql` ya está generado en el repositorio.
* *(Opcional)* Graphviz para regenerar los diagramas desde los archivos `.dot`.

## Ejecución paso a paso (desde una base vacía)

Ejecutar **en este orden**. Todos los scripts están en UTF-8; con `sqlcmd` se usa `-f 65001` para que las
tildes y eñes se lean correctamente.

| Paso | Script | Qué hace | Tiempo aprox. |
|---|---|---|---|
| 0 *(solo si ya existe la base)* | `00_reinicio_entorno.sql` | **⚠ Elimina la base `GestionDeportiva`** | segundos |
| 1 | `01_crear_base_y_tablas.sql` | Crea la base y las 12 tablas | segundos |
| 2 | `02_restricciones_y_reglas.sql` | FK, UNIQUE, CHECK, índices y 5 triggers | segundos |
| 3 | `03_datos_semilla.sql` | Carga 180.193 registros sintéticos | ~1 minuto |
| 4 | `04_vistas.sql` | Crea 3 vistas | segundos |
| 5 | `05_consultas_negocio.sql` | Ejecuta las 10 consultas de negocio | segundos |
| 6 | `06_pruebas_restricciones.sql` | Ejecuta 48 pruebas (no modifica datos) | segundos |
| 7 | `07_metadatos_diccionario.sql` *(opcional)* | Muestra los metadatos para comparar con el diccionario | segundos |
| 8 | `scripts/mongodb/caso_05_funcionalidad.js` | Colección MongoDB y operaciones CRUD | segundos |

### Opción A: SSMS o Azure Data Studio
Abrir cada archivo de `scripts/sqlserver/` en orden y ejecutarlo (F5). El script `03_datos_semilla.sql`
pesa ~9,5 MB; si el editor se vuelve lento, ejecutarlo con `sqlcmd` (opción B).

### Opción B: `sqlcmd` (Windows, autenticación de Windows)
Desde la raíz del repositorio:

```bat
sqlcmd -S localhost -E -f 65001 -b -i scripts\sqlserver\00_reinicio_entorno.sql
sqlcmd -S localhost -E -f 65001 -b -i scripts\sqlserver\01_crear_base_y_tablas.sql
sqlcmd -S localhost -E -f 65001 -b -i scripts\sqlserver\02_restricciones_y_reglas.sql
sqlcmd -S localhost -E -f 65001 -b -i scripts\sqlserver\03_datos_semilla.sql
sqlcmd -S localhost -E -f 65001 -b -i scripts\sqlserver\04_vistas.sql
sqlcmd -S localhost -E -f 65001 -b -i scripts\sqlserver\05_consultas_negocio.sql -o consultas.txt
sqlcmd -S localhost -E -f 65001 -b -i scripts\sqlserver\06_pruebas_restricciones.sql
```

Con usuario SQL en lugar de `-E` usar `-U usuario -P contraseña` (no guardar contraseñas en el repositorio).
Si el servidor es una instancia con nombre, cambiar `localhost` por `localhost\SQLEXPRESS`.

### Opción C: Docker (como se probó este proyecto)

```bash
docker run -d --name sqlcaso5 -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='<contraseña segura>' -p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
docker run -d --name mongocaso5 -p 27017:27017 mongo:7
# para cada script, en orden:
docker cp scripts/sqlserver/01_crear_base_y_tablas.sql sqlcaso5:/tmp/
docker exec sqlcaso5 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '<contraseña segura>' -C -f 65001 -b -i /tmp/01_crear_base_y_tablas.sql
```

### MongoDB

```bash
mongosh "mongodb://localhost:27017" scripts/mongodb/caso_05_funcionalidad.js
```

## Cómo comprobar que la solución funciona

1. Al final de `03_datos_semilla.sql` se muestra el conteo de cada tabla: todas deben tener **1.000 o más**
   registros (la menor es `entrenador` / `equipo` con 1.200).
2. `06_pruebas_restricciones.sql` termina con el resumen `PASA | 48`. Cada fila muestra la regla, lo
   esperado, lo obtenido y el mensaje real de SQL Server.
3. `05_consultas_negocio.sql` devuelve 13 conjuntos de resultados; se pueden comparar con
   [`documentacion/consultas_negocio.md`](documentacion/consultas_negocio.md). Como los datos son
   reproducibles, los resultados deben coincidir.
4. El script de MongoDB imprime `Verificación de la actualización: CORRECTA`,
   `¿El documento de prueba sigue existiendo? NO (eliminado)` y `Documentos restantes (deben ser 5): 5`.
5. `07_metadatos_diccionario.sql` lista columnas, tipos y restricciones reales para compararlos con
   [`documentacion/diccionario_datos.md`](documentacion/diccionario_datos.md).

## Regenerar archivos generados (opcional)

```bash
python scripts/generador/generar_datos_semilla.py           # vuelve a crear 03_datos_semilla.sql (idéntico)
# diccionario y diagrama relacional a partir de los metadatos reales:
sqlcmd -S localhost -E -d GestionDeportiva -f 65001 -W -s "|" -i scripts\sqlserver\07_metadatos_diccionario.sql -o evidencias\resultados\07_metadatos_resultado.txt
python scripts/generador/generar_diccionario_y_relacional.py
dot -Tpng -Gdpi=150 diagramas/relacional/modelo_relacional.dot -o diagramas/relacional/modelo_relacional.png
dot -Tpng -Gdpi=150 diagramas/er/modelo_er.dot -o diagramas/er/modelo_er.png
```

## Resumen de la solución

* **Modelo:** superentidad `persona` con subtipos `deportista` y `entrenador` (una persona se registra una
  vez aunque cumpla los dos roles); relaciones M:N resueltas con `entrenador_equipo`, `integrante_equipo`,
  `inscripcion` y `participacion_encuentro`; el marcador vive en `encuentro` (1:1). Normalizado hasta 3FN
  (estadísticas, edad y nombres derivados no se almacenan).
* **Integridad:** 12 PK, 18 FK, 17 UNIQUE, 33 CHECK, 17 DEFAULT, 11 índices y 5 triggers
  para las reglas que comparan con otras filas (solapamiento de periodos, fechas del torneo, inscripción
  aprobada, resultado definitivo inmodificable, participantes válidos).
* **Datos:** generador con semilla fija; 1.035 a 112.506 registros por tabla, todos coherentes con las
  reglas.
* **Consultas:** SELECT/WHERE/ORDER BY, agregaciones, GROUP BY/HAVING, JOIN de hasta 6 tablas,
  subconsultas (correlacionadas, NOT EXISTS, en HAVING), CTE y vistas.
* **MongoDB:** `perfil_deportivo` con validador `$jsonSchema`, índice único por deportista y CRUD
  verificado; los registros oficiales siguen en SQL Server.

## Declaración de uso de herramientas de IA

En el desarrollo de este proyecto se utilizó un asistente de inteligencia artificial (Claude, de Anthropic)
como apoyo para estructurar el diseño, escribir y depurar los scripts SQL y MongoDB, el generador de datos
y la documentación, y para ejecutar las pruebas. Los resultados reportados provienen de la ejecución real
de los scripts (ver `evidencias/`). El equipo revisó el trabajo y es responsable de explicar y sustentar el
diseño, las restricciones, las consultas y las decisiones técnicas. Detalle en
[`documentacion/bitacora.md`](documentacion/bitacora.md).
