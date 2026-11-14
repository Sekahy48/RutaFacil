#!/usr/bin/env python3
"""Contraste WCAG 2.2 de los colores de RutaFácil.

Lee los hex de lib/ui/tema.dart (líneas `const kNormal… = Color(0xFF……);` y
`const kAlto… = Color(0xFF……);`), calcula la razón de contraste de los pares
de uso de la app y escribe docs/contrastes_app.csv con las columnas
id,uso,primer_plano,fondo,ratio,minimo,resultado.

Además avisa si algún hex de tema.dart no coincide con los valores de la
especificación de la semana 4.

Sin dependencias: python docs/scripts/contrastes.py  (desde la raíz del repo
o desde cualquier sitio; las rutas se resuelven respecto al script).
"""

import csv
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
TEMA = RAIZ / "lib" / "ui" / "tema.dart"
SALIDA = RAIZ / "docs" / "contrastes_app.csv"

# Valores de la especificación (Prompt_Code_S4.md, sección 2).
ESPERADOS = {
    "kNormalFondo": "F1F1EE",
    "kNormalSuperficie": "F8F8F6",
    "kNormalTexto": "1B1F23",
    "kNormalTextoSecundario": "444B52",
    "kNormalAcento": "2C5F6F",
    "kNormalSobreAcento": "F8F8F6",
    "kNormalBorde": "6A7178",
    "kNormalFoco": "1A4FB5",
    "kNormalError": "A12626",
    "kNormalExito": "1F6B36",
    "kNormalAvisoFondo": "FFF1CC",
    "kNormalAvisoBorde": "8A5A00",
    "kNormalPestanaInactiva": "E9E9E4",
    "kNormalMapa": "E8E8E4",
    "kAltoFondo": "121214",
    "kAltoTexto": "F2F2F2",
    "kAltoTextoSecundario": "D4D4D4",
    "kAltoAcento": "E8D27F",
    "kAltoSobreAcento": "121214",
    "kAltoBorde": "E8D27F",
    "kAltoFoco": "E8D27F",
    "kAltoError": "FF9E9E",
    "kAltoExito": "8DF0A0",
}

# (id, uso, constante primer plano, constante fondo, mínimo)
PARES = [
    ("N01", "Texto / fondo", "kNormalTexto", "kNormalFondo", 4.5),
    ("N02", "Texto / superficie", "kNormalTexto", "kNormalSuperficie", 4.5),
    ("N03", "Texto secundario / fondo", "kNormalTextoSecundario", "kNormalFondo", 4.5),
    ("N04", "Texto secundario / superficie", "kNormalTextoSecundario", "kNormalSuperficie", 4.5),
    ("N05", "Superficie (texto sobre acento) / acento", "kNormalSobreAcento", "kNormalAcento", 4.5),
    ("N06", "Acento (texto de botón secundario) / superficie", "kNormalAcento", "kNormalSuperficie", 4.5),
    ("N07", "Error / superficie", "kNormalError", "kNormalSuperficie", 4.5),
    ("N08", "Éxito / superficie", "kNormalExito", "kNormalSuperficie", 4.5),
    ("N09", "Texto / aviso fondo", "kNormalTexto", "kNormalAvisoFondo", 4.5),
    ("N10", "Superficie / acento (pestaña activa)", "kNormalSobreAcento", "kNormalAcento", 4.5),
    ("N11", "Texto secundario / pestaña inactiva", "kNormalTextoSecundario", "kNormalPestanaInactiva", 4.5),
    ("N12", "Borde / fondo", "kNormalBorde", "kNormalFondo", 3.0),
    ("N13", "Borde / superficie", "kNormalBorde", "kNormalSuperficie", 3.0),
    ("N14", "Foco / fondo", "kNormalFoco", "kNormalFondo", 3.0),
    ("N15", "Borde aviso / fondo aviso", "kNormalAvisoBorde", "kNormalAvisoFondo", 3.0),
    ("N16", "Acento (opción elegida) / superficie", "kNormalAcento", "kNormalSuperficie", 3.0),
    ("A01", "AC · Texto / fondo", "kAltoTexto", "kAltoFondo", 4.5),
    ("A02", "AC · Texto secundario / fondo", "kAltoTextoSecundario", "kAltoFondo", 4.5),
    ("A03", "AC · Acento (botones, bordes, foco, texto de botón) / fondo", "kAltoAcento", "kAltoFondo", 4.5),
    ("A04", "AC · Texto sobre acento / acento", "kAltoSobreAcento", "kAltoAcento", 4.5),
    ("A05", "AC · Error / fondo", "kAltoError", "kAltoFondo", 4.5),
    ("A06", "AC · Éxito / fondo", "kAltoExito", "kAltoFondo", 4.5),
]


def leer_colores(ruta: Path) -> dict:
    patron = re.compile(r"^const\s+(k(?:Normal|Alto)\w+)\s*=\s*Color\(0x[0-9A-Fa-f]{2}([0-9A-Fa-f]{6})\);", re.M)
    return {n: h.upper() for n, h in patron.findall(ruta.read_text(encoding="utf-8"))}


def lineal(c: float) -> float:
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminancia(hexa: str) -> float:
    r, g, b = (int(hexa[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * lineal(r) + 0.7152 * lineal(g) + 0.0722 * lineal(b)


def contraste(a: str, b: str) -> float:
    la, lb = luminancia(a), luminancia(b)
    claro, oscuro = max(la, lb), min(la, lb)
    return (claro + 0.05) / (oscuro + 0.05)


def main() -> int:
    colores = leer_colores(TEMA)
    avisos = []
    for nombre, esperado in ESPERADOS.items():
        real = colores.get(nombre)
        if real is None:
            avisos.append(f"AVISO: {nombre} no está en tema.dart")
        elif real != esperado:
            avisos.append(f"AVISO: {nombre} = #{real}, la especificación dice #{esperado}")

    filas, fallos = [], []
    for id_, uso, pp, fondo, minimo in PARES:
        a, b = colores[pp], colores[fondo]
        r = contraste(a, b)
        # WCAG no redondea: 4,499 es FAIL. El CSV muestra 2 decimales.
        resultado = "PASS" if r >= minimo else "FAIL"
        if resultado == "FAIL":
            fallos.append(f"FAIL: {id_} {uso}: {r:.2f}:1 < {minimo}:1")
        filas.append([id_, uso, f"#{a}", f"#{b}", f"{r:.2f}", f"{minimo:g}", resultado])

    with SALIDA.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["id", "uso", "primer_plano", "fondo", "ratio", "minimo", "resultado"])
        w.writerows(filas)

    for fila in filas:
        print(f"{fila[0]}  {fila[4]:>6}:1  (mín. {fila[5]})  {fila[6]}  {fila[1]}")
    for m in avisos + fallos:
        print(m)
    print(f"Escrito {SALIDA.relative_to(RAIZ)}: {len(filas)} pares, "
          f"{len(fallos)} FAIL, {len(avisos)} avisos de hex.")
    return 1 if fallos or avisos else 0


if __name__ == "__main__":
    sys.exit(main())
