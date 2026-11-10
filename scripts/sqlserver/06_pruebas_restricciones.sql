/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Script 06: pruebas de restricciones y reglas de negocio
   ---------------------------------------------------------------------
   Cómo funciona:
   - Cada prueba es una instrucción (INSERT/UPDATE/DELETE) que se ejecuta
     con el procedimiento temporal #probar dentro de una transacción.
   - La transacción SIEMPRE se deshace (ROLLBACK), por lo que las pruebas
     no modifican los datos semilla y el script se puede repetir.
   - Se compara el resultado esperado (ACEPTADO o RECHAZADO) con el
     obtenido y se guarda el mensaje de error de SQL Server.
   - Al final se muestra la tabla de resultados y el resumen PASA/FALLA.
   Los identificadores de prueba se buscan con consultas (no se escriben
   a mano), así el script funciona sobre cualquier carga de datos válida.
   Requiere: scripts 01, 02 y 03 ejecutados.
   ===================================================================== */
USE GestionDeportiva;
GO
SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
CREATE TABLE #resultado (
    codigo      VARCHAR(5),
    regla       NVARCHAR(60),
    prueba      NVARCHAR(200),
    esperado    VARCHAR(10),
    obtenido    VARCHAR(10),
    veredicto   VARCHAR(5),
    mensaje     NVARCHAR(400)
);
GO

IF OBJECT_ID('tempdb..#probar') IS NOT NULL DROP PROCEDURE #probar;
GO
CREATE PROCEDURE #probar
    @codigo    VARCHAR(5),
    @regla     NVARCHAR(60),
    @prueba    NVARCHAR(200),
    @esperado  VARCHAR(10),          -- 'ACEPTADO' o 'RECHAZADO'
    @sentencia NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @obtenido VARCHAR(10), @mensaje NVARCHAR(4000);
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC sp_executesql @sentencia;
        SET @obtenido = 'ACEPTADO';
        SET @mensaje  = N'Operación ejecutada sin errores (luego se deshizo con ROLLBACK).';
        ROLLBACK TRANSACTION;          -- las pruebas no dejan cambios
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @obtenido = 'RECHAZADO';
        SET @mensaje  = ERROR_MESSAGE();
    END CATCH;

    INSERT INTO #resultado
    VALUES (@codigo, @regla, @prueba, @esperado, @obtenido,
            CASE WHEN @esperado = @obtenido THEN 'PASA' ELSE 'FALLA' END,
            LEFT(@mensaje, 400));
END;
GO

/* ---------------------------------------------------------------------
   Datos de apoyo para las pruebas (se buscan en la base)
   --------------------------------------------------------------------- */
DECLARE @sql NVARCHAR(MAX);

-- Encuentro con resultado definitivo
DECLARE @enc_definitivo INT = (SELECT TOP 1 id_encuentro FROM dbo.encuentro
                               WHERE resultado_definitivo = 1 ORDER BY id_encuentro);
-- Encuentro programado de un torneo en curso
DECLARE @enc_programado INT = (SELECT TOP 1 e.id_encuentro FROM dbo.encuentro e
                               JOIN dbo.torneo t ON t.id_torneo = e.id_torneo
                               WHERE e.estado = 'PROGRAMADO' AND t.estado = 'EN_CURSO' ORDER BY e.id_encuentro);
-- Torneo futuro con al menos dos equipos aprobados
DECLARE @torneo_futuro INT = (SELECT TOP 1 t.id_torneo FROM dbo.torneo t
                              WHERE t.estado = 'PROGRAMADO'
                                AND (SELECT COUNT(*) FROM dbo.inscripcion i
                                     WHERE i.id_torneo = t.id_torneo AND i.estado = 'APROBADA') >= 2
                              ORDER BY t.id_torneo);
DECLARE @eq_aprobado_1 INT = (SELECT MIN(id_equipo) FROM dbo.inscripcion WHERE id_torneo = @torneo_futuro AND estado = 'APROBADA');
DECLARE @eq_aprobado_2 INT = (SELECT MAX(id_equipo) FROM dbo.inscripcion WHERE id_torneo = @torneo_futuro AND estado = 'APROBADA');
-- Equipo de la misma disciplina SIN inscripción aprobada en ese torneo
DECLARE @eq_sin_aprobar INT = (SELECT TOP 1 q.id_equipo FROM dbo.equipo q
                               JOIN dbo.torneo t ON t.id_torneo = @torneo_futuro AND t.id_disciplina = q.id_disciplina
                               WHERE NOT EXISTS (SELECT 1 FROM dbo.inscripcion i WHERE i.id_torneo = t.id_torneo
                                                 AND i.id_equipo = q.id_equipo AND i.estado = 'APROBADA')
                               ORDER BY q.id_equipo);
