"""
Proyecto integrador - Caso 5: Gestión deportiva
Integrantes: Juan Sebastián Cárdenas, Juan David Segura
Genera el diccionario de datos (Markdown) y el diagrama del modelo relacional
(Graphviz) A PARTIR DE LOS METADATOS REALES de SQL Server, para garantizar que
la documentación coincide exactamente con la implementación.

Pasos:
  1. Ejecutar scripts/sqlserver/07_metadatos_diccionario.sql con sqlcmd y guardar
     la salida separada por "|" en evidencias/resultados/07_metadatos_resultado.txt
     sqlcmd -S localhost -E -d GestionDeportiva -f 65001 -W -s "|" -i 07_metadatos_diccionario.sql -o ...
  2. python scripts/generador/generar_diccionario_y_relacional.py
  3. dot -Tpng -Gdpi=150 diagramas/relacional/modelo_relacional.dot -o diagramas/relacional/modelo_relacional.png

Las descripciones de negocio de cada tabla y columna están en este archivo.
"""
import re
from collections import defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
METADATOS = RAIZ / "evidencias" / "resultados" / "07_metadatos_resultado.txt"
DICCIONARIO = RAIZ / "documentacion" / "diccionario_datos.md"
DOT = RAIZ / "diagramas" / "relacional" / "modelo_relacional.dot"

ORDEN_TABLAS = ["disciplina", "persona", "deportista", "entrenador", "equipo", "entrenador_equipo",
                "integrante_equipo", "escenario", "torneo", "inscripcion", "encuentro", "participacion_encuentro"]

TABLAS = {
    "disciplina": "Catálogo de disciplinas deportivas. Una disciplina es la combinación de deporte, modalidad, rama y categoría en la que se compite (ej.: Fútbol / Fútbol 11 / FEMENINA / ELITE).",
    "persona": "Datos personales comunes a deportistas y entrenadores. Se registran una sola vez aunque la persona cumpla los dos roles (evita duplicar información de personas).",
    "deportista": "Rol de deportista de una persona (subtipo de PERSONA, relación 1:1 opcional).",
    "entrenador": "Rol de entrenador de una persona (subtipo de PERSONA, relación 1:1 opcional).",
    "equipo": "Equipos de la organización; cada equipo compite en una disciplina.",
    "entrenador_equipo": "Asignación de un entrenador a un equipo en un periodo (resuelve la relación M:N DIRIGE y conserva la vigencia). Regla 2.",
    "integrante_equipo": "Participación de un deportista en un equipo a lo largo del tiempo, con función y fechas (resuelve la relación M:N INTEGRA). Regla 3.",
    "escenario": "Escenarios deportivos donde se juegan los encuentros. Regla 4 (capacidad positiva) y regla 8 (pueden no tener encuentros).",
    "torneo": "Torneos de una disciplina con fechas coherentes. Regla 4.",
    "inscripcion": "Inscripción de un equipo en un torneo (resuelve la relación M:N SE INSCRIBE). Regla 7: estado inicial por defecto PENDIENTE.",
    "encuentro": "Partido entre dos equipos dentro de un torneo, en un escenario, con su marcador (el resultado es 1:1 con el encuentro). Reglas 5, 6 y 7.",
    "participacion_encuentro": "Deportistas que jugaron un encuentro con su equipo; base de los reportes de participación y desempeño (resuelve la relación M:N PARTICIPA).",
}

