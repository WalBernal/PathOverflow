"""Genera voces de diálogo con Qwen3-TTS VoiceDesign (local, Apache 2.0): cada voz sale
de una descripción en texto (docs/voces.md), sin grabaciones.

Uso (desde la raíz del proyecto):
  tools/voces/.venv-qwen/Scripts/python.exe tools/voces/generar_qwen.py tools/voces/prueba_qwen.json tools/voces/salida_qwen

El JSON: {"voces": {nombre: descripción}, "lineas": [{"id", "voz", "texto", "tono"?}]}.
«tono» se añade a la descripción solo en esa línea (p. ej. "shouting in panic").
"""
import json
import re
import sys
import time
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from qwen_tts import Qwen3TTSModel

AQUI = Path(__file__).resolve().parent
MODELO = AQUI / "modelo" / "qwen-voicedesign"


def limpiar(texto: str) -> str:
    t = re.sub(r"\[/?[a-z]+\]", "", texto)
    t = t.replace("{jugador}", "")
    t = re.sub(r"\.{4,}", "...", t)
    t = re.sub(r"\?{2,}", "?", t)
    t = t.replace("«", "").replace("»", "")
    return re.sub(r"\s+", " ", t).strip()


def main() -> None:
    datos = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    salida = Path(sys.argv[2])
    salida.mkdir(parents=True, exist_ok=True)
    torch.manual_seed(7)
    modelo = Qwen3TTSModel.from_pretrained(str(MODELO), device_map="cuda:0", dtype=torch.bfloat16)
    solo = set(sys.argv[3].split(",")) if len(sys.argv) > 3 else None
    for e in datos["lineas"]:
        if solo and e["id"] not in solo:
            continue
        instr = datos["voces"][e["voz"]]
        if e.get("tono"):
            instr += " In this line: " + e["tono"] + "."
        texto = limpiar(e["texto"])
        t0 = time.time()
        # Tope de duración según el texto (12 tokens por segundo; al menos ~9 letras por
        # segundo): sin él, una frase corta que acaba en «...» puede seguir murmurando.
        tope = int(max(4.0, len(texto) / 9.0) * 12) + 24
        wavs, sr = modelo.generate_voice_design(text=texto, instruct=instr, language="Spanish", max_new_tokens=tope)
        audio = np.asarray(wavs[0], dtype=np.float32)
        sf.write(str(salida / f"{e['id']}.wav"), audio, sr, subtype="PCM_16")
        print(f"{e['id']}: {len(audio) / sr:.1f} s en {time.time() - t0:.1f} s · {e['voz']}", flush=True)
    # La muestra: todas las líneas de la carpeta seguidas, con una pausa entre cada una.
    partes = []
    for f in sorted(salida.glob("*.wav")):
        if f.name.startswith("muestra"):
            continue
        audio, sr = sf.read(str(f), dtype="float32")
        partes += [audio, np.zeros(int(sr * 0.7), dtype=np.float32)]
    sf.write(str(salida / "muestra_qwen.wav"), np.concatenate(partes), sr, subtype="PCM_16")


if __name__ == "__main__":
    main()
