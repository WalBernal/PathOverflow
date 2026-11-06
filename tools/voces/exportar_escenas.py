"""Saca las líneas habladas de data/cutscenes.json con el id que usa el juego
(VoiceLines.cutscene_id: "<escena>_<nº de paso>", y "_m"/"_f" en las del jugador) y
les pone la voz del reparto (tools/voces/voces.json). Escribe una lista para
generar_qwen.py.

Uso (desde la raíz del proyecto):
  tools/voces/.venv-qwen/Scripts/python.exe tools/voces/exportar_escenas.py prologo_ tools/voces/lineas_prologo.json
El primer argumento es el prefijo de las escenas (prologo_ = todas las del prólogo).
"""
import json
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent.parent


def main() -> None:
    prefijo, destino = sys.argv[1], Path(sys.argv[2])
    reparto = json.loads((AQUI / "voces.json").read_text(encoding="utf-8"))
    hablantes = reparto["hablantes"]
    escenas = json.loads((RAIZ / "data" / "cutscenes.json").read_text(encoding="utf-8"))["cutscenes"]
    lineas, sin_voz = [], []
    for nombre, escena in escenas.items():
        if not nombre.startswith(prefijo):
            continue
        for i, paso in enumerate(escena.get("steps", [])):
            if "effect" in paso or "input" in paso or not paso.get("text"):
                continue
            estilo = paso.get("style", "")
            if estilo == "console":
                continue   # la terminal se lee en pantalla, no en voz alta
            base = f"{nombre}_{i:02d}"
            quien = paso.get("speaker", "") or estilo
            if quien == "player":
                lineas.append({"id": base + "_m", "voz": "egresado", "texto": paso["text"]})
                lineas.append({"id": base + "_f", "voz": "egresada", "texto": paso["text"]})
            elif quien in hablantes:
                lineas.append({"id": base, "voz": hablantes[quien], "texto": paso["text"]})
            else:
                sin_voz.append(f"{base} ({quien or '¿?'})")
    destino.write_text(json.dumps({"voces": reparto["voces"], "lineas": lineas}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(lineas)} líneas → {destino}")
    if sin_voz:
        print("Sin voz en el reparto:", ", ".join(sin_voz))


if __name__ == "__main__":
    main()
