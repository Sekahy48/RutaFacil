#!/usr/bin/env python3
"""Simulaciones APROXIMADAS de visión a partir de las capturas normales.

Lee docs/capturas_s4/normal/*.png y escribe, con el mismo nombre de archivo:
  docs/capturas_s4/grises/        luminancia relativa WCAG (en RGB lineal)
  docs/capturas_s4/protanopia/    Machado, Oliveira y Fernandes (2009), severidad 1,0
  docs/capturas_s4/deuteranopia/  Machado, Oliveira y Fernandes (2009), severidad 1,0

Las matrices se aplican en RGB lineal (se quita y se vuelve a poner la curva
sRGB). Son simulaciones aproximadas: no sustituyen a pruebas con personas.

Requiere Pillow y numpy:  pip install pillow numpy
Uso (desde cualquier carpeta):  python docs/scripts/simular.py
"""

from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
CAPTURAS = RAIZ / "docs" / "capturas_s4"
ORIGEN = CAPTURAS / "normal"

# Machado et al. 2009, tabla de severidad 1.0.
MATRICES = {
    "protanopia": np.array([
        [0.152286, 1.052583, -0.204868],
        [0.114503, 0.786281, 0.099216],
        [-0.003882, -0.048116, 1.051998],
    ]),
    "deuteranopia": np.array([
        [0.367322, 0.860646, -0.227968],
        [0.280085, 0.672501, 0.047413],
        [-0.011820, 0.042940, 0.968881],
    ]),
}

# Coeficientes de luminancia relativa de WCAG 2.x.
LUMINANCIA = np.array([0.2126, 0.7152, 0.0722])


def a_lineal(srgb: np.ndarray) -> np.ndarray:
    c = srgb / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def a_srgb(lineal: np.ndarray) -> np.ndarray:
    c = np.clip(lineal, 0.0, 1.0)
    c = np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)
    return np.round(c * 255.0).astype(np.uint8)


def simular(ruta: Path) -> None:
    rgb = np.asarray(Image.open(ruta).convert("RGB"), dtype=np.float64)
    lin = a_lineal(rgb)

    y = lin @ LUMINANCIA
    gris = a_srgb(np.repeat(y[..., None], 3, axis=2))
    guardar(gris, "grises", ruta.name)

    for nombre, m in MATRICES.items():
        guardar(a_srgb(lin @ m.T), nombre, ruta.name)


def guardar(datos: np.ndarray, carpeta: str, nombre: str) -> None:
    destino = CAPTURAS / carpeta
    destino.mkdir(parents=True, exist_ok=True)
    Image.fromarray(datos, "RGB").save(destino / nombre, optimize=True)


def main() -> None:
    archivos = sorted(ORIGEN.glob("*.png"))
    if not archivos:
        raise SystemExit(f"No hay capturas en {ORIGEN}")
    for ruta in archivos:
        simular(ruta)
        print(f"  {ruta.name}")
    print(f"{len(archivos)} capturas × 3 simulaciones en {CAPTURAS.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