-- Equipo de OTRA disciplina
DECLARE @eq_otra_disciplina INT = (SELECT TOP 1 q.id_equipo FROM dbo.equipo q
                                   JOIN dbo.torneo t ON t.id_torneo = @torneo_futuro
                                   WHERE q.id_disciplina <> t.id_disciplina ORDER BY q.id_equipo);
DECLARE @inicio_torneo_futuro DATE = (SELECT fecha_inicio FROM dbo.torneo WHERE id_torneo = @torneo_futuro);
DECLARE @escenario INT = (SELECT TOP 1 id_escenario FROM dbo.escenario WHERE estado = 'DISPONIBLE' ORDER BY id_escenario);
-- Un encuentro existente (para reservar su mismo escenario y hora)
DECLARE @enc_existente INT = (SELECT TOP 1 id_encuentro FROM dbo.encuentro
                              WHERE id_torneo = @torneo_futuro ORDER BY id_encuentro);
-- Equipo con entrenador PRINCIPAL vigente y un entrenador que no ha estado en ese equipo
DECLARE @eq_con_principal INT = (SELECT TOP 1 id_equipo FROM dbo.entrenador_equipo
                                 WHERE rol = 'PRINCIPAL' AND fecha_fin IS NULL ORDER BY id_equipo);
DECLARE @entrenador_nuevo INT = (SELECT TOP 1 en.id_entrenador FROM dbo.entrenador en
                                 WHERE NOT EXISTS (SELECT 1 FROM dbo.entrenador_equipo a
                                                   WHERE a.id_entrenador = en.id_entrenador AND a.id_equipo = @eq_con_principal)
                                 ORDER BY en.id_entrenador);
-- Integración vigente de un deportista
DECLARE @integrante INT = (SELECT TOP 1 id_integrante FROM dbo.integrante_equipo WHERE fecha_fin IS NULL ORDER BY id_integrante);
-- Encuentro finalizado y un deportista que nunca integró esos equipos
DECLARE @enc_finalizado INT = (SELECT TOP 1 id_encuentro FROM dbo.encuentro WHERE estado = 'FINALIZADO' ORDER BY id_encuentro);
DECLARE @dep_ajeno INT = (SELECT TOP 1 d.id_deportista FROM dbo.deportista d
                          WHERE NOT EXISTS (SELECT 1 FROM dbo.integrante_equipo m
                                            JOIN dbo.encuentro e ON e.id_encuentro = @enc_finalizado
                                            WHERE m.id_deportista = d.id_deportista
                                              AND m.id_equipo IN (e.id_equipo_local, e.id_equipo_visitante))
                          ORDER BY d.id_deportista);
-- Inscripción existente (para duplicarla)
DECLARE @insc INT = (SELECT MIN(id_inscripcion) FROM dbo.inscripcion);

