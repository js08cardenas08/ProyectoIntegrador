"""
Proyecto integrador - Caso 5: Gestión deportiva
Integrantes: Juan Sebastián Cárdenas, Juan David Segura

Genera documentacion/diccionario_datos.xlsx: una sola hoja con una fila por
columna de la base. Toma los metadatos reales de SQL Server
(evidencias/resultados/07_metadatos_resultado.txt) y las descripciones de
generar_diccionario.py.

Uso:  python scripts/generador/generar_diccionario_excel.py
"""
import sys
from collections import defaultdict
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generar_diccionario as base  # noqa: E402

SALIDA = base.RAIZ / "documentacion" / "diccionario_datos.xlsx"

# Regla de cada CHECK explicada en palabras sencillas: (tabla, columna) -> texto
REGLAS = {
    ("disciplina", "rama"): "MASCULINA, FEMENINA o MIXTA",
    ("disciplina", "categoria"): "RECREATIVA, AFICIONADA, INTERMEDIA, AVANZADA o ELITE",
    ("disciplina", "tipo_participacion"): "CONJUNTO o INDIVIDUAL",
    ("persona", "tipo_documento"): "CC, TI, CE o PAS",
    ("persona", "numero_documento"): "Solo números o letras mayúsculas, mínimo 5",
    ("persona", "fecha_nacimiento"): "Entre 1940 y hoy",
    ("persona", "sexo"): "F o M",
    ("persona", "correo"): "Formato texto@dominio.ext",
    ("deportista", "estado"): "ACTIVO, LESIONADO, SUSPENDIDO o RETIRADO",
    ("entrenador", "nivel_licencia"): "BASICO, INTERMEDIO, AVANZADO o PROFESIONAL",
    ("entrenador", "anios_experiencia"): "Entre 0 y 60",
    ("entrenador", "estado"): "ACTIVO o INACTIVO",
    ("equipo", "estado"): "ACTIVO o INACTIVO",
    ("entrenador_equipo", "rol"): "PRINCIPAL, ASISTENTE o PREPARADOR_FISICO",
    ("entrenador_equipo", "fecha_fin"): "Vacía o mayor o igual a fecha_inicio",
    ("integrante_equipo", "funcion"): "CAPITAN, TITULAR, SUPLENTE o RESERVA",
    ("integrante_equipo", "numero_camiseta"): "Entre 0 y 99",
    ("integrante_equipo", "fecha_fin"): "Vacía o mayor o igual a fecha_inicio",
    ("escenario", "tipo"): "ESTADIO, COLISEO, CANCHA, PISCINA, PISTA, VELODROMO o GIMNASIO",
    ("escenario", "capacidad"): "Mayor que 0",
    ("escenario", "estado"): "DISPONIBLE, MANTENIMIENTO o INACTIVO",
    ("torneo", "fecha_fin"): "Mayor o igual a fecha_inicio",
    ("torneo", "estado"): "PROGRAMADO, EN_CURSO, FINALIZADO o CANCELADO",
    ("inscripcion", "estado"): "PENDIENTE, APROBADA, RECHAZADA o RETIRADA",
    ("encuentro", "id_equipo_visitante"): "Distinto del equipo local",
    ("encuentro", "jornada"): "Mayor que 0",
    ("encuentro", "estado"): "PROGRAMADO, EN_JUEGO, FINALIZADO, SUSPENDIDO o CANCELADO",
    ("encuentro", "puntaje_local"): "0 o más; vacío si el encuentro no se ha jugado",
    ("encuentro", "puntaje_visitante"): "0 o más; vacío si el encuentro no se ha jugado",
    ("encuentro", "resultado_definitivo"): "Solo puede ser 1 si el encuentro está FINALIZADO",
    ("participacion_encuentro", "minutos_jugados"): "Entre 0 y 300",
    ("participacion_encuentro", "calificacion"): "Entre 0 y 10",
}