COLUMNAS = {
    "disciplina": {
        "id_disciplina": "Identificador único de la disciplina (sustituto).",
        "codigo": "Código legible: DEPORTE-modalidad-rama-categoría (ej. FUT-1-F-ELI).",
        "deporte": "Nombre del deporte (Fútbol, Baloncesto, Natación…).",
        "modalidad": "Modalidad del deporte (Fútbol 11, 3x3, Playa, Por equipos…).",
        "rama": "Rama de competencia: MASCULINA, FEMENINA o MIXTA.",
        "categoria": "Nivel competitivo: RECREATIVA, AFICIONADA, INTERMEDIA, AVANZADA o ELITE.",
        "tipo_participacion": "CONJUNTO (equipos) o INDIVIDUAL.",
    },
    "persona": {
        "id_persona": "Identificador único de la persona (sustituto).",
        "tipo_documento": "Tipo de documento: CC, TI, CE o PAS.",
        "numero_documento": "Número del documento (solo dígitos o letras mayúsculas, mínimo 5 caracteres).",
        "nombres": "Nombres de la persona.",
        "apellidos": "Apellidos de la persona.",
        "fecha_nacimiento": "Fecha de nacimiento (entre 1940-01-01 y la fecha actual).",
        "sexo": "Sexo registrado para efectos de la rama de competencia: F o M.",
        "correo": "Correo electrónico de contacto (único, formato texto@dominio.ext).",
        "telefono": "Teléfono de contacto (opcional).",
        "fecha_registro": "Fecha y hora en que se registró la persona en el sistema.",
    },
    "deportista": {
        "id_deportista": "Identificador único del deportista.",
        "id_persona": "Persona a la que corresponde el rol de deportista (una persona = un registro de deportista).",
        "id_disciplina": "Disciplina principal del deportista.",
        "estado": "Estado deportivo: ACTIVO, LESIONADO, SUSPENDIDO o RETIRADO.",
        "fecha_ingreso": "Fecha de afiliación a la organización.",
    },
    "entrenador": {
        "id_entrenador": "Identificador único del entrenador.",
        "id_persona": "Persona a la que corresponde el rol de entrenador.",
        "numero_licencia": "Número de la licencia de entrenador (único).",
        "nivel_licencia": "Nivel de la licencia: BASICO, INTERMEDIO, AVANZADO o PROFESIONAL.",
        "anios_experiencia": "Años de experiencia como entrenador (0 a 60).",
        "estado": "Estado del entrenador en la organización: ACTIVO o INACTIVO.",
        "fecha_ingreso": "Fecha de vinculación a la organización.",
    },
    "equipo": {
        "id_equipo": "Identificador único del equipo.",
        "codigo": "Código del equipo (EQ-00001).",
        "nombre": "Nombre del equipo (no se repite dentro de la misma disciplina).",
        "id_disciplina": "Disciplina en la que compite el equipo.",
        "ciudad": "Ciudad sede del equipo.",
        "fecha_fundacion": "Fecha de fundación; ninguna asignación de entrenador o deportista puede ser anterior.",
        "estado": "ACTIVO o INACTIVO.",
    },
    "entrenador_equipo": {
        "id_asignacion": "Identificador único de la asignación.",
        "id_entrenador": "Entrenador asignado.",
        "id_equipo": "Equipo dirigido.",
        "rol": "Rol en el cuerpo técnico: PRINCIPAL, ASISTENTE o PREPARADOR_FISICO.",
        "fecha_inicio": "Inicio de la vigencia de la asignación.",
        "fecha_fin": "Fin de la vigencia; NULL = asignación vigente.",
    },
    "integrante_equipo": {
        "id_integrante": "Identificador único del periodo de participación.",
        "id_deportista": "Deportista que integra el equipo.",
        "id_equipo": "Equipo que integra.",
        "funcion": "Función en el equipo: CAPITAN, TITULAR, SUPLENTE o RESERVA.",
        "numero_camiseta": "Número de camiseta (0 a 99, opcional).",
        "fecha_inicio": "Fecha en que empieza a integrar el equipo.",
        "fecha_fin": "Fecha en que deja el equipo; NULL = sigue vigente.",
    },
    "escenario": {
        "id_escenario": "Identificador único del escenario.",
        "codigo": "Código del escenario (ESC-0001).",
        "nombre": "Nombre del escenario (no se repite en la misma ciudad).",
        "tipo": "ESTADIO, COLISEO, CANCHA, PISCINA, PISTA, VELODROMO o GIMNASIO.",
        "ciudad": "Ciudad donde está el escenario.",
        "direccion": "Dirección del escenario.",
        "capacidad": "Capacidad de espectadores (debe ser positiva).",
        "estado": "DISPONIBLE, MANTENIMIENTO o INACTIVO.",
    },
    "torneo": {
        "id_torneo": "Identificador único del torneo.",
        "codigo": "Código del torneo (TOR-0001).",
        "nombre": "Nombre del torneo.",
        "id_disciplina": "Disciplina del torneo; solo se inscriben equipos de esta disciplina.",
        "fecha_inicio": "Fecha de inicio del torneo.",
        "fecha_fin": "Fecha de finalización (no anterior a fecha_inicio).",
        "estado": "PROGRAMADO, EN_CURSO, FINALIZADO o CANCELADO.",
    },
    "inscripcion": {
        "id_inscripcion": "Identificador único de la inscripción.",
        "id_torneo": "Torneo en el que se inscribe el equipo.",
        "id_equipo": "Equipo inscrito.",
        "fecha_inscripcion": "Fecha de la inscripción (no posterior al fin del torneo).",
        "estado": "PENDIENTE (inicial), APROBADA, RECHAZADA o RETIRADA. Solo los equipos APROBADOS pueden jugar.",
    },
    "encuentro": {
        "id_encuentro": "Identificador único del encuentro.",
        "id_torneo": "Torneo al que pertenece el encuentro.",
        "id_escenario": "Escenario asignado.",
        "id_equipo_local": "Equipo local.",
        "id_equipo_visitante": "Equipo visitante (distinto del local).",
        "fecha_hora": "Fecha y hora programada (dentro de las fechas del torneo).",
        "jornada": "Número de jornada o ronda dentro del torneo (mayor que 0).",
        "estado": "PROGRAMADO (inicial), EN_JUEGO, FINALIZADO, SUSPENDIDO o CANCELADO.",
        "puntaje_local": "Puntos/goles/sets del equipo local; NULL mientras no se juega.",
        "puntaje_visitante": "Puntos/goles/sets del equipo visitante; NULL mientras no se juega.",
        "resultado_definitivo": "1 = resultado oficial (homologado); 0 = no definitivo. Solo puede ser 1 si el encuentro está FINALIZADO.",
    },
    "participacion_encuentro": {
        "id_participacion": "Identificador único de la participación.",
        "id_encuentro": "Encuentro jugado.",
        "id_deportista": "Deportista que jugó.",
        "id_equipo": "Equipo con el que jugó (debe ser el local o el visitante).",
        "es_titular": "1 = inició como titular; 0 = ingresó como suplente.",
        "minutos_jugados": "Minutos jugados (0 a 300); NULL en deportes sin reloj (voleibol, béisbol…).",
        "calificacion": "Calificación de desempeño del deportista en el encuentro (0,0 a 10,0).",
    },
}