/* =====================================================================
   A. UNICIDAD (UNIQUE) Y CÓDIGOS DUPLICADOS
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.disciplina (codigo, deporte, modalidad, rama, categoria, tipo_participacion)
             SELECT codigo, N''Otro'', N''Otra'', ''MIXTA'', ''ELITE'', ''CONJUNTO'' FROM dbo.disciplina WHERE id_disciplina = 1;';
EXEC #probar 'P01', N'Regla 1 - identificador único', N'Disciplina con código duplicado', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.persona (tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento, sexo, correo)
             SELECT tipo_documento, numero_documento, N''Prueba'', N''Duplicada'', ''2000-01-01'', ''M'', ''nuevo.correo@correo.example''
             FROM dbo.persona WHERE id_persona = 1;';
EXEC #probar 'P02', N'Regla 1 - identificador único', N'Persona con documento duplicado', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.persona (tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento, sexo, correo)
             SELECT ''CC'', ''9999999901'', N''Prueba'', N''Correo'', ''2000-01-01'', ''F'', correo FROM dbo.persona WHERE id_persona = 1;';
EXEC #probar 'P03', N'Regla 1 - identificador único', N'Persona con correo duplicado', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.equipo (codigo, nombre, id_disciplina, ciudad, fecha_fundacion)
             SELECT codigo, N''Equipo Prueba'', id_disciplina, N''Bogotá'', ''2020-01-01'' FROM dbo.equipo WHERE id_equipo = 1;';
EXEC #probar 'P04', N'Regla 1 - identificador único', N'Equipo con código duplicado', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.deportista (id_persona, id_disciplina) SELECT id_persona, id_disciplina FROM dbo.deportista WHERE id_deportista = 1;';
EXEC #probar 'P05', N'Regla 1 - identificador único', N'Misma persona registrada dos veces como deportista', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.inscripcion (id_torneo, id_equipo, fecha_inscripcion)
             SELECT id_torneo, id_equipo, fecha_inscripcion FROM dbo.inscripcion WHERE id_inscripcion = ' + CAST(@insc AS NVARCHAR(10)) + N';';
EXEC #probar 'P06', N'Inscripciones', N'Inscribir dos veces el mismo equipo en el mismo torneo', 'RECHAZADO', @sql;

/* =====================================================================
   B. CLAVES FORÁNEAS INEXISTENTES E INTEGRIDAD REFERENCIAL
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.deportista (id_persona, id_disciplina) VALUES (9000, 999999);';
EXEC #probar 'P07', N'Integridad referencial', N'Deportista con disciplina inexistente (FK)', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.encuentro (id_torneo, id_escenario, id_equipo_local, id_equipo_visitante, fecha_hora)
             VALUES (999999, 1, 1, 2, ''2026-12-01T10:00:00'');';
EXEC #probar 'P08', N'Integridad referencial', N'Encuentro con torneo inexistente (FK)', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.integrante_equipo (id_deportista, id_equipo, fecha_inicio) VALUES (1, 999999, ''2024-01-01'');';
EXEC #probar 'P09', N'Integridad referencial', N'Integrante en equipo inexistente (FK)', 'RECHAZADO', @sql;

SET @sql = N'DELETE FROM dbo.disciplina WHERE id_disciplina = (SELECT TOP 1 id_disciplina FROM dbo.torneo);';
EXEC #probar 'P10', N'Integridad referencial', N'Borrar una disciplina que tiene torneos y deportistas', 'RECHAZADO', @sql;

/* =====================================================================
   C. NOT NULL, CHECK Y VALORES FUERA DE RANGO
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.equipo (codigo, nombre, id_disciplina, ciudad, fecha_fundacion) VALUES (''EQ-PRUEBA'', NULL, 1, N''Cali'', ''2020-01-01'');';
EXEC #probar 'P11', N'NOT NULL', N'Equipo sin nombre', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.escenario (codigo, nombre, tipo, ciudad, direccion, capacidad) VALUES (''ESC-P1'', N''Prueba cero'', ''CANCHA'', N''Cali'', N''Calle 1'', 0);';
EXEC #probar 'P12', N'Regla 4 - capacidad positiva', N'Escenario con capacidad 0', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.escenario (codigo, nombre, tipo, ciudad, direccion, capacidad) VALUES (''ESC-P2'', N''Prueba negativa'', ''CANCHA'', N''Cali'', N''Calle 1'', -50);';
EXEC #probar 'P13', N'Regla 4 - capacidad positiva', N'Escenario con capacidad negativa', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.escenario (codigo, nombre, tipo, ciudad, direccion, capacidad) VALUES (''ESC-P3'', N''Prueba válida'', ''CANCHA'', N''Cali'', N''Calle 1'', 500);
             IF (SELECT estado FROM dbo.escenario WHERE codigo = ''ESC-P3'') <> ''DISPONIBLE'' THROW 50100, ''DEFAULT de estado no aplicado'', 1;';
EXEC #probar 'P14', N'Regla 4 / Regla 8', N'Escenario válido (capacidad 500, estado DEFAULT DISPONIBLE, sin encuentros)', 'ACEPTADO', @sql;

SET @sql = N'INSERT INTO dbo.torneo (codigo, nombre, id_disciplina, fecha_inicio, fecha_fin) VALUES (''TOR-P1'', N''Torneo fechas invertidas'', 1, ''2027-05-01'', ''2027-04-01'');';
EXEC #probar 'P15', N'Regla 4 - fechas coherentes', N'Torneo con fecha final anterior a la inicial', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.torneo (codigo, nombre, id_disciplina, fecha_inicio, fecha_fin) VALUES (''TOR-P2'', N''Torneo válido'', 1, ''2027-04-01'', ''2027-05-01'');
             IF (SELECT estado FROM dbo.torneo WHERE codigo = ''TOR-P2'') <> ''PROGRAMADO'' THROW 50100, ''DEFAULT de estado no aplicado'', 1;';
EXEC #probar 'P16', N'Regla 4 - fechas coherentes', N'Torneo válido (estado DEFAULT PROGRAMADO)', 'ACEPTADO', @sql;

SET @sql = N'UPDATE dbo.deportista SET estado = ''VACACIONES'' WHERE id_deportista = 1;';
EXEC #probar 'P17', N'Dominio de estados', N'Deportista con estado no permitido', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.persona (tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento, sexo, correo)
             VALUES (''CC'', ''9999999902'', N''Prueba'', N''Correo'', ''2000-01-01'', ''F'', ''correo-sin-arroba.example'');';
EXEC #probar 'P18', N'Formato de datos', N'Correo sin formato válido', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.persona (tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento, sexo, correo)
             VALUES (''CC'', ''9999999903'', N''Prueba'', N''Futuro'', DATEADD(YEAR, 1, GETDATE()), ''F'', ''futuro@correo.example'');';
EXEC #probar 'P19', N'Fechas coherentes', N'Persona con fecha de nacimiento futura', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.integrante_equipo SET numero_camiseta = 120 WHERE id_integrante = 1;';
EXEC #probar 'P20', N'Valores fuera de rango', N'Número de camiseta 120 (permitido 0-99)', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.participacion_encuentro SET calificacion = 11.5 WHERE id_participacion = 1;';
EXEC #probar 'P21', N'Valores fuera de rango', N'Calificación 11,5 (permitido 0-10)', 'RECHAZADO', @sql;

/* =====================================================================
   D. REGLA 2: ENTRENADORES POR PERIODOS
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.entrenador_equipo (id_entrenador, id_equipo, rol, fecha_inicio, fecha_fin)
             VALUES (' + CAST(@entrenador_nuevo AS NVARCHAR(10)) + N', ' + CAST(@eq_con_principal AS NVARCHAR(10)) + N', ''ASISTENTE'', ''2026-05-01'', ''2026-03-01'');';
EXEC #probar 'P22', N'Regla 2 - vigencia', N'Asignación con fecha fin anterior a fecha inicio', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.entrenador_equipo (id_entrenador, id_equipo, rol, fecha_inicio)
             VALUES (' + CAST(@entrenador_nuevo AS NVARCHAR(10)) + N', ' + CAST(@eq_con_principal AS NVARCHAR(10)) + N', ''PRINCIPAL'', ''2026-06-01'');';
EXEC #probar 'P23', N'Regla 2 - vigencia', N'Segundo entrenador PRINCIPAL con periodo cruzado en el mismo equipo', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.entrenador_equipo (id_entrenador, id_equipo, rol, fecha_inicio, fecha_fin)
             VALUES (' + CAST(@entrenador_nuevo AS NVARCHAR(10)) + N', ' + CAST(@eq_con_principal AS NVARCHAR(10)) + N', ''ASISTENTE'', ''2026-06-01'', ''2026-12-31'');';
EXEC #probar 'P24', N'Regla 2 - vigencia', N'Entrenador ASISTENTE con periodo válido', 'ACEPTADO', @sql;

SET @sql = N'INSERT INTO dbo.entrenador_equipo (id_entrenador, id_equipo, rol, fecha_inicio)
             VALUES (' + CAST(@entrenador_nuevo AS NVARCHAR(10)) + N', ' + CAST(@eq_con_principal AS NVARCHAR(10)) + N', ''ASISTENTE'', ''1990-01-01'');';
EXEC #probar 'P25', N'Regla 2 - vigencia', N'Asignación que empieza antes de la fundación del equipo', 'RECHAZADO', @sql;

/* =====================================================================
   E. REGLA 3: DEPORTISTAS EN EQUIPOS A LO LARGO DEL TIEMPO
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.integrante_equipo (id_deportista, id_equipo, funcion, fecha_inicio)
             SELECT id_deportista, id_equipo, ''SUPLENTE'', DATEADD(DAY, 10, fecha_inicio)
             FROM dbo.integrante_equipo WHERE id_integrante = ' + CAST(@integrante AS NVARCHAR(10)) + N';';
EXEC #probar 'P26', N'Regla 3 - función y fechas', N'Deportista con dos periodos cruzados en el mismo equipo', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.integrante_equipo SET funcion = ''ENTRENADOR'' WHERE id_integrante = 1;';
EXEC #probar 'P27', N'Regla 3 - función y fechas', N'Función no permitida para un integrante', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.integrante_equipo (id_deportista, id_equipo, funcion, fecha_inicio, fecha_fin)
             SELECT TOP 1 d.id_deportista, q.id_equipo, ''TITULAR'', ''2026-11-01'', ''2026-10-01''
             FROM dbo.deportista d CROSS JOIN dbo.equipo q WHERE q.id_equipo = 1 ORDER BY d.id_deportista DESC;';
EXEC #probar 'P28', N'Regla 3 - función y fechas', N'Participación con fecha fin anterior a fecha inicio', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.integrante_equipo (id_deportista, id_equipo, funcion, numero_camiseta, fecha_inicio)
             SELECT TOP 1 d.id_deportista, 1, ''RESERVA'', 77, ''2026-11-01''
             FROM dbo.deportista d
             WHERE NOT EXISTS (SELECT 1 FROM dbo.integrante_equipo m WHERE m.id_deportista = d.id_deportista AND m.id_equipo = 1)
             ORDER BY d.id_deportista;';
EXEC #probar 'P29', N'Regla 3 - función y fechas', N'Nueva participación válida (función RESERVA, vigente)', 'ACEPTADO', @sql;

/* =====================================================================
   F. INSCRIPCIONES (estado DEFAULT y coherencia)
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.inscripcion (id_torneo, id_equipo)
             VALUES (' + CAST(@torneo_futuro AS NVARCHAR(10)) + N', ' + CAST(@eq_otra_disciplina AS NVARCHAR(10)) + N');';
EXEC #probar 'P30', N'Inscripciones', N'Inscribir un equipo de otra disciplina', 'RECHAZADO', @sql;

SET @sql = N'DECLARE @eq INT = (SELECT TOP 1 q.id_equipo FROM dbo.equipo q
                                JOIN dbo.torneo t ON t.id_torneo = ' + CAST(@torneo_futuro AS NVARCHAR(10)) + N' AND t.id_disciplina = q.id_disciplina
                                WHERE NOT EXISTS (SELECT 1 FROM dbo.inscripcion i WHERE i.id_torneo = t.id_torneo AND i.id_equipo = q.id_equipo));
             INSERT INTO dbo.inscripcion (id_torneo, id_equipo) VALUES (' + CAST(@torneo_futuro AS NVARCHAR(10)) + N', @eq);
             IF (SELECT estado FROM dbo.inscripcion WHERE id_torneo = ' + CAST(@torneo_futuro AS NVARCHAR(10)) + N' AND id_equipo = @eq) <> ''PENDIENTE''
                THROW 50100, ''DEFAULT de estado no aplicado'', 1;';
EXEC #probar 'P31', N'Regla 7 - DEFAULT de inscripción', N'Inscripción válida sin indicar estado queda PENDIENTE', 'ACEPTADO', @sql;

/* =====================================================================
   G. REGLA 5: ENCUENTROS VÁLIDOS
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.encuentro (id_torneo, id_escenario, id_equipo_local, id_equipo_visitante, fecha_hora)
             VALUES (' + CAST(@torneo_futuro AS NVARCHAR(10)) + N', ' + CAST(@escenario AS NVARCHAR(10)) + N', '
             + CAST(@eq_aprobado_1 AS NVARCHAR(10)) + N', ' + CAST(@eq_aprobado_1 AS NVARCHAR(10)) + N', '''
             + CONVERT(NVARCHAR(10), @inicio_torneo_futuro, 23) + N'T07:00:00'');';
EXEC #probar 'P32', N'Regla 5 - no enfrentarse a sí mismo', N'Encuentro de un equipo contra sí mismo', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.encuentro (id_torneo, id_escenario, id_equipo_local, id_equipo_visitante, fecha_hora)
             VALUES (' + CAST(@torneo_futuro AS NVARCHAR(10)) + N', ' + CAST(@escenario AS NVARCHAR(10)) + N', '
             + CAST(@eq_aprobado_1 AS NVARCHAR(10)) + N', ' + CAST(@eq_aprobado_2 AS NVARCHAR(10)) + N', ''2020-01-01T10:00:00'');';
EXEC #probar 'P33', N'Regla 5 - fechas del torneo', N'Encuentro con fecha fuera del torneo', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.encuentro (id_torneo, id_escenario, id_equipo_local, id_equipo_visitante, fecha_hora)
             VALUES (' + CAST(@torneo_futuro AS NVARCHAR(10)) + N', ' + CAST(@escenario AS NVARCHAR(10)) + N', '
             + CAST(@eq_aprobado_1 AS NVARCHAR(10)) + N', ' + CAST(@eq_sin_aprobar AS NVARCHAR(10)) + N', '''
             + CONVERT(NVARCHAR(10), @inicio_torneo_futuro, 23) + N'T07:00:00'');';
EXEC #probar 'P34', N'Regla 5 - participantes válidos', N'Encuentro con un equipo sin inscripción aprobada', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.encuentro (id_torneo, id_escenario, id_equipo_local, id_equipo_visitante, fecha_hora)
             SELECT id_torneo, id_escenario, id_equipo_visitante, id_equipo_local, fecha_hora
             FROM dbo.encuentro WHERE id_encuentro = ' + CAST(@enc_existente AS NVARCHAR(10)) + N';';
EXEC #probar 'P35', N'Asignación de escenarios', N'Dos encuentros en el mismo escenario a la misma fecha y hora', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.encuentro (id_torneo, id_escenario, id_equipo_local, id_equipo_visitante, fecha_hora)
             VALUES (' + CAST(@torneo_futuro AS NVARCHAR(10)) + N', ' + CAST(@escenario AS NVARCHAR(10)) + N', '
             + CAST(@eq_aprobado_1 AS NVARCHAR(10)) + N', ' + CAST(@eq_aprobado_2 AS NVARCHAR(10)) + N', '''
             + CONVERT(NVARCHAR(10), @inicio_torneo_futuro, 23) + N'T07:00:00'');
             DECLARE @id INT = SCOPE_IDENTITY();
             IF (SELECT estado FROM dbo.encuentro WHERE id_encuentro = @id) <> ''PROGRAMADO''
                OR (SELECT resultado_definitivo FROM dbo.encuentro WHERE id_encuentro = @id) <> 0
                THROW 50100, ''DEFAULT de estado/resultado no aplicado'', 1;';
EXEC #probar 'P36', N'Regla 5 y Regla 7 - DEFAULT de encuentro', N'Encuentro válido: queda PROGRAMADO y no definitivo', 'ACEPTADO', @sql;

/* =====================================================================
   H. REGLA 6: RESULTADOS DEFINITIVOS
   ===================================================================== */
