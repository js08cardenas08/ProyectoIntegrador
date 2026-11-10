"""
Proyecto integrador - Caso 5: Gestión deportiva
Generador de datos semilla sintéticos para SQL Server.

Produce el archivo scripts/sqlserver/03_datos_semilla.sql con INSERT
explícitos. Usa una semilla fija (random.seed), por lo que cada ejecución
genera EXACTAMENTE los mismos datos (reproducibles).

Uso (desde la raíz del repositorio):
    python scripts/generador/generar_datos_semilla.py

Todos los nombres, documentos y correos son ficticios (dominio reservado
.example). No se usan datos personales reales.
"""
import random
from datetime import date, datetime, timedelta
from pathlib import Path

SEMILLA = 2026
FECHA_REF = date(2026, 11, 1)          # "hoy" de los datos: separa pasado y futuro
random.seed(SEMILLA)

RAIZ = Path(__file__).resolve().parents[2]
SALIDA = RAIZ / "scripts" / "sqlserver" / "03_datos_semilla.sql"

# ---------------------------------------------------------------------------
# Catálogos base
# ---------------------------------------------------------------------------
# deporte: (código, [(modalidad, tipo_participacion, minutos_partido)], perfil_marcador, escenarios_aptos)
DEPORTES = {
    "Fútbol":            ("FUT", [("Fútbol 11", "CONJUNTO", 90), ("Fútbol 7", "CONJUNTO", 50), ("Fútbol Sala", "CONJUNTO", 40)], "goles", None),
    "Baloncesto":        ("BAL", [("5x5", "CONJUNTO", 40), ("3x3", "CONJUNTO", 10), ("Silla de ruedas", "CONJUNTO", 40)], "baloncesto", ("COLISEO", "GIMNASIO")),
    "Voleibol":          ("VOL", [("Sala", "CONJUNTO", None), ("Playa", "CONJUNTO", None), ("Sentado", "CONJUNTO", None)], "sets", ("COLISEO", "GIMNASIO")),
    "Balonmano":         ("BMN", [("Pista", "CONJUNTO", 60), ("Playa", "CONJUNTO", 20), ("Silla de ruedas", "CONJUNTO", 40)], "balonmano", ("COLISEO", "GIMNASIO")),
    "Rugby":             ("RUG", [("Rugby 15", "CONJUNTO", 80), ("Rugby 7", "CONJUNTO", 14), ("Touch", "CONJUNTO", 40)], "rugby", ("ESTADIO", "CANCHA")),
    "Hockey":            ("HOC", [("Césped", "CONJUNTO", 60), ("Sala", "CONJUNTO", 40), ("Patines", "CONJUNTO", 50)], "goles", None),
    "Béisbol":           ("BEI", [("Béisbol", "CONJUNTO", None), ("Sóftbol rápido", "CONJUNTO", None), ("Sóftbol lento", "CONJUNTO", None)], "beisbol", ("ESTADIO", "CANCHA")),
    "Ultimate":          ("ULT", [("Césped", "CONJUNTO", None), ("Playa", "CONJUNTO", None), ("Indoor", "CONJUNTO", None)], "ultimate", ("CANCHA", "ESTADIO")),
    "Tenis":             ("TEN", [("Individual", "INDIVIDUAL", None), ("Dobles", "CONJUNTO", None), ("Por equipos", "CONJUNTO", None)], "partidas", ("CANCHA",)),
    "Tenis de mesa":     ("TME", [("Individual", "INDIVIDUAL", None), ("Dobles", "CONJUNTO", None), ("Por equipos", "CONJUNTO", None)], "partidas", ("GIMNASIO", "COLISEO")),
    "Bádminton":         ("BAD", [("Individual", "INDIVIDUAL", None), ("Dobles", "CONJUNTO", None), ("Por equipos", "CONJUNTO", None)], "partidas", ("GIMNASIO", "COLISEO")),
    "Squash":            ("SQU", [("Individual", "INDIVIDUAL", None), ("Dobles", "CONJUNTO", None), ("Por equipos", "CONJUNTO", None)], "partidas", ("GIMNASIO",)),
    "Judo":              ("JUD", [("Combate", "INDIVIDUAL", None), ("Kata", "INDIVIDUAL", None), ("Por equipos", "CONJUNTO", None)], "partidas", ("COLISEO", "GIMNASIO")),
    "Taekwondo":         ("TKD", [("Combate", "INDIVIDUAL", None), ("Poomsae", "INDIVIDUAL", None), ("Por equipos", "CONJUNTO", None)], "partidas", ("COLISEO", "GIMNASIO")),
    "Karate":            ("KAR", [("Kumite", "INDIVIDUAL", None), ("Kata", "INDIVIDUAL", None), ("Por equipos", "CONJUNTO", None)], "partidas", ("COLISEO", "GIMNASIO")),
    "Atletismo":         ("ATL", [("Pista", "INDIVIDUAL", None), ("Ruta", "INDIVIDUAL", None), ("Relevos", "CONJUNTO", None)], None, None),
    "Natación":          ("NAT", [("Piscina corta", "INDIVIDUAL", None), ("Piscina larga", "INDIVIDUAL", None), ("Aguas abiertas", "INDIVIDUAL", None)], None, None),
    "Ciclismo":          ("CIC", [("Ruta", "INDIVIDUAL", None), ("Pista", "INDIVIDUAL", None), ("Montaña", "INDIVIDUAL", None)], None, None),
    "Patinaje":          ("PAT", [("Velocidad", "INDIVIDUAL", None), ("Artístico", "INDIVIDUAL", None), ("Freestyle", "INDIVIDUAL", None)], None, None),
    "Gimnasia":          ("GIM", [("Artística", "INDIVIDUAL", None), ("Rítmica", "INDIVIDUAL", None), ("Trampolín", "INDIVIDUAL", None)], None, None),
    "Esgrima":           ("ESG", [("Florete", "INDIVIDUAL", None), ("Espada", "INDIVIDUAL", None), ("Sable", "INDIVIDUAL", None)], None, None),
    "Levantamiento de pesas": ("PES", [("Arranque", "INDIVIDUAL", None), ("Envión", "INDIVIDUAL", None), ("Total olímpico", "INDIVIDUAL", None)], None, None),
    "Ajedrez":           ("AJE", [("Clásico", "INDIVIDUAL", None), ("Rápido", "INDIVIDUAL", None), ("Relámpago", "INDIVIDUAL", None)], None, None),
}
DEPORTES_EXTERIOR = ("ESTADIO", "CANCHA")
RAMAS = [("MASCULINA", "M"), ("FEMENINA", "F"), ("MIXTA", "X")]
CATEGORIAS = [("RECREATIVA", "REC"), ("AFICIONADA", "AFI"), ("INTERMEDIA", "INT"), ("AVANZADA", "AVA"), ("ELITE", "ELI")]

