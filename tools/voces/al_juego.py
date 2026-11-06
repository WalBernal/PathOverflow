"""Pasa los .wav generados a audio/voces/<id>.ogg (Ogg Vorbis mono, lo que importa
Godot), todos al mismo volumen percibido y sin silencios largos en los bordes.

Uso (desde la raíz del proyecto):
  tools/voces/.venv-qwen/Scripts/python.exe tools/voces/al_juego.py tools/voces/salida_prologo
"""
import sys
from pathlib import Path

import numpy as np
import soundfile as sf

AQUI = Path(__file__).resolve().parent
DESTINO = AQUI.parent.parent / "audio" / "voces"
RMS_OBJETIVO = 10 ** (-20 / 20)   # -20 dBFS
PICO_MAX = 0.89


def recortar(a: np.ndarray, sr: int) -> np.ndarray:
    """Quita el silencio de los bordes, dejando 80 ms al empezar y 150 ms al acabar."""
    voz = np.flatnonzero(np.abs(a) > 0.01)
    if voz.size == 0:
        return a
    ini = max(0, voz[0] - int(sr * 0.08))
    fin = min(len(a), voz[-1] + int(sr * 0.15))
    return a[ini:fin]


def main() -> None:
    origen = Path(sys.argv[1])
    DESTINO.mkdir(parents=True, exist_ok=True)
    total = 0.0
    for f in sorted(origen.glob("*.wav")):
        if f.name.startswith("muestra"):
            continue
        a, sr = sf.read(str(f), dtype="float32")
        if a.ndim > 1:
            a = a.mean(axis=1)
        a = recortar(a, sr)
        rms = float(np.sqrt(np.mean(a ** 2))) or 1e-6
        a = a * (RMS_OBJETIVO / rms)
        pico = float(np.abs(a).max())
        if pico > PICO_MAX:
            a = a * (PICO_MAX / pico)
        sf.write(str(DESTINO / (f.stem + ".ogg")), a, sr, format="OGG", subtype="VORBIS")
        total += len(a) / sr
        print(f"{f.stem}.ogg  {len(a) / sr:.1f} s")
    kb = sum(p.stat().st_size for p in DESTINO.glob("*.ogg")) / 1024
    print(f"{total:.0f} s de voz · {kb:.0f} KB en {DESTINO}")


if __name__ == "__main__":
    main()