SET @sql = N'UPDATE dbo.encuentro SET estado = ''EN_JUEGO'', puntaje_local = 1, puntaje_visitante = 0, resultado_definitivo = 1
             WHERE id_encuentro = ' + CAST(@enc_programado AS NVARCHAR(10)) + N';';
EXEC #probar 'P37', N'Regla 6 - resultado definitivo', N'Declarar definitivo un encuentro que no ha finalizado (EN_JUEGO)', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.encuentro SET resultado_definitivo = 1 WHERE id_encuentro = ' + CAST(@enc_programado AS NVARCHAR(10)) + N';';
EXEC #probar 'P38', N'Regla 6 - resultado definitivo', N'Declarar definitivo un encuentro PROGRAMADO sin marcador', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.encuentro SET puntaje_local = 2, puntaje_visitante = 1 WHERE id_encuentro = ' + CAST(@enc_programado AS NVARCHAR(10)) + N';';
EXEC #probar 'P39', N'Coherencia de resultados', N'Registrar marcador a un encuentro PROGRAMADO', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.encuentro SET estado = ''FINALIZADO'', puntaje_local = 2, puntaje_visitante = NULL
             WHERE id_encuentro = ' + CAST(@enc_programado AS NVARCHAR(10)) + N';';
EXEC #probar 'P40', N'Coherencia de resultados', N'Marcador incompleto (solo un puntaje)', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.encuentro SET estado = ''FINALIZADO'', puntaje_local = -1, puntaje_visitante = 0
             WHERE id_encuentro = ' + CAST(@enc_programado AS NVARCHAR(10)) + N';';
