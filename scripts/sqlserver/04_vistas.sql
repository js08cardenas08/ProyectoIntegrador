/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Integrantes: Juan Sebastián Cárdenas, Juan David Segura
   Script 04: vista de resultados por equipo
   ---------------------------------------------------------------------
   Un equipo puede jugar un encuentro como LOCAL o como VISITANTE.
   Para contar sus victorias hay que mirar las dos columnas de la tabla
   encuentro. Esta vista lo resuelve una sola vez:
     - la primera parte toma los partidos donde el equipo fue local;
     - la segunda parte toma los partidos donde fue visitante;
     - UNION ALL junta las dos listas.
   Cada fila trae un 1 en victoria, empate o derrota, así las consultas
   solo tienen que sumar (SUM).
   Solo cuenta encuentros con resultado definitivo (regla 6).
   La vista no guarda datos: siempre se calcula desde la tabla encuentro.
   Se usa en las consultas 4 y 10.
   ===================================================================== */
USE GestionDeportiva;
GO

-- Vistas de una versión anterior del proyecto (ya no se usan).
DROP VIEW IF EXISTS dbo.vw_deportista_detalle;
DROP VIEW IF EXISTS dbo.vw_encuentro_detalle;
GO

CREATE OR ALTER VIEW dbo.vw_resultado_equipo
AS
-- Partidos en los que el equipo jugó como LOCAL
SELECT id_encuentro,
       id_torneo,
       id_equipo_local AS id_equipo,
       CASE WHEN puntaje_local > puntaje_visitante THEN 1 ELSE 0 END AS victoria,
       CASE WHEN puntaje_local = puntaje_visitante THEN 1 ELSE 0 END AS empate,
       CASE WHEN puntaje_local < puntaje_visitante THEN 1 ELSE 0 END AS derrota
FROM dbo.encuentro
WHERE resultado_definitivo = 1

UNION ALL

-- Partidos en los que el equipo jugó como VISITANTE
SELECT id_encuentro,
       id_torneo,
       id_equipo_visitante,
       CASE WHEN puntaje_visitante > puntaje_local THEN 1 ELSE 0 END,
       CASE WHEN puntaje_visitante = puntaje_local THEN 1 ELSE 0 END,
       CASE WHEN puntaje_visitante < puntaje_local THEN 1 ELSE 0 END
FROM dbo.encuentro
WHERE resultado_definitivo = 1;
GO

PRINT N'Script 04 finalizado: vista vw_resultado_equipo creada.';
GO