NOMBRES_M = ["Juan", "Carlos", "Andrés", "Luis", "Jorge", "Santiago", "Sebastián", "Mateo", "Nicolás", "Daniel",
             "Felipe", "Camilo", "Alejandro", "David", "Julián", "Esteban", "Diego", "Miguel", "Samuel", "Tomás",
             "Gabriel", "Óscar", "Mauricio", "Iván", "Fabián", "Héctor", "Cristian", "Emilio", "Martín", "Simón"]
NOMBRES_F = ["María", "Laura", "Valentina", "Daniela", "Camila", "Sofía", "Isabella", "Paula", "Natalia", "Andrea",
             "Juliana", "Carolina", "Gabriela", "Mariana", "Luisa", "Catalina", "Sara", "Ana", "Lucía", "Manuela",
             "Diana", "Paola", "Valeria", "Ximena", "Juana", "Alejandra", "Tatiana", "Lorena", "Mónica", "Salomé"]
APELLIDOS = ["García", "Rodríguez", "Martínez", "López", "González", "Hernández", "Pérez", "Sánchez", "Ramírez", "Torres",
             "Díaz", "Vargas", "Moreno", "Rojas", "Jiménez", "Castro", "Ortiz", "Gómez", "Ruiz", "Suárez",
             "Romero", "Herrera", "Medina", "Aguilar", "Muñoz", "Peña", "Cárdenas", "Ríos", "Mejía", "Restrepo",
             "Ospina", "Arango", "Quintero", "Salazar", "Cortés", "Valencia", "Cifuentes", "Guerrero", "Mora", "Patiño",
             "Bermúdez", "Londoño", "Zapata", "Cardona", "Escobar", "Galeano", "Montoya", "Rincón", "Becerra", "Acosta"]
CIUDADES = ["Bogotá", "Medellín", "Cali", "Barranquilla", "Cartagena", "Bucaramanga", "Pereira", "Manizales",
            "Ibagué", "Santa Marta", "Villavicencio", "Pasto", "Neiva", "Armenia", "Tunja", "Popayán",
            "Montería", "Valledupar", "Sincelejo", "Cúcuta", "Riohacha", "Yopal", "Florencia", "Quibdó", "Leticia"]
PREFIJOS_EQUIPO = ["Club", "Club Deportivo", "Atlético", "Deportivo", "Real", "Unión", "Independiente", "Academia"]
NUCLEOS_EQUIPO = ["Halcones", "Cóndores", "Tigres", "Pumas", "Jaguares", "Águilas", "Leones", "Toros", "Titanes",
                  "Guerreros", "Centauros", "Lobos", "Panteras", "Delfines", "Tiburones", "Búhos", "Dragones",
                  "Fénix", "Rayos", "Huracanes", "Volcanes", "Andes", "Pacífico", "Caribe", "Llanos", "Sabana",
                  "Cafeteros", "Orquídeas", "Ceibas", "Colibríes"]
BARRIOS = ["El Prado", "La Floresta", "San José", "Santa Fe", "El Poblado", "La Esperanza", "Los Alpes", "El Recreo",
           "Villa Olímpica", "La Castellana", "Las Américas", "El Bosque", "San Fernando", "La Candelaria",
           "Los Almendros", "El Rosal", "Laureles", "Belén", "Normandía", "Modelia", "Santa Isabel", "La Pradera",
           "El Jardín", "Los Pinos", "Altos del Río", "La Granja", "San Antonio", "Bella Vista", "El Lago", "Villa Luz",
           "Campo Alegre", "Ciudad Jardín", "Las Palmas", "El Retiro", "Puerto Nuevo", "La Victoria", "Galerías",
           "Mirador", "Los Cerezos", "El Porvenir", "Nueva Granada", "La Sultana", "Primavera", "San Martín"]
TIPOS_ESCENARIO = [("ESTADIO", "Estadio", (5000, 45000), 0.12), ("COLISEO", "Coliseo", (1000, 15000), 0.22),
                   ("CANCHA", "Cancha", (100, 3000), 0.30), ("GIMNASIO", "Gimnasio", (100, 1500), 0.18),
                   ("PISCINA", "Piscina", (200, 3000), 0.08), ("PISTA", "Pista atlética", (500, 8000), 0.06),
                   ("VELODROMO", "Velódromo", (1000, 6000), 0.04)]
