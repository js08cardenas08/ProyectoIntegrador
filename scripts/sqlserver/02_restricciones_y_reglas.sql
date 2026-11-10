/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Script 02: restricciones (FK, UNIQUE, CHECK), índices y triggers
   ---------------------------------------------------------------------
   Convención de nombres:
     pk_ clave primaria   fk_ clave foránea   uq_ único
     ck_ verificación     df_ valor por defecto   ix_ índice   tr_ trigger
   Las reglas que comparan una fila con OTRAS filas (solapamiento de
   periodos, fechas del torneo, inscripción de los equipos, etc.) NO
   pueden resolverse con CHECK: se implementan con triggers AFTER que
   lanzan un error (THROW) y deshacen la operación completa.
   ===================================================================== */
USE GestionDeportiva;
GO
SET NOCOUNT ON;
GO

/* =====================================================================
   1. DISCIPLINA
   ===================================================================== */
ALTER TABLE dbo.disciplina ADD
    CONSTRAINT uq_disciplina_codigo UNIQUE (codigo),
    CONSTRAINT uq_disciplina_combinacion UNIQUE (deporte, modalidad, rama, categoria),
    CONSTRAINT ck_disciplina_rama CHECK (rama IN ('MASCULINA', 'FEMENINA', 'MIXTA')),
    CONSTRAINT ck_disciplina_categoria CHECK (categoria IN ('RECREATIVA', 'AFICIONADA', 'INTERMEDIA', 'AVANZADA', 'ELITE')),
    CONSTRAINT ck_disciplina_tipo CHECK (tipo_participacion IN ('CONJUNTO', 'INDIVIDUAL'));
GO

/* =====================================================================
   2. PERSONA
   ===================================================================== */
ALTER TABLE dbo.persona ADD
    CONSTRAINT uq_persona_documento UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT uq_persona_correo UNIQUE (correo),
    CONSTRAINT ck_persona_tipo_documento CHECK (tipo_documento IN ('CC', 'TI', 'CE', 'PAS')),
    CONSTRAINT ck_persona_numero_documento CHECK (numero_documento NOT LIKE '%[^0-9A-Z]%' AND LEN(numero_documento) >= 5),
    CONSTRAINT ck_persona_sexo CHECK (sexo IN ('F', 'M')),
    CONSTRAINT ck_persona_correo CHECK (correo LIKE '%_@_%._%'),
    CONSTRAINT ck_persona_fecha_nacimiento CHECK (fecha_nacimiento >= '1940-01-01' AND fecha_nacimiento <= CAST(GETDATE() AS DATE));
GO

/* =====================================================================
   3. DEPORTISTA (subtipo de persona, relación 1:1 opcional)
   ===================================================================== */
ALTER TABLE dbo.deportista ADD
    CONSTRAINT uq_deportista_persona UNIQUE (id_persona),
    CONSTRAINT fk_deportista_persona FOREIGN KEY (id_persona) REFERENCES dbo.persona (id_persona),
    CONSTRAINT fk_deportista_disciplina FOREIGN KEY (id_disciplina) REFERENCES dbo.disciplina (id_disciplina),
    CONSTRAINT ck_deportista_estado CHECK (estado IN ('ACTIVO', 'LESIONADO', 'SUSPENDIDO', 'RETIRADO'));
GO

/* =====================================================================
   4. ENTRENADOR (subtipo de persona, relación 1:1 opcional)
   ===================================================================== */
ALTER TABLE dbo.entrenador ADD
    CONSTRAINT uq_entrenador_persona UNIQUE (id_persona),
    CONSTRAINT uq_entrenador_licencia UNIQUE (numero_licencia),
    CONSTRAINT fk_entrenador_persona FOREIGN KEY (id_persona) REFERENCES dbo.persona (id_persona),
    CONSTRAINT ck_entrenador_nivel CHECK (nivel_licencia IN ('BASICO', 'INTERMEDIO', 'AVANZADO', 'PROFESIONAL')),
    CONSTRAINT ck_entrenador_anios_experiencia CHECK (anios_experiencia BETWEEN 0 AND 60),
    CONSTRAINT ck_entrenador_estado CHECK (estado IN ('ACTIVO', 'INACTIVO'));
GO

/* =====================================================================
   5. EQUIPO
   ===================================================================== */
