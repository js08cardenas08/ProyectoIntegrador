"""
Proyecto integrador - Caso 5: Gestión deportiva
Integrantes: Juan Sebastián Cárdenas, Juan David Segura

Genera documentacion/diccionario_datos.xlsx con la misma información que
documentacion/diccionario_datos.md: metadatos reales de SQL Server
(evidencias/resultados/07_metadatos_resultado.txt) + descripciones de negocio
definidas en generar_diccionario_y_relacional.py.

Uso:  python scripts/generador/generar_diccionario_excel.py
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generar_diccionario_y_relacional as base  # noqa: E402

SALIDA = base.RAIZ / "documentacion" / "diccionario_datos.xlsx"

AZUL, CREMA, NARANJA, GRIS = "14233B", "F7F5EF", "B44F1C", "3E4A5C"
F_TIT = Font(name="Arial", size=16, bold=True, color=AZUL)
F_SUB = Font(name="Arial", size=10, color=GRIS)
F_HDR = Font(name="Arial", size=10, bold=True, color=CREMA)
F_TXT = Font(name="Arial", size=10, color="1A1A1A")
F_B = Font(name="Arial", size=10, bold=True, color="1A1A1A")
F_SEC = Font(name="Arial", size=11, bold=True, color=NARANJA)
F_LINK = Font(name="Arial", size=10, color="1F4E9E", underline="single")
FILL_HDR = PatternFill("solid", fgColor=AZUL)
FILL_ALT = PatternFill("solid", fgColor="F2EFE8")
LINEA = Side(style="thin", color="C9C2B2")
BORDE = Border(left=LINEA, right=LINEA, top=LINEA, bottom=LINEA)
ARRIBA = Alignment(vertical="top", wrap_text=True)


def encabezado(ws, fila, textos):
    for i, t in enumerate(textos, start=1):
        c = ws.cell(row=fila, column=i, value=t)
        c.font, c.fill, c.border = F_HDR, FILL_HDR, BORDE
        c.alignment = Alignment(vertical="center", wrap_text=True)
    ws.row_dimensions[fila].height = 22


def fila_datos(ws, fila, valores, alterna, negrita_primera=True):
    for i, v in enumerate(valores, start=1):
        c = ws.cell(row=fila, column=i, value=v)
        c.font = F_B if (i == 1 and negrita_primera) else F_TXT
        c.border, c.alignment = BORDE, ARRIBA
        if alterna:
            c.fill = FILL_ALT


def anchos(ws, valores):
    for i, w in enumerate(valores, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w


def main():
    columnas, restricciones, triggers = base.leer_metadatos()
    por_tabla, restr_tabla, trig_tabla = defaultdict(list), defaultdict(list), defaultdict(list)
    for c in columnas:
        por_tabla[c["tabla"]].append(c)
    for r in restricciones:
        restr_tabla[r["tabla"]].append(r)
    for t in triggers:
        trig_tabla[t["tabla"]].append(t["trigger_nombre"])

    wb = Workbook()

    # ---------------- Hoja Resumen ----------------
    ws = wb.active
    ws.title = "Resumen"
    ws["A1"] = "Diccionario de datos — Caso 5: Gestión deportiva"
    ws["A1"].font = F_TIT
    ws["A2"] = "Juan Sebastián Cárdenas · Juan David Segura · Base de datos GestionDeportiva (Microsoft SQL Server)"
    ws["A2"].font = F_SUB
    ws["A3"] = ("Generado desde el catálogo real de SQL Server (script 07_metadatos_diccionario.sql), "
                "por lo que tipos, nulabilidad, DEFAULT y restricciones coinciden con la implementación.")
    ws["A3"].font = F_SUB
    encabezado(ws, 5, ["#", "Tabla", "Descripción", "Columnas", "Ir a la hoja"])
    fila = 6
    for i, tabla in enumerate(base.ORDEN_TABLAS, start=1):
        n = len(por_tabla[tabla])
        primera, ultima = 6, 5 + n   # filas de columnas en la hoja de la tabla
        fila_datos(ws, fila, [i, tabla, base.TABLAS[tabla],
                              f"=COUNTA('{tabla}'!A{primera}:A{ultima})", "Ver detalle"], i % 2 == 0, False)
        ws.cell(row=fila, column=2).font = F_B
        link = ws.cell(row=fila, column=5)
        link.hyperlink, link.font = f"#'{tabla}'!A1", F_LINK
        fila += 1
    fila_datos(ws, fila, ["", "Total", "", f"=SUM(D6:D{fila - 1})", ""], False, False)
    ws.cell(row=fila, column=2).font = F_B
    ws.cell(row=fila, column=4).font = F_B
    fila += 2
    for txt in ["Convenciones: pk_ clave primaria · fk_ clave foránea · uq_ único · ck_ verificación · "
                "df_ valor por defecto · tr_ trigger.",
                "Todas las PK son INT IDENTITY(1,1). NVARCHAR en nombres con tildes y ñ; VARCHAR en códigos y estados.",
                "Hojas adicionales: «Relaciones» (claves foráneas) y «Restricciones» (UNIQUE, CHECK y triggers)."]:
        ws.cell(row=fila, column=1, value=txt).font = F_SUB
        fila += 1
    anchos(ws, [5, 26, 90, 11, 14])
    ws.freeze_panes = "A6"

    # ---------------- Una hoja por tabla ----------------
    for tabla in base.ORDEN_TABLAS:
        ws = wb.create_sheet(tabla)
        ws["A1"] = f"Tabla {tabla}"
        ws["A1"].font = F_TIT
        ws["A2"] = base.TABLAS[tabla]
        ws["A2"].font = F_SUB
        ws["A3"] = "« Volver al resumen"
        ws["A3"].hyperlink, ws["A3"].font = "#'Resumen'!A1", F_LINK
        encabezado(ws, 5, ["Columna", "Descripción", "Tipo", "Nulo", "Clave", "DEFAULT", "Restricciones y reglas"])
        fila = 6
        for j, c in enumerate(por_tabla[tabla]):
            clave = []
            if c["pk"] == "PK":
                clave.append("PK")
            if c["fk"]:
                clave.append("FK → " + c["fk"].replace("FK -> ", ""))
            reglas = ["IDENTITY(1,1)"] if c["identidad"] else []
            for r in restr_tabla[tabla]:
                cols_uq = [x.strip() for x in r["definicion"].split(",")]
                if r["tipo"] == "UNIQUE" and c["columna"] in cols_uq:
                    reglas.append(r["restriccion"] + ("" if len(cols_uq) == 1 else f" ({r['definicion']})"))
                if r["tipo"] == "CHECK" and re.search(r"\[" + re.escape(c["columna"]) + r"\]", r["definicion"]):
                    reglas.append(r["restriccion"])
            fila_datos(ws, fila, [c["columna"], base.COLUMNAS[tabla][c["columna"]], base.tipo_completo(c),
                                  "Sí" if c["nulabilidad"] == "NULL" else "No", " · ".join(clave) or "—",
                                  base.limpiar_default(c["valor_default"]) or "—", "\n".join(reglas) or "—"],
                       j % 2 == 1)
            fila += 1
        fila += 1
        ws.cell(row=fila, column=1, value="Restricciones de la tabla").font = F_SEC
        fila += 1
        encabezado(ws, fila, ["Nombre", "Tipo", "Definición"])
        fila += 1
        for j, r in enumerate(sorted(restr_tabla[tabla], key=lambda r: (r["tipo"], r["restriccion"]))):
            fila_datos(ws, fila, [r["restriccion"], r["tipo"], r["definicion"]], j % 2 == 1)
            ws.merge_cells(start_row=fila, start_column=3, end_row=fila, end_column=7)
            fila += 1
        for t in trig_tabla[tabla]:
            fila_datos(ws, fila, [t, "TRIGGER AFTER INSERT, UPDATE", base.TRIGGERS[t]], False)
            ws.merge_cells(start_row=fila, start_column=3, end_row=fila, end_column=7)
            ws.row_dimensions[fila].height = 30
            fila += 1
        anchos(ws, [34, 48, 15, 7, 26, 26, 40])
        ws.freeze_panes = "A6"

    # ---------------- Relaciones ----------------
    ws = wb.create_sheet("Relaciones")
    ws["A1"] = "Relaciones (claves foráneas)"
    ws["A1"].font = F_TIT
    encabezado(ws, 3, ["Tabla hija", "Columna", "Tabla padre", "Columna padre", "Cardinalidad"])
    fila, j = 4, 0
    for tabla in base.ORDEN_TABLAS:
        for c in por_tabla[tabla]:
            if c["fk"]:
                padre, colp = c["fk"].replace("FK -> ", "").split(".")
                unico = any(r["tipo"] == "UNIQUE" and r["definicion"] == c["columna"] for r in restr_tabla[tabla])
                fila_datos(ws, fila, [tabla, c["columna"], padre, colp, "1:1 (UNIQUE)" if unico else "N:1"], j % 2 == 1)
                fila, j = fila + 1, j + 1
    anchos(ws, [26, 22, 18, 18, 16])
    ws.auto_filter.ref = f"A3:E{fila - 1}"
    ws.freeze_panes = "A4"

    # ---------------- Restricciones ----------------
    ws = wb.create_sheet("Restricciones")
    ws["A1"] = "Restricciones UNIQUE, CHECK y triggers"
    ws["A1"].font = F_TIT
    encabezado(ws, 3, ["Tabla", "Nombre", "Tipo", "Definición o regla"])
    fila, j = 4, 0
    for tabla in base.ORDEN_TABLAS:
        for r in sorted(restr_tabla[tabla], key=lambda r: (r["tipo"], r["restriccion"])):
            fila_datos(ws, fila, [tabla, r["restriccion"], r["tipo"], r["definicion"]], j % 2 == 1)
            fila, j = fila + 1, j + 1
        for t in trig_tabla[tabla]:
            fila_datos(ws, fila, [tabla, t, "TRIGGER", base.TRIGGERS[t]], j % 2 == 1)
            fila, j = fila + 1, j + 1
    anchos(ws, [24, 38, 12, 110])
    ws.auto_filter.ref = f"A3:D{fila - 1}"
    ws.freeze_panes = "A4"

    for hoja in wb.worksheets:   # impresión: horizontal y ajustada al ancho de la página
        hoja.page_setup.orientation = "landscape"
        hoja.page_setup.fitToWidth, hoja.page_setup.fitToHeight = 1, 0
        hoja.sheet_properties.pageSetUpPr.fitToPage = True
        hoja.print_options.horizontalCentered = True
    wb.save(SALIDA)
    print("Generado", SALIDA.relative_to(base.RAIZ))


if __name__ == "__main__":
    main()