TIPOS_TORNEO = ["Liga", "Copa", "Torneo Abierto", "Copa Interclubes", "Campeonato Departamental", "Torneo Relámpago"]
SIN_ACENTO = str.maketrans("áéíóúÁÉÍÓÚñÑü", "aeiouAEIOUnNu")


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
def fecha_aleatoria(inicio: date, fin: date) -> date:
    return inicio + timedelta(days=random.randint(0, (fin - inicio).days))


def sumar_meses(f: date, meses: int) -> date:
    m = f.month - 1 + meses
    anio, mes = f.year + m // 12, m % 12 + 1
    return date(anio, mes, min(f.day, 28))


def sql(v):
    """Convierte un valor de Python a literal T-SQL."""
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, datetime):
        return "'" + v.strftime("%Y-%m-%dT%H:%M:%S") + "'"
    if isinstance(v, date):
        return "'" + v.strftime("%Y-%m-%d") + "'"
    if isinstance(v, str):
        return "N'" + v.replace("'", "''") + "'"
    raise TypeError(v)


class Decimal1(float):
    """Número con un decimal (para calificaciones)."""


def literal(v):
    if isinstance(v, Decimal1):
        return f"{v:.1f}"
    return sql(v)


# ---------------------------------------------------------------------------
# 1. DISCIPLINAS (23 deportes x 3 modalidades x 3 ramas x 5 categorías = 1.035)
# ---------------------------------------------------------------------------
disciplinas = []          # dicts
for deporte, (cod, modalidades, perfil, aptos) in DEPORTES.items():
    for im, (modalidad, tipo, minutos) in enumerate(modalidades, start=1):
        for rama, rcod in RAMAS:
            for categoria, ccod in CATEGORIAS:
                disciplinas.append(dict(
                    id=len(disciplinas) + 1, codigo=f"{cod}-{im}-{rcod}-{ccod}", deporte=deporte,
                    modalidad=modalidad, rama=rama, categoria=categoria, tipo=tipo,
                    minutos=minutos, perfil=perfil, aptos=aptos))

# Disciplinas "activas": con equipos, torneos y encuentros (deportes de conjunto,
# categorías competitivas). El resto existe en el catálogo y tiene deportistas
# afiliados, pero aún no tiene competencias.
candidatas = [d for d in disciplinas
              if d["perfil"] is not None and d["tipo"] == "CONJUNTO" and d["categoria"] != "RECREATIVA"
              and (d["perfil"] != "partidas" or d["modalidad"] == "Por equipos")
              and d["modalidad"] not in ("Silla de ruedas", "Sentado")]
activas = sorted(random.sample(candidatas, 100), key=lambda d: d["id"])
ids_activas = {d["id"] for d in activas}
inactivas = [d for d in disciplinas if d["id"] not in ids_activas]

# ---------------------------------------------------------------------------
# 2. PERSONAS y 3. DEPORTISTAS
#    personas 1..8000 = deportistas; 7801..9000 = entrenadores
#    (200 personas son deportista y entrenador a la vez -> no se duplican sus datos)
# ---------------------------------------------------------------------------
N_DEPORTISTAS, N_PERSONAS = 8000, 9000
INICIO_ENTRENADORES = 7801
personas, deportistas = [], []
documentos_usados, correos_usados = set(), set()


def nueva_persona(sexo: str, edad_min: int, edad_max: int) -> dict:
    pid = len(personas) + 1
    nacimiento = fecha_aleatoria(date(FECHA_REF.year - edad_max - 1, FECHA_REF.month, 2),
                                 date(FECHA_REF.year - edad_min, FECHA_REF.month, 1))
    edad = (FECHA_REF - nacimiento).days // 365
    nombres = random.choice(NOMBRES_M if sexo == "M" else NOMBRES_F)
    if random.random() < 0.45:
        segundo = random.choice(NOMBRES_M if sexo == "M" else NOMBRES_F)
        if segundo != nombres:
            nombres += " " + segundo
    ap1, ap2 = random.choice(APELLIDOS), random.choice(APELLIDOS)
    r = random.random()
    if edad < 18:
        tipo = "TI"
    elif r < 0.03:
        tipo = "CE"
    elif r < 0.05:
        tipo = "PAS"
    else:
        tipo = "CC"
    while True:
        if tipo == "PAS":
            numero = random.choice("ABCDEFGHJKLMNPRSTUVWXYZ") + random.choice("ABCDEFGHJKLMNPRSTUVWXYZ") + str(random.randint(100000, 999999))
        elif tipo == "CE":
            numero = str(random.randint(100000, 9999999))
        else:
            numero = str(random.randint(1000000000, 1199999999))
        if (tipo, numero) not in documentos_usados:
            documentos_usados.add((tipo, numero))
            break
    base = f"{nombres.split()[0]}.{ap1}".lower().translate(SIN_ACENTO).replace(" ", "")
    correo = f"{base}{pid}@correo.example"
    correos_usados.add(correo)
    telefono = None if random.random() < 0.08 else "3" + str(random.randint(100000000, 259999999))
    fecha_registro = datetime(2024, 1, 15, 8, 0, 0) + timedelta(minutes=pid * 7)
    p = dict(id=pid, tipo_documento=tipo, numero_documento=numero, nombres=nombres, apellidos=f"{ap1} {ap2}",
             fecha_nacimiento=nacimiento, sexo=sexo, correo=correo, telefono=telefono, fecha_registro=fecha_registro)
    personas.append(p)
    return p