ALTER TABLE dbo.equipo ADD
    CONSTRAINT uq_equipo_codigo UNIQUE (codigo),
    CONSTRAINT uq_equipo_nombre_disciplina UNIQUE (nombre, id_disciplina),
    CONSTRAINT fk_equipo_disciplina FOREIGN KEY (id_disciplina) REFERENCES dbo.disciplina (id_disciplina),
    CONSTRAINT ck_equipo_estado CHECK (estado IN ('ACTIVO', 'INACTIVO'));
GO

/* =====================================================================
   6. ENTRENADOR_EQUIPO
   ===================================================================== */
ALTER TABLE dbo.entrenador_equipo ADD
    CONSTRAINT uq_entrenador_equipo_inicio UNIQUE (id_entrenador, id_equipo, fecha_inicio),
    CONSTRAINT fk_entrenador_equipo_entrenador FOREIGN KEY (id_entrenador) REFERENCES dbo.entrenador (id_entrenador),
    CONSTRAINT fk_entrenador_equipo_equipo FOREIGN KEY (id_equipo) REFERENCES dbo.equipo (id_equipo),
    CONSTRAINT ck_entrenador_equipo_rol CHECK (rol IN ('PRINCIPAL', 'ASISTENTE', 'PREPARADOR_FISICO')),
    CONSTRAINT ck_entrenador_equipo_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio);
GO

/* =====================================================================
   7. INTEGRANTE_EQUIPO
   ===================================================================== */
ALTER TABLE dbo.integrante_equipo ADD
    CONSTRAINT uq_integrante_equipo_inicio UNIQUE (id_deportista, id_equipo, fecha_inicio),
    CONSTRAINT fk_integrante_equipo_deportista FOREIGN KEY (id_deportista) REFERENCES dbo.deportista (id_deportista),
    CONSTRAINT fk_integrante_equipo_equipo FOREIGN KEY (id_equipo) REFERENCES dbo.equipo (id_equipo),
    CONSTRAINT ck_integrante_equipo_funcion CHECK (funcion IN ('CAPITAN', 'TITULAR', 'SUPLENTE', 'RESERVA')),
    CONSTRAINT ck_integrante_equipo_camiseta CHECK (numero_camiseta IS NULL OR numero_camiseta BETWEEN 0 AND 99),
    CONSTRAINT ck_integrante_equipo_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio);
GO

/* =====================================================================
   8. ESCENARIO
   ===================================================================== */
ALTER TABLE dbo.escenario ADD
    CONSTRAINT uq_escenario_codigo UNIQUE (codigo),
    CONSTRAINT uq_escenario_nombre_ciudad UNIQUE (nombre, ciudad),
    CONSTRAINT ck_escenario_tipo CHECK (tipo IN ('ESTADIO', 'COLISEO', 'CANCHA', 'PISCINA', 'PISTA', 'VELODROMO', 'GIMNASIO')),
    CONSTRAINT ck_escenario_capacidad CHECK (capacidad > 0),
    CONSTRAINT ck_escenario_estado CHECK (estado IN ('DISPONIBLE', 'MANTENIMIENTO', 'INACTIVO'));
GO

/* =====================================================================
   9. TORNEO
   ===================================================================== */
ALTER TABLE dbo.torneo ADD
    CONSTRAINT uq_torneo_codigo UNIQUE (codigo),
    CONSTRAINT fk_torneo_disciplina FOREIGN KEY (id_disciplina) REFERENCES dbo.disciplina (id_disciplina),
    CONSTRAINT ck_torneo_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT ck_torneo_estado CHECK (estado IN ('PROGRAMADO', 'EN_CURSO', 'FINALIZADO', 'CANCELADO'));
GO

/* =====================================================================
   10. INSCRIPCION
   ===================================================================== */
ALTER TABLE dbo.inscripcion ADD
    CONSTRAINT uq_inscripcion_torneo_equipo UNIQUE (id_torneo, id_equipo),
    CONSTRAINT fk_inscripcion_torneo FOREIGN KEY (id_torneo) REFERENCES dbo.torneo (id_torneo),
    CONSTRAINT fk_inscripcion_equipo FOREIGN KEY (id_equipo) REFERENCES dbo.equipo (id_equipo),
    CONSTRAINT ck_inscripcion_estado CHECK (estado IN ('PENDIENTE', 'APROBADA', 'RECHAZADA', 'RETIRADA'));
GO

