/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Integrantes: Juan Sebastián Cárdenas, Juan David Segura
   Script 05: consultas de negocio (10 preguntas del caso)
   ---------------------------------------------------------------------
   Cada consulta indica: pregunta, propósito para la organización y
   técnicas SQL usadas. Los parámetros se declaran con DECLARE para
   poder cambiarlos fácilmente durante la sustentación.
   Requiere: scripts 01 a 04 ejecutados.
   La interpretación de los resultados está en
   documentacion/consultas_negocio.md
   ===================================================================== */
USE GestionDeportiva;
GO
SET NOCOUNT ON;
GO

/* =====================================================================
   CONSULTA 1. Listar deportistas por disciplina y estado.
   Propósito: conocer, para un deporte, qué deportistas hay en cada
   disciplina (modalidad, rama, categoría) y en qué estado se encuentran
   (activos, lesionados, suspendidos, retirados).
   Técnicas: vista (JOIN persona-deportista-disciplina), WHERE con
   parámetros, ORDER BY; resumen con COUNT y GROUP BY.
   ===================================================================== */
PRINT N'=== CONSULTA 1a: deportistas de un deporte filtrados por estado ===';
DECLARE @deporte NVARCHAR(40) = N'Baloncesto';
DECLARE @estado  VARCHAR(12)  = 'LESIONADO';

SELECT codigo_disciplina, modalidad, rama, categoria, estado,
       id_deportista, apellidos, nombres, edad
FROM dbo.vw_deportista_detalle
WHERE deporte = @deporte
  AND estado  = @estado
ORDER BY modalidad, rama, categoria, apellidos, nombres;
GO

PRINT N'=== CONSULTA 1b: cantidad de deportistas por deporte y estado ===';
SELECT deporte,
       COUNT(*)                                             AS total,
       SUM(CASE WHEN estado = 'ACTIVO'     THEN 1 ELSE 0 END) AS activos,
       SUM(CASE WHEN estado = 'LESIONADO'  THEN 1 ELSE 0 END) AS lesionados,
       SUM(CASE WHEN estado = 'SUSPENDIDO' THEN 1 ELSE 0 END) AS suspendidos,
       SUM(CASE WHEN estado = 'RETIRADO'   THEN 1 ELSE 0 END) AS retirados
FROM dbo.vw_deportista_detalle
GROUP BY deporte
ORDER BY total DESC, deporte;
GO

/* =====================================================================
   CONSULTA 2. Consultar encuentros entre dos fechas.
   Propósito: programación y seguimiento de encuentros de un periodo
   (agenda de escenarios, resultados de la semana/mes).
   Técnicas: vista, WHERE con rango de fechas, ORDER BY.
   Nota: se usa "< día siguiente" para incluir todo el último día,
   porque fecha_hora tiene hora.
   ===================================================================== */
PRINT N'=== CONSULTA 2: encuentros entre dos fechas ===';
DECLARE @desde DATE = '2026-10-01';
DECLARE @hasta DATE = '2026-10-07';

SELECT fecha_hora, codigo_torneo, torneo, equipo_local, equipo_visitante,
       escenario, ciudad_escenario, estado,
       puntaje_local, puntaje_visitante, resultado_definitivo
FROM dbo.vw_encuentro_detalle
WHERE fecha_hora >= @desde
  AND fecha_hora <  DATEADD(DAY, 1, @hasta)
ORDER BY fecha_hora, torneo;
GO

/* =====================================================================
   CONSULTA 3. Contar encuentros por torneo y escenario.
   Propósito: medir el uso de cada escenario dentro de cada torneo para
   planear la asignación de escenarios.
   Técnicas: JOIN de tres tablas, COUNT, SUM con CASE, GROUP BY, ORDER BY.
   ===================================================================== */
PRINT N'=== CONSULTA 3: encuentros por torneo y escenario ===';
SELECT t.codigo                                               AS codigo_torneo,
       t.nombre                                               AS torneo,
       es.codigo                                              AS codigo_escenario,
       es.nombre                                              AS escenario,
       es.ciudad,
       COUNT(*)                                               AS total_encuentros,
       SUM(CASE WHEN e.estado = 'FINALIZADO' THEN 1 ELSE 0 END) AS finalizados,
       SUM(CASE WHEN e.estado = 'PROGRAMADO' THEN 1 ELSE 0 END) AS programados,
       SUM(CASE WHEN e.estado IN ('CANCELADO', 'SUSPENDIDO') THEN 1 ELSE 0 END) AS cancelados_o_suspendidos
