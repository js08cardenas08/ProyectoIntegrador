# Consultas de negocio — Caso 5: Gestión deportiva

Script: [`scripts/sqlserver/05_consultas_negocio.sql`](../scripts/sqlserver/05_consultas_negocio.sql)
(requiere las vistas de [`04_vistas.sql`](../scripts/sqlserver/04_vistas.sql)).
Resultado completo de la ejecución: [`evidencias/resultados/05_consultas_negocio_resultado.txt`](../evidencias/resultados/05_consultas_negocio_resultado.txt).

Las cifras de este documento salen de ejecutar los scripts sobre los datos semilla (semilla fija 2026,
fecha de referencia de los datos: 1 de noviembre de 2026). Como los datos son reproducibles, al
reconstruir la base desde cero se obtienen los mismos resultados.

## Vistas utilizadas

| Vista | Qué hace | Por qué aporta valor |
|---|---|---|
| `vw_deportista_detalle` | Une `deportista` + `persona` + `disciplina` y calcula la edad | Evita repetir el mismo JOIN; los datos personales siguen guardados una sola vez en `persona` |
| `vw_encuentro_detalle` | Une `encuentro` con torneo, disciplina, escenario y los dos equipos (la tabla `equipo` se usa dos veces con alias `el` y `ev`) | Ficha legible de cada encuentro |
| `vw_resultado_equipo` | Convierte cada encuentro con resultado **definitivo** en dos filas (una por equipo) con `VICTORIA`, `DERROTA` o `EMPATE` usando `UNION ALL` | Permite contar resultados por equipo sin guardar columnas calculadas (evita redundancia) |

## Resumen de técnicas por consulta

| # | Pregunta | Técnicas principales | Filas obtenidas |
|---|---|---|---|
| 1 | Deportistas por disciplina y estado | Vista, `WHERE` con parámetros, `ORDER BY`; `COUNT` + `SUM(CASE)` + `GROUP BY` | 70 (1a) / 23 (1b) |
| 2 | Encuentros entre dos fechas | Vista, rango de fechas, `ORDER BY` | 128 |
| 3 | Encuentros por torneo y escenario | `JOIN` 3 tablas, `COUNT`, `SUM(CASE)`, `GROUP BY` | 11.322 |
| 4 | Victorias, derrotas y empates por equipo | `LEFT JOIN` con vista, `COUNT`, `SUM(CASE)`, `ISNULL`, `GROUP BY` | 1.200 |
| 5 | Encuentros con torneo, participantes y escenario | `JOIN` de 6 tablas, subconsultas correlacionadas | 10 |
| 6 | Escenarios sin encuentros programados | `LEFT JOIN ... IS NULL`; `NOT EXISTS` + `GROUP BY` | 285 (6a) / 7 (6b) |
| 7 | Equipos que nunca han disputado encuentros | `NOT EXISTS`, subconsulta escalar | 101 |
| 8 | Torneos con más encuentros que el promedio | `LEFT JOIN`, `GROUP BY`, `HAVING` con subconsulta y `AVG` | 465 |
| 9 | Deportistas con participación superior al promedio | `JOIN` 4 tablas, `COUNT`, `SUM`, `AVG`, `HAVING` con subconsulta | 3.367 |
| 10 | Equipos con más victorias en un torneo | CTE (`WITH`), vista, subconsulta correlacionada con `MAX` | 5 (10a) / 1.380 (10b) |

---

## Consulta 1. Listar deportistas por disciplina y estado

**Propósito:** saber qué deportistas tiene la organización en cada disciplina y si están disponibles
(activos) o no (lesionados, suspendidos, retirados), para conformar equipos e inscripciones.

* **1a** filtra un deporte y un estado (parámetros `@deporte = 'Baloncesto'`, `@estado = 'LESIONADO'`) y
  ordena por modalidad, rama, categoría y apellidos.
* **1b** resume, por deporte, cuántos deportistas hay en cada estado.

**Resultado:** hay 70 deportistas de baloncesto lesionados repartidos en las modalidades 5x5, 3x3 y silla
de ruedas. En el resumen, Ultimate (946), Hockey (733) y Baloncesto (726) son los deportes con más
deportistas; alrededor del 75 % de cada deporte está activo. Los deportes individuales (natación,
atletismo, ciclismo…) tienen pocos afiliados y todavía no tienen equipos ni torneos.

**Interpretación:** el área técnica puede ver rápidamente cuántos deportistas no están disponibles en
cada disciplina antes de cerrar una convocatoria. Como el nombre y el documento se leen de `persona`,
el reporte no duplica información personal.

## Consulta 2. Consultar encuentros entre dos fechas

**Propósito:** agenda de encuentros de un periodo (por ejemplo, una semana) con su resultado.
Parámetros `@desde = '2026-10-01'` y `@hasta = '2026-10-07'`.

**Resultado:** 128 encuentros en esa semana: 117 finalizados y 11 en otros estados (suspendidos o
cancelados). Cada fila muestra torneo, equipos, escenario y ciudad.

**Interpretación:** sirve para revisar la ocupación de escenarios y los resultados pendientes de
homologar (`resultado_definitivo = 0`). La condición `fecha_hora < DATEADD(DAY, 1, @hasta)` incluye todo
el último día aunque el encuentro tenga hora.

## Consulta 3. Contar encuentros por torneo y escenario

**Propósito:** medir cuántas veces se usó cada escenario en cada torneo, separando finalizados,
programados y cancelados/suspendidos.

**Resultado:** 11.322 combinaciones torneo–escenario (978 torneos con encuentros y 815 escenarios
utilizados). En la mayoría de torneos cada escenario recibe 1 o 2 encuentros, porque los partidos se
juegan en la ciudad del equipo local.