/* =====================================================================
   11. ENCUENTRO
   ===================================================================== */
ALTER TABLE dbo.encuentro ADD
    -- Un escenario no puede tener dos encuentros a la misma fecha y hora
    CONSTRAINT uq_encuentro_escenario_fecha UNIQUE (id_escenario, fecha_hora),
    CONSTRAINT fk_encuentro_torneo FOREIGN KEY (id_torneo) REFERENCES dbo.torneo (id_torneo),
    CONSTRAINT fk_encuentro_escenario FOREIGN KEY (id_escenario) REFERENCES dbo.escenario (id_escenario),
    CONSTRAINT fk_encuentro_equipo_local FOREIGN KEY (id_equipo_local) REFERENCES dbo.equipo (id_equipo),
    CONSTRAINT fk_encuentro_equipo_visitante FOREIGN KEY (id_equipo_visitante) REFERENCES dbo.equipo (id_equipo),
    -- Regla 5: un equipo no puede enfrentarse a sí mismo
    CONSTRAINT ck_encuentro_equipos_distintos CHECK (id_equipo_local <> id_equipo_visitante),
    CONSTRAINT ck_encuentro_estado CHECK (estado IN ('PROGRAMADO', 'EN_JUEGO', 'FINALIZADO', 'SUSPENDIDO', 'CANCELADO')),
    CONSTRAINT ck_encuentro_jornada CHECK (jornada > 0),
    CONSTRAINT ck_encuentro_puntajes_no_negativos CHECK (puntaje_local >= 0 AND puntaje_visitante >= 0),
    -- Los dos puntajes se registran juntos (ambos nulos o ambos con valor)
    CONSTRAINT ck_encuentro_puntajes_completos CHECK ((puntaje_local IS NULL AND puntaje_visitante IS NULL)
                                                   OR (puntaje_local IS NOT NULL AND puntaje_visitante IS NOT NULL)),
    -- Un encuentro programado o cancelado no tiene marcador
    CONSTRAINT ck_encuentro_puntajes_segun_estado CHECK (estado IN ('EN_JUEGO', 'FINALIZADO', 'SUSPENDIDO')
                                                   OR (puntaje_local IS NULL AND puntaje_visitante IS NULL)),
    -- Regla 6: el resultado solo es definitivo si el encuentro está FINALIZADO y tiene marcador
    CONSTRAINT ck_encuentro_resultado_definitivo CHECK (resultado_definitivo = 0
                                                   OR (estado = 'FINALIZADO' AND puntaje_local IS NOT NULL));
GO

/* =====================================================================
   12. PARTICIPACION_ENCUENTRO
   ===================================================================== */
ALTER TABLE dbo.participacion_encuentro ADD
    CONSTRAINT uq_participacion_encuentro_deportista UNIQUE (id_encuentro, id_deportista),
    CONSTRAINT fk_participacion_encuentro FOREIGN KEY (id_encuentro) REFERENCES dbo.encuentro (id_encuentro),
    CONSTRAINT fk_participacion_deportista FOREIGN KEY (id_deportista) REFERENCES dbo.deportista (id_deportista),
    CONSTRAINT fk_participacion_equipo FOREIGN KEY (id_equipo) REFERENCES dbo.equipo (id_equipo),
    CONSTRAINT ck_participacion_minutos CHECK (minutos_jugados IS NULL OR minutos_jugados BETWEEN 0 AND 300),
    CONSTRAINT ck_participacion_calificacion CHECK (calificacion IS NULL OR calificacion BETWEEN 0 AND 10);
GO

/* =====================================================================
   ÍNDICES sobre claves foráneas usadas en JOIN y filtros frecuentes
   (SQL Server no los crea automáticamente para las FK).
   ===================================================================== */
CREATE INDEX ix_deportista_disciplina_estado ON dbo.deportista (id_disciplina, estado);
CREATE INDEX ix_equipo_disciplina            ON dbo.equipo (id_disciplina);
CREATE INDEX ix_entrenador_equipo_equipo     ON dbo.entrenador_equipo (id_equipo);
CREATE INDEX ix_integrante_equipo_equipo     ON dbo.integrante_equipo (id_equipo);
CREATE INDEX ix_torneo_disciplina            ON dbo.torneo (id_disciplina);
CREATE INDEX ix_inscripcion_equipo           ON dbo.inscripcion (id_equipo);
CREATE INDEX ix_encuentro_torneo             ON dbo.encuentro (id_torneo);
CREATE INDEX ix_encuentro_fecha_hora         ON dbo.encuentro (fecha_hora);
CREATE INDEX ix_encuentro_equipo_local       ON dbo.encuentro (id_equipo_local);
CREATE INDEX ix_encuentro_equipo_visitante   ON dbo.encuentro (id_equipo_visitante);
CREATE INDEX ix_participacion_deportista     ON dbo.participacion_encuentro (id_deportista);
GO