TRIGGERS = {
    "tr_entrenador_equipo_validar": "Regla 2: la asignación no inicia antes de la fundación del equipo; no hay dos entrenadores PRINCIPALES con periodos cruzados en un equipo ni el mismo entrenador con periodos cruzados en el mismo equipo.",
    "tr_integrante_equipo_validar": "Regla 3: la participación no inicia antes de la fundación del equipo; un deportista no tiene dos periodos cruzados en el mismo equipo.",
    "tr_inscripcion_validar": "El equipo debe ser de la misma disciplina del torneo; la inscripción no puede ser posterior al fin del torneo.",
    "tr_encuentro_validar": "Regla 5: la fecha del encuentro está dentro del torneo y ambos equipos tienen inscripción APROBADA. Regla 6: un resultado definitivo no se puede modificar.",
    "tr_participacion_validar": "El equipo del deportista juega el encuentro, el encuentro se jugó (EN_JUEGO, FINALIZADO o SUSPENDIDO) y el deportista integraba el equipo en esa fecha.",
}


def leer_metadatos():
    secciones, actual = [], None
    for linea in METADATOS.read_text(encoding="utf-8").splitlines():
        if not linea.strip() or linea.startswith("Changed database"):
            continue
        partes = linea.split("|")
        if set(linea) <= set("-|"):
            continue
        if partes[0] == "tabla":
            actual = {"cabecera": partes, "filas": []}
            secciones.append(actual)
        elif actual is not None:
            actual["filas"].append(dict(zip(actual["cabecera"], partes)))
    return secciones[0]["filas"], secciones[1]["filas"], secciones[2]["filas"]


def tipo_completo(c):
    t, l = c["tipo"], c["longitud"]
    if t in ("varchar", "nvarchar", "char"):
        return f"{t.upper()}({l})"
    if t == "decimal":
        return f"DECIMAL({l})"
    if t == "datetime2":
        return f"DATETIME2({l})"
    return t.upper()


