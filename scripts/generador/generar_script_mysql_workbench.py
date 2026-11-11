"""
Proyecto integrador - Caso 5: Gestión deportiva
Integrantes: Juan Sebastián Cárdenas, Juan David Segura

Genera diagramas/workbench/gestion_deportiva_mysql.sql: la MISMA estructura de la
base de SQL Server (12 tablas, PK, FK, UNIQUE, DEFAULT y descripciones) escrita en
dialecto MySQL, solo para dibujar el diagrama en MySQL Workbench
(File > Import > Reverse Engineer MySQL Create Script).

La implementación oficial del proyecto sigue siendo SQL Server. Este script no lleva
datos, CHECK ni triggers porque el diagrama no los muestra.

Uso:  python scripts/generador/generar_script_mysql_workbench.py
"""
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generar_diccionario_y_relacional as base  # noqa: E402

SALIDA = base.RAIZ / "diagramas" / "workbench" / "gestion_deportiva_mysql.sql"


def tipo_mysql(c):
    t, l = c["tipo"], c["longitud"]
    if t in ("varchar", "nvarchar"):
        return f"VARCHAR({l})"
    if t == "char":
        return f"CHAR({l})"
    if t == "decimal":
        return f"DECIMAL({l})"
    if t == "datetime2":
        return "DATETIME"
    if t == "bit":
        return "TINYINT(1)"
    return t.upper()   # INT, SMALLINT, TINYINT, DATE


def default_mysql(c):
    d = base.limpiar_default(c["valor_default"])
    if not d:
        return ""
    if d == "SYSDATETIME()":
        return " DEFAULT CURRENT_TIMESTAMP"
    if "GETDATE" in d:
        return ""          # fecha de hoy: lo asigna SQL Server; en MySQL 8 sería DEFAULT (CURRENT_DATE)
    return f" DEFAULT {d}"


def comentario(texto):
    return texto.replace("'", "''")


def main():
    columnas, restricciones, _ = base.leer_metadatos()
    por_tabla, restr = defaultdict(list), defaultdict(list)
    for c in columnas:
        por_tabla[c["tabla"]].append(c)
    for r in restricciones:
        restr[r["tabla"]].append(r)

    sal = ["-- =====================================================================",
           "-- Proyecto integrador - Caso 5: Gestión deportiva",
           "-- Integrantes: Juan Sebastián Cárdenas, Juan David Segura",
           "-- Estructura de la base GestionDeportiva en dialecto MySQL para dibujar",
           "-- el diagrama en MySQL Workbench. La implementación oficial está en",
           "-- SQL Server (scripts/sqlserver). Generado por",
           "-- scripts/generador/generar_script_mysql_workbench.py",
           "-- =====================================================================",
           "",
           "CREATE SCHEMA IF NOT EXISTS gestion_deportiva DEFAULT CHARACTER SET utf8mb4;",
           "USE gestion_deportiva;",
           ""]
    for tabla in base.ORDEN_TABLAS:
        lineas = []
        for c in por_tabla[tabla]:
            nulo = " NULL" if c["nulabilidad"] == "NULL" else " NOT NULL"
            auto = " AUTO_INCREMENT" if c["identidad"] else ""
            lineas.append(f"  {c['columna']} {tipo_mysql(c)}{nulo}{auto}{default_mysql(c)} "
                          f"COMMENT '{comentario(base.COLUMNAS[tabla][c['columna']])}'")
        pk = [c["columna"] for c in por_tabla[tabla] if c["pk"] == "PK"]
        lineas.append(f"  CONSTRAINT pk_{tabla} PRIMARY KEY ({', '.join(pk)})")
        for r in sorted(restr[tabla], key=lambda r: r["restriccion"]):
            if r["tipo"] == "UNIQUE":
                lineas.append(f"  CONSTRAINT {r['restriccion']} UNIQUE ({r['definicion']})")
        for c in por_tabla[tabla]:
            if c["fk"]:
                padre, colp = c["fk"].replace("FK -> ", "").split(".")
                nombre = {"id_equipo_local": "fk_encuentro_equipo_local",
                          "id_equipo_visitante": "fk_encuentro_equipo_visitante"}.get(c["columna"], f"fk_{tabla}_{padre}")
                if tabla == "participacion_encuentro":
                    nombre = f"fk_participacion_{padre}"
                lineas.append(f"  CONSTRAINT {nombre} FOREIGN KEY ({c['columna']}) REFERENCES {padre} ({colp})")
        sal.append(f"CREATE TABLE {tabla} (")
        sal.append(",\n".join(lineas))
        sal.append(f") ENGINE=InnoDB COMMENT='{comentario(base.TABLAS[tabla])}';")
        sal.append("")
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    SALIDA.write_text("\n".join(sal), encoding="utf-8")
    print("Generado", SALIDA.relative_to(base.RAIZ))


if __name__ == "__main__":
    main()
