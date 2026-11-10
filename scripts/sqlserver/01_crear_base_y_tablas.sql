/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Script 01: creación de la base de datos y de las tablas
   ---------------------------------------------------------------------
   Contenido:
     - Base de datos GestionDeportiva.
     - 12 tablas con sus columnas, tipos, NOT NULL, PRIMARY KEY y DEFAULT.
   Las claves foráneas, UNIQUE, CHECK y triggers se agregan en el
   script 02_restricciones_y_reglas.sql para separar estructura y reglas.
   Requisito: ejecutar sobre un servidor sin la base GestionDeportiva
   (o después de 00_reinicio_entorno.sql).
   ===================================================================== */
SET NOCOUNT ON;
GO

IF DB_ID(N'GestionDeportiva') IS NULL
    CREATE DATABASE GestionDeportiva;
GO

USE GestionDeportiva;
GO

-- Protección: si las tablas ya existen, detener el script sin tocar nada.
IF OBJECT_ID(N'dbo.disciplina', N'U') IS NOT NULL
BEGIN
    RAISERROR(N'Las tablas ya existen. Ejecute 00_reinicio_entorno.sql si desea reconstruir desde cero.', 16, 1);
    SET NOEXEC ON;   -- las instrucciones siguientes se compilan pero no se ejecutan
END
GO

/* ---------------------------------------------------------------------
   1. DISCIPLINA: combinación deporte + modalidad + rama + categoría
      (ej.: Fútbol / Fútbol 11 / FEMENINA / ELITE).
   --------------------------------------------------------------------- */
CREATE TABLE dbo.disciplina (
    id_disciplina       INT IDENTITY(1,1) NOT NULL,
    codigo              VARCHAR(20)   NOT NULL,
    deporte             NVARCHAR(40)  NOT NULL,
    modalidad           NVARCHAR(40)  NOT NULL,
    rama                VARCHAR(10)   NOT NULL,
    categoria           VARCHAR(12)   NOT NULL,
    tipo_participacion  VARCHAR(10)   NOT NULL,
    CONSTRAINT pk_disciplina PRIMARY KEY (id_disciplina)
);
GO

/* ---------------------------------------------------------------------
   2. PERSONA: datos personales comunes de deportistas y entrenadores.
      Se registran una sola vez aunque la persona cumpla ambos roles.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.persona (
    id_persona          INT IDENTITY(1,1) NOT NULL,
    tipo_documento      VARCHAR(3)    NOT NULL,
    numero_documento    VARCHAR(20)   NOT NULL,
    nombres             NVARCHAR(60)  NOT NULL,
    apellidos           NVARCHAR(60)  NOT NULL,
    fecha_nacimiento    DATE          NOT NULL,
    sexo                CHAR(1)       NOT NULL,
    correo              VARCHAR(100)  NOT NULL,
    telefono            VARCHAR(15)   NULL,
    fecha_registro      DATETIME2(0)  NOT NULL CONSTRAINT df_persona_fecha_registro DEFAULT (SYSDATETIME()),
    CONSTRAINT pk_persona PRIMARY KEY (id_persona)
);
GO

/* ---------------------------------------------------------------------
   3. DEPORTISTA: rol de deportista de una persona.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.deportista (
    id_deportista       INT IDENTITY(1,1) NOT NULL,
    id_persona          INT           NOT NULL,
    id_disciplina       INT           NOT NULL,   -- disciplina principal
    estado              VARCHAR(12)   NOT NULL CONSTRAINT df_deportista_estado DEFAULT ('ACTIVO'),
    fecha_ingreso       DATE          NOT NULL CONSTRAINT df_deportista_fecha_ingreso DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT pk_deportista PRIMARY KEY (id_deportista)
);
GO

/* ---------------------------------------------------------------------
   4. ENTRENADOR: rol de entrenador de una persona.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.entrenador (
    id_entrenador       INT IDENTITY(1,1) NOT NULL,
    id_persona          INT           NOT NULL,
    numero_licencia     VARCHAR(20)   NOT NULL,
    nivel_licencia      VARCHAR(12)   NOT NULL,
    anios_experiencia   TINYINT       NOT NULL CONSTRAINT df_entrenador_anios_experiencia DEFAULT (0),
    estado              VARCHAR(10)   NOT NULL CONSTRAINT df_entrenador_estado DEFAULT ('ACTIVO'),
    fecha_ingreso       DATE          NOT NULL CONSTRAINT df_entrenador_fecha_ingreso DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT pk_entrenador PRIMARY KEY (id_entrenador)
);
GO

/* ---------------------------------------------------------------------
   5. EQUIPO
   --------------------------------------------------------------------- */
CREATE TABLE dbo.equipo (
    id_equipo           INT IDENTITY(1,1) NOT NULL,
    codigo              VARCHAR(20)   NOT NULL,
    nombre              NVARCHAR(80)  NOT NULL,
    id_disciplina       INT           NOT NULL,
    ciudad              NVARCHAR(50)  NOT NULL,
    fecha_fundacion     DATE          NOT NULL,
    estado              VARCHAR(10)   NOT NULL CONSTRAINT df_equipo_estado DEFAULT ('ACTIVO'),
    CONSTRAINT pk_equipo PRIMARY KEY (id_equipo)
);
GO