def sexo_para_rama(rama: str) -> str:
    if rama == "MASCULINA":
        return "M"
    if rama == "FEMENINA":
        return "F"
    return random.choice("MF")


# 7.000 deportistas en disciplinas activas (70 por disciplina) + 1.000 en las demás
asignacion_disciplina = [d for d in activas for _ in range(70)]
asignacion_disciplina += [random.choice(inactivas) for _ in range(N_DEPORTISTAS - len(asignacion_disciplina))]
for i, disc in enumerate(asignacion_disciplina, start=1):
    es_tambien_entrenador = i >= INICIO_ENTRENADORES
    if es_tambien_entrenador:
        p = nueva_persona(sexo_para_rama(disc["rama"]), 28, 50)
        estado = "RETIRADO" if random.random() < 0.7 else "ACTIVO"
    else:
        p = nueva_persona(sexo_para_rama(disc["rama"]), 16, 38)
        r = random.random()
        estado = "ACTIVO" if r < 0.76 else "LESIONADO" if r < 0.84 else "SUSPENDIDO" if r < 0.88 else "RETIRADO"
    deportistas.append(dict(id=i, id_persona=p["id"], disciplina=disc, estado=estado, fecha_ingreso=None,
                            nacimiento=p["fecha_nacimiento"]))

# ---------------------------------------------------------------------------
# 4. ENTRENADORES (1.200): personas 7801..9000
# ---------------------------------------------------------------------------
entrenadores = []
deportes_con_equipos = sorted({d["deporte"] for d in activas})
for pid in range(INICIO_ENTRENADORES, N_PERSONAS + 1):
    if pid <= N_DEPORTISTAS:
        p = personas[pid - 1]                       # persona ya registrada como deportista
    else:
        p = nueva_persona("M" if random.random() < 0.65 else "F", 25, 65)
    edad = (FECHA_REF - p["fecha_nacimiento"]).days // 365
    exp = random.randint(0, min(40, edad - 22))
    nivel = "BASICO" if exp < 3 else "INTERMEDIO" if exp < 8 else "AVANZADO" if exp < 15 else random.choice(["AVANZADO", "PROFESIONAL"])
    entrenadores.append(dict(id=len(entrenadores) + 1, id_persona=p["id"], licencia=f"LIC-{2015 + len(entrenadores) % 11}-{len(entrenadores) + 1:05d}",
                             nivel=nivel, exp=exp, estado="ACTIVO", fecha_ingreso=None,
                             deporte=random.choice(deportes_con_equipos)))

# ---------------------------------------------------------------------------
# 5. EQUIPOS: 11 por disciplina activa (1.100) + 100 en otras disciplinas (sin partidos)
# ---------------------------------------------------------------------------
equipos, nombres_por_disciplina = [], {}


def nuevo_equipo(disc: dict, estado: str = "ACTIVO") -> dict:
    usados = nombres_por_disciplina.setdefault(disc["id"], set())
    while True:
        ciudad = random.choice(CIUDADES)
        nombre = f"{random.choice(PREFIJOS_EQUIPO)} {random.choice(NUCLEOS_EQUIPO)} de {ciudad}"
        if nombre not in usados:
            usados.add(nombre)
            break
    e = dict(id=len(equipos) + 1, codigo=f"EQ-{len(equipos) + 1:05d}", nombre=nombre, disciplina=disc,
             ciudad=ciudad, fundacion=fecha_aleatoria(date(2005, 1, 1), date(2020, 6, 30)),
             estado=estado, fuerza=random.random())
    equipos.append(e)
    return e


equipos_por_disciplina = {}
for disc in activas:
    equipos_por_disciplina[disc["id"]] = [nuevo_equipo(disc) for _ in range(11)]
for _ in range(100):
    disc = random.choice([d for d in inactivas if d["tipo"] == "CONJUNTO"])
    nuevo_equipo(disc, "ACTIVO" if random.random() < 0.7 else "INACTIVO")

# ---------------------------------------------------------------------------
# 6. ENTRENADOR_EQUIPO: historial de técnicos principales + asistentes
# ---------------------------------------------------------------------------
asignaciones = []
entrenadores_por_deporte = {}
for en in entrenadores:
    entrenadores_por_deporte.setdefault(en["deporte"], []).append(en)
todos_entrenadores = entrenadores[:]


def pool_entrenadores(deporte):
    return entrenadores_por_deporte.get(deporte) or todos_entrenadores


for eq in equipos:
    pool = pool_entrenadores(eq["disciplina"]["deporte"])
    inicio = max(eq["fundacion"], date(2018, 1, 1)) + timedelta(days=random.randint(0, 200))
    anterior = None
    while inicio < FECHA_REF:
        fin = sumar_meses(inicio, random.randint(10, 40))
        abierto = fin >= FECHA_REF
        en = random.choice([x for x in pool if x is not anterior])
        asignaciones.append(dict(id=len(asignaciones) + 1, entrenador=en, equipo=eq, rol="PRINCIPAL",
                                 inicio=inicio,
                                 fin=None if abierto and eq["estado"] == "ACTIVO" else max(inicio, min(fin, FECHA_REF - timedelta(days=30)))))
        anterior = en
        if abierto:
            break
        inicio = fin + timedelta(days=random.randint(1, 45))
    for _ in range(random.choice([0, 1, 1, 2])):   # asistentes / preparadores físicos
        ini = fecha_aleatoria(max(eq["fundacion"], date(2019, 1, 1)), date(2025, 6, 30))
        fin = sumar_meses(ini, random.randint(6, 30))
        en = random.choice(pool)
        if any(a["entrenador"] is en and a["equipo"] is eq for a in asignaciones):
            continue
        asignaciones.append(dict(id=len(asignaciones) + 1, entrenador=en, equipo=eq,
                                 rol=random.choice(["ASISTENTE", "PREPARADOR_FISICO"]), inicio=ini,
                                 fin=None if fin >= FECHA_REF and eq["estado"] == "ACTIVO" else min(fin, FECHA_REF - timedelta(days=1))))

