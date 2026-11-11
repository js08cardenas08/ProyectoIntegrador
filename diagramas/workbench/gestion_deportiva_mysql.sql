-- =====================================================================
-- Proyecto integrador - Caso 5: Gestión deportiva
-- Integrantes: Juan Sebastián Cárdenas, Juan David Segura
-- Estructura de la base GestionDeportiva en dialecto MySQL para dibujar
-- el diagrama en MySQL Workbench. La implementación oficial está en
-- SQL Server (scripts/sqlserver). Generado por
-- scripts/generador/generar_script_mysql_workbench.py
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS gestion_deportiva DEFAULT CHARACTER SET utf8mb4;
USE gestion_deportiva;

CREATE TABLE disciplina (
  id_disciplina INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único de la disciplina (sustituto).',
  codigo VARCHAR(20) NOT NULL COMMENT 'Código legible: DEPORTE-modalidad-rama-categoría (ej. FUT-1-F-ELI).',
  deporte VARCHAR(40) NOT NULL COMMENT 'Nombre del deporte (Fútbol, Baloncesto, Natación…).',
  modalidad VARCHAR(40) NOT NULL COMMENT 'Modalidad del deporte (Fútbol 11, 3x3, Playa, Por equipos…).',
  rama VARCHAR(10) NOT NULL COMMENT 'Rama de competencia: MASCULINA, FEMENINA o MIXTA.',
  categoria VARCHAR(12) NOT NULL COMMENT 'Nivel competitivo: RECREATIVA, AFICIONADA, INTERMEDIA, AVANZADA o ELITE.',
  tipo_participacion VARCHAR(10) NOT NULL COMMENT 'CONJUNTO (equipos) o INDIVIDUAL.',
  CONSTRAINT pk_disciplina PRIMARY KEY (id_disciplina),
  CONSTRAINT uq_disciplina_codigo UNIQUE (codigo),
  CONSTRAINT uq_disciplina_combinacion UNIQUE (deporte, modalidad, rama, categoria)
) ENGINE=InnoDB COMMENT='Catálogo de disciplinas deportivas. Una disciplina es la combinación de deporte, modalidad, rama y categoría en la que se compite (ej.: Fútbol / Fútbol 11 / FEMENINA / ELITE).';

CREATE TABLE persona (
  id_persona INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único de la persona (sustituto).',
  tipo_documento VARCHAR(3) NOT NULL COMMENT 'Tipo de documento: CC, TI, CE o PAS.',
  numero_documento VARCHAR(20) NOT NULL COMMENT 'Número del documento (solo dígitos o letras mayúsculas, mínimo 5 caracteres).',
  nombres VARCHAR(60) NOT NULL COMMENT 'Nombres de la persona.',
  apellidos VARCHAR(60) NOT NULL COMMENT 'Apellidos de la persona.',
  fecha_nacimiento DATE NOT NULL COMMENT 'Fecha de nacimiento (entre 1940-01-01 y la fecha actual).',
  sexo CHAR(1) NOT NULL COMMENT 'Sexo registrado para efectos de la rama de competencia: F o M.',
  correo VARCHAR(100) NOT NULL COMMENT 'Correo electrónico de contacto (único, formato texto@dominio.ext).',
  telefono VARCHAR(15) NULL COMMENT 'Teléfono de contacto (opcional).',
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora en que se registró la persona en el sistema.',
  CONSTRAINT pk_persona PRIMARY KEY (id_persona),
  CONSTRAINT uq_persona_correo UNIQUE (correo),
  CONSTRAINT uq_persona_documento UNIQUE (tipo_documento, numero_documento)
) ENGINE=InnoDB COMMENT='Datos personales comunes a deportistas y entrenadores. Se registran una sola vez aunque la persona cumpla los dos roles (evita duplicar información de personas).';

CREATE TABLE deportista (
  id_deportista INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del deportista.',
  id_persona INT NOT NULL COMMENT 'Persona a la que corresponde el rol de deportista (una persona = un registro de deportista).',
  id_disciplina INT NOT NULL COMMENT 'Disciplina principal del deportista.',
  estado VARCHAR(12) NOT NULL DEFAULT 'ACTIVO' COMMENT 'Estado deportivo: ACTIVO, LESIONADO, SUSPENDIDO o RETIRADO.',
  fecha_ingreso DATE NOT NULL COMMENT 'Fecha de afiliación a la organización.',
  CONSTRAINT pk_deportista PRIMARY KEY (id_deportista),
  CONSTRAINT uq_deportista_persona UNIQUE (id_persona),
  CONSTRAINT fk_deportista_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona),
  CONSTRAINT fk_deportista_disciplina FOREIGN KEY (id_disciplina) REFERENCES disciplina (id_disciplina)
) ENGINE=InnoDB COMMENT='Rol de deportista de una persona (subtipo de PERSONA, relación 1:1 opcional).';

