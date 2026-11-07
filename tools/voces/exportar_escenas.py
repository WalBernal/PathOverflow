"""Saca las líneas habladas de data/cutscenes.json con el id que usa el juego
(VoiceLines.cutscene_id: "<escena>_<nº de paso>", y "_m"/"_f" en las del jugador) y
les pone la voz del reparto (tools/voces/voces.json). Escribe una lista para
generar_qwen.py.

Uso (desde la raíz del proyecto):
  tools/voces/.venv-qwen/Scripts/python.exe tools/voces/exportar_escenas.py prologo_ tools/voces/lineas_prologo.json
El primer argumento es el prefijo de las escenas (prologo_ = todas las del prólogo,
* = todas), o «npc» para los diálogos de los NPC de data/npcs.json.
"""
import json
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent.parent


def npc_id(dialogo: str, parte: str, indice: int = -1) -> str:
    """Igual que VoiceLines.npc_id en el juego."""
    return f"npc_{dialogo}_{parte}" + (f"_{indice}" if indice >= 0 else "")


def exportar_npcs(reparto: dict, destino: Path) -> None:
    """Las líneas de los diálogos de NPC (npcs.json): el texto de cada nodo, su versión
    para el dedo, sus textos al releerlo y las frases de menú y saludo. Las opciones del
    jugador no se leen en voz alta."""
    datos = json.loads((RAIZ / "data" / "npcs.json").read_text(encoding="utf-8"))
    quien = {npc.get("dialogue", nid): nid for nid, npc in datos["npcs"].items()}
    lineas, sin_voz = [], []

    def lista(valor, dialogo, parte, voz):
        if isinstance(valor, list):
            for i, t in enumerate(valor):
                lineas.append({"id": npc_id(dialogo, parte, i), "voz": voz, "texto": t})
        elif isinstance(valor, str) and valor:
            lineas.append({"id": npc_id(dialogo, parte), "voz": voz, "texto": valor})

    for dialogo, d in datos["dialogues"].items():
        voz = reparto["hablantes"].get(quien.get(dialogo, dialogo))
        if not voz:
            sin_voz.append(dialogo)
            continue
        for nodo, n in d.get("nodes", {}).items():
            lista(n.get("text", ""), dialogo, nodo, voz)
            lista(n.get("text_touch", ""), dialogo, nodo + "_tactil", voz)
            lista(n.get("again", ""), dialogo, nodo + "_otra", voz)
        lista(d.get("menu", []), dialogo, "_menu", voz)
        lista(d.get("greeting_again", []), dialogo, "_saludo", voz)
    destino.write_text(json.dumps({"voces": reparto["voces"], "lineas": lineas}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(lineas)} líneas de NPC → {destino}")
    if sin_voz:
        print("Diálogos sin voz en el reparto:", ", ".join(sin_voz))


def main() -> None:
    prefijo, destino = sys.argv[1], Path(sys.argv[2])
    reparto = json.loads((AQUI / "voces.json").read_text(encoding="utf-8"))
    if prefijo == "npc":   # los diálogos de los NPC, no las escenas
        exportar_npcs(reparto, destino)
        return
    if prefijo == "*":   # todas las escenas
        prefijo = ""
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
            por_nombre = reparto.get("nombres", {}).get(f"{estilo}:{paso.get('name', '')}")
            if not paso.get("speaker") and por_nombre:   # jefes y avisos del «Sistema»
                lineas.append({"id": base, "voz": por_nombre, "texto": paso["text"]})
            elif quien == "player":
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
