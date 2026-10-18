"""Genera data/passive_tree.json: un árbol pasivo de prueba de ~200 nodos.

Uso:  python tools/generate_passive_tree.py

Es un generador de PROTOTIPO para tener algo jugable ya. Cuando el diseño
madure, el árbol se editará a mano con una herramienta dentro del editor de
Godot (un plugin @tool) y este script dejará de usarse.

Estructura generada:
  - Un anillo central (hub) que conecta las 5 clases.
  - Cada clase: nodo de inicio, 3 ramas hacia fuera con un "cluster"
    (anillo de 6 nodos con un notable) y una piedra angular al final.
  - Conectores entre los clusters laterales de clases vecinas.
"""
import json
import math
import random
from pathlib import Path

random.seed(1337)
OUT = Path(__file__).resolve().parent.parent / "data" / "passive_tree.json"

# Orden alrededor del círculo: los híbridos quedan entre sus dos atributos.
CLASSES = [
    ("guerrero", "Guerrero", ["str"]),
    ("duelista", "Duelista", ["str", "dex"]),
    ("exploradora", "Exploradora", ["dex"]),
    ("hechicero", "Hechicero", ["int"]),
    ("templario", "Templario", ["int", "str"]),
]


def mod(stat, kind, value, tags=None):
    m = {"stat": stat, "type": kind, "value": value}
    if tags:
        m["tags"] = tags
    return m


ATTR_STAT = {"str": ("strength", "Fuerza"), "dex": ("dexterity", "Destreza"), "int": ("intelligence", "Inteligencia")}

MINOR_POOLS = {
    "str": [
        ("Fuerza", [mod("strength", "flat", 10)]),
        ("Vida", [mod("life", "increased", 8)]),
        ("Armadura", [mod("armour", "increased", 15)]),
        ("Golpe pesado", [mod("physical_damage", "increased", 10, ["melee"])]),
        ("Regeneración", [mod("life_regen", "flat", 4)]),
    ],
    "dex": [
        ("Destreza", [mod("dexterity", "flat", 10)]),
        ("Evasión", [mod("evasion", "increased", 15)]),
        ("Velocidad de ataque", [mod("attack_speed", "increased", 4)]),
        ("Proyectiles", [mod("projectile_speed", "increased", 10)]),
        ("Crítico", [mod("crit_chance", "increased", 12)]),
    ],
    "int": [
        ("Inteligencia", [mod("intelligence", "flat", 10)]),
        ("Escudo de energía", [mod("energy_shield", "increased", 10)]),
        ("Maná", [mod("mana", "increased", 8)]),
        ("Hechicería", [mod("elemental_damage", "increased", 10, ["spell"])]),
        ("Lanzamiento", [mod("cast_speed", "increased", 4)]),
    ],
    "generic": [
        ("Daño", [mod("damage", "increased", 8)]),
        ("Resistencia al fuego", [mod("fire_res", "flat", 12)]),
        ("Resistencia al frío", [mod("cold_res", "flat", 12)]),
        ("Resistencia al rayo", [mod("lightning_res", "flat", 12)]),
        ("Área de efecto", [mod("area_of_effect", "increased", 6)]),
        ("Vida", [mod("life", "flat", 15)]),
    ],
}

