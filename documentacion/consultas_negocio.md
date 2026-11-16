# Consultas de negocio — Caso 5: Gestión deportiva

Script: [`scripts/sqlserver/05_consultas_negocio.sql`](../scripts/sqlserver/05_consultas_negocio.sql)
(requiere la vista de [`04_vistas.sql`](../scripts/sqlserver/04_vistas.sql)).
Resultado completo de la ejecución: [`evidencias/resultados/05_consultas_negocio_resultado.txt`](../evidencias/resultados/05_consultas_negocio_resultado.txt).

Las consultas usan solo lo visto en clase: `SELECT`, `JOIN`, `WHERE`, `ORDER BY`, funciones de agregación
(`COUNT`, `SUM`), `GROUP BY` / `HAVING` y subconsultas sencillas (`NOT IN` y el promedio dentro de `HAVING`).
Los valores de filtro (deporte, estado, fechas, código del torneo) van escritos directamente en el `WHERE`;
para consultar otro caso basta con cambiar ese valor.

Las cifras de este documento salen de ejecutar los scripts sobre los datos semilla (semilla fija 2026,
fecha de referencia de los datos: 1 de noviembre de 2026). Como los datos son reproducibles, al
reconstruir la base desde cero se obtienen los mismos resultados.

## Vista utilizada

| Vista | Qué hace | Por qué aporta valor |
|---|---|---|
| `vw_resultado_equipo` | Toma cada encuentro con resultado **definitivo** y lo pone dos veces: una vez desde el equipo local y otra desde el visitante (`UNION ALL`). Cada fila trae un 1 en `victoria`, `empate` o `derrota` | Un equipo puede jugar de local o de visitante; la vista junta las dos cosas una sola vez y las consultas 4 y 10 solo tienen que sumar. No guarda datos: se calcula siempre desde `encuentro` (evita redundancia) |

## Resumen de técnicas por consulta

| # | Pregunta | Técnicas principales | Filas obtenidas |
|---|---|---|---|
| 1 | Deportistas por disciplina y estado | `JOIN` 3 tablas, `WHERE`, `ORDER BY`; `COUNT` + `GROUP BY` | 70 (1a) / 90 (1b) |
| 2 | Encuentros entre dos fechas | `JOIN` 3 tablas, `WHERE` con rango de fechas, `ORDER BY` | 128 |
| 3 | Encuentros por torneo y escenario | `JOIN` 3 tablas, `COUNT`, `GROUP BY` | 11.322 |
| 4 | Victorias, derrotas y empates por equipo | Vista, `JOIN`, `COUNT`, `SUM`, `GROUP BY` | 1.099 |
| 5 | Encuentros con torneo, participantes y escenario | `JOIN` de 5 tablas (`equipo` dos veces con alias) | 10 |
| 6 | Escenarios sin encuentros programados | Subconsulta con `NOT IN` | 496 |
| 7 | Equipos que nunca han disputado encuentros | Dos subconsultas con `NOT IN` (local y visitante) | 101 |
| 8 | Torneos con más encuentros que el promedio | `JOIN`, `GROUP BY`, `HAVING` con subconsulta (promedio) | 465 |
| 9 | Deportistas con participación superior al promedio | `JOIN` 4 tablas, `COUNT`, `HAVING` con subconsulta (promedio) | 3.367 |
| 10 | Equipos con más victorias en un torneo | Vista, `JOIN`, `SUM`, `GROUP BY`, `ORDER BY ... DESC` | 5 |

---

## Consulta 1. Listar deportistas por disciplina y estado

**Propósito:** saber qué deportistas tiene la organización en cada disciplina y si están disponibles
(activos) o no (lesionados, suspendidos, retirados), para conformar equipos e inscripciones.

* **1a** une `deportista`, `persona` y `disciplina`, filtra `deporte = 'Baloncesto'` y `estado = 'LESIONADO'`
  y ordena por modalidad, rama, categoría y apellidos.
* **1b** cuenta, con `COUNT(*)` y `GROUP BY deporte, estado`, cuántos deportistas hay de cada deporte en
  cada estado.

**Resultado:** hay 70 deportistas de baloncesto lesionados repartidos en las modalidades 5x5, 3x3 y silla
de ruedas. El resumen tiene 90 filas (cada deporte con sus estados); alrededor del 75 % de cada deporte
está activo. Los deportes individuales (natación, atletismo, ciclismo…) tienen pocos afiliados y todavía
no tienen equipos ni torneos.

**Interpretación:** el área técnica puede ver rápidamente cuántos deportistas no están disponibles en
cada disciplina antes de cerrar una convocatoria. Como el nombre se lee de `persona`, el reporte no
duplica información personal.

## Consulta 2. Consultar encuentros entre dos fechas

**Propósito:** agenda de encuentros de un periodo (la primera semana de octubre de 2026) con su resultado.

**Resultado:** 128 encuentros en esa semana: 117 finalizados y 11 en otros estados (suspendidos o
cancelados). Cada fila muestra fecha, torneo, escenario, estado y marcador.

**Interpretación:** sirve para revisar la ocupación de escenarios y los resultados de la semana. La
condición `fecha_hora >= '2026-10-01' AND fecha_hora < '2026-10-08'` incluye completo el día 7, aunque el
encuentro tenga hora.

## Consulta 3. Contar encuentros por torneo y escenario

**Propósito:** medir cuántas veces se usó cada escenario en cada torneo.

**Resultado:** 11.322 combinaciones torneo–escenario. En la mayoría de torneos cada escenario recibe 1 o
2 encuentros, porque los partidos se juegan en la ciudad del equipo local.