FROM dbo.encuentro e
JOIN dbo.torneo    t  ON t.id_torneo     = e.id_torneo
JOIN dbo.escenario es ON es.id_escenario = e.id_escenario
GROUP BY t.codigo, t.nombre, es.codigo, es.nombre, es.ciudad
ORDER BY t.codigo, total_encuentros DESC, es.nombre;
GO

/* =====================================================================
   CONSULTA 4. Calcular victorias, derrotas y empates por equipo.
   Propósito: tabla de desempeño histórico de cada equipo.
   Solo cuentan resultados definitivos (regla 6). Se usa LEFT JOIN desde
   equipo para incluir también a los equipos sin partidos (regla 8), que
   aparecen con 0.
   Técnicas: vista, LEFT JOIN, COUNT, SUM con CASE, GROUP BY, ORDER BY.
   ===================================================================== */
PRINT N'=== CONSULTA 4: victorias, derrotas y empates por equipo ===';
SELECT q.codigo,
       q.nombre                                                   AS equipo,
       di.deporte,
       di.modalidad,
       COUNT(r.id_encuentro)                                      AS jugados,
       SUM(CASE WHEN r.resultado = 'VICTORIA' THEN 1 ELSE 0 END)  AS victorias,
       SUM(CASE WHEN r.resultado = 'EMPATE'   THEN 1 ELSE 0 END)  AS empates,
       SUM(CASE WHEN r.resultado = 'DERROTA'  THEN 1 ELSE 0 END)  AS derrotas,
       ISNULL(SUM(r.puntos_favor), 0)                             AS puntos_favor,
       ISNULL(SUM(r.puntos_contra), 0)                            AS puntos_contra
FROM dbo.equipo q
JOIN dbo.disciplina di                ON di.id_disciplina = q.id_disciplina
LEFT JOIN dbo.vw_resultado_equipo r   ON r.id_equipo      = q.id_equipo
GROUP BY q.codigo, q.nombre, di.deporte, di.modalidad
ORDER BY victorias DESC, empates DESC, q.nombre;
GO

/* =====================================================================
   CONSULTA 5. Mostrar encuentros con torneo, participantes y escenario.
   Propósito: ficha completa de los encuentros de un torneo: quién jugó,
   dónde, el resultado y cuántos deportistas de cada equipo participaron.
   Técnicas: JOIN entre 6 tablas (equipo dos veces con alias),
   subconsultas correlacionadas para contar deportistas, WHERE, ORDER BY.
   ===================================================================== */
PRINT N'=== CONSULTA 5: encuentros con torneo, participantes y escenario ===';
DECLARE @codigo_torneo VARCHAR(20) = 'TOR-0007';

SELECT e.id_encuentro,
       e.jornada,
       e.fecha_hora,
       t.nombre                       AS torneo,
       di.deporte + N' - ' + di.modalidad AS disciplina,
       el.nombre                      AS equipo_local,
       ev.nombre                      AS equipo_visitante,
       e.puntaje_local,
       e.puntaje_visitante,
       e.estado,
       es.nombre + N' (' + es.ciudad + N')' AS escenario,
       (SELECT COUNT(*) FROM dbo.participacion_encuentro p
         WHERE p.id_encuentro = e.id_encuentro AND p.id_equipo = e.id_equipo_local)     AS deportistas_local,
       (SELECT COUNT(*) FROM dbo.participacion_encuentro p
         WHERE p.id_encuentro = e.id_encuentro AND p.id_equipo = e.id_equipo_visitante) AS deportistas_visitante
FROM dbo.encuentro  e
JOIN dbo.torneo     t  ON t.id_torneo      = e.id_torneo
JOIN dbo.disciplina di ON di.id_disciplina = t.id_disciplina
JOIN dbo.equipo     el ON el.id_equipo     = e.id_equipo_local
JOIN dbo.equipo     ev ON ev.id_equipo     = e.id_equipo_visitante
JOIN dbo.escenario  es ON es.id_escenario  = e.id_escenario
WHERE t.codigo = @codigo_torneo
ORDER BY e.jornada, e.fecha_hora;
GO