/* ---------------------------------------------------------------------
   6. ENTRENADOR_EQUIPO: asignación de un entrenador a un equipo en un
      periodo (resuelve la relación M:N y conserva la vigencia).
      fecha_fin NULL = asignación vigente.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.entrenador_equipo (
    id_asignacion       INT IDENTITY(1,1) NOT NULL,
    id_entrenador       INT           NOT NULL,
    id_equipo           INT           NOT NULL,
    rol                 VARCHAR(20)   NOT NULL CONSTRAINT df_entrenador_equipo_rol DEFAULT ('PRINCIPAL'),
    fecha_inicio        DATE          NOT NULL,
    fecha_fin           DATE          NULL,
    CONSTRAINT pk_entrenador_equipo PRIMARY KEY (id_asignacion)
);
GO

/* ---------------------------------------------------------------------
   7. INTEGRANTE_EQUIPO: participación de un deportista en un equipo a lo
      largo del tiempo (M:N con función y fechas). fecha_fin NULL = vigente.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.integrante_equipo (
    id_integrante       INT IDENTITY(1,1) NOT NULL,
    id_deportista       INT           NOT NULL,
    id_equipo           INT           NOT NULL,
    funcion             VARCHAR(10)   NOT NULL CONSTRAINT df_integrante_equipo_funcion DEFAULT ('TITULAR'),
    numero_camiseta     TINYINT       NULL,
    fecha_inicio        DATE          NOT NULL,
    fecha_fin           DATE          NULL,
    CONSTRAINT pk_integrante_equipo PRIMARY KEY (id_integrante)
);
GO

/* ---------------------------------------------------------------------
   8. ESCENARIO
   --------------------------------------------------------------------- */
CREATE TABLE dbo.escenario (
    id_escenario        INT IDENTITY(1,1) NOT NULL,
    codigo              VARCHAR(20)   NOT NULL,
    nombre              NVARCHAR(80)  NOT NULL,
    tipo                VARCHAR(12)   NOT NULL,
    ciudad              NVARCHAR(50)  NOT NULL,
    direccion           NVARCHAR(100) NOT NULL,
    capacidad           INT           NOT NULL,
    estado              VARCHAR(15)   NOT NULL CONSTRAINT df_escenario_estado DEFAULT ('DISPONIBLE'),
    CONSTRAINT pk_escenario PRIMARY KEY (id_escenario)
);
GO

/* ---------------------------------------------------------------------
   9. TORNEO
   --------------------------------------------------------------------- */
CREATE TABLE dbo.torneo (
    id_torneo           INT IDENTITY(1,1) NOT NULL,
    codigo              VARCHAR(20)   NOT NULL,
    nombre              NVARCHAR(100) NOT NULL,
    id_disciplina       INT           NOT NULL,
    fecha_inicio        DATE          NOT NULL,
    fecha_fin           DATE          NOT NULL,
    estado              VARCHAR(12)   NOT NULL CONSTRAINT df_torneo_estado DEFAULT ('PROGRAMADO'),
    CONSTRAINT pk_torneo PRIMARY KEY (id_torneo)
);
GO

/* ---------------------------------------------------------------------
   10. INSCRIPCION: equipo inscrito en un torneo.
       Estado inicial por defecto: 'PENDIENTE'.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.inscripcion (
    id_inscripcion      INT IDENTITY(1,1) NOT NULL,
    id_torneo           INT           NOT NULL,
    id_equipo           INT           NOT NULL,
    fecha_inscripcion   DATE          NOT NULL CONSTRAINT df_inscripcion_fecha DEFAULT (CAST(GETDATE() AS DATE)),
    estado              VARCHAR(10)   NOT NULL CONSTRAINT df_inscripcion_estado DEFAULT ('PENDIENTE'),
    CONSTRAINT pk_inscripcion PRIMARY KEY (id_inscripcion)
);
GO

/* ---------------------------------------------------------------------
   11. ENCUENTRO: partido entre dos equipos dentro de un torneo, en un
       escenario. El resultado (marcador) se guarda en la misma fila
       porque es 1:1 con el encuentro.
       Estado inicial por defecto: 'PROGRAMADO'.
   --------------------------------------------------------------------- */
CREATE TABLE dbo.encuentro (
    id_encuentro          INT IDENTITY(1,1) NOT NULL,
    id_torneo             INT           NOT NULL,
    id_escenario          INT           NOT NULL,
    id_equipo_local       INT           NOT NULL,
    id_equipo_visitante   INT           NOT NULL,
    fecha_hora            DATETIME2(0)  NOT NULL,
    jornada               SMALLINT      NOT NULL CONSTRAINT df_encuentro_jornada DEFAULT (1),
    estado                VARCHAR(12)   NOT NULL CONSTRAINT df_encuentro_estado DEFAULT ('PROGRAMADO'),
    puntaje_local         SMALLINT      NULL,
    puntaje_visitante     SMALLINT      NULL,
    resultado_definitivo  BIT           NOT NULL CONSTRAINT df_encuentro_resultado_definitivo DEFAULT (0),
    CONSTRAINT pk_encuentro PRIMARY KEY (id_encuentro)
);
GO

/* ---------------------------------------------------------------------
   12. PARTICIPACION_ENCUENTRO: deportistas que jugaron un encuentro con
       su equipo (base para los reportes de participación y desempeño).
   --------------------------------------------------------------------- */
CREATE TABLE dbo.participacion_encuentro (
    id_participacion    INT IDENTITY(1,1) NOT NULL,
    id_encuentro        INT           NOT NULL,
    id_deportista       INT           NOT NULL,
    id_equipo           INT           NOT NULL,
    es_titular          BIT           NOT NULL CONSTRAINT df_participacion_es_titular DEFAULT (1),
    minutos_jugados     SMALLINT      NULL,
    calificacion        DECIMAL(3,1)  NULL,
    CONSTRAINT pk_participacion_encuentro PRIMARY KEY (id_participacion)
);
GO

SET NOEXEC OFF;
GO
SELECT COUNT(*) AS tablas_creadas FROM GestionDeportiva.sys.tables WHERE is_ms_shipped = 0;
PRINT N'Script 01 finalizado.';
GO