**Interpretación:** si un escenario concentra muchos encuentros de un mismo torneo es un candidato a
saturarse. Se agrupa también por código del escenario porque hay escenarios con el mismo nombre en
ciudades distintas.

## Consulta 4. Calcular victorias, derrotas y empates por equipo

**Propósito:** tabla histórica de desempeño de cada equipo.

**Resultado:** 1.099 equipos con al menos un resultado definitivo. Los líderes tienen 26 victorias (por
ejemplo, *Unión Huracanes de Bucaramanga*, con 31 partidos: 26 victorias y 5 derrotas). Los 101 equipos
que no han jugado no aparecen aquí; se listan en la consulta 7 (1.099 + 101 = 1.200 equipos).

**Interpretación:** solo se cuentan encuentros con resultado definitivo (regla 6), así que un partido
suspendido o pendiente de homologación no altera las estadísticas. Los empates solo aparecen en deportes
que los permiten (fútbol, hockey, balonmano, rugby); en baloncesto o voleibol siempre hay ganador.

**Local y visitante:** un equipo puede jugar como local o como visitante. La vista `vw_resultado_equipo`
pone cada encuentro una vez por cada equipo, así que `COUNT(*)` da todos los partidos del equipo y
`SUM(victoria)`, `SUM(empate)` y `SUM(derrota)` cuentan sus resultados. Comprobación: la vista tiene
21.244 filas (el doble de los 10.622 encuentros con resultado definitivo) y el total de victorias es
igual al total de derrotas.

## Consulta 5. Mostrar encuentros con torneo, participantes y escenario

**Propósito:** ficha completa de un torneo (`TOR-0007`, *Copa Interclubes Fútbol 11 Masculino
Intermedia 2025-II*).

**Resultado:** 10 encuentros (5 equipos, todos contra todos a una vuelta, 5 jornadas). Para cada uno se
ven jornada, equipo local, marcador, equipo visitante, escenario y estado.

**Interpretación:** la tabla `equipo` se une dos veces con alias distintos (`el` para el local y `ev`
para el visitante) porque el encuentro guarda dos equipos. Confirma la regla 5: cada encuentro pertenece
a un torneo, usa un escenario y sus participantes son dos equipos distintos.

## Consulta 6. Listar escenarios sin encuentros programados

**Propósito:** encontrar escenarios libres para la próxima programación (la regla 8 permite escenarios
sin encuentros).

**Resultado:** de 997 escenarios disponibles, 496 no tienen ningún encuentro en estado `PROGRAMADO`:
119 canchas, 76 piscinas, 70 coliseos, 65 gimnasios, 64 pistas, 60 estadios y 42 velódromos.

**Interpretación:** la subconsulta devuelve los escenarios que sí tienen encuentros programados y
`NOT IN` deja los demás. La organización tiene capacidad libre; antes de alquilar escenarios externos
puede asignar estos.

## Consulta 7. Encontrar equipos que nunca han disputado encuentros

**Propósito:** detectar equipos registrados sin actividad competitiva (regla 8).
"Disputar" significa haber jugado (`EN_JUEGO`, `FINALIZADO` o `SUSPENDIDO`).

**Resultado:** 101 equipos. 100 pertenecen a disciplinas que aún no tienen torneos (por ejemplo,
bádminton dobles o atletismo relevos) y uno, *Atlético Rayos de Pasto*, tiene 4 inscripciones pero
ninguna aprobada que le haya permitido jugar.

**Interpretación:** son equipos para promover en próximas convocatorias o revisar si deben pasar a
estado `INACTIVO`.

**Local y visitante:** la consulta usa dos `NOT IN`, uno sobre `id_equipo_local` y otro sobre
`id_equipo_visitante`. Si solo se revisara la columna de local, aparecerían además 3 equipos que sí
jugaron, pero solo como visitantes.

## Consulta 8. Identificar torneos con más encuentros que el promedio

**Propósito:** reconocer los torneos que exigen más logística.

**Resultado:** el promedio es **12,29 encuentros por torneo** (12.289 encuentros entre 1.000 torneos,
contando también los torneos sin encuentros). 465 torneos lo superan; los mayores tienen 28 encuentros
(8 equipos aprobados).

**Interpretación:** el promedio se calcula con dos subconsultas: total de encuentros dividido entre total
de torneos (se multiplica por `1.0` para que la división dé decimales). `HAVING` compara el conteo de cada
torneo con ese promedio. El número de encuentros depende de cuántas inscripciones se aprueban (n equipos →
n·(n−1)/2 encuentros).

## Consulta 9. Consultar deportistas con participación superior al promedio

**Propósito:** identificar a los deportistas más utilizados.
Participación = número de encuentros jugados (filas en `participacion_encuentro`).

**Resultado:** 6.634 deportistas han jugado al menos un encuentro, con un promedio de **16,96
encuentros**. 3.367 superan ese promedio; el máximo es 43 encuentros.

**Interpretación:** son los deportistas con mayor carga competitiva; cruzar esta lista con el estado
(por ejemplo, `LESIONADO`) ayuda a planear descanso y rotación.

## Consulta 10. Mostrar equipos con más victorias en un torneo

**Resultado (torneo `TOR-0007`):** *Real Fénix de Florencia* lidera con 3 victorias, 1 empate y 0
derrotas; el último es *Deportivo Búhos de Tunja* con 4 derrotas.

**Interpretación:** la consulta usa la misma vista de la consulta 4 (local + visitante), filtra un torneo
y ordena por victorias de mayor a menor, así el primero de la lista es el equipo con más victorias. Si
dos equipos empatan en victorias, el segundo criterio del `ORDER BY` son los empates. Para ver otro
torneo solo se cambia el código en el `WHERE`.