/* =====================================================================
   CONSULTA 6. Listar escenarios sin encuentros programados.
   Propósito: identificar escenarios subutilizados o libres para asignar
   nuevos encuentros (regla 8: se permiten escenarios sin encuentros).
   6a: escenarios que nunca han tenido ningún encuentro (LEFT JOIN ... IS NULL).
   6b: escenarios disponibles que hoy no tienen encuentros PROGRAMADOS a
       futuro (NOT EXISTS), es decir, libres para la próxima programación.
   ===================================================================== */
PRINT N'=== CONSULTA 6a: escenarios que nunca han tenido encuentros ===';
SELECT es.codigo, es.nombre, es.tipo, es.ciudad, es.capacidad, es.estado
FROM dbo.escenario es
LEFT JOIN dbo.encuentro e ON e.id_escenario = es.id_escenario
WHERE e.id_encuentro IS NULL
ORDER BY es.tipo, es.ciudad, es.nombre;
GO

PRINT N'=== CONSULTA 6b: escenarios disponibles sin encuentros PROGRAMADOS ===';
SELECT es.tipo,
       COUNT(*) AS escenarios_libres
FROM dbo.escenario es
WHERE es.estado = 'DISPONIBLE'
  AND NOT EXISTS (SELECT 1
                  FROM dbo.encuentro e
                  WHERE e.id_escenario = es.id_escenario
                    AND e.estado = 'PROGRAMADO')
GROUP BY es.tipo
ORDER BY escenarios_libres DESC;
GO

/* =====================================================================
   CONSULTA 7. Encontrar equipos que nunca han disputado encuentros.
   Propósito: detectar equipos inscritos en el sistema que no han jugado
   (regla 8). "Disputar" = jugar un encuentro (EN_JUEGO, FINALIZADO o
   SUSPENDIDO); un partido solo programado o cancelado no cuenta.
   Técnicas: subconsulta NOT EXISTS, JOIN, ORDER BY.
   ===================================================================== */
PRINT N'=== CONSULTA 7: equipos que nunca han disputado encuentros ===';
SELECT q.codigo, q.nombre AS equipo, di.deporte, di.modalidad, di.rama, di.categoria,
       q.ciudad, q.estado,
       (SELECT COUNT(*) FROM dbo.inscripcion i WHERE i.id_equipo = q.id_equipo) AS inscripciones
FROM dbo.equipo q
JOIN dbo.disciplina di ON di.id_disciplina = q.id_disciplina
WHERE NOT EXISTS (SELECT 1
                  FROM dbo.encuentro e
                  WHERE q.id_equipo IN (e.id_equipo_local, e.id_equipo_visitante)
                    AND e.estado IN ('EN_JUEGO', 'FINALIZADO', 'SUSPENDIDO'))
ORDER BY di.deporte, q.nombre;
GO

/* =====================================================================
   CONSULTA 8. Identificar torneos con más encuentros que el promedio.
   Propósito: reconocer los torneos más exigentes en logística
   (escenarios, árbitros, programación).
   El promedio se calcula sobre TODOS los torneos, incluidos los que no
   tienen encuentros (cancelados o sin equipos aprobados), por eso se usa
   LEFT JOIN en la subconsulta.
   Técnicas: LEFT JOIN, COUNT, GROUP BY, HAVING con subconsulta, AVG.
   ===================================================================== */
PRINT N'=== CONSULTA 8: torneos con más encuentros que el promedio ===';
SELECT t.codigo, t.nombre AS torneo, t.estado, t.fecha_inicio, t.fecha_fin,
       COUNT(e.id_encuentro) AS encuentros,
       (SELECT CAST(AVG(CAST(x.n AS DECIMAL(10,2))) AS DECIMAL(10,2))
          FROM (SELECT COUNT(e2.id_encuentro) AS n
                  FROM dbo.torneo t2
                  LEFT JOIN dbo.encuentro e2 ON e2.id_torneo = t2.id_torneo
                 GROUP BY t2.id_torneo) x) AS promedio_general
FROM dbo.torneo t
LEFT JOIN dbo.encuentro e ON e.id_torneo = t.id_torneo
GROUP BY t.codigo, t.nombre, t.estado, t.fecha_inicio, t.fecha_fin
HAVING COUNT(e.id_encuentro) > (SELECT AVG(CAST(x.n AS DECIMAL(10,2)))
                                  FROM (SELECT COUNT(e2.id_encuentro) AS n
                                          FROM dbo.torneo t2
                                          LEFT JOIN dbo.encuentro e2 ON e2.id_torneo = t2.id_torneo
                                         GROUP BY t2.id_torneo) x)
