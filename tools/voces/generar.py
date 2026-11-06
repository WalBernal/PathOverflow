"""Genera voces de diálogo con Kokoro (local, Apache 2.0) a partir de una lista JSON.

Uso (desde la raíz del proyecto):
  tools/voces/.venv/Scripts/python.exe tools/voces/generar.py tools/voces/prueba_prologo.json tools/voces/salida

Cada entrada: {"id": "rafa_01", "voz": "em_alex", "velocidad": 0.9, "texto": "..."}.
«voz» puede ser una mezcla: "em_alex:0.7+em_santa:0.3".
Voces en español del modelo: ef_dora (mujer), em_alex y em_santa (hombres).
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

AQUI = Path(__file__).resolve().parent
MODELO = AQUI / "modelo" / "kokoro-v1.0.int8.onnx"
VOCES = AQUI / "modelo" / "voices-v1.0.bin"


def limpiar(texto: str) -> str:
    """Del texto del juego a algo que se lea bien en voz alta."""
    t = re.sub(r"\[/?[a-z]+\]", "", texto)            # etiquetas BBCode
    t = t.replace("{jugador}", "")
    t = re.sub(r"\.{4,}", "...", t)                   # «.....» de Rafa → pausa
    t = re.sub(r"\?{2,}", "?", t)
    t = t.replace("«", "").replace("»", "")
    t = re.sub(r"\s+", " ", t).strip()
    return t


def voz(kokoro: Kokoro, nombre: str):
    if "+" not in nombre and ":" not in nombre:
        return nombre
    mezcla = None
    for parte in nombre.split("+"):
        n, _, peso = parte.partition(":")
        v = kokoro.get_voice_style(n.strip()) * float(peso or 1.0)
        mezcla = v if mezcla is None else mezcla + v
    return mezcla


def main() -> None:
    lista = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    salida = Path(sys.argv[2])
    salida.mkdir(parents=True, exist_ok=True)
    kokoro = Kokoro(str(MODELO), str(VOCES))
    for e in lista:
        texto = limpiar(e["texto"])
        muestras, rate = kokoro.create(texto, voice=voz(kokoro, e["voz"]), speed=float(e.get("velocidad", 1.0)), lang="es")
        muestras = np.concatenate([np.zeros(int(rate * 0.08), dtype=muestras.dtype), muestras])
        destino = salida / f"{e['id']}.ogg"
        sf.write(str(destino), muestras, rate, format="OGG", subtype="VORBIS")
        print(f"{e['id']}: {len(muestras) / rate:.1f} s · {e['voz']} · {texto[:60]}")


if __name__ == "__main__":
    main()