EXEC #probar 'P41', N'Valores fuera de rango', N'Marcador negativo', 'RECHAZADO', @sql;

SET @sql = N'UPDATE dbo.encuentro SET estado = ''FINALIZADO'', puntaje_local = 2, puntaje_visitante = 1, resultado_definitivo = 1
             WHERE id_encuentro = ' + CAST(@enc_programado AS NVARCHAR(10)) + N';';
EXEC #probar 'P42', N'Regla 6 - resultado definitivo', N'Finalizar el encuentro y declarar el resultado definitivo', 'ACEPTADO', @sql;

SET @sql = N'UPDATE dbo.encuentro SET puntaje_local = puntaje_local + 1 WHERE id_encuentro = ' + CAST(@enc_definitivo AS NVARCHAR(10)) + N';';
EXEC #probar 'P43', N'Regla 6 - resultado definitivo', N'Modificar el marcador de un resultado ya definitivo', 'RECHAZADO', @sql;

/* =====================================================================
   I. PARTICIPACIÓN DE DEPORTISTAS EN ENCUENTROS
   ===================================================================== */
SET @sql = N'INSERT INTO dbo.participacion_encuentro (id_encuentro, id_deportista, id_equipo)
             SELECT ' + CAST(@enc_finalizado AS NVARCHAR(10)) + N', ' + CAST(@dep_ajeno AS NVARCHAR(10)) + N', id_equipo_local
             FROM dbo.encuentro WHERE id_encuentro = ' + CAST(@enc_finalizado AS NVARCHAR(10)) + N';';
