"""Genera data/passive_tree.json: el árbol pasivo con clusters temáticos.

Uso:  python tools/generate_passive_tree.py

Cada cluster (anillo o rueda de pasivas) tiene UNA temática de
data/passive_themes.json: todas sus pasivas menores y su notable son de ese
tipo (vida, fuego, crítico...). Entre clusters hay caminos de atributos, como
los "nodos de viaje" de PoE.

Estructura (7 clases):
  - Centro: inicio del Full Stack (las tres stats), rodeado por el anillo de
    Versatilidad (con 3 notables y su piedra angular) y el anillo central de
    atributos.
  - 6 clases alrededor, cada 60°, ordenadas para que las vecinas compartan
    atributo: Guerrero (FUE), Duelista (FUE/DES), Exploradora (DES),
    Hacker (DES/INT), Hechicero (INT), Templario (INT/FUE).
  - Por clase: inicio, 4 clusters cercanos, 4 lejanos y una piedra angular.
    El inicio SOLO se conecta hacia delante (sus 4 ramas): nada llega a él por
    detrás. La región se une al centro por los lados, no por el inicio.
  - Entre el anillo central y cada clase, un cluster interior; entre clase y
    clase, un cluster "puerta" unido al centro y a los clusters laterales de
    las dos clases vecinas, y un puente exterior entre sus clusters lejanos.

Si cambias la estructura, sube TREE_VERSION: los personajes guardados con otra
versión recuperan sus puntos de pasiva al cargar (los ids de los nodos cambian).
"""
import json
import math
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "passive_tree.json"
THEMES = json.loads((ROOT / "data" / "passive_themes.json").read_text(encoding="utf-8"))["themes"]
TREE_VERSION = 3

# id, nombre, atributos, temáticas de los 4 clusters cercanos, de los 4 lejanos y del cluster interior.
CLASSES = [
    ("guerrero", "Guerrero", ["str"],
     ["vida", "armadura", "fisico", "area"], ["robo_vida", "vida", "armadura", "fisico"], "resistencias"),
    ("duelista", "Duelista", ["str", "dex"],
     ["fisico", "velocidad_ataque", "evasion", "robo_vida"], ["critico", "armadura", "fisico", "velocidad_ataque"], "movilidad"),
    ("exploradora", "Exploradora", ["dex"],
     ["proyectiles", "evasion", "velocidad_ataque", "critico"], ["frio", "caos", "proyectiles", "evasion"], "movilidad"),
    ("hacker", "Hacker", ["dex", "int"],
     ["critico", "caos", "evasion", "rayo"], ["lanzamiento", "proyectiles", "escudo", "tiempos"], "tiempos"),
    ("hechicero", "Hechicero", ["int"],
     ["rayo", "fuego", "frio", "lanzamiento"], ["escudo", "mana", "critico", "caos"], "mana"),
    ("templario", "Templario", ["int", "str"],
     ["fuego", "area", "escudo", "vida"], ["rayo", "mana", "armadura", "lanzamiento"], "tiempos"),
]
CENTER_CLASS = ("full_stack", "Full Stack")
GATE_THEMES = ["resistencias", "atributos", "resistencias", "atributos", "resistencias", "atributos"]
BRIDGE_THEMES = ["resistencias", "atributos", "resistencias", "atributos", "resistencias", "atributos"]

KEYSTONES = {
    "guerrero": ("Monolito Legacy", "Nadie sabe cómo funciona. Nadie se atreve a tocarlo.",
                 [("armour", "more", 100), ("movement_speed", "more", -15)]),
    "duelista": ("git push --force", "La historia la escriben quienes la sobrescriben.",
                 [("attack_speed", "more", 20), ("armour", "more", -40), ("evasion", "more", -40)]),
    "exploradora": ("Deuda Técnica", "Ya la pagarás. Con intereses.",
                    [("damage", "more", 30), ("life", "more", -20)]),
    "hacker": ("Root Sin Contraseña", "Acceso total. Para ti y para cualquiera que pase.",
               [("crit_chance", "more", 50), ("energy_shield", "more", -50), ("life", "more", -10)]),
    "hechicero": ("Programación Orientada a Deadlines", "El código más rápido es el que nadie revisa.",
                  [("cast_speed", "more", 25), ("mana", "more", -30)]),
    "templario": ("Funciona en mi Máquina", "En producción es otra historia.",
                  [("energy_shield", "more", 60), ("life", "more", -40)]),
    "full_stack": ("Hola Mundo en 40 Lenguajes", "Sabes decir hola en todos. Y nada más.",
                   [("damage", "more", 12), ("life", "more", 8), ("crit_multiplier", "flat", -30)]),
}

ATTR_STAT = {"str": ("strength", "Fuerza"), "dex": ("dexterity", "Destreza"), "int": ("intelligence", "Inteligencia")}

N_OUTER = len(CLASSES)
SECTOR = 360.0 / N_OUTER
R_START = 900
HUB_R = 320
HUB_N = 24             # 4 nodos por clase: las direcciones de clase y de puerta caen en nodos del anillo
CORE_R = 150
CORE_N = 12
INNER_R = 600          # clusters interiores (entre el anillo central y cada clase)
GATE_R = 620           # clusters puerta (entre clases vecinas)
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