/* =====================================================================
   TRIGGERS DE REGLAS DE NEGOCIO
   ===================================================================== */

/* ---------------------------------------------------------------------
   tr_entrenador_equipo_validar (Regla 2)
   - La asignación no puede empezar antes de la fundación del equipo.
   - Un equipo no puede tener dos entrenadores PRINCIPALES con periodos
     que se crucen.
   - El mismo entrenador no puede tener dos asignaciones cruzadas en el
     mismo equipo.
   Dos periodos [ini1, fin1] y [ini2, fin2] se cruzan si
   ini1 <= fin2 AND ini2 <= fin1 (fin NULL = vigente = '9999-12-31').
   --------------------------------------------------------------------- */
CREATE TRIGGER dbo.tr_entrenador_equipo_validar
ON dbo.entrenador_equipo
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.equipo e ON e.id_equipo = i.id_equipo
               WHERE i.fecha_inicio < e.fecha_fundacion)
        THROW 50001, N'Regla 2: la asignación del entrenador no puede iniciar antes de la fundación del equipo.', 1;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.entrenador_equipo a
                 ON a.id_equipo = i.id_equipo
                AND a.id_asignacion <> i.id_asignacion
               WHERE ((i.rol = 'PRINCIPAL' AND a.rol = 'PRINCIPAL') OR a.id_entrenador = i.id_entrenador)
                 AND a.fecha_inicio <= ISNULL(i.fecha_fin, '9999-12-31')
                 AND i.fecha_inicio <= ISNULL(a.fecha_fin, '9999-12-31'))
        THROW 50002, N'Regla 2: el periodo se cruza con otra asignación (dos entrenadores principales a la vez o el mismo entrenador repetido en el equipo).', 1;
END;
GO

/* ---------------------------------------------------------------------
   tr_integrante_equipo_validar (Regla 3)
   - La participación no puede empezar antes de la fundación del equipo.
   - Un deportista no puede tener dos periodos cruzados en el mismo equipo.
   --------------------------------------------------------------------- */
CREATE TRIGGER dbo.tr_integrante_equipo_validar
ON dbo.integrante_equipo
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.equipo e ON e.id_equipo = i.id_equipo
               WHERE i.fecha_inicio < e.fecha_fundacion)
        THROW 50003, N'Regla 3: la participación del deportista no puede iniciar antes de la fundación del equipo.', 1;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.integrante_equipo m
                 ON m.id_deportista = i.id_deportista
                AND m.id_equipo = i.id_equipo
                AND m.id_integrante <> i.id_integrante
               WHERE m.fecha_inicio <= ISNULL(i.fecha_fin, '9999-12-31')
                 AND i.fecha_inicio <= ISNULL(m.fecha_fin, '9999-12-31'))
        THROW 50004, N'Regla 3: el deportista ya integra este equipo en un periodo que se cruza con el nuevo.', 1;
END;
GO

/* ---------------------------------------------------------------------
   tr_inscripcion_validar (inscripciones coherentes)
   - El equipo debe pertenecer a la misma disciplina del torneo.
   - La inscripción no puede ser posterior a la finalización del torneo.
   --------------------------------------------------------------------- */
CREATE TRIGGER dbo.tr_inscripcion_validar
ON dbo.inscripcion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.torneo t ON t.id_torneo = i.id_torneo
               JOIN dbo.equipo e ON e.id_equipo = i.id_equipo
               WHERE e.id_disciplina <> t.id_disciplina)
        THROW 50005, N'Inscripción inválida: la disciplina del equipo no coincide con la del torneo.', 1;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.torneo t ON t.id_torneo = i.id_torneo
               WHERE i.fecha_inscripcion > t.fecha_fin)
        THROW 50006, N'Inscripción inválida: la fecha de inscripción es posterior al final del torneo.', 1;
END;
GO