for en in entrenadores:
    propias = [a for a in asignaciones if a["entrenador"] is en]
    primera = min((a["inicio"] for a in propias), default=fecha_aleatoria(date(2019, 1, 1), date(2025, 12, 31)))
    en["fecha_ingreso"] = primera - timedelta(days=random.randint(0, 365))
    if not any(a["fin"] is None for a in propias) and random.random() < 0.5:
        en["estado"] = "INACTIVO"

# ---------------------------------------------------------------------------
# 7. INTEGRANTE_EQUIPO: trayectoria de cada deportista en equipos de su disciplina
# ---------------------------------------------------------------------------
integrantes = []
membresias_por_equipo = {}
for dep in deportistas:
    disc = dep["disciplina"]
    disponibles = equipos_por_disciplina.get(disc["id"])
    minimo_edad = date(dep["nacimiento"].year + 14, dep["nacimiento"].month, min(dep["nacimiento"].day, 28))
    if not disponibles or random.random() < 0.03:   # sin equipo (afiliado reciente o disciplina sin competencias)
        dep["fecha_ingreso"] = max(fecha_aleatoria(date(2018, 1, 1), date(2026, 10, 15)), minimo_edad)
        continue
    inicio = max(fecha_aleatoria(date(2021, 1, 1), date(2023, 12, 31)), minimo_edad)
    if inicio >= FECHA_REF:
        dep["fecha_ingreso"] = minimo_edad
        continue
    dep["fecha_ingreso"] = inicio - timedelta(days=random.randint(0, 400))
    retiro = fecha_aleatoria(date(2023, 6, 1), date(2026, 9, 30)) if dep["estado"] == "RETIRADO" else None
    anterior = None
    while inicio < FECHA_REF and (retiro is None or inicio < retiro):
        equipo = random.choice([e for e in disponibles if e is not anterior])
        fin = sumar_meses(inicio, random.randint(8, 30))
        if retiro and fin >= retiro:
            fin_real = retiro
        elif fin >= FECHA_REF:
            fin_real = None
        else:
            fin_real = fin
        r = random.random()
        funcion = "CAPITAN" if r < 0.08 else "TITULAR" if r < 0.63 else "SUPLENTE" if r < 0.93 else "RESERVA"
        m = dict(id=len(integrantes) + 1, deportista=dep, equipo=equipo, funcion=funcion,
                 camiseta=None if random.random() < 0.1 else random.randint(1, 99), inicio=inicio, fin=fin_real)
        integrantes.append(m)
        membresias_por_equipo.setdefault(equipo["id"], []).append(m)
        if fin_real is None or fin_real == retiro:
            break
        anterior = equipo
        inicio = fin + timedelta(days=random.randint(1, 60))

# ---------------------------------------------------------------------------
# 8. ESCENARIOS (1.100)
# ---------------------------------------------------------------------------
escenarios, nombres_escenario = [], set()
pesos_tipo = [t[3] for t in TIPOS_ESCENARIO]
for i in range(1, 1101):
    tipo, etiqueta, (cmin, cmax), _ = random.choices(TIPOS_ESCENARIO, weights=pesos_tipo)[0]
    while True:
        ciudad = random.choice(CIUDADES)
        nombre = f"{etiqueta} {random.choice(['Municipal', 'Barrial', 'Comunitario', 'Distrital', 'Universitario', 'Olímpico', 'Central'])} {random.choice(BARRIOS)}"
        if (nombre, ciudad) not in nombres_escenario:
            nombres_escenario.add((nombre, ciudad))
            break
    r = random.random()
    escenarios.append(dict(id=i, codigo=f"ESC-{i:04d}", nombre=nombre, tipo=tipo, ciudad=ciudad,
                           direccion=f"{random.choice(['Calle', 'Carrera', 'Avenida', 'Diagonal', 'Transversal'])} {random.randint(1, 180)} # {random.randint(1, 99)}-{random.randint(1, 99)}",
                           capacidad=random.randint(cmin, cmax) // 10 * 10,
                           estado="DISPONIBLE" if r < 0.90 else "MANTENIMIENTO" if r < 0.97 else "INACTIVO"))
escenarios_por_ciudad_tipo = {}
for esc in escenarios:
    if esc["estado"] == "DISPONIBLE":
        escenarios_por_ciudad_tipo.setdefault((esc["ciudad"], esc["tipo"]), []).append(esc)

# ---------------------------------------------------------------------------
# 9. TORNEOS (10 por disciplina activa = 1.000), 10. INSCRIPCIONES,
# 11. ENCUENTROS y 12. PARTICIPACIONES
# ---------------------------------------------------------------------------
torneos, inscripciones, encuentros, participaciones = [], [], [], []
ocupacion_escenario = set()      # (id_escenario, fecha_hora) ya usados
SEMESTRE = {1: "I", 2: "II"}