EXEC #probar 'P44', N'Regla 5 - participantes válidos', N'Deportista que no integraba el equipo en la fecha del encuentro', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.participacion_encuentro (id_encuentro, id_deportista, id_equipo)
             SELECT ' + CAST(@enc_finalizado AS NVARCHAR(10)) + N', 1, q.id_equipo FROM dbo.equipo q
             WHERE q.id_equipo NOT IN (SELECT id_equipo_local FROM dbo.encuentro WHERE id_encuentro = ' + CAST(@enc_finalizado AS NVARCHAR(10)) + N'
                                       UNION SELECT id_equipo_visitante FROM dbo.encuentro WHERE id_encuentro = ' + CAST(@enc_finalizado AS NVARCHAR(10)) + N')
               AND q.id_equipo = (SELECT MAX(id_equipo) FROM dbo.equipo);';
EXEC #probar 'P45', N'Regla 5 - participantes válidos', N'Participación con un equipo que no juega el encuentro', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.participacion_encuentro (id_encuentro, id_deportista, id_equipo)
             SELECT id_encuentro, 1, id_equipo_local FROM dbo.encuentro WHERE id_encuentro = ' + CAST(@enc_programado AS NVARCHAR(10)) + N';';
EXEC #probar 'P46', N'Regla 5 - participantes válidos', N'Participación en un encuentro que aún no se juega', 'RECHAZADO', @sql;

