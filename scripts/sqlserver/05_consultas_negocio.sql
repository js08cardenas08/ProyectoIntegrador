/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Integrantes: Juan Sebastián Cárdenas, Juan David Segura
   Script 05: consultas de negocio (10 preguntas del caso)
   ---------------------------------------------------------------------
   Cada consulta usa lo visto en clase: SELECT, JOIN, WHERE, ORDER BY,
   funciones de agregación (COUNT, SUM), GROUP BY / HAVING y
   subconsultas sencillas.
   Para ejecutar UNA consulta: seleccionarla (desde su comentario hasta
   el GO) y presionar F5.
   Requiere: scripts 01 a 04 ejecutados.
   La interpretación de los resultados está en
   documentacion/consultas_negocio.md
   ===================================================================== */
USE GestionDeportiva;
GO

/* ---------------------------------------------------------------------
   CONSULTA 1. Listar deportistas por disciplina y estado.
   1a: los deportistas de baloncesto que están lesionados.
   1b: cuántos deportistas hay de cada deporte en cada estado.
   --------------------------------------------------------------------- */
-- 1a
SELECT di.deporte, di.modalidad, di.rama, di.categoria,
       d.estado, p.apellidos, p.nombres
FROM deportista d
JOIN persona    p  ON p.id_persona     = d.id_persona
JOIN disciplina di ON di.id_disciplina = d.id_disciplina
WHERE di.deporte = 'Baloncesto'
  AND d.estado   = 'LESIONADO'
ORDER BY di.modalidad, di.rama, di.categoria, p.apellidos;
GO

-- 1b
SELECT di.deporte, d.estado, COUNT(*) AS cantidad
FROM deportista d
JOIN disciplina di ON di.id_disciplina = d.id_disciplina
GROUP BY di.deporte, d.estado
ORDER BY di.deporte, d.estado;
GO

/* ---------------------------------------------------------------------
   CONSULTA 2. Consultar encuentros entre dos fechas.
   Encuentros de la primera semana de octubre de 2026 (del 1 al 7).
   --------------------------------------------------------------------- */
SELECT e.fecha_hora, t.nombre AS torneo, es.nombre AS escenario,
       e.estado, e.puntaje_local, e.puntaje_visitante
FROM encuentro e
JOIN torneo    t  ON t.id_torneo     = e.id_torneo
JOIN escenario es ON es.id_escenario = e.id_escenario
WHERE e.fecha_hora >= '2026-10-01'
  AND e.fecha_hora <  '2026-10-08'
ORDER BY e.fecha_hora;
GO

/* ---------------------------------------------------------------------
   CONSULTA 3. Contar encuentros por torneo y escenario.
   --------------------------------------------------------------------- */
SELECT t.codigo AS codigo_torneo, t.nombre AS torneo,
       es.codigo AS codigo_escenario, es.nombre AS escenario,
       COUNT(*) AS encuentros
FROM encuentro e
JOIN torneo    t  ON t.id_torneo     = e.id_torneo
JOIN escenario es ON es.id_escenario = e.id_escenario
GROUP BY t.codigo, t.nombre, es.codigo, es.nombre
ORDER BY t.codigo, encuentros DESC;
GO

/* ---------------------------------------------------------------------
   CONSULTA 4. Calcular victorias, derrotas y empates por equipo.
   La vista vw_resultado_equipo (script 04) ya junta los partidos de
   cada equipo como local y como visitante, con un 1 en victoria,
   empate o derrota. Aquí solo se suman por equipo.
   Los equipos que no han jugado aparecen en la consulta 7.
   --------------------------------------------------------------------- */
SELECT q.codigo, q.nombre AS equipo,
       COUNT(*)        AS partidos,
       SUM(r.victoria) AS victorias,
       SUM(r.empate)   AS empates,
       SUM(r.derrota)  AS derrotas
FROM vw_resultado_equipo r
JOIN equipo q ON q.id_equipo = r.id_equipo
GROUP BY q.codigo, q.nombre
ORDER BY victorias DESC, q.nombre;
GO

/* ---------------------------------------------------------------------
   CONSULTA 5. Mostrar encuentros con torneo, participantes y escenario.
   Los encuentros del torneo TOR-0007. La tabla equipo se une dos
   veces: una para el equipo local (el) y otra para el visitante (ev).
   --------------------------------------------------------------------- */
SELECT t.nombre AS torneo, e.jornada,
       el.nombre AS equipo_local, e.puntaje_local,
       e.puntaje_visitante, ev.nombre AS equipo_visitante,
       es.nombre AS escenario, e.estado