/* ---------------------------------------------------------------------
   tr_encuentro_validar (Reglas 5 y 6)
   Se valida al insertar o cuando cambian torneo, equipos o fecha:
   - La fecha del encuentro debe estar dentro de las fechas del torneo.
   - Ambos equipos deben tener inscripción APROBADA en ese torneo
     (participantes válidos).
   Además, en cualquier actualización:
   - Un resultado ya declarado definitivo no se puede modificar.
   --------------------------------------------------------------------- */
CREATE TRIGGER dbo.tr_encuentro_validar
ON dbo.encuentro
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Filas nuevas o con cambios en datos de programación
    SELECT i.*
    INTO #revisar
    FROM inserted i
    LEFT JOIN deleted d ON d.id_encuentro = i.id_encuentro
    WHERE d.id_encuentro IS NULL
       OR d.id_torneo <> i.id_torneo
       OR d.id_equipo_local <> i.id_equipo_local
       OR d.id_equipo_visitante <> i.id_equipo_visitante
       OR d.fecha_hora <> i.fecha_hora;

    IF EXISTS (SELECT 1
               FROM #revisar r
               JOIN dbo.torneo t ON t.id_torneo = r.id_torneo
               WHERE CAST(r.fecha_hora AS DATE) NOT BETWEEN t.fecha_inicio AND t.fecha_fin)
        THROW 50007, N'Regla 5: la fecha del encuentro está fuera de las fechas del torneo.', 1;

    IF EXISTS (SELECT 1
               FROM #revisar r
               WHERE NOT EXISTS (SELECT 1 FROM dbo.inscripcion ins
                                 WHERE ins.id_torneo = r.id_torneo
                                   AND ins.id_equipo = r.id_equipo_local
                                   AND ins.estado = 'APROBADA')
                  OR NOT EXISTS (SELECT 1 FROM dbo.inscripcion ins
                                 WHERE ins.id_torneo = r.id_torneo
                                   AND ins.id_equipo = r.id_equipo_visitante
                                   AND ins.estado = 'APROBADA'))
        THROW 50008, N'Regla 5: ambos equipos deben tener inscripción APROBADA en el torneo del encuentro.', 1;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN deleted d ON d.id_encuentro = i.id_encuentro
               WHERE d.resultado_definitivo = 1
                 AND (i.resultado_definitivo = 0
                      OR i.estado <> d.estado
                      OR i.puntaje_local <> d.puntaje_local
                      OR i.puntaje_visitante <> d.puntaje_visitante))
        THROW 50009, N'Regla 6: el resultado del encuentro ya es definitivo y no puede modificarse.', 1;
END;
GO

/* ---------------------------------------------------------------------
   tr_participacion_validar (participantes válidos)
   - El equipo del deportista debe ser el local o el visitante.
   - Solo se registran participaciones en encuentros que se jugaron
     (EN_JUEGO, FINALIZADO o SUSPENDIDO).
   - El deportista debe integrar ese equipo en la fecha del encuentro.
   --------------------------------------------------------------------- */
CREATE TRIGGER dbo.tr_participacion_validar
ON dbo.participacion_encuentro
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.encuentro en ON en.id_encuentro = i.id_encuentro
               WHERE i.id_equipo NOT IN (en.id_equipo_local, en.id_equipo_visitante))
        THROW 50010, N'Participación inválida: el equipo no juega este encuentro.', 1;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.encuentro en ON en.id_encuentro = i.id_encuentro
               WHERE en.estado NOT IN ('EN_JUEGO', 'FINALIZADO', 'SUSPENDIDO'))
        THROW 50011, N'Participación inválida: el encuentro no se ha jugado (está programado o cancelado).', 1;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN dbo.encuentro en ON en.id_encuentro = i.id_encuentro
               WHERE NOT EXISTS (SELECT 1
                                 FROM dbo.integrante_equipo m
                                 WHERE m.id_deportista = i.id_deportista
                                   AND m.id_equipo = i.id_equipo
                                   AND m.fecha_inicio <= CAST(en.fecha_hora AS DATE)
                                   AND (m.fecha_fin IS NULL OR m.fecha_fin >= CAST(en.fecha_hora AS DATE))))
        THROW 50012, N'Participación inválida: el deportista no integraba ese equipo en la fecha del encuentro.', 1;
END;
GO

PRINT N'Script 02 finalizado: restricciones, índices y triggers creados.';
GO
