/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Script 04: vistas
   ---------------------------------------------------------------------
   Las vistas guardan JOIN que se repiten en varias consultas de negocio.
   No almacenan datos: siempre muestran la información actual de las
   tablas, por lo que no generan redundancia.
   (Se ejecuta antes del script 05 porque las consultas las utilizan.)
   ===================================================================== */
USE GestionDeportiva;
GO

/* ---------------------------------------------------------------------
   vw_deportista_detalle
   Un deportista con sus datos personales (tabla persona) y su
   disciplina principal. Usada en la consulta 1.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_deportista_detalle
AS
SELECT d.id_deportista,
       p.tipo_documento,
       p.numero_documento,
       p.nombres,
       p.apellidos,
       p.sexo,
       DATEDIFF(YEAR, p.fecha_nacimiento, GETDATE())
         - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, p.fecha_nacimiento, GETDATE()), p.fecha_nacimiento) > GETDATE()
                THEN 1 ELSE 0 END                      AS edad,
       d.estado,
       d.fecha_ingreso,
       di.id_disciplina,
       di.codigo                                       AS codigo_disciplina,
       di.deporte,
       di.modalidad,
       di.rama,
       di.categoria
FROM dbo.deportista d
JOIN dbo.persona    p  ON p.id_persona     = d.id_persona
JOIN dbo.disciplina di ON di.id_disciplina = d.id_disciplina;
GO

/* ---------------------------------------------------------------------
   vw_encuentro_detalle
   Encuentro con torneo, disciplina, escenario y nombres de los dos
   equipos (la tabla equipo se une dos veces con alias distintos).
   Usada en las consultas 2 y 5.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_encuentro_detalle
AS
SELECT e.id_encuentro,
       e.fecha_hora,
       e.jornada,
       e.estado,
       e.puntaje_local,
       e.puntaje_visitante,
       e.resultado_definitivo,
       t.id_torneo,
       t.codigo        AS codigo_torneo,
       t.nombre        AS torneo,
       di.deporte,
       di.modalidad,
       es.id_escenario,
       es.nombre       AS escenario,
       es.ciudad       AS ciudad_escenario,
       el.id_equipo    AS id_equipo_local,
       el.nombre       AS equipo_local,
       ev.id_equipo    AS id_equipo_visitante,
       ev.nombre       AS equipo_visitante
FROM dbo.encuentro  e
JOIN dbo.torneo     t  ON t.id_torneo      = e.id_torneo
JOIN dbo.disciplina di ON di.id_disciplina = t.id_disciplina
JOIN dbo.escenario  es ON es.id_escenario  = e.id_escenario
JOIN dbo.equipo     el ON el.id_equipo     = e.id_equipo_local
JOIN dbo.equipo     ev ON ev.id_equipo     = e.id_equipo_visitante;
GO

/* ---------------------------------------------------------------------
   vw_resultado_equipo
   Convierte cada encuentro con resultado DEFINITIVO en dos filas, una por
   equipo, con su marcador a favor/en contra y el resultado
   (VICTORIA, DERROTA o EMPATE). Solo se cuentan resultados definitivos
   (regla 6). Usada en las consultas 4 y 10.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_resultado_equipo
AS
SELECT e.id_encuentro,
       e.id_torneo,
       e.id_equipo_local       AS id_equipo,
       e.id_equipo_visitante   AS id_rival,
       'LOCAL'                 AS condicion,
       e.puntaje_local         AS puntos_favor,
       e.puntaje_visitante     AS puntos_contra,
       CASE WHEN e.puntaje_local > e.puntaje_visitante THEN 'VICTORIA'
            WHEN e.puntaje_local < e.puntaje_visitante THEN 'DERROTA'
            ELSE 'EMPATE' END  AS resultado
FROM dbo.encuentro e
WHERE e.resultado_definitivo = 1
UNION ALL
SELECT e.id_encuentro,
       e.id_torneo,
       e.id_equipo_visitante,
       e.id_equipo_local,
       'VISITANTE',
       e.puntaje_visitante,
       e.puntaje_local,
       CASE WHEN e.puntaje_visitante > e.puntaje_local THEN 'VICTORIA'
            WHEN e.puntaje_visitante < e.puntaje_local THEN 'DERROTA'
            ELSE 'EMPATE' END
FROM dbo.encuentro e
WHERE e.resultado_definitivo = 1;
GO

PRINT N'Script 04 finalizado: vistas creadas.';
GO