NOTABLES = {
    "str": [
        ("Café como dependencia", "npm install cafeína --save",
         [mod("life_regen", "flat", 10), mod("attack_speed", "increased", 6)]),
        ("Rubber Duck de guerra", "El pato escucha. El pato juzga.",
         [mod("life", "increased", 15), mod("armour", "increased", 20)]),
        ("Hotfix en caliente", "Directo a producción, como los valientes.",
         [mod("physical_damage", "increased", 25, ["melee"]), mod("life", "flat", 20)]),
        ("Código espagueti", "Todo está conectado. Literalmente todo.",
         [mod("strength", "flat", 20), mod("physical_damage", "increased", 15)]),
    ],
    "dex": [
        ("Off-by-one", "Fallaste por uno. Siempre por uno.",
         [mod("crit_chance", "increased", 30), mod("crit_multiplier", "flat", 15)]),
        ("Async/Await", "Prometo que volveré. Promise pending.",
         [mod("attack_speed", "increased", 10), mod("movement_speed", "increased", 5)]),
        ("Regex que nadie entiende", "^(?:(?!esperanza).)*$",
         [mod("projectile_speed", "increased", 20), mod("physical_damage", "increased", 15, ["projectile"])]),
        ("Bucle infinito", "while (true) { esquivar(); }",
         [mod("evasion", "increased", 30), mod("dexterity", "flat", 15)]),
    ],
    "int": [
        ("Copiado de Stack Overflow", "Pegado con la máxima convicción y cero comprensión.",
         [mod("elemental_damage", "increased", 25, ["spell"]), mod("mana", "flat", 30)]),
        ("Recursión", "Para entender la recursión, primero hay que entender la recursión.",
         [mod("cast_speed", "increased", 8), mod("intelligence", "flat", 20)]),
        ("Null Pointer", "Apunta al vacío. El vacío devuelve el golpe.",
         [mod("chaos_damage", "increased", 30), mod("chaos_res", "flat", 15)]),
        ("Garbage Collector", "Recoge lo que tú olvidas liberar.",
         [mod("energy_shield", "increased", 25), mod("mana", "increased", 15)]),
    ],
    "generic": [
        ("Es una feature, no un bug", "Documentado. Con orgullo.",
         [mod("damage", "increased", 15), mod("fire_res", "flat", 8), mod("cold_res", "flat", 8), mod("lightning_res", "flat", 8)]),
        ("Tests en verde", "Los tests pasan. Nadie pregunta qué testean.",
         [mod("fire_res", "flat", 15), mod("cold_res", "flat", 15), mod("lightning_res", "flat", 15)]),
        ("Commit a las 3 AM", "Mensaje: 'arreglos'. Archivos cambiados: 47.",
         [mod("damage", "increased", 20), mod("life", "increased", -5)]),
        ("Merge conflict", "<<<<<<< HEAD",
         [mod("area_of_effect", "increased", 15), mod("damage", "increased", 10)]),
        ("Kernel Panic", "Tu sistema operativo y tú tenéis algo en común.",
         [mod("crit_multiplier", "flat", 25)]),
        ("Caché invalidada", "Uno de los dos problemas difíciles. El otro es ponerle nombre a las cosas.",
         [mod("cast_speed", "increased", 5), mod("attack_speed", "increased", 5)]),
        ("404: Dolor no encontrado", "El recurso solicitado no existe en este servidor.",
         [mod("block_chance", "flat", 5), mod("life", "increased", 10)]),
        ("sudo", "Un gran poder conlleva una gran responsabilidad. O no.",
         [mod("damage", "increased", 12), mod("area_of_effect", "increased", 8)]),
    ],
}

KEYSTONES = {
    "guerrero": ("Monolito legacy", "Nadie sabe cómo funciona. Nadie se atreve a tocarlo.",
                 [mod("armour", "more", 100), mod("movement_speed", "more", -15)]),
    "duelista": ("git push --force", "La historia la escriben quienes la sobrescriben.",
                 [mod("attack_speed", "more", 20), mod("armour", "more", -40), mod("evasion", "more", -40)]),
    "exploradora": ("Deuda técnica", "Ya la pagarás. Con intereses.",
                    [mod("damage", "more", 30), mod("life", "more", -20)]),
    "hechicero": ("Programación orientada a deadlines", "El código más rápido es el que nadie revisa.",
                  [mod("cast_speed", "more", 25), mod("mana", "more", -30)]),
    "templario": ("Funciona en mi máquina", "En producción es otra historia.",
                  [mod("energy_shield", "more", 60), mod("life", "more", -40)]),
}

HUB_RADIUS = 160
START_RADIUS = 440
PATH_STEP = 70
CLUSTER_DIST = 320
CLUSTER_RADIUS = 62

nodes = []
edges = []


def add(kind, name, x, y, mods=None, flavor="", class_id=None):
    n = {"id": len(nodes), "kind": kind, "name": name, "x": round(x, 1), "y": round(y, 1), "mods": mods or []}
    if flavor:
        n["flavor"] = flavor
    if class_id:
        n["class_id"] = class_id
    nodes.append(n)
    return n["id"]


def link(a, b):
    edges.append([a, b])


def polar(r, deg):
    rad = math.radians(deg)
    return r * math.cos(rad), r * math.sin(rad)


def minor(pool_keys, x, y):
    name, mods = random.choice(MINOR_POOLS[random.choice(pool_keys)])
    return add("minor", name, x, y, mods)


def notable(entry, x, y):
    name, flavor, mods = entry
    return add("notable", name, x, y, mods, flavor)


def dist(a, b):
    return math.hypot(nodes[a]["x"] - nodes[b]["x"], nodes[a]["y"] - nodes[b]["y"])