def hub_node(deg):
    """Nodo del anillo central más cercano a un ángulo."""
    k = round((deg + 90) / (360.0 / HUB_N)) % HUB_N
    return hub[k]


def walk_between(a, b, count, attrs):
    """Camino de `count` nodos de viaje en línea recta de a a b (enlazado a ambos)."""
    (ax, ay), (bx, by) = pos(a), pos(b)
    prev = a
    for k in range(count):
        t = (k + 1) / (count + 1)
        n = travel(attrs[k % len(attrs)], ax + (bx - ax) * t, ay + (by - ay) * t)
        link(prev, n)
        prev = n
    link(prev, b)


def closest(ring, x, y):
    return min(ring, key=lambda n: math.hypot(pos(n)[0] - x, pos(n)[1] - y))


# --- Centro: Full Stack ---
center_start = add("start", CENTER_CLASS[1], 0, 0, class_id=CENTER_CLASS[0])
core_cid = new_cluster("versatil", 0, 0, CORE_R)
core = []
for i in range(CORE_N):
    x, y = polar(CORE_R, -90 + 360.0 * i / CORE_N)
    if i % 4 == 2:
        core.append(notable("versatil", x, y, core_cid))
    else:
        core.append(minor("versatil", i, x, y, core_cid))
for i in range(CORE_N):
    link(core[i], core[(i + 1) % CORE_N])