AZUL, CREMA = "14233B", "F7F5EF"
LINEA = Side(style="thin", color="C9C2B2")
BORDE = Border(left=LINEA, right=LINEA, top=LINEA, bottom=LINEA)


def main():
    columnas, restricciones, _ = base.leer_metadatos()
    unicos = defaultdict(list)                 # tabla -> [columnas de cada UNIQUE]
    for r in restricciones:
        if r["tipo"] == "UNIQUE":
            unicos[r["tabla"]].append([x.strip() for x in r["definicion"].split(",")])
    por_tabla = defaultdict(list)
    for c in columnas:
        por_tabla[c["tabla"]].append(c)

    wb = Workbook()
    ws = wb.active
    ws.title = "Diccionario"
    ws["A1"] = "Diccionario de datos — Caso 5: Gestión deportiva"
    ws["A1"].font = Font(name="Arial", size=14, bold=True, color=AZUL)
    ws["A2"] = "Juan Sebastián Cárdenas · Juan David Segura · Base GestionDeportiva (SQL Server)"
    ws["A2"].font = Font(name="Arial", size=10, color="3E4A5C")

    titulos = ["Tabla", "Columna", "Descripción", "Tipo", "Nulo", "Clave", "Valor por defecto", "Regla"]
    for i, t in enumerate(titulos, start=1):
        c = ws.cell(row=4, column=i, value=t)
        c.font = Font(name="Arial", size=10, bold=True, color=CREMA)
        c.fill = PatternFill("solid", fgColor=AZUL)
        c.border = BORDE
        c.alignment = Alignment(vertical="center")

    fila = 5
    for n, tabla in enumerate(base.ORDEN_TABLAS):
        relleno = PatternFill("solid", fgColor="F2EFE8" if n % 2 else "FFFFFF")   # alterna por tabla
        for col in por_tabla[tabla]:
            nombre = col["columna"]
            clave = "PK" if col["pk"] == "PK" else ""
            if col["fk"]:
                clave = "FK → " + col["fk"].replace("FK -> ", "").split(".")[0]
            reglas = []
            for grupo in unicos[tabla]:
                if nombre in grupo:
                    reglas.append("Único" if len(grupo) == 1
                                  else "Único junto con " + ", ".join(g for g in grupo if g != nombre))
            if (tabla, nombre) in REGLAS:
                reglas.append(REGLAS[(tabla, nombre)])
            defecto = (base.limpiar_default(col["valor_default"]).replace("'", "")
                       .replace("CAST(GETDATE() AS DATE)", "Fecha de hoy")
                       .replace("SYSDATETIME()", "Fecha y hora actual"))
            valores = [tabla, nombre, base.COLUMNAS[tabla][nombre], base.tipo_completo(col),
                       "Sí" if col["nulabilidad"] == "NULL" else "No", clave, defecto, "; ".join(reglas)]
            for i, v in enumerate(valores, start=1):
                c = ws.cell(row=fila, column=i, value=v)
                c.font = Font(name="Arial", size=10, bold=(i <= 2))
                c.fill, c.border = relleno, BORDE
                c.alignment = Alignment(vertical="top", wrap_text=True)
            fila += 1

    for letra, ancho in zip("ABCDEFGH", [24, 22, 55, 14, 6, 18, 18, 40]):
        ws.column_dimensions[letra].width = ancho
    ws.freeze_panes = "C5"
    ws.auto_filter.ref = f"A4:H{fila - 1}"
    ws.page_setup.orientation = "landscape"
    ws.page_setup.fitToWidth, ws.page_setup.fitToHeight = 1, 0
    ws.sheet_properties.pageSetUpPr.fitToPage = True
    ws.print_title_rows = "4:4"
    wb.save(SALIDA)
    print("Generado", SALIDA.relative_to(base.RAIZ), "con", fila - 5, "columnas")


if __name__ == "__main__":
    main()