# Notables: 2 por atributo de la clase + 1 genérico; los genéricos sobrantes van al hub.
pools = {k: list(v) for k, v in NOTABLES.items()}
class_notables = []
for _, _, attrs in CLASSES:
    picks = [pools[attrs[0]].pop(0), pools[attrs[-1]].pop(0), pools["generic"].pop(0)]
    class_notables.append(picks)
hub_notables = pools["generic"]

# --- Hub central ---
hub = []
for i in range(10):
    x, y = polar(HUB_RADIUS, -90 + 36 * i)
    if i % 2 == 1 and hub_notables:
        hub.append(notable(hub_notables.pop(0), x, y))
    else:
        hub.append(minor(["generic"], x, y))
for i in range(10):
    link(hub[i], hub[(i + 1) % 10])

# --- Regiones de cada clase ---
side_clusters = []
for ci, (cid, cname, attrs) in enumerate(CLASSES):
    ang = -90 + 72 * ci
    sx, sy = polar(START_RADIUS, ang)
    start = add("start", cname, sx, sy, class_id=cid)

    # Camino hacia el hub.
    prev = start
    for r in (350, 255):
        x, y = polar(r, ang)
        n = minor(attrs, x, y)
        link(prev, n)
        prev = n
    link(prev, hub[2 * ci])

    clusters = []
    for bi, off in enumerate((-38, 0, 38)):
        d = math.radians(ang + off)
        dx, dy = math.cos(d), math.sin(d)
        prev = start
        for k in range(1, 4):
            x, y = sx + dx * PATH_STEP * k, sy + dy * PATH_STEP * k
            if k == 2:
                stat, label = ATTR_STAT[attrs[bi % len(attrs)]]
                n = add("minor", label, x, y, [mod(stat, "flat", 10)])
            else:
                n = minor(attrs, x, y)
            link(prev, n)
            prev = n
        cx, cy = sx + dx * CLUSTER_DIST, sy + dy * CLUSTER_DIST
        base = math.degrees(math.atan2(dy, dx)) + 180  # j=0 mira hacia el inicio
        ring = []
        for j in range(6):
            rx, ry = polar(CLUSTER_RADIUS, base + 60 * j)
            if j == 3:
                ring.append(notable(class_notables[ci][bi], cx + rx, cy + ry))
            else:
                ring.append(minor(attrs + ["generic"], cx + rx, cy + ry))
        for j in range(6):
            link(ring[j], ring[(j + 1) % 6])
        link(prev, ring[0])
        clusters.append(ring)

    # Une los clusters vecinos: así la región de una clase es accesible desde
    # fuera sin atravesar su nodo de inicio (que está bloqueado para las demás).
    for left, right in ((clusters[0], clusters[1]), (clusters[1], clusters[2])):
        link(*min(((p, q) for p in left for q in right), key=lambda pq: dist(*pq)))

    # Piedra angular al final de la rama central.
    d = math.radians(ang)
    dx, dy = math.cos(d), math.sin(d)
    prev = clusters[1][3]
    for extra in (80, 160):
        reach = CLUSTER_DIST + CLUSTER_RADIUS + extra
        n = minor(attrs, sx + dx * reach, sy + dy * reach)
        link(prev, n)
        prev = n
    ks_name, ks_flavor, ks_mods = KEYSTONES[cid]
    reach = CLUSTER_DIST + CLUSTER_RADIUS + 260
    ks = add("keystone", ks_name, sx + dx * reach, sy + dy * reach, ks_mods, ks_flavor)
    link(prev, ks)

    side_clusters.append((clusters[0], clusters[2]))

# --- Conectores entre clases vecinas ---
for i in range(len(CLASSES)):
    right = side_clusters[i][1]
    left = side_clusters[(i + 1) % len(CLASSES)][0]
    a, b = min(((p, q) for p in right for q in left), key=lambda pq: dist(*pq))
    ax, ay, bx, by = nodes[a]["x"], nodes[a]["y"], nodes[b]["x"], nodes[b]["y"]
    prev = a
    steps = 4
    for s in range(1, steps + 1):
        t = s / (steps + 1)
        n = minor(["generic"], ax + (bx - ax) * t, ay + (by - ay) * t)
        link(prev, n)
        prev = n
    link(prev, b)

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps({"version": 1, "nodes": nodes, "edges": edges}, ensure_ascii=False, indent=1), encoding="utf-8")
kinds = {}
for n in nodes:
    kinds[n["kind"]] = kinds.get(n["kind"], 0) + 1
print(f"Escrito {OUT}: {len(nodes)} nodos, {len(edges)} aristas, {kinds}")