CREATE TABLE entrenador (
  id_entrenador INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del entrenador.',
  id_persona INT NOT NULL COMMENT 'Persona a la que corresponde el rol de entrenador.',
  numero_licencia VARCHAR(20) NOT NULL COMMENT 'Número de la licencia de entrenador (único).',
  nivel_licencia VARCHAR(12) NOT NULL COMMENT 'Nivel de la licencia: BASICO, INTERMEDIO, AVANZADO o PROFESIONAL.',
  anios_experiencia TINYINT NOT NULL DEFAULT 0 COMMENT 'Años de experiencia como entrenador (0 a 60).',
  estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVO' COMMENT 'Estado del entrenador en la organización: ACTIVO o INACTIVO.',
  fecha_ingreso DATE NOT NULL COMMENT 'Fecha de vinculación a la organización.',
  CONSTRAINT pk_entrenador PRIMARY KEY (id_entrenador),
  CONSTRAINT uq_entrenador_licencia UNIQUE (numero_licencia),
  CONSTRAINT uq_entrenador_persona UNIQUE (id_persona),
  CONSTRAINT fk_entrenador_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona)
) ENGINE=InnoDB COMMENT='Rol de entrenador de una persona (subtipo de PERSONA, relación 1:1 opcional).';

CREATE TABLE equipo (
  id_equipo INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del equipo.',
  codigo VARCHAR(20) NOT NULL COMMENT 'Código del equipo (EQ-00001).',
  nombre VARCHAR(80) NOT NULL COMMENT 'Nombre del equipo (no se repite dentro de la misma disciplina).',
  id_disciplina INT NOT NULL COMMENT 'Disciplina en la que compite el equipo.',
  ciudad VARCHAR(50) NOT NULL COMMENT 'Ciudad sede del equipo.',
  fecha_fundacion DATE NOT NULL COMMENT 'Fecha de fundación; ninguna asignación de entrenador o deportista puede ser anterior.',
  estado VARCHAR(10) NOT NULL DEFAULT 'ACTIVO' COMMENT 'ACTIVO o INACTIVO.',
  CONSTRAINT pk_equipo PRIMARY KEY (id_equipo),
  CONSTRAINT uq_equipo_codigo UNIQUE (codigo),
  CONSTRAINT uq_equipo_nombre_disciplina UNIQUE (nombre, id_disciplina),
  CONSTRAINT fk_equipo_disciplina FOREIGN KEY (id_disciplina) REFERENCES disciplina (id_disciplina)
) ENGINE=InnoDB COMMENT='Equipos de la organización; cada equipo compite en una disciplina.';

CREATE TABLE entrenador_equipo (
  id_asignacion INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único de la asignación.',
  id_entrenador INT NOT NULL COMMENT 'Entrenador asignado.',
  id_equipo INT NOT NULL COMMENT 'Equipo dirigido.',
  rol VARCHAR(20) NOT NULL DEFAULT 'PRINCIPAL' COMMENT 'Rol en el cuerpo técnico: PRINCIPAL, ASISTENTE o PREPARADOR_FISICO.',
  fecha_inicio DATE NOT NULL COMMENT 'Inicio de la vigencia de la asignación.',
  fecha_fin DATE NULL COMMENT 'Fin de la vigencia; NULL = asignación vigente.',
  CONSTRAINT pk_entrenador_equipo PRIMARY KEY (id_asignacion),
  CONSTRAINT uq_entrenador_equipo_inicio UNIQUE (id_entrenador, id_equipo, fecha_inicio),
  CONSTRAINT fk_entrenador_equipo_entrenador FOREIGN KEY (id_entrenador) REFERENCES entrenador (id_entrenador),
  CONSTRAINT fk_entrenador_equipo_equipo FOREIGN KEY (id_equipo) REFERENCES equipo (id_equipo)
) ENGINE=InnoDB COMMENT='Asignación de un entrenador a un equipo en un periodo (resuelve la relación M:N DIRIGE y conserva la vigencia). Regla 2.';