# Tres radios desde el inicio (solo hacia fuera).
for i in (0, 4, 8):
    x, y = polar(CORE_R / 2.0, -90 + 360.0 * i / CORE_N)
    spoke = travel(["str", "dex", "int"][i // 4], x, y)
    link(center_start, spoke)
    link(spoke, core[i])

# --- Anillo central de atributos ---
hub = []
for i in range(HUB_N):
    x, y = polar(HUB_R, -90 + 360.0 * i / HUB_N)
    if i % 8 == 6:
        hub.append(notable("atributos", x, y, ""))
    else:
        hub.append(add("minor", "Todos los atributos", x, y, THEMES["atributos"]["minors"][0][1], theme="atributos"))
for i in range(HUB_N):
    link(hub[i], hub[(i + 1) % HUB_N])
# El núcleo se une al anillo por seis radios (entre los radios del inicio).
for i in (1, 3, 5, 7, 9, 11):
    deg = -90 + 360.0 * i / CORE_N
    walk_between(core[i], hub_node(deg), 1, ["str", "dex", "int"])
# Piedra angular del Full Stack: hacia fuera desde un notable del núcleo, entre dos radios.
ks_name, ks_flavor, ks_mods = KEYSTONES[CENTER_CLASS[0]]
kx, ky = polar(HUB_R - 70, -90 + 360.0 * 10 / CORE_N)
ks_center = add("keystone", ks_name, kx, ky, [{"stat": s, "type": t, "value": v} for s, t, v in ks_mods], ks_flavor,
                icon="ks_" + CENTER_CLASS[0])
walk_between(core[10], ks_center, 1, ["int"])

# --- Regiones de clase ---
side_rings = []   # por clase: (anillo cercano de -45°, anillo cercano de +45°)
far_side_rings = []
for ci, (cid, cname, attrs, tier1, tier2, inner_theme) in enumerate(CLASSES):
    ang = -90 + SECTOR * ci
    sx, sy = polar(R_START, ang)
    start = add("start", cname, sx, sy, class_id=cid)

    near_rings = []
    sides = {}
    far_sides = {}
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
            sides[bi] = ring
        # Cluster lejano.
        far_x, far_y = pos(far)
        gap = T2_DIST - T1_DIST - T1_R - T2_R
        prev = walk(far, far_x, far_y, dx, dy, [gap / 3.0, gap * 2 / 3.0], attrs)
        cx2, cy2 = sx + dx * T2_DIST, sy + dy * T2_DIST
        shape2 = wheel_cluster if bi % 2 == 0 else ring_cluster
        count2 = 8 if shape2 is wheel_cluster else 9
        entry2, far2, ring2 = shape2(tier2[bi], cx2, cy2, T2_R, count2, back_deg)
        link(prev, entry2)
        if bi in (0, 3):
            far_sides[bi] = ring2
        # Piedra angular al final de la rama 2.
        if bi == 2:
            fx, fy = pos(far2)
            prev = walk(far2, fx, fy, dx, dy, [90, 180], attrs)
            ks_name, ks_flavor, ks_mods = KEYSTONES[cid]
            ks = add("keystone", ks_name, fx + dx * 290, fy + dy * 290,
                     [{"stat": s, "type": t, "value": v} for s, t, v in ks_mods], ks_flavor, icon="ks_" + cid)
            link(prev, ks)
    # Une los clusters cercanos vecinos por sus nodos más alejados del inicio,
    # para que ninguna conexión pase por detrás del inicio.
    for r1, r2 in zip(near_rings, near_rings[1:]):
        def score(pq):
            p, q = pq
            mid = ((pos(p)[0] + pos(q)[0]) / 2.0, (pos(p)[1] + pos(q)[1]) / 2.0)
            return dist(p, q) - 0.6 * math.hypot(mid[0] - sx, mid[1] - sy)
        link(*min(((p, q) for p in r1 for q in r2), key=score))
    side_rings.append((sides[0], sides[3]))
    far_side_rings.append((far_sides[0], far_sides[3]))

    # Cluster interior: entre el anillo central y la clase (NO se une al inicio).
    ix, iy = polar(INNER_R, ang)
    entry_deg = ang + 180
    i_entry, i_far, i_ring = ring_cluster(inner_theme, ix, iy, 70, 7, entry_deg)
    walk_between(hub_node(ang), i_entry, 2, attrs)

# --- Puertas entre clases vecinas y puentes exteriores ---
for i in range(N_OUTER):
    j = (i + 1) % N_OUTER
    gate_ang = -90 + SECTOR * i + SECTOR / 2.0
    gx, gy = polar(GATE_R, gate_ang)
    g_entry, g_far, g_ring = ring_cluster(GATE_THEMES[i], gx, gy, 62, 6, gate_ang + 180)
    # Hacia el centro.
    walk_between(hub_node(gate_ang), g_entry, 2, ["str", "dex", "int"])
    # Hacia los clusters laterales de las dos clases.
    shared = sorted(set(CLASSES[i][2]) | set(CLASSES[j][2]))
    for ring in (side_rings[i][1], side_rings[j][0]):
        a = closest(ring, gx, gy)
        b = closest(g_ring, *pos(a))
        steps = max(1, int(dist(a, b) // 140))
        walk_between(a, b, steps, shared)
    # Y con los clusters interiores de ambas clases.
    for k in (i, j):
        ix, iy = polar(INNER_R, -90 + SECTOR * k)
        inner = [n["id"] for n in nodes if n.get("cluster") and abs(nodes[n["id"]]["x"] - ix) < 80 and abs(nodes[n["id"]]["y"] - iy) < 80]
        a = closest(inner, gx, gy)
        b = closest(g_ring, *pos(a))
        walk_between(a, b, 1, shared)
    # Puente exterior entre los clusters lejanos laterales.
    right = far_side_rings[i][1]
    left = far_side_rings[j][0]
    a = min(right, key=lambda n: min(dist(n, m) for m in left))
    b = min(left, key=lambda m: dist(a, m))
    (ax, ay), (bx, by) = pos(a), pos(b)
    mx, my = (ax + bx) / 2.0, (ay + by) / 2.0
    entry_deg = math.degrees(math.atan2(ay - my, ax - mx))
    e1, e2, ring = ring_cluster(BRIDGE_THEMES[i], mx, my, 55, 6, entry_deg)
    for side in (a, b):
        target = min(ring, key=lambda n: dist(side, n))
        walk_between(side, target, 1, shared)

# --- Comprobaciones de diseño ---
starts = [n for n in nodes if n["kind"] == "start"]
adj = {n["id"]: set() for n in nodes}
for a, b in edges:
    adj[a].add(b)
    adj[b].add(a)


def seg_dist(p, a, b):
    (ax, ay), (bx, by), (px, py) = pos(a), pos(b), pos(p)
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / ((dx * dx + dy * dy) or 1.0)))
    return math.hypot(ax + t * dx - px, ay + t * dy - py)


for s in starts:
    sid = s["id"]
    for a, b in edges:
        if sid not in (a, b):
            assert seg_dist(sid, a, b) > 60, f"arista pasando junto al inicio de {s['name']}"
    if s["class_id"] != CENTER_CLASS[0]:
        ox, oy = s["x"], s["y"]
        for nb in adj[sid]:
            nx, ny = pos(nb)
            assert (nx - ox) * ox + (ny - oy) * oy > 0, f"{s['name']}: conexión por detrás del inicio"
# Todo alcanzable desde cualquier inicio sin pasar por otros inicios.
start_ids = {s["id"] for s in starts}
for s in starts:
    seen = {s["id"]}
    todo = [s["id"]]
    while todo:
        cur = todo.pop()
        for nb in adj[cur]:
            if nb not in seen and nb not in start_ids:
                seen.add(nb)
                todo.append(nb)
    assert len(seen) == len(nodes) - len(start_ids) + 1, f"desde {s['name']} no se llega a todo"

themes_out = {k: {"name": v["name"], "color": v["color"]} for k, v in THEMES.items()}
OUT.write_text(json.dumps({"version": TREE_VERSION, "themes": themes_out, "clusters": clusters,
                           "nodes": nodes, "edges": edges}, ensure_ascii=False, indent=1), encoding="utf-8")
kinds = {}
for n in nodes:
    kinds[n["kind"]] = kinds.get(n["kind"], 0) + 1
print(f"Escrito {OUT}: {len(nodes)} nodos, {len(edges)} aristas, {len(clusters)} clusters, {kinds}")