SET @sql = N'INSERT INTO dbo.participacion_encuentro (id_encuentro, id_deportista, id_equipo)
             SELECT TOP 1 id_encuentro, id_deportista, id_equipo FROM dbo.participacion_encuentro ORDER BY id_participacion;';
EXEC #probar 'P47', N'Identificador único', N'Registrar dos veces al mismo deportista en el mismo encuentro', 'RECHAZADO', @sql;

/* =====================================================================
   J. REGLA 8: ESCENARIOS SIN ENCUENTROS Y EQUIPOS SIN PARTIDOS
   (se comprueba que el modelo y los datos los permiten)
   ===================================================================== */
SET @sql = N'IF NOT EXISTS (SELECT 1 FROM dbo.escenario es WHERE NOT EXISTS (SELECT 1 FROM dbo.encuentro e WHERE e.id_escenario = es.id_escenario))
                THROW 50100, ''No hay escenarios sin encuentros'', 1;
             IF NOT EXISTS (SELECT 1 FROM dbo.equipo q WHERE NOT EXISTS (SELECT 1 FROM dbo.encuentro e WHERE q.id_equipo IN (e.id_equipo_local, e.id_equipo_visitante)))
                THROW 50100, ''No hay equipos sin encuentros'', 1;';
EXEC #probar 'P48', N'Regla 8', N'Existen escenarios sin encuentros y equipos sin partidos', 'ACEPTADO', @sql;
GO

/* =====================================================================
   RESULTADOS
   ===================================================================== */
SELECT codigo, regla, prueba, esperado, obtenido, veredicto, mensaje
FROM #resultado
ORDER BY codigo;

SELECT veredicto, COUNT(*) AS pruebas
FROM #resultado
GROUP BY veredicto;
GO