CREATE TABLE integrante_equipo (
  id_integrante INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del periodo de participación.',
  id_deportista INT NOT NULL COMMENT 'Deportista que integra el equipo.',
  id_equipo INT NOT NULL COMMENT 'Equipo que integra.',
  funcion VARCHAR(10) NOT NULL DEFAULT 'TITULAR' COMMENT 'Función en el equipo: CAPITAN, TITULAR, SUPLENTE o RESERVA.',
  numero_camiseta TINYINT NULL COMMENT 'Número de camiseta (0 a 99, opcional).',
  fecha_inicio DATE NOT NULL COMMENT 'Fecha en que empieza a integrar el equipo.',
  fecha_fin DATE NULL COMMENT 'Fecha en que deja el equipo; NULL = sigue vigente.',
  CONSTRAINT pk_integrante_equipo PRIMARY KEY (id_integrante),
  CONSTRAINT uq_integrante_equipo_inicio UNIQUE (id_deportista, id_equipo, fecha_inicio),
  CONSTRAINT fk_integrante_equipo_deportista FOREIGN KEY (id_deportista) REFERENCES deportista (id_deportista),
  CONSTRAINT fk_integrante_equipo_equipo FOREIGN KEY (id_equipo) REFERENCES equipo (id_equipo)
) ENGINE=InnoDB COMMENT='Participación de un deportista en un equipo a lo largo del tiempo, con función y fechas (resuelve la relación M:N INTEGRA). Regla 3.';

CREATE TABLE escenario (
  id_escenario INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del escenario.',
  codigo VARCHAR(20) NOT NULL COMMENT 'Código del escenario (ESC-0001).',
  nombre VARCHAR(80) NOT NULL COMMENT 'Nombre del escenario (no se repite en la misma ciudad).',
  tipo VARCHAR(12) NOT NULL COMMENT 'ESTADIO, COLISEO, CANCHA, PISCINA, PISTA, VELODROMO o GIMNASIO.',
  ciudad VARCHAR(50) NOT NULL COMMENT 'Ciudad donde está el escenario.',
  direccion VARCHAR(100) NOT NULL COMMENT 'Dirección del escenario.',
  capacidad INT NOT NULL COMMENT 'Capacidad de espectadores (debe ser positiva).',
  estado VARCHAR(15) NOT NULL DEFAULT 'DISPONIBLE' COMMENT 'DISPONIBLE, MANTENIMIENTO o INACTIVO.',
  CONSTRAINT pk_escenario PRIMARY KEY (id_escenario),
  CONSTRAINT uq_escenario_codigo UNIQUE (codigo),
  CONSTRAINT uq_escenario_nombre_ciudad UNIQUE (nombre, ciudad)
) ENGINE=InnoDB COMMENT='Escenarios deportivos donde se juegan los encuentros. Regla 4 (capacidad positiva) y regla 8 (pueden no tener encuentros).';

CREATE TABLE torneo (
  id_torneo INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del torneo.',
  codigo VARCHAR(20) NOT NULL COMMENT 'Código del torneo (TOR-0001).',
  nombre VARCHAR(100) NOT NULL COMMENT 'Nombre del torneo.',
  id_disciplina INT NOT NULL COMMENT 'Disciplina del torneo; solo se inscriben equipos de esta disciplina.',
  fecha_inicio DATE NOT NULL COMMENT 'Fecha de inicio del torneo.',
  fecha_fin DATE NOT NULL COMMENT 'Fecha de finalización (no anterior a fecha_inicio).',
  estado VARCHAR(12) NOT NULL DEFAULT 'PROGRAMADO' COMMENT 'PROGRAMADO, EN_CURSO, FINALIZADO o CANCELADO.',
  CONSTRAINT pk_torneo PRIMARY KEY (id_torneo),
  CONSTRAINT uq_torneo_codigo UNIQUE (codigo),
  CONSTRAINT fk_torneo_disciplina FOREIGN KEY (id_disciplina) REFERENCES disciplina (id_disciplina)
) ENGINE=InnoDB COMMENT='Torneos de una disciplina con fechas coherentes. Regla 4.';

CREATE TABLE inscripcion (
  id_inscripcion INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único de la inscripción.',
  id_torneo INT NOT NULL COMMENT 'Torneo en el que se inscribe el equipo.',
  id_equipo INT NOT NULL COMMENT 'Equipo inscrito.',
  fecha_inscripcion DATE NOT NULL COMMENT 'Fecha de la inscripción (no posterior al fin del torneo).',
  estado VARCHAR(10) NOT NULL DEFAULT 'PENDIENTE' COMMENT 'PENDIENTE (inicial), APROBADA, RECHAZADA o RETIRADA. Solo los equipos APROBADOS pueden jugar.',
  CONSTRAINT pk_inscripcion PRIMARY KEY (id_inscripcion),
  CONSTRAINT uq_inscripcion_torneo_equipo UNIQUE (id_torneo, id_equipo),
  CONSTRAINT fk_inscripcion_torneo FOREIGN KEY (id_torneo) REFERENCES torneo (id_torneo),
  CONSTRAINT fk_inscripcion_equipo FOREIGN KEY (id_equipo) REFERENCES equipo (id_equipo)
) ENGINE=InnoDB COMMENT='Inscripción de un equipo en un torneo (resuelve la relación M:N SE INSCRIBE). Regla 7: estado inicial por defecto PENDIENTE.';

