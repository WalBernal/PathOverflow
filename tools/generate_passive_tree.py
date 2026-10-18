"""Genera data/passive_tree.json: el árbol pasivo con clusters temáticos.

Uso:  python tools/generate_passive_tree.py

Cada cluster (anillo o rueda de pasivas) tiene UNA temática de
data/passive_themes.json: todas sus pasivas menores y su notable son de ese
tipo (vida, fuego, crítico...). Entre clusters hay caminos de atributos, como
los "nodos de viaje" de PoE.

Estructura:
  - Anillo central de atributos que conecta las 5 clases.
  - Por clase: inicio, 4 clusters cercanos (anillo o rueda), 4 lejanos y una
    piedra angular al final de una de las ramas.
  - Puentes temáticos entre clases vecinas.

Si cambias la estructura, sube TREE_VERSION: los personajes guardados con otra
versión recuperan sus puntos de pasiva al cargar (los ids de los nodos cambian).
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "passive_tree.json"
THEMES = json.loads((ROOT / "data" / "passive_themes.json").read_text(encoding="utf-8"))["themes"]
TREE_VERSION = 2

# id, nombre, atributos, temáticas de los 4 clusters cercanos y de los 4 lejanos.
CLASSES = [
    ("guerrero", "Guerrero", ["str"],
     ["vida", "armadura", "fisico", "area"], ["robo_vida", "vida", "armadura", "fisico"]),
    ("duelista", "Duelista", ["str", "dex"],
     ["fisico", "velocidad_ataque", "evasion", "robo_vida"], ["critico", "armadura", "fisico", "velocidad_ataque"]),
    ("exploradora", "Exploradora", ["dex"],
     ["proyectiles", "evasion", "velocidad_ataque", "critico"], ["frio", "caos", "proyectiles", "evasion"]),
    ("hechicero", "Hechicero", ["int"],
     ["rayo", "fuego", "frio", "lanzamiento"], ["escudo", "mana", "critico", "caos"]),
    ("templario", "Templario", ["int", "str"],
     ["fuego", "area", "escudo", "vida"], ["rayo", "mana", "armadura", "lanzamiento"]),
]
BRIDGE_THEMES = ["resistencias", "atributos", "resistencias", "atributos", "resistencias"]

KEYSTONES = {
    "guerrero": ("Monolito Legacy", "Nadie sabe cómo funciona. Nadie se atreve a tocarlo.",
                 [("armour", "more", 100), ("movement_speed", "more", -15)]),
    "duelista": ("git push --force", "La historia la escriben quienes la sobrescriben.",
                 [("attack_speed", "more", 20), ("armour", "more", -40), ("evasion", "more", -40)]),
    "exploradora": ("Deuda Técnica", "Ya la pagarás. Con intereses.",
                    [("damage", "more", 30), ("life", "more", -20)]),
    "hechicero": ("Programación Orientada a Deadlines", "El código más rápido es el que nadie revisa.",
                  [("cast_speed", "more", 25), ("mana", "more", -30)]),
    "templario": ("Funciona en mi Máquina", "En producción es otra historia.",
                  [("energy_shield", "more", 60), ("life", "more", -40)]),
}

ATTR_STAT = {"str": ("strength", "Fuerza"), "dex": ("dexterity", "Destreza"), "int": ("intelligence", "Inteligencia")}

R_START = 700
HUB_R = 260
HUB_N = 15
PATH_STEP = 95
T1_DIST, T1_R = 360, 75
T2_DIST, T2_R = 690, 88
OFFSETS = [-45, -15, 15, 45]

nodes = []
edges = []
clusters = []
_notable_counter = {}
_cluster_name_counter = {}


def add(kind, name, x, y, mods=None, flavor="", class_id=None, cluster="", theme="", icon=""):
    n = {"id": len(nodes), "kind": kind, "name": name, "x": round(x, 1), "y": round(y, 1), "mods": mods or []}
    for key, value in (("flavor", flavor), ("class_id", class_id), ("cluster", cluster), ("theme", theme), ("icon", icon)):
        if value:
            n[key] = value
    nodes.append(n)
    return n["id"]


def link(a, b):
    edges.append([a, b])


def pos(node_id):
    return nodes[node_id]["x"], nodes[node_id]["y"]


def dist(a, b):
    (ax, ay), (bx, by) = pos(a), pos(b)
    return math.hypot(ax - bx, ay - by)


def polar(r, deg):
    rad = math.radians(deg)
    return r * math.cos(rad), r * math.sin(rad)


def new_cluster(theme, cx, cy, radius):
    names = THEMES[theme]["cluster_names"]
    k = _cluster_name_counter.get(theme, 0)
    _cluster_name_counter[theme] = k + 1
    cid = "c%d" % len(clusters)
    clusters.append({"id": cid, "theme": theme, "name": "%s: %s" % (THEMES[theme]["name"], names[k % len(names)]),
                     "x": round(cx, 1), "y": round(cy, 1), "radius": radius})
    return cid


def minor(theme, k, x, y, cluster):
    name, mods = THEMES[theme]["minors"][k % len(THEMES[theme]["minors"])]
    return add("minor", name, x, y, mods, cluster=cluster, theme=theme)


def notable(theme, x, y, cluster):
    pool = THEMES[theme]["notables"]
    k = _notable_counter.get(theme, 0)
    _notable_counter[theme] = k + 1
    name, flavor, mods = pool[k % len(pool)]
    return add("notable", name, x, y, mods, flavor, cluster=cluster, theme=theme, icon=theme)


def travel(attr, x, y):
    stat, label = ATTR_STAT[attr]
    return add("minor", label, x, y, [{"stat": stat, "type": "flat", "value": 10}], theme="atributos")


def ring_cluster(theme, cx, cy, radius, count, entry_deg):
    """Anillo: count nodos en círculo; el notable, en el lado opuesto a la entrada."""
    cid = new_cluster(theme, cx, cy, radius)
    ids = []
    for j in range(count):
        x, y = polar(radius, entry_deg + 360.0 * j / count)
        if j == count // 2:
            ids.append(notable(theme, cx + x, cy + y, cid))
        else:
            ids.append(minor(theme, j, cx + x, cy + y, cid))
    for j in range(count):
        link(ids[j], ids[(j + 1) % count])
    return ids[0], ids[count // 2], ids


def wheel_cluster(theme, cx, cy, radius, count, entry_deg):
    """Rueda: anillo de menores con el notable en el centro, unido a la entrada y a la salida."""
    cid = new_cluster(theme, cx, cy, radius)
    ids = []
    for j in range(count):
        x, y = polar(radius, entry_deg + 360.0 * j / count)
        ids.append(minor(theme, j, cx + x, cy + y, cid))
    for j in range(count):
        link(ids[j], ids[(j + 1) % count])
    center = notable(theme, cx, cy, cid)
    link(ids[0], center)
    link(center, ids[count // 2])
    return ids[0], ids[count // 2], ids + [center]


def walk(prev, x0, y0, dx, dy, distances, attrs):
    """Camino de nodos de atributo desde (x0, y0) en dirección (dx, dy)."""
    for k, d in enumerate(distances):
        n = travel(attrs[k % len(attrs)], x0 + dx * d, y0 + dy * d)
        link(prev, n)
        prev = n
    return prev


# --- Anillo central de atributos ---
hub = []
for i in range(HUB_N):
    x, y = polar(HUB_R, -90 + 360.0 * i / HUB_N)
    if i in (2, 9):
        hub.append(notable("atributos", x, y, ""))
    else:
        hub.append(add("minor", "Todos los atributos", x, y, THEMES["atributos"]["minors"][0][1], theme="atributos"))
for i in range(HUB_N):
    link(hub[i], hub[(i + 1) % HUB_N])

# --- Regiones de clase ---
outer_clusters = []  # por clase: (anillo del cluster de -45°, anillo del de +45°)
for ci, (cid, cname, attrs, tier1, tier2) in enumerate(CLASSES):
    ang = -90 + 72 * ci
    sx, sy = polar(R_START, ang)
    start = add("start", cname, sx, sy, class_id=cid)

    # Camino al anillo central.
    rdx, rdy = -math.cos(math.radians(ang)), -math.sin(math.radians(ang))
    last = walk(start, sx, sy, rdx, rdy, [140, 280], attrs)
    link(last, hub[3 * ci])

    side_rings = {}
    near_rings = []
    for bi, off in enumerate(OFFSETS):
        d = math.radians(ang + off)
        dx, dy = math.cos(d), math.sin(d)
        back_deg = math.degrees(math.atan2(dy, dx)) + 180
        # Cluster cercano.
        prev = walk(start, sx, sy, dx, dy, [PATH_STEP, PATH_STEP * 2], attrs)
        cx, cy = sx + dx * T1_DIST, sy + dy * T1_DIST
        shape = ring_cluster if bi % 2 == 0 else wheel_cluster
        count = 8 if shape is ring_cluster else 7
        entry, far, ring = shape(tier1[bi], cx, cy, T1_R, count, back_deg)
        link(prev, entry)
        near_rings.append(ring)
        if bi in (0, 3):
            side_rings[bi] = ring
        # Cluster lejano.
        far_x, far_y = pos(far)
        gap = T2_DIST - T1_DIST - T1_R - T2_R
        prev = walk(far, far_x, far_y, dx, dy, [gap / 3.0, gap * 2 / 3.0], attrs)
        cx2, cy2 = sx + dx * T2_DIST, sy + dy * T2_DIST
        shape2 = wheel_cluster if bi % 2 == 0 else ring_cluster
        count2 = 8 if shape2 is wheel_cluster else 9
        entry2, far2, _ = shape2(tier2[bi], cx2, cy2, T2_R, count2, back_deg)
        link(prev, entry2)
        # Piedra angular al final de la rama 2.
        if bi == 2:
            fx, fy = pos(far2)
            prev = walk(far2, fx, fy, dx, dy, [90, 180], attrs)
            ks_name, ks_flavor, ks_mods = KEYSTONES[cid]
            ks = add("keystone", ks_name, fx + dx * 290, fy + dy * 290,
                     [{"stat": s, "type": t, "value": v} for s, t, v in ks_mods], ks_flavor, icon="ks_" + cid)
            link(prev, ks)
    # Une los clusters cercanos vecinos: así la región de la clase es accesible
    # desde fuera sin pasar por su inicio (bloqueado para las demás clases).
    for r1, r2 in zip(near_rings, near_rings[1:]):
        link(*min(((p, q) for p in r1 for q in r2), key=lambda pq: dist(*pq)))
    outer_clusters.append((side_rings[0], side_rings[3]))

# --- Puentes entre clases vecinas ---
for i in range(len(CLASSES)):
    right = outer_clusters[i][1]
    left = outer_clusters[(i + 1) % len(CLASSES)][0]
    a = min(right, key=lambda n: min(dist(n, m) for m in left))
    b = min(left, key=lambda m: dist(a, m))
    (ax, ay), (bx, by) = pos(a), pos(b)
    mx, my = (ax + bx) / 2.0, (ay + by) / 2.0
    entry_deg = math.degrees(math.atan2(ay - my, ax - mx))
    e1, e2, ring = ring_cluster(BRIDGE_THEMES[i], mx, my, 55, 6, entry_deg)
    # Une cada lado con el nodo del puente más cercano, con un nodo de viaje en medio.
    for side in (a, b):
        target = min(ring, key=lambda n: dist(side, n))
        (sx, sy), (tx, ty) = pos(side), pos(target)
        mid = travel("str" if i % 2 == 0 else "dex", (sx + tx) / 2.0, (sy + ty) / 2.0)
        link(side, mid)
        link(mid, target)

themes_out = {k: {"name": v["name"], "color": v["color"]} for k, v in THEMES.items()}
OUT.write_text(json.dumps({"version": TREE_VERSION, "themes": themes_out, "clusters": clusters,
                           "nodes": nodes, "edges": edges}, ensure_ascii=False, indent=1), encoding="utf-8")
kinds = {}
for n in nodes:
    kinds[n["kind"]] = kinds.get(n["kind"], 0) + 1
print(f"Escrito {OUT}: {len(nodes)} nodos, {len(edges)} aristas, {len(clusters)} clusters, {kinds}")