**Interpretación:** si un escenario concentra muchos encuentros de un mismo torneo es un candidato a
saturarse; si tiene muchos cancelados puede indicar problemas de disponibilidad.

## Consulta 4. Calcular victorias, derrotas y empates por equipo

**Propósito:** tabla histórica de desempeño de cada equipo.

**Resultado:** 1.200 filas (todos los equipos). Los líderes tienen 26 victorias (por ejemplo,
*Unión Huracanes de Bucaramanga* en baloncesto 5x5 con 26 victorias y 5 derrotas). 101 equipos aparecen
con 0 jugados gracias al `LEFT JOIN`.

**Interpretación:** solo se cuentan encuentros con resultado definitivo (regla 6), así que un partido
suspendido o pendiente de homologación no altera las estadísticas. Los empates solo aparecen en deportes
que los permiten (fútbol, hockey, balonmano, rugby); en baloncesto o voleibol siempre hay ganador.

## Consulta 5. Mostrar encuentros con torneo, participantes y escenario

**Propósito:** ficha completa de un torneo (`@codigo_torneo = 'TOR-0007'`, *Copa Interclubes Fútbol 11
Masculino Intermedia 2025-II*).

**Resultado:** 10 encuentros (5 equipos, todos contra todos a una vuelta, 5 jornadas). Para cada uno se
ven equipos, marcador, estado, escenario y cuántos deportistas de cada equipo participaron (subconsultas
correlacionadas sobre `participacion_encuentro`).

**Interpretación:** confirma la regla 5: cada encuentro pertenece a un torneo, usa un escenario y sus
participantes son dos equipos distintos inscritos y aprobados en ese torneo.

## Consulta 6. Listar escenarios sin encuentros programados

**Propósito:** encontrar escenarios libres o subutilizados (regla 8 permite escenarios sin encuentros).

* **6a** (escenarios que nunca han tenido encuentros): 285 escenarios. La mayoría son piscinas (85),
  pistas atléticas (66) y velódromos (45), porque los deportes que los usan todavía no tienen torneos; el
  resto son canchas, coliseos o estadios en mantenimiento o inactivos.
* **6b** (escenarios **disponibles** sin encuentros en estado `PROGRAMADO`): por tipo, 119 canchas,
  76 piscinas, 70 coliseos, 65 gimnasios, 64 pistas, 60 estadios y algunos velódromos libres para la
  próxima programación.

**Interpretación:** la organización tiene capacidad ociosa; antes de alquilar escenarios externos puede
asignar los disponibles. 6a usa `LEFT JOIN ... IS NULL` y 6b usa `NOT EXISTS`; ambas formas son
equivalentes para buscar "lo que no tiene relacionados".

## Consulta 7. Encontrar equipos que nunca han disputado encuentros

**Propósito:** detectar equipos registrados sin actividad competitiva (regla 8).
"Disputar" significa haber jugado (`EN_JUEGO`, `FINALIZADO` o `SUSPENDIDO`).

**Resultado:** 101 equipos. 100 pertenecen a disciplinas que aún no tienen torneos (por ejemplo,
bádminton dobles o atletismo relevos) y uno, *Atlético Rayos de Pasto*, tiene 4 inscripciones pero
ninguna aprobada que le haya permitido jugar.

**Interpretación:** son equipos para promover en próximas convocatorias o revisar si deben pasar a
estado `INACTIVO`.

## Consulta 8. Identificar torneos con más encuentros que el promedio

**Propósito:** reconocer los torneos que exigen más logística.

**Resultado:** el promedio general es **12,29 encuentros por torneo** (incluye los torneos cancelados
con 0 encuentros, por eso se usa `LEFT JOIN`). 465 torneos lo superan: 419 finalizados, 31 en curso y
15 programados. Los mayores tienen 28 encuentros (8 equipos aprobados).

**Interpretación:** el número de encuentros depende de cuántas inscripciones se aprueban (n equipos →
n·(n−1)/2 encuentros). Los torneos grandes necesitan más escenarios y fechas.

## Consulta 9. Consultar deportistas con participación superior al promedio

**Propósito:** identificar a los deportistas más utilizados y su desempeño.
Participación = número de encuentros jugados (filas en `participacion_encuentro`).

**Resultado:** 6.634 deportistas han jugado al menos un encuentro, con un promedio de **16,96
encuentros**. 3.367 superan ese promedio; el máximo es 43 encuentros. Para cada uno se muestran
encuentros como titular, minutos totales (nulos en deportes sin reloj, como voleibol) y calificación
promedio (escala 0–10).

**Interpretación:** son los deportistas con mayor carga competitiva; cruzar esta lista con el estado
(por ejemplo, `LESIONADO`) ayuda a planear descanso y rotación.

## Consulta 10. Mostrar equipos con más victorias en un torneo

* **10a** (torneo `TOR-0007`): *Real Fénix de Florencia* lidera con 3 victorias, 1 empate y 0 derrotas.
* **10b** (todos los torneos): 1.380 filas para 882 torneos con resultados definitivos. En 364 torneos
  hay empate en el primer lugar y por eso se muestran varios equipos: la subconsulta correlacionada
  `v.victorias = (SELECT MAX(...) ... WHERE v2.id_torneo = v.id_torneo)` devuelve **todos** los que
  alcanzan el máximo, en lugar de escoger uno arbitrariamente.

**Interpretación:** permite premiar o sembrar equipos para el siguiente torneo. Si se necesitara un
único campeón, el desempate se haría con puntos a favor menos puntos en contra (criterio que se puede
agregar al `ORDER BY`).