def marcador(perfil: str, modalidad: str, fuerza_l: float, fuerza_v: float):
    """Devuelve (local, visitante) coherente con el deporte."""
    p_local = 0.5 + (fuerza_l - fuerza_v) * 0.35 + 0.05     # ventaja de local y diferencia de nivel
    gana_local = random.random() < p_local
    if perfil == "goles":
        a = random.choices(range(6), weights=[28, 30, 21, 12, 6, 3])[0]
        b = random.choices(range(6), weights=[28, 30, 21, 12, 6, 3])[0]
        g, p = max(a, b), min(a, b)
        if g == p and random.random() < 0.5:
            g += 1
    elif perfil == "balonmano":
        g = random.randint(22, 38); p = g - random.randint(0, 8)
    elif perfil == "baloncesto":
        if modalidad == "3x3":
            g = random.randint(15, 21); p = random.randint(6, g - 1)
        else:
            g = random.randint(62, 108); p = g - random.randint(1, 25)
    elif perfil == "sets":
        g = 2 if modalidad == "Playa" else 3
        p = random.randint(0, g - 1)
    elif perfil == "rugby":
        if modalidad == "Touch":
            g = random.randint(3, 12); p = random.randint(0, g)
        else:
            g = random.randint(10, 48); p = max(0, g - random.randint(0, 30))
    elif perfil == "beisbol":
        g = random.randint(2, 13); p = random.randint(0, g - 1)
    elif perfil == "ultimate":
        g = 15; p = random.randint(5, 14)
    else:  # partidas (encuentro por equipos al mejor de 5)
        g = 3; p = random.randint(0, 2)
    return (g, p) if gana_local else (p, g)


def nombre_disciplina(disc: dict) -> str:
    """'Fútbol' + 'Fútbol 11' -> 'Fútbol 11'; 'Voleibol' + 'Playa' -> 'Voleibol Playa'."""
    if disc["modalidad"].startswith(disc["deporte"].split()[0]) or disc["modalidad"].startswith("Sóftbol"):
        return disc["modalidad"]
    return f"{disc['deporte']} {disc['modalidad']}"


def miembros_en(equipo_id: int, dia: date):
    return [m for m in membresias_por_equipo.get(equipo_id, [])
            if m["inicio"] <= dia and (m["fin"] is None or m["fin"] >= dia)]


def elegir_escenario(local: dict, aptos, dia: date):
    """Escenario disponible y apto, preferiblemente en la ciudad del equipo local,
    sin otro encuentro el mismo día a la misma hora (uq_encuentro_escenario_fecha)."""
    tipos = aptos or DEPORTES_EXTERIOR
    opciones = [e for t in tipos for e in escenarios_por_ciudad_tipo.get((local["ciudad"], t), [])]
    if not opciones:
        opciones = [e for (c, t), lst in escenarios_por_ciudad_tipo.items() if t in tipos for e in lst]
    random.shuffle(opciones)
    horas = [8, 10, 12, 14, 16, 18, 20]
    random.shuffle(horas)
    for hora in horas:
        momento = datetime(dia.year, dia.month, dia.day, hora)
        for esc in opciones[:8]:
            if (esc["id"], momento) not in ocupacion_escenario:
                ocupacion_escenario.add((esc["id"], momento))
                return esc, momento
    raise RuntimeError("sin escenario libre")