CREATE TABLE encuentro (
  id_encuentro INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del encuentro.',
  id_torneo INT NOT NULL COMMENT 'Torneo al que pertenece el encuentro.',
  id_escenario INT NOT NULL COMMENT 'Escenario asignado.',
  id_equipo_local INT NOT NULL COMMENT 'Equipo local.',
  id_equipo_visitante INT NOT NULL COMMENT 'Equipo visitante (distinto del local).',
  fecha_hora DATETIME NOT NULL COMMENT 'Fecha y hora programada (dentro de las fechas del torneo).',
  jornada SMALLINT NOT NULL DEFAULT 1 COMMENT 'Número de jornada o ronda dentro del torneo (mayor que 0).',
  estado VARCHAR(12) NOT NULL DEFAULT 'PROGRAMADO' COMMENT 'PROGRAMADO (inicial), EN_JUEGO, FINALIZADO, SUSPENDIDO o CANCELADO.',
  puntaje_local SMALLINT NULL COMMENT 'Puntos/goles/sets del equipo local; NULL mientras no se juega.',
  puntaje_visitante SMALLINT NULL COMMENT 'Puntos/goles/sets del equipo visitante; NULL mientras no se juega.',
  resultado_definitivo TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = resultado oficial (homologado); 0 = no definitivo. Solo puede ser 1 si el encuentro está FINALIZADO.',
  CONSTRAINT pk_encuentro PRIMARY KEY (id_encuentro),
  CONSTRAINT uq_encuentro_escenario_fecha UNIQUE (id_escenario, fecha_hora),
  CONSTRAINT fk_encuentro_torneo FOREIGN KEY (id_torneo) REFERENCES torneo (id_torneo),
  CONSTRAINT fk_encuentro_escenario FOREIGN KEY (id_escenario) REFERENCES escenario (id_escenario),
  CONSTRAINT fk_encuentro_equipo_local FOREIGN KEY (id_equipo_local) REFERENCES equipo (id_equipo),
  CONSTRAINT fk_encuentro_equipo_visitante FOREIGN KEY (id_equipo_visitante) REFERENCES equipo (id_equipo)
) ENGINE=InnoDB COMMENT='Partido entre dos equipos dentro de un torneo, en un escenario, con su marcador (el resultado es 1:1 con el encuentro). Reglas 5, 6 y 7.';

CREATE TABLE participacion_encuentro (
  id_participacion INT NOT NULL AUTO_INCREMENT COMMENT 'Identificador único de la participación.',
  id_encuentro INT NOT NULL COMMENT 'Encuentro jugado.',
  id_deportista INT NOT NULL COMMENT 'Deportista que jugó.',
  id_equipo INT NOT NULL COMMENT 'Equipo con el que jugó (debe ser el local o el visitante).',
  es_titular TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = inició como titular; 0 = ingresó como suplente.',
  minutos_jugados SMALLINT NULL COMMENT 'Minutos jugados (0 a 300); NULL en deportes sin reloj (voleibol, béisbol…).',
  calificacion DECIMAL(3,1) NULL COMMENT 'Calificación de desempeño del deportista en el encuentro (0,0 a 10,0).',
  CONSTRAINT pk_participacion_encuentro PRIMARY KEY (id_participacion),
  CONSTRAINT uq_participacion_encuentro_deportista UNIQUE (id_encuentro, id_deportista),
  CONSTRAINT fk_participacion_encuentro FOREIGN KEY (id_encuentro) REFERENCES encuentro (id_encuentro),
  CONSTRAINT fk_participacion_deportista FOREIGN KEY (id_deportista) REFERENCES deportista (id_deportista),
  CONSTRAINT fk_participacion_equipo FOREIGN KEY (id_equipo) REFERENCES equipo (id_equipo)
) ENGINE=InnoDB COMMENT='Deportistas que jugaron un encuentro con su equipo; base de los reportes de participación y desempeño (resuelve la relación M:N PARTICIPA).';