def limpiar_default(d):
    d = d.strip()
    while d.startswith("(") and d.endswith(")"):
        d = d[1:-1]
    return d.replace("CONVERT([date],getdate())", "CAST(GETDATE() AS DATE)").replace("sysdatetime()", "SYSDATETIME()")


def main():
    columnas, restricciones, triggers = leer_metadatos()
    por_tabla = defaultdict(list)
    for c in columnas:
        por_tabla[c["tabla"]].append(c)
    restr_tabla = defaultdict(list)
    for r in restricciones:
        restr_tabla[r["tabla"]].append(r)
    trig_tabla = defaultdict(list)
    for t in triggers:
        trig_tabla[t["tabla"]].append(t["trigger_nombre"])

    assert set(por_tabla) == set(ORDEN_TABLAS), set(por_tabla) ^ set(ORDEN_TABLAS)
    for tabla in ORDEN_TABLAS:   # toda columna implementada debe estar descrita y viceversa
        reales = {c["columna"] for c in por_tabla[tabla]}
        assert reales == set(COLUMNAS[tabla]), (tabla, reales ^ set(COLUMNAS[tabla]))

    md = ["# Diccionario de datos — Caso 5: Gestión deportiva", "",
          "Base de datos: **GestionDeportiva** (Microsoft SQL Server). 12 tablas.", "",
          "> Este diccionario se generó a partir del catálogo real de SQL Server "
          "(`scripts/sqlserver/07_metadatos_diccionario.sql`) con "
          "`scripts/generador/generar_diccionario_y_relacional.py`; por eso los tipos, longitudes, nulabilidad, "
          "DEFAULT y restricciones coinciden exactamente con la implementación. Las descripciones y reglas de "
          "negocio se redactaron para el caso.", "",
          "**Convenciones:** `pk_` clave primaria · `fk_` clave foránea · `uq_` único · `ck_` verificación · "
          "`df_` valor por defecto · `tr_` trigger. Todas las PK son `INT IDENTITY(1,1)` (claves sustitutas). "
          "Los textos con nombres de personas, lugares o deportes usan `NVARCHAR` para soportar tildes y eñes; "
          "los códigos y estados usan `VARCHAR`.", "",
          "## Resumen de tablas", "", "| # | Tabla | Descripción | Columnas |", "|---|---|---|---|"]
    for i, tabla in enumerate(ORDEN_TABLAS, 1):
        md.append(f"| {i} | [`{tabla}`](#{tabla}) | {TABLAS[tabla]} | {len(por_tabla[tabla])} |")

    for tabla in ORDEN_TABLAS:
        md += ["", f"## {tabla}", "", TABLAS[tabla], "",
               "| Columna | Descripción | Tipo | Nulo | Clave | DEFAULT | Restricciones y reglas |",
               "|---|---|---|---|---|---|---|"]
        for c in por_tabla[tabla]:
            clave = []
            if c["pk"] == "PK":
                clave.append("**PK**")
            if c["fk"]:
                clave.append("FK → `" + c["fk"].replace("FK -> ", "") + "`")
            reglas = []
            if c["identidad"]:
                reglas.append("IDENTITY(1,1)")
            for r in restr_tabla[tabla]:
                if r["tipo"] == "UNIQUE" and c["columna"] in [x.strip() for x in r["definicion"].split(",")]:
                    cols = r["definicion"]
                    reglas.append(f"`{r['restriccion']}`" + ("" if "," not in cols else f" ({cols})"))
                if r["tipo"] == "CHECK" and re.search(r"\[" + re.escape(c["columna"]) + r"\]", r["definicion"]):
                    reglas.append(f"`{r['restriccion']}`")
            dflt = limpiar_default(c["valor_default"])
            md.append(f"| `{c['columna']}` | {COLUMNAS[tabla][c['columna']]} | {tipo_completo(c)} | "
                      f"{'Sí' if c['nulabilidad'] == 'NULL' else 'No'} | {' '.join(clave) or '—'} | "
                      f"{('`' + dflt + '`') if dflt else '—'} | {', '.join(reglas) or '—'} |")
        md += ["", "**Restricciones de la tabla:**", ""]
        for r in sorted(restr_tabla[tabla], key=lambda r: (r["tipo"], r["restriccion"])):
            defin = r["definicion"].replace("|", "\\|")
            md.append(f"- `{r['restriccion']}` ({r['tipo']}): `{defin}`")
        for t in trig_tabla[tabla]:
            md.append(f"- `{t}` (TRIGGER AFTER INSERT, UPDATE): {TRIGGERS[t]}")

    md += ["", "## Relaciones (claves foráneas)", "", "| Tabla hija | Columna | Tabla padre | Cardinalidad |", "|---|---|---|---|"]
    for tabla in ORDEN_TABLAS:
        for c in por_tabla[tabla]:
            if c["fk"]:
                padre = c["fk"].replace("FK -> ", "").split(".")[0]
                card = "1:1 (UNIQUE)" if any(r["tipo"] == "UNIQUE" and r["definicion"] == c["columna"] for r in restr_tabla[tabla]) else "N:1"
                md.append(f"| `{tabla}` | `{c['columna']}` | `{padre}` | {card} |")
    DICCIONARIO.write_text("\n".join(md) + "\n", encoding="utf-8")

    # ---------------- Diagrama relacional (Graphviz) ----------------
    dot = ["// Modelo relacional - Caso 5: Gestión deportiva (generado desde el catálogo de SQL Server)",
           "digraph relacional {",
           '  graph [rankdir=LR, splines=spline, nodesep=0.35, ranksep=1.6, fontname="Helvetica", labelloc=t, fontsize=20, pad=0.3,',
           '         label=<<B>Caso 5 — Gestión deportiva: modelo relacional (SQL Server)</B><BR/><FONT POINT-SIZE="11">PK = clave primaria · FK = clave foránea · UQ = único · UQc = parte de un UNIQUE compuesto · línea: padre (1, barra) → hija (N, pata de gallo)</FONT>>];',
           '  node [shape=plain, fontname="Helvetica", fontsize=10];',
           '  edge [color="#4A5568", arrowhead=crow, arrowtail=tee, dir=both, penwidth=1.2];']
    for tabla in ORDEN_TABLAS:
        filas = [f'<TR><TD COLSPAN="3" BGCOLOR="#22543D"><FONT COLOR="white"><B>{tabla}</B></FONT></TD></TR>']
        uniques = {r["definicion"].strip() for r in restr_tabla[tabla] if r["tipo"] == "UNIQUE" and "," not in r["definicion"]}
        uniques_comp = {x.strip() for r in restr_tabla[tabla] if r["tipo"] == "UNIQUE" and "," in r["definicion"] for x in r["definicion"].split(",")}
        for c in por_tabla[tabla]:
            marcas = []
            if c["pk"]:
                marcas.append("PK")
            if c["fk"]:
                marcas.append("FK")
            if c["columna"] in uniques:
                marcas.append("UQ")
            elif c["columna"] in uniques_comp:
                marcas.append("UQc")
            nombre = f"<B>{c['columna']}</B>" if c["pk"] else c["columna"]
            nulo = "" if c["nulabilidad"] == "NOT NULL" else " NULL"
            filas.append(f'<TR><TD ALIGN="LEFT" PORT="{c["columna"]}">{nombre}</TD><TD ALIGN="LEFT">{tipo_completo(c)}{nulo}</TD>'
                         + (f'<TD ALIGN="LEFT"><FONT COLOR="#9B2C2C">{" ".join(marcas)}</FONT></TD></TR>' if marcas else '<TD></TD></TR>'))
        dot.append(f'  {tabla} [label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3" BGCOLOR="#F0FFF4">{"".join(filas)}</TABLE>>];')
    for tabla in ORDEN_TABLAS:
        for c in por_tabla[tabla]:
            if c["fk"]:
                padre, col = c["fk"].replace("FK -> ", "").split(".")
                dot.append(f'  {padre}:{col}:e -> {tabla}:{c["columna"]}:w;')
    dot.append("}")
    DOT.write_text("\n".join(dot) + "\n", encoding="utf-8")
    print("Generados:", DICCIONARIO.relative_to(RAIZ), DOT.relative_to(RAIZ))


if __name__ == "__main__":
    main()