for disc in activas:
    eqs = equipos_por_disciplina[disc["id"]]
    # Un torneo por semestre: 2022-II, 2023-I, ..., 2027-I (10 torneos por disciplina)
    for n in range(10):
        anio, sem = 2022 + (n + 1) // 2, 2 if n % 2 == 0 else 1
        inicio = fecha_aleatoria(date(anio, 2, 1), date(anio, 3, 15)) if sem == 1 else fecha_aleatoria(date(anio, 8, 1), date(anio, 9, 15))
        duracion = random.randint(45, 110)
        fin = inicio + timedelta(days=duracion)
        if fin < FECHA_REF:
            estado = "CANCELADO" if random.random() < 0.03 else "FINALIZADO"
        elif inicio <= FECHA_REF:
            estado = "EN_CURSO"
        else:
            estado = "PROGRAMADO"
        rama_txt = {"MASCULINA": "Masculino", "FEMENINA": "Femenino", "MIXTA": "Mixto"}[disc["rama"]]
        t = dict(id=len(torneos) + 1, codigo=f"TOR-{len(torneos) + 1:04d}",
                 nombre=f"{random.choice(TIPOS_TORNEO)} {nombre_disciplina(disc)} {rama_txt} {disc['categoria'].capitalize()} {anio}-{SEMESTRE[sem]}",
                 disciplina=disc, inicio=inicio, fin=fin, estado=estado)
        torneos.append(t)

        # --- Inscripciones ---------------------------------------------------
        k = random.randint(4, 7)
        elegidos = random.sample(eqs, k + random.choice([0, 0, 1, 2]))
        aprobados = []
        for idx, eq in enumerate(elegidos):
            if t["estado"] == "PROGRAMADO":
                est = "APROBADA" if random.random() < 0.6 else "PENDIENTE"
            elif idx < k:
                est = "APROBADA"
            else:
                est = random.choice(["RECHAZADA", "RETIRADA"])
            f_ins = inicio - timedelta(days=random.randint(5, 45))
            if f_ins > FECHA_REF:                      # torneo futuro: inscripción ya recibida
                f_ins = FECHA_REF - timedelta(days=random.randint(0, 30))
            inscripciones.append(dict(id=len(inscripciones) + 1, torneo=t, equipo=eq, fecha=f_ins, estado=est))
            if est == "APROBADA":
                aprobados.append(eq)

        # --- Encuentros: todos contra todos a una vuelta ---------------------
        if t["estado"] != "CANCELADO" and len(aprobados) >= 2:
            lista = aprobados[:] + ([None] if len(aprobados) % 2 else [])
            n_jornadas = len(lista) - 1
            for j in range(n_jornadas):
                dia_jornada = inicio + timedelta(days=round(j * duracion / max(1, n_jornadas)))
                for a in range(len(lista) // 2):
                    l, v = lista[a], lista[-1 - a]
                    if l is None or v is None:
                        continue
                    if j % 2 == 1:
                        l, v = v, l
                    dia = min(dia_jornada + timedelta(days=random.randint(0, 2)), fin)
                    esc, momento = elegir_escenario(l, disc["aptos"], dia)
                    pl = pv = None
                    definitivo = False
                    if momento.date() < FECHA_REF:
                        r = random.random()
                        if r < 0.025:
                            est = "CANCELADO"
                        elif r < 0.05:
                            est = "SUSPENDIDO"
                            gl, gv = marcador(disc["perfil"], disc["modalidad"], l["fuerza"], v["fuerza"])
                            pl, pv = gl // 2, gv // 2
                        else:
                            est = "FINALIZADO"
                            pl, pv = marcador(disc["perfil"], disc["modalidad"], l["fuerza"], v["fuerza"])
                            definitivo = random.random() < 0.97   # algunos quedan pendientes de homologación
                    else:
                        est = "PROGRAMADO"
                    enc = dict(id=len(encuentros) + 1, torneo=t, escenario=esc, local=l, visitante=v,
                               momento=momento, jornada=j + 1, estado=est, pl=pl, pv=pv, definitivo=definitivo)
                    encuentros.append(enc)

                    # --- Participaciones de los deportistas -----------------
                    if est in ("FINALIZADO", "SUSPENDIDO"):
                        for eq, propio, rival in ((l, pl, pv), (v, pv, pl)):
                            plantilla = miembros_en(eq["id"], momento.date())
                            random.shuffle(plantilla)
                            n_titulares = max(1, round(len(plantilla) * 0.65))
                            for pos, m in enumerate(plantilla):
                                titular = pos < n_titulares
                                if disc["minutos"]:
                                    total = disc["minutos"] if est == "FINALIZADO" else disc["minutos"] // 2
                                    minutos = random.randint(total * 2 // 3, total) if titular else random.randint(1, max(1, total // 2))
                                else:
                                    minutos = None
                                base = 6.4 + (0.7 if propio > rival else -0.5 if propio < rival else 0) + (0.3 if titular else -0.4)
                                calif = None if random.random() < 0.04 else Decimal1(round(min(10, max(2, random.gauss(base, 0.9))), 1))
                                participaciones.append(dict(id=len(participaciones) + 1, encuentro=enc, deportista=m["deportista"],
                                                            equipo=eq, titular=titular, minutos=minutos, calificacion=calif))


# ---------------------------------------------------------------------------
# Escritura del script SQL
# ---------------------------------------------------------------------------
def bloque_insert(tabla: str, columnas: list, filas: list, out: list):
    out.append(f"\n-- {tabla}: {len(filas)} registros")
    out.append(f"SET IDENTITY_INSERT dbo.{tabla} ON;")
    for i in range(0, len(filas), 1000):
        out.append(f"INSERT INTO dbo.{tabla} ({', '.join(columnas)}) VALUES")
        lote = filas[i:i + 1000]
        out.append(",\n".join("(" + ", ".join(literal(v) for v in fila) + ")" for fila in lote) + ";")
        if (i // 1000) % 10 == 9:
            out.append("GO")
    out.append(f"SET IDENTITY_INSERT dbo.{tabla} OFF;")
    out.append("GO")


out = [f"""/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Script 03: datos semilla sintéticos
   ---------------------------------------------------------------------
   ARCHIVO GENERADO AUTOMÁTICAMENTE por scripts/generador/generar_datos_semilla.py
   (semilla aleatoria fija = {SEMILLA}, fecha de referencia = {FECHA_REF}).
   No editar a mano: modificar el generador y volver a ejecutarlo.

   - Todos los datos son ficticios (correos con dominio reservado .example).
   - Se insertan los identificadores explícitos (IDENTITY_INSERT) para que
     las claves foráneas sean reproducibles en cualquier servidor.
   - El orden de carga respeta las dependencias de las FK y los triggers:
     disciplina, persona, deportista, entrenador, equipo, entrenador_equipo,
     integrante_equipo, escenario, torneo, inscripcion, encuentro,
     participacion_encuentro.
   Requisito: tablas vacías (ejecutar después de 01 y 02).
   ===================================================================== */
USE GestionDeportiva;
GO
SET NOCOUNT ON;
GO
IF EXISTS (SELECT 1 FROM dbo.disciplina)
BEGIN
    RAISERROR(N'Ya existen datos. Ejecute 00_reinicio_entorno.sql, 01 y 02 antes de cargar la semilla.', 16, 1);
    SET NOEXEC ON;
END
GO"""]

bloque_insert("disciplina", ["id_disciplina", "codigo", "deporte", "modalidad", "rama", "categoria", "tipo_participacion"],
              [(d["id"], d["codigo"], d["deporte"], d["modalidad"], d["rama"], d["categoria"], d["tipo"]) for d in disciplinas], out)
bloque_insert("persona", ["id_persona", "tipo_documento", "numero_documento", "nombres", "apellidos", "fecha_nacimiento", "sexo", "correo", "telefono", "fecha_registro"],
              [(p["id"], p["tipo_documento"], p["numero_documento"], p["nombres"], p["apellidos"], p["fecha_nacimiento"], p["sexo"], p["correo"], p["telefono"], p["fecha_registro"]) for p in personas], out)
bloque_insert("deportista", ["id_deportista", "id_persona", "id_disciplina", "estado", "fecha_ingreso"],
              [(d["id"], d["id_persona"], d["disciplina"]["id"], d["estado"], d["fecha_ingreso"]) for d in deportistas], out)
bloque_insert("entrenador", ["id_entrenador", "id_persona", "numero_licencia", "nivel_licencia", "anios_experiencia", "estado", "fecha_ingreso"],
              [(e["id"], e["id_persona"], e["licencia"], e["nivel"], e["exp"], e["estado"], e["fecha_ingreso"]) for e in entrenadores], out)
bloque_insert("equipo", ["id_equipo", "codigo", "nombre", "id_disciplina", "ciudad", "fecha_fundacion", "estado"],
              [(e["id"], e["codigo"], e["nombre"], e["disciplina"]["id"], e["ciudad"], e["fundacion"], e["estado"]) for e in equipos], out)
bloque_insert("entrenador_equipo", ["id_asignacion", "id_entrenador", "id_equipo", "rol", "fecha_inicio", "fecha_fin"],
              [(a["id"], a["entrenador"]["id"], a["equipo"]["id"], a["rol"], a["inicio"], a["fin"]) for a in asignaciones], out)
bloque_insert("integrante_equipo", ["id_integrante", "id_deportista", "id_equipo", "funcion", "numero_camiseta", "fecha_inicio", "fecha_fin"],
              [(m["id"], m["deportista"]["id"], m["equipo"]["id"], m["funcion"], m["camiseta"], m["inicio"], m["fin"]) for m in integrantes], out)
bloque_insert("escenario", ["id_escenario", "codigo", "nombre", "tipo", "ciudad", "direccion", "capacidad", "estado"],
              [(e["id"], e["codigo"], e["nombre"], e["tipo"], e["ciudad"], e["direccion"], e["capacidad"], e["estado"]) for e in escenarios], out)
bloque_insert("torneo", ["id_torneo", "codigo", "nombre", "id_disciplina", "fecha_inicio", "fecha_fin", "estado"],
              [(t["id"], t["codigo"], t["nombre"], t["disciplina"]["id"], t["inicio"], t["fin"], t["estado"]) for t in torneos], out)
bloque_insert("inscripcion", ["id_inscripcion", "id_torneo", "id_equipo", "fecha_inscripcion", "estado"],
              [(i["id"], i["torneo"]["id"], i["equipo"]["id"], i["fecha"], i["estado"]) for i in inscripciones], out)
bloque_insert("encuentro", ["id_encuentro", "id_torneo", "id_escenario", "id_equipo_local", "id_equipo_visitante", "fecha_hora", "jornada", "estado", "puntaje_local", "puntaje_visitante", "resultado_definitivo"],
              [(e["id"], e["torneo"]["id"], e["escenario"]["id"], e["local"]["id"], e["visitante"]["id"], e["momento"], e["jornada"], e["estado"], e["pl"], e["pv"], e["definitivo"]) for e in encuentros], out)
bloque_insert("participacion_encuentro", ["id_participacion", "id_encuentro", "id_deportista", "id_equipo", "es_titular", "minutos_jugados", "calificacion"],
              [(p["id"], p["encuentro"]["id"], p["deportista"]["id"], p["equipo"]["id"], p["titular"], p["minutos"], p["calificacion"]) for p in participaciones], out)

out.append("""
SET NOEXEC OFF;
GO
-- Verificación de la carga: registros por tabla
SELECT 'disciplina' AS tabla, COUNT(*) AS registros FROM dbo.disciplina
UNION ALL SELECT 'persona', COUNT(*) FROM dbo.persona
UNION ALL SELECT 'deportista', COUNT(*) FROM dbo.deportista
UNION ALL SELECT 'entrenador', COUNT(*) FROM dbo.entrenador
UNION ALL SELECT 'equipo', COUNT(*) FROM dbo.equipo
UNION ALL SELECT 'entrenador_equipo', COUNT(*) FROM dbo.entrenador_equipo
UNION ALL SELECT 'integrante_equipo', COUNT(*) FROM dbo.integrante_equipo
UNION ALL SELECT 'escenario', COUNT(*) FROM dbo.escenario
UNION ALL SELECT 'torneo', COUNT(*) FROM dbo.torneo
UNION ALL SELECT 'inscripcion', COUNT(*) FROM dbo.inscripcion
UNION ALL SELECT 'encuentro', COUNT(*) FROM dbo.encuentro
UNION ALL SELECT 'participacion_encuentro', COUNT(*) FROM dbo.participacion_encuentro;
GO
PRINT N'Script 03 finalizado: datos semilla cargados.';
GO
""")

SALIDA.write_text("﻿" + "\n".join(out), encoding="utf-8")   # BOM UTF-8: SSMS reconoce tildes y eñes
print(f"Generado {SALIDA.relative_to(RAIZ)}")
for nombre, lista in [("disciplina", disciplinas), ("persona", personas), ("deportista", deportistas),
                      ("entrenador", entrenadores), ("equipo", equipos), ("entrenador_equipo", asignaciones),
                      ("integrante_equipo", integrantes), ("escenario", escenarios), ("torneo", torneos),
                      ("inscripcion", inscripciones), ("encuentro", encuentros),
                      ("participacion_encuentro", participaciones)]:
    print(f"  {nombre:<25}{len(lista):>8}")
