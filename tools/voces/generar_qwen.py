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
MODELO_BASE = AQUI / "modelo" / "qwen-base"   # para clonar las tomas aprobadas (referencias/)


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
    solo = set(sys.argv[3].split(",")) if len(sys.argv) > 3 else None
    # Sin lista de ids, se salta lo ya generado: si se corta, basta con volver a lanzarlo.
    lineas = [e for e in datos["lineas"] if (e["id"] in solo if solo else not (salida / f"{e['id']}.wav").exists())]
    print(f"{len(lineas)} líneas por generar", flush=True)
    # Una voz es una descripción (se diseña en cada línea) o {"ref", "ref_texto", ...}: una
    # toma aprobada que se clona con el modelo Base, para que suene igual en todas sus líneas.
    disenar = [e for e in lineas if isinstance(datos["voces"][e["voz"]], str)]
    clonar = [e for e in lineas if not isinstance(datos["voces"][e["voz"]], str)]
    for grupo, carpeta in ((disenar, MODELO), (clonar, MODELO_BASE)):
        if not grupo:
            continue
        torch.manual_seed(7)
        modelo = Qwen3TTSModel.from_pretrained(str(carpeta), device_map="cuda:0", dtype=torch.bfloat16)
        for e in grupo:
            voz = datos["voces"][e["voz"]]
            texto = limpiar(e["texto"])
            t0 = time.time()
            # Tope de duración según el texto (12 tokens por segundo; al menos ~9 letras por
            # segundo): sin él, una frase corta que acaba en «...» puede seguir murmurando.
            tope = int(max(4.0, len(texto) / 9.0) * 12) + 24
            if isinstance(voz, str):
                instr = voz + (" In this line: " + e["tono"] + "." if e.get("tono") else "")
                wavs, sr = modelo.generate_voice_design(text=texto, instruct=instr, language="Spanish", max_new_tokens=tope)
            else:
                wavs, sr = modelo.generate_voice_clone(text=texto, language="Spanish", ref_audio=str(AQUI / voz["ref"]),
                    ref_text=limpiar(voz["ref_texto"]), max_new_tokens=tope)
            audio = np.asarray(wavs[0], dtype=np.float32)
            sf.write(str(salida / f"{e['id']}.wav"), audio, sr, subtype="PCM_16")
            modo = "diseño" if isinstance(voz, str) else "clon"
            print(f"{e['id']}: {len(audio) / sr:.1f} s en {time.time() - t0:.1f} s · {e['voz']} ({modo})", flush=True)
        del modelo
        torch.cuda.empty_cache()
    # La muestra: todas las líneas de la carpeta seguidas, con una pausa entre cada una
    # (solo en las pruebas: con cientos de líneas sería un archivo enorme).
    archivos = [f for f in sorted(salida.glob("*.wav")) if not f.name.startswith("muestra")]
    if len(archivos) > 60:
        return
    partes = []
    for f in archivos:
        if f.name.startswith("muestra"):
            continue
        audio, sr = sf.read(str(f), dtype="float32")
        partes += [audio, np.zeros(int(sr * 0.7), dtype=np.float32)]
    sf.write(str(salida / "muestra_qwen.wav"), np.concatenate(partes), sr, subtype="PCM_16")


if __name__ == "__main__":
    main()