FROM encuentro e
JOIN torneo    t  ON t.id_torneo     = e.id_torneo
JOIN equipo    el ON el.id_equipo    = e.id_equipo_local
JOIN equipo    ev ON ev.id_equipo    = e.id_equipo_visitante
JOIN escenario es ON es.id_escenario = e.id_escenario
WHERE t.codigo = 'TOR-0007'
ORDER BY e.jornada;
GO

/* ---------------------------------------------------------------------
   CONSULTA 6. Listar escenarios sin encuentros programados.
   Escenarios disponibles que hoy no tienen ningún encuentro
   PROGRAMADO, es decir, libres para la próxima programación.
   La subconsulta trae los escenarios que SÍ tienen encuentros
   programados; NOT IN deja los que no están en esa lista.
   --------------------------------------------------------------------- */
SELECT codigo, nombre, tipo, ciudad, capacidad
FROM escenario
WHERE estado = 'DISPONIBLE'
  AND id_escenario NOT IN (SELECT id_escenario
                           FROM encuentro
                           WHERE estado = 'PROGRAMADO')
ORDER BY tipo, nombre;
GO

/* ---------------------------------------------------------------------
   CONSULTA 7. Encontrar equipos que nunca han disputado encuentros.
   "Disputar" = haber jugado (EN_JUEGO, FINALIZADO o SUSPENDIDO).
   Se revisan las dos columnas: el equipo no puede estar como local
   NI como visitante en un encuentro jugado.
   --------------------------------------------------------------------- */
SELECT q.codigo, q.nombre AS equipo, di.deporte, di.modalidad
FROM equipo q
JOIN disciplina di ON di.id_disciplina = q.id_disciplina
WHERE q.id_equipo NOT IN (SELECT id_equipo_local
                          FROM encuentro
                          WHERE estado IN ('EN_JUEGO', 'FINALIZADO', 'SUSPENDIDO'))
  AND q.id_equipo NOT IN (SELECT id_equipo_visitante
                          FROM encuentro
                          WHERE estado IN ('EN_JUEGO', 'FINALIZADO', 'SUSPENDIDO'))
ORDER BY di.deporte, q.nombre;
GO

/* ---------------------------------------------------------------------
   CONSULTA 8. Identificar torneos con más encuentros que el promedio.
   Promedio = total de encuentros / total de torneos (se multiplica por
   1.0 para que la división tenga decimales).
   HAVING filtra los grupos (torneos) después de contar.
   --------------------------------------------------------------------- */
SELECT t.codigo, t.nombre AS torneo, COUNT(*) AS encuentros
FROM torneo t
JOIN encuentro e ON e.id_torneo = t.id_torneo
GROUP BY t.codigo, t.nombre
HAVING COUNT(*) > (SELECT COUNT(*) * 1.0 FROM encuentro)
                / (SELECT COUNT(*) FROM torneo)
ORDER BY encuentros DESC;
GO

/* ---------------------------------------------------------------------
   CONSULTA 9. Consultar deportistas con participación superior al
   promedio.
   Participación = encuentros jugados (filas en participacion_encuentro).
   Promedio = total de participaciones / deportistas que han jugado.
   --------------------------------------------------------------------- */
SELECT p.nombres, p.apellidos, di.deporte,
       COUNT(*) AS encuentros_jugados
FROM participacion_encuentro pe
JOIN deportista d  ON d.id_deportista  = pe.id_deportista
JOIN persona    p  ON p.id_persona     = d.id_persona
JOIN disciplina di ON di.id_disciplina = d.id_disciplina
GROUP BY d.id_deportista, p.nombres, p.apellidos, di.deporte
HAVING COUNT(*) > (SELECT COUNT(*) * 1.0 / COUNT(DISTINCT id_deportista)
                   FROM participacion_encuentro)
ORDER BY encuentros_jugados DESC;
GO

/* ---------------------------------------------------------------------
   CONSULTA 10. Mostrar equipos con más victorias en un torneo.
   Victorias, empates y derrotas de cada equipo en el torneo TOR-0007,
   de mayor a menor número de victorias (el primero es el que más ganó).
   Usa la misma vista de la consulta 4 (local + visitante).
   --------------------------------------------------------------------- */
SELECT q.nombre AS equipo,
       SUM(r.victoria) AS victorias,
       SUM(r.empate)   AS empates,
       SUM(r.derrota)  AS derrotas
FROM vw_resultado_equipo r
JOIN equipo q ON q.id_equipo = r.id_equipo
JOIN torneo t ON t.id_torneo = r.id_torneo
WHERE t.codigo = 'TOR-0007'
GROUP BY q.nombre
ORDER BY victorias DESC, empates DESC;
GO