ORDER BY encuentros DESC, t.codigo;
GO

/* =====================================================================
   CONSULTA 9. Consultar deportistas con participación superior al promedio.
   Propósito: identificar a los deportistas más utilizados por sus
   equipos y su desempeño (minutos y calificación promedio).
   Participación = número de encuentros en los que el deportista jugó.
   El promedio se calcula entre los deportistas que han jugado al menos
   un encuentro.
   Técnicas: JOIN, COUNT, SUM, AVG, GROUP BY, HAVING con subconsulta.
   ===================================================================== */
PRINT N'=== CONSULTA 9: deportistas con participación superior al promedio ===';
SELECT d.id_deportista,
       p.apellidos + N', ' + p.nombres     AS deportista,
       di.deporte + N' - ' + di.modalidad  AS disciplina,
       d.estado,
       COUNT(*)                            AS encuentros_jugados,
       SUM(CASE WHEN pe.es_titular = 1 THEN 1 ELSE 0 END) AS como_titular,
       SUM(pe.minutos_jugados)             AS minutos_totales,
       CAST(AVG(pe.calificacion) AS DECIMAL(4,2)) AS calificacion_promedio
FROM dbo.participacion_encuentro pe
JOIN dbo.deportista d  ON d.id_deportista  = pe.id_deportista
JOIN dbo.persona    p  ON p.id_persona     = d.id_persona
JOIN dbo.disciplina di ON di.id_disciplina = d.id_disciplina
GROUP BY d.id_deportista, p.apellidos, p.nombres, di.deporte, di.modalidad, d.estado
HAVING COUNT(*) > (SELECT AVG(CAST(x.n AS DECIMAL(10,2)))
                     FROM (SELECT COUNT(*) AS n
                             FROM dbo.participacion_encuentro
                            GROUP BY id_deportista) x)
ORDER BY encuentros_jugados DESC, calificacion_promedio DESC;
GO

/* =====================================================================
   CONSULTA 10. Mostrar equipos con más victorias en un torneo.
   Propósito: identificar al líder (o líderes empatados) de cada torneo
   según victorias con resultado definitivo.
   10a: un torneo concreto (parámetro) con la tabla de victorias.
   10b: todos los torneos: equipo(s) con el máximo de victorias, usando
        una subconsulta correlacionada; si hay empate se muestran todos.
   Técnicas: CTE (WITH), vista, GROUP BY, subconsulta correlacionada, MAX.
   ===================================================================== */
PRINT N'=== CONSULTA 10a: victorias por equipo en un torneo ===';
DECLARE @torneo VARCHAR(20) = 'TOR-0007';

SELECT q.nombre AS equipo,
       COUNT(*)                                                  AS jugados,
       SUM(CASE WHEN r.resultado = 'VICTORIA' THEN 1 ELSE 0 END) AS victorias,
       SUM(CASE WHEN r.resultado = 'EMPATE'   THEN 1 ELSE 0 END) AS empates,
       SUM(CASE WHEN r.resultado = 'DERROTA'  THEN 1 ELSE 0 END) AS derrotas
FROM dbo.vw_resultado_equipo r
JOIN dbo.torneo t ON t.id_torneo = r.id_torneo
JOIN dbo.equipo q ON q.id_equipo = r.id_equipo
WHERE t.codigo = @torneo
GROUP BY q.nombre
ORDER BY victorias DESC, empates DESC;
GO

PRINT N'=== CONSULTA 10b: equipo(s) con más victorias en cada torneo ===';
WITH victorias_torneo AS (
    SELECT r.id_torneo, r.id_equipo, COUNT(*) AS victorias
    FROM dbo.vw_resultado_equipo r
    WHERE r.resultado = 'VICTORIA'
    GROUP BY r.id_torneo, r.id_equipo
)
SELECT t.codigo, t.nombre AS torneo, t.estado AS estado_torneo,
       q.nombre AS equipo, v.victorias
FROM victorias_torneo v
JOIN dbo.torneo t ON t.id_torneo = v.id_torneo
JOIN dbo.equipo q ON q.id_equipo = v.id_equipo
WHERE v.victorias = (SELECT MAX(v2.victorias)
                       FROM victorias_torneo v2
                      WHERE v2.id_torneo = v.id_torneo)
ORDER BY t.codigo, q.nombre;
GO
