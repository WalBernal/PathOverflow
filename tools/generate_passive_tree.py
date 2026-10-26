"""Genera data/passive_tree.json: el árbol pasivo 2.0 (diseño en docs/arbol_2.md).

Uso:  python tools/generate_passive_tree.py

Efectos: los de data/passive_themes.json (menores, notables y nombres de cluster
por familia) y data/passive_identity.json (notables de estilo de cada clase,
piedras angulares extra y constelaciones). Las maestrías se arman con los
notables de su familia (elegir 1 de 3).

Si cambias la estructura, sube TREE_VERSION: los personajes guardados con otra
versión recuperan sus puntos de pasiva al cargar. Las claves (`key`) no dependen
del orden de generación: lo que no se mueve conserva la suya.

Estructura:
  - Centro: inicio del Full Stack, anillo de viaje y anillo interior de 12 clusters
    (6 hacia las clases, 6 hacia las puertas).
  - 6 regiones de clase (60° cada una) con 4 anillos de clusters (A-D) de tamaños
    distintos; en el anillo A, el «corazón» de la clase (cluster grande de su estilo);
    en el D, su piedra angular.
  - 12 clusters «puerta» en las fronteras entre regiones vecinas (dos por frontera).
  - Anillo exterior de 6 constelaciones, entre región y región.
  - Los clusters se unen por un grafo de Gabriel de sus centros (vecinos cercanos y
    sin cruces), con caminos de nodos de viaje cada ~85 px.
Cada nodo lleva una clave estable (`key`), p. ej. "guerrero.C1:5" o "via:guerrero.A0-guerrero.B1:2":
el árbol final se referirá a los nodos por ella, no por su id numérico.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "passive_tree.json"
THEMES = json.loads((ROOT / "data" / "passive_themes.json").read_text(encoding="utf-8"))["themes"]
IDENTITY = json.loads((ROOT / "data" / "passive_identity.json").read_text(encoding="utf-8"))
TREE_VERSION = 8
# Multiplicador de los aumentos de daño de las pasivas menores (que no se queden en un +4 %).
DAMAGE_MINOR_SCALE = 1.5
DAMAGE_STATS = {"damage", "physical_damage", "elemental_damage", "fire_damage", "cold_damage", "lightning_damage",
                "chaos_damage", "minion_damage", "attack_speed", "cast_speed", "crit_chance", "area_of_effect"}
# Los menores valen más en los clusters grandes.
SIZE_SCALE = {"S": 1.0, "M": 1.0, "L": 1.15, "XL": 1.25, "C": 1.5}
ATTRIBUTE_TRAVEL = 8
ATTR_STAT = {"str": ("strength", "Fuerza"), "dex": ("dexterity", "Destreza"), "int": ("intelligence", "Inteligencia")}
# Piedra angular de cada clase (en el borde de su región; la del Full Stack, junto al centro).
KEYSTONES = {
    "guerrero": ("Modo Seguro", "Arranca con lo mínimo. Lento, feo, pero no se cae.",
                 [("safe_mode", "flat", 1), ("armour", "more", 40), ("movement_speed", "more", -10)]),
    "duelista": ("Código Espagueti", "Nadie sabe hacia dónde va. Ni siquiera tus proyectiles.",
                 [("spaghetti_code", "flat", 2), ("attack_speed", "more", 10), ("damage", "more", -10)]),
    "exploradora": ("Deuda Técnica", "Ya la pagarás. Con intereses.",
                    [("damage", "more", 30), ("life", "more", -20)]),
    "hacker": ("Tipado Estático", "Si compila, funciona. Y nunca te sorprende: ni para bien ni para mal.",
               [("static_typing", "flat", 1), ("damage", "more", 20)]),
    "hechicero": ("Recolector de Basura", "La memoria se libera sola. Cuando le apetece. Y solo si matas algo.",
                  [("garbage_collector", "flat", 3), ("cast_speed", "more", 15)]),
    "templario": ("Microservicios", "Divide y vencerás. O divide y depura doce logs a la vez.",
                  [("microservices", "flat", 1), ("extra_devices", "flat", 1), ("damage", "more", 15, ["automaton"])]),
    "full_stack": ("Monolito", "Un solo binario de 2 GB. Hace de todo. Nadie lo entiende. Funciona.",
                   [("monolith", "flat", 1), ("life", "more", 8)]),
}
# Regiones con una de las piedras angulares extra (identity.keystones), en su anillo C.
EXTRA_KEYSTONE_REGIONS = ["exploradora", "hacker", "hechicero", "templario"]

# Clases: (id, nombre, ángulo, atributos) en el mismo orden que el árbol actual.
CLASSES = [
    ("guerrero", "Técnico de Soporte", -90, "str"),
    ("duelista", "Tester QA", -30, "str/dex"),
    ("exploradora", "Desarrolladora Frontend", 30, "dex"),
    ("hacker", "Ingeniera de Prompts", 90, "dex/int"),
    ("hechicero", "Científico de Datos", 150, "int"),
    ("templario", "Ingeniero DevOps", -150, "int/str"),
]
CENTER = ("full_stack", "Desarrollador Full Stack")
R_START = 1100
# Familias por región, en el orden en que se reparten por sus clusters (corazón primero).
REGION_THEMES = {
    "guerrero": ["vida", "armadura", "fisico", "hemorragia", "resistencias", "vida", "armadura", "fisico", "robo_vida", "legion", "hemorragia", "resistencias", "vida", "fisico", "ignicion", "vida", "versatil", "caos"],
    "duelista": ["velocidad_ataque", "fisico", "critico", "hemorragia", "evasion", "robo_vida", "armadura", "velocidad_ataque", "critico", "movilidad", "fisico", "hemorragia", "evasion", "robo_vida", "atributos", "proyectiles", "vida", "criogenia"],
    "exploradora": ["proyectiles", "evasion", "critico", "toxinas", "movilidad", "velocidad_ataque", "proyectiles", "evasion", "frio", "toxinas", "critico", "movilidad", "proyectiles", "tiempos", "criogenia", "caos", "versatil", "velocidad_ataque"],
    "hacker": ["caos", "toxinas", "critico", "lanzamiento", "evasion", "escudo", "caos", "rayo", "toxinas", "tiempos", "mana", "lanzamiento", "critico", "caos", "sobrecarga", "automatizacion", "frio", "fuego"],
    "hechicero": ["lanzamiento", "fuego", "frio", "rayo", "mana", "escudo", "ignicion", "criogenia", "sobrecarga", "area", "fuego", "frio", "rayo", "mana", "ignicion", "lanzamiento", "caos", "tiempos"],
    "templario": ["automatizacion", "legion", "escudo", "area", "mana", "armadura", "automatizacion", "legion", "fuego", "resistencias", "tiempos", "escudo", "area", "mana", "rayo", "vida", "robo_vida", "atributos"],
}
GATE_THEMES = ["hemorragia", "resistencias", "toxinas", "movilidad", "criogenia", "sobrecarga", "mana", "ignicion", "legion", "automatizacion", "armadura", "atributos"]
INNER_THEMES = ["mana", "vida", "atributos", "resistencias", "escudo", "versatil", "tiempos", "area", "atributos", "mana", "robo_vida", "movilidad"]
CONSTELLATIONS = [("Pentester", "str+dex"), ("Hacker Ético", "dex+int"), ("Arquitecto", "int+str"),
                  ("Full Stack", "str+dex+int"), ("Rubber Duck", "dex+int"), ("Pager de Guardia", "int+str")]

# Anillos de cada región: (radio, [(desplazamiento angular, tamaño)]).
REGION_RINGS = [
    ("A", 1460, [(-19, "M"), (0, "XL"), (19, "M")]),
    ("B", 1800, [(-23, "S"), (-8, "M"), (8, "M"), (23, "S")]),
    ("C", 2140, [(-22, "L"), (-7, "M"), (7, "M"), (22, "L")]),
    ("D", 2480, [(-26, "M"), (-14, "S"), (0, "K"), (14, "S"), (26, "M")]),
    ("E", 2820, [(-9, "M"), (9, "M")]),
]
SIZE_RADIUS = {"S": 70, "M": 105, "L": 150, "XL": 185, "K": 40, "C": 150}
PATH_STEP = 105
NODE_R = {"minor": 10.0, "notable": 22.0, "keystone": 30.0, "start": 30.0, "mastery": 22.0}

nodes = []
edges = set()
clusters = []   # {key, theme, x, y, nodes: [ids], size}


def add(kind, x, y, key, cluster="", theme="", name=""):
    nid = len(nodes)
    nodes.append({"id": nid, "key": key, "kind": kind, "name": name, "x": round(x, 1), "y": round(y, 1),
                  "mods": [], "cluster": cluster, "theme": theme})
    return nid


def link(a, b):
    if a != b:
        edges.add((min(a, b), max(a, b)))


def polar(r, deg):
    a = math.radians(deg)
    return r * math.cos(a), r * math.sin(a)


# --- Formas de cluster: devuelven [(dx, dy, tipo)] y las aristas internas ---

def shape(size, idx):
    """Forma según el tamaño (y una variante por índice, para que no se repitan)."""
    r = SIZE_RADIUS[size]
    pts, inner = [], []
    if size == "S":
        if idx % 2 == 0:   # rombo: 3 menores y el notable en la punta
            pts = [(-r, 0, "minor"), (0, -r * 0.7, "minor"), (0, r * 0.7, "minor"), (r, 0, "notable")]
            inner = [(0, 1), (0, 2), (1, 3), (2, 3)]
        else:              # cadena curva
            pts = [(-r, r * 0.3, "minor"), (-r * 0.35, -r * 0.2, "minor"), (r * 0.35, -r * 0.2, "minor"), (r, r * 0.3, "notable")]
            inner = [(0, 1), (1, 2), (2, 3)]
    elif size == "M":
        if idx % 2 == 0:   # rueda: 6 alrededor y el notable en el centro
            pts = [(0, 0, "notable")] + [(r * math.cos(math.tau * k / 6), r * math.sin(math.tau * k / 6), "minor") for k in range(6)]
            inner = [(k, k % 6 + 1) for k in range(1, 7)] + [(0, 1), (0, 4)]
        else:              # estrella: notable en el centro y 6 radios cortos
            pts = [(0, 0, "notable")]
            for k in range(3):
                a = math.tau * k / 3 + 0.5
                pts += [(r * 0.55 * math.cos(a), r * 0.55 * math.sin(a), "minor"), (r * math.cos(a), r * math.sin(a), "minor")]
            inner = [(0, 1), (1, 2), (0, 3), (3, 4), (0, 5), (5, 6)]
    elif size in ["L", "XL"]:
        # Panal: centro (maestría), anillo de 6 y anillo exterior con 2 notables.
        outer_n = 7 if size == "L" else 10
        pts = [(0, 0, "mastery")]
        pts += [(r * 0.45 * math.cos(math.tau * k / 6), r * 0.45 * math.sin(math.tau * k / 6), "minor") for k in range(6)]
        for k in range(outer_n):
            a = math.tau * k / outer_n + 0.3
            kind = "notable" if k in (outer_n // 4, outer_n // 4 + outer_n // 2) else "minor"
            pts.append((r * math.cos(a), r * math.sin(a), kind))
        inner = [(k, k % 6 + 1) for k in range(1, 7)] + [(0, 1), (0, 4)]
        for k in range(outer_n):
            inner.append((7 + k, 7 + (k + 1) % outer_n))
        # Unir los dos anillos por tres radios.
        for k in range(3):
            o = 7 + (k * outer_n) // 3
            best = min(range(1, 7), key=lambda i: (pts[i][0] - pts[o][0]) ** 2 + (pts[i][1] - pts[o][1]) ** 2)
            inner.append((best, o))
        # El exterior no se cierra del todo: un hueco por donde se entra.
        inner = [e for e in inner if not (e == (7 + outer_n - 1, 7) or e == (6 + outer_n, 7))]
    elif size == "C":
        # Constelación: estrella de 5 puntas (contorno) con el notable en el centro.
        pts = [(0, 0, "notable")]
        for k in range(10):
            a = -math.pi / 2 + math.tau * k / 10
            rr = r if k % 2 == 0 else r * 0.45
            pts.append((rr * math.cos(a), rr * math.sin(a), "minor"))
        inner = [(1 + k, 1 + (k + 1) % 10) for k in range(9)] + [(0, 2), (0, 6)]
    elif size == "K":
        pts = [(-r * 1.6, 0, "minor"), (0, 0, "keystone")]
        inner = [(0, 1)]
    return pts, inner


def build_cluster(key, theme, cx, cy, size, idx, rot=0.0):
    pts, inner = shape(size, idx)
    ids = []
    ca, sa = math.cos(rot), math.sin(rot)
    for k, (dx, dy, kind) in enumerate(pts):
        x = cx + dx * ca - dy * sa
        y = cy + dx * sa + dy * ca
        ids.append(add(kind, x, y, "%s:%d" % (key, k), key, theme))
    for a, b in inner:
        link(ids[a], ids[b])
    clusters.append({"key": key, "theme": theme, "x": cx, "y": cy, "nodes": ids, "size": size})
    return clusters[-1]


# --- Centro ---
center_start = add("start", 0, 0, "start.full_stack", name=CENTER[1])
nodes[center_start]["class_id"] = CENTER[0]
hub = []
for k in range(18):
    x, y = polar(330, -90 + 20 * k)
    hub.append(add("minor", x, y, "hub:%d" % k, "", "atributos"))
for k in range(18):
    link(hub[k], hub[(k + 1) % 18])
for k in range(0, 18, 3):
    link(center_start, hub[k]) if k % 6 == 0 else None
inner_clusters = []
for k in range(12):
    ang = -90 + 30 * k
    size = "M" if k % 2 == 0 else ("K" if k == 1 else "S")   # junto al centro, la piedra del Full Stack
    x, y = polar(720, ang)
    inner_clusters.append(build_cluster("centro.I%d" % k, INNER_THEMES[k] if size != "K" else "", x, y, size, k, math.radians(ang)))

# --- Regiones de clase ---
starts = {}
region_clusters = {}
for ci, (cid, cname, ang, attrs) in enumerate(CLASSES):
    x, y = polar(R_START, ang)
    sid = add("start", x, y, "start." + cid, name=cname)
    nodes[sid]["class_id"] = cid
    starts[cid] = sid
    themes = REGION_THEMES[cid]
    t = 0
    lst = []
    for ring, radius, slots in REGION_RINGS:
        for si, (off, size) in enumerate(slots):
            cx, cy = polar(radius, ang + off)
            theme = themes[t % len(themes)] if size != "K" else ""
            t += 1 if size != "K" else 0
            c = build_cluster("%s.%s%d" % (cid, ring, si), theme, cx, cy, size, si + ci, math.radians(ang + off))
            c["region"] = cid
            if ring == "A" and size == "XL":
                c["heart"] = True
            lst.append(c)
    region_clusters[cid] = lst

# --- Puertas entre regiones vecinas y constelaciones ---
gates = []
for ci, (cid, _n, ang, _a) in enumerate(CLASSES):
    border = ang + 30
    for gi, radius in enumerate([1300, 2050]):
        x, y = polar(radius * 0.94, border)
        gates.append(build_cluster("puerta.%s%d" % (cid, gi), GATE_THEMES[(ci * 2 + gi) % len(GATE_THEMES)], x, y, "M", ci + gi, math.radians(border)))
    x, y = polar(2760, border)
    name, req = CONSTELLATIONS[ci]
    c = build_cluster("constelacion.%d" % ci, "", x, y, "C", ci, math.radians(border + 90))
    c["constellation"] = name
    c["requires"] = req

# --- Conexiones: grafo de Gabriel sobre los centros (más los inicios) ---
points = []   # (x, y, ref) ref = ("cluster", c) | ("start", id)
for c in clusters:
    points.append((c["x"], c["y"], ("cluster", c)))
for cid, sid in starts.items():
    points.append((nodes[sid]["x"], nodes[sid]["y"], ("start", sid)))
# El centro no entra: se une por su anillo de viaje (más abajo).


def gabriel_pairs(pts, max_len):
    out = []
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            ax, ay = pts[i][0], pts[i][1]
            bx, by = pts[j][0], pts[j][1]
            d2 = (ax - bx) ** 2 + (ay - by) ** 2
            if d2 > max_len ** 2:
                continue
            mx, my = (ax + bx) / 2, (ay + by) / 2
            r2 = d2 / 4
            ok = True
            for k in range(len(pts)):
                if k in (i, j):
                    continue
                if (pts[k][0] - mx) ** 2 + (pts[k][1] - my) ** 2 < r2:
                    ok = False
                    break
            if ok:
                out.append((i, j))
    return out


def ref_nodes(ref):
    return ref[1]["nodes"] if ref[0] == "cluster" else [ref[1]]


def entry(ref, toward):
    """Nodo del cluster más cercano a `toward` (no la maestría ni la piedra angular)."""
    cand = [n for n in ref_nodes(ref) if nodes[n]["kind"] not in ("mastery",)]
    return min(cand, key=lambda n: (nodes[n]["x"] - toward[0]) ** 2 + (nodes[n]["y"] - toward[1]) ** 2)


def travel_path(a, b, key):
    ax, ay, bx, by = nodes[a]["x"], nodes[a]["y"], nodes[b]["x"], nodes[b]["y"]
    d = math.hypot(bx - ax, by - ay)
    steps = max(1, int(d // PATH_STEP))
    prev = a
    for k in range(1, steps):
        t = k / steps
        n = add("minor", ax + (bx - ax) * t, ay + (by - ay) * t, "via:%s:%d" % (key, k), "", "atributos")
        link(prev, n)
        prev = n
    link(prev, b)


start_ids = set(starts.values()) | {center_start}
for i, j in gabriel_pairs(points, 820):
    ri, rj = points[i][2], points[j][2]
    # Los inicios de clase solo conectan hacia fuera (a su región), nunca hacia el centro.
    for r_s, other in ((ri, points[j]), (rj, points[i])):
        if r_s[0] == "start" and r_s[1] in starts.values():
            sx, sy = nodes[r_s[1]]["x"], nodes[r_s[1]]["y"]
            own = next(cid for cid, sid in starts.items() if sid == r_s[1])
            ref = other[2]
            # Solo hacia fuera y a clusters de su propia región (ni puertas ni el centro).
            if math.hypot(other[0], other[1]) < math.hypot(sx, sy) - 1 or ref[0] != "cluster" or ref[1].get("region") != own:
                break
    else:
        ea = entry(ri, (points[j][0], points[j][1]))
        eb = entry(rj, (points[i][0], points[i][1]))
        ka = ri[1]["key"] if ri[0] == "cluster" else nodes[ri[1]]["key"]
        kb = rj[1]["key"] if rj[0] == "cluster" else nodes[rj[1]]["key"]
        travel_path(ea, eb, "%s-%s" % (ka, kb))
# El centro se une al anillo de viaje y este a los clusters interiores.
for c in inner_clusters:
    h = min(hub, key=lambda n: (nodes[n]["x"] - c["x"]) ** 2 + (nodes[n]["y"] - c["y"]) ** 2)
    travel_path(h, entry(("cluster", c), (nodes[h]["x"], nodes[h]["y"])), "hub-%s" % c["key"])

# --- Comprobaciones ---
adj = {n["id"]: set() for n in nodes}
for a, b in edges:
    adj[a].add(b)
    adj[b].add(a)
seen = {center_start}
stack = [center_start]
while stack:
    cur = stack.pop()
    for nb in adj[cur]:
        if nb not in seen:
            seen.add(nb)
            stack.append(nb)


def overlaps():
    out = 0
    cell = {}
    for n in nodes:
        cell.setdefault((int(n["x"] // 80), int(n["y"] // 80)), []).append(n)
    for n in nodes:
        cx, cy = int(n["x"] // 80), int(n["y"] // 80)
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for m in cell.get((cx + dx, cy + dy), []):
                    if m["id"] <= n["id"]:
                        continue
                    if math.hypot(n["x"] - m["x"], n["y"] - m["y"]) < NODE_R[n["kind"]] + NODE_R[m["kind"]] + 4:
                        out += 1
    return out


kinds = {}
for n in nodes:
    kinds[n["kind"]] = kinds.get(n["kind"], 0) + 1
sizes = {}
for c in clusters:
    sizes[c["size"]] = sizes.get(c["size"], 0) + 1
theme_count = {}
for c in clusters:
    if c["theme"]:
        theme_count[c["theme"]] = theme_count.get(c["theme"], 0) + 1

# Las piedras angulares no son de ningún cluster (como en el árbol de siempre).
for c in clusters:
    if c["size"] == "K":
        for nid in c["nodes"]:
            nodes[nid]["cluster"] = ""

# --- Efectos: cada nodo según su papel ---

def scaled(mods, factor):
    out = []
    for md in mods:
        md = dict(md)
        if md["stat"] in DAMAGE_STATS and md["type"] == "increased":
            md["value"] = round(md["value"] * DAMAGE_MINOR_SCALE)
        if factor != 1.0 and md["type"] in ("flat", "increased"):
            md["value"] = round(md["value"] * factor, 1) if isinstance(md["value"], float) else round(md["value"] * factor)
        out.append(md)
    return out


def ks_mods(raw):
    out = []
    for entry in raw:
        md = {"stat": entry[0], "type": entry[1], "value": entry[2]}
        if len(entry) > 3:
            md["tags"] = entry[3]
        out.append(md)
    return out


def attr_at(x, y):
    """Atributo de los nodos de viaje: el de la clase más cercana (las mixtas alternan)."""
    if math.hypot(x, y) < 520:
        return ["str", "dex", "int"][int((math.degrees(math.atan2(y, x)) + 360) // 40) % 3]
    best = min(CLASSES, key=lambda c: abs(((math.degrees(math.atan2(y, x)) - c[2] + 540) % 360) - 180))
    parts = best[3].split("/")
    return parts[int(abs(x + y)) // 97 % len(parts)]


minor_counter = {}
notable_counter = {}
name_counter = {}
for c in clusters:
    theme = c["theme"]
    if theme:
        names = THEMES[theme]["cluster_names"]
        k = name_counter.get(theme, 0)
        name_counter[theme] = k + 1
        c["name"] = "%s: %s" % (THEMES[theme]["name"], names[k % len(names)])
    factor = SIZE_SCALE.get(c["size"], 1.0)
    for nid in c["nodes"]:
        n = nodes[nid]
        if n["kind"] == "minor" and theme:
            pool = THEMES[theme]["minors"]
            k = minor_counter.get(theme, 0)
            minor_counter[theme] = k + 1
            n["name"], mods = pool[k % len(pool)]
            n["mods"] = scaled(mods, factor)
        elif n["kind"] == "notable" and theme:
            pool = THEMES[theme]["notables"]
            k = notable_counter.get(theme, 0)
            notable_counter[theme] = k + 1
            n["name"], n["flavor"], n["mods"] = pool[k % len(pool)][0], pool[k % len(pool)][1], pool[k % len(pool)][2]
            n["icon"] = theme
        elif n["kind"] == "mastery":
            # Maestría: elegir 1 de 3 bonos (los tres primeros notables de su familia).
            pool = THEMES[theme]["notables"]
            n["kind"] = "notable"
            n["name"] = "Maestría de %s" % THEMES[theme]["name"]
            n["icon"] = theme
            n["choices"] = [{"name": pool[k][0], "mods": pool[k][2]} for k in range(min(3, len(pool)))]

# Notable de estilo de cada clase: el primer notable de su corazón (el del Full Stack, en el anillo interior).
for cid, sdef in IDENTITY.get("style", {}).items():
    if cid == "full_stack":
        target = next(c for c in clusters if c["key"] == "centro.I0")
    else:
        target = next(c for c in clusters if c.get("region") == cid and c.get("heart"))
    nid = next(n for n in target["nodes"] if nodes[n]["kind"] == "notable" and not nodes[n].get("choices"))
    nodes[nid].update({"name": sdef["name"], "flavor": sdef["flavor"], "mods": sdef["mods"], "style": True})

# Piedras angulares: la de cada clase en su hueco K y las extra en el anillo C de cuatro regiones.
for c in clusters:
    if c["size"] != "K":
        continue
    cid = c.get("region", "full_stack")
    name, flavor, raw = KEYSTONES[cid]
    for nid in c["nodes"]:
        n = nodes[nid]
        if n["kind"] == "keystone":
            n.update({"name": name, "flavor": flavor, "mods": ks_mods(raw), "icon": "ks_" + cid})
        else:
            stat, label = ATTR_STAT[attr_at(n["x"], n["y"])]
            n.update({"name": label, "mods": [{"stat": stat, "type": "flat", "value": ATTRIBUTE_TRAVEL}], "theme": "atributos"})
for cid, kdef in zip(EXTRA_KEYSTONE_REGIONS, IDENTITY.get("keystones", [])):
    target = next(c for c in clusters if c["key"] == "%s.C0" % cid)
    notables = [n for n in target["nodes"] if nodes[n]["kind"] == "notable" and not nodes[n].get("choices")]
    n = nodes[notables[-1]]
    n.update({"kind": "keystone", "name": kdef["name"], "flavor": kdef["flavor"], "mods": kdef["mods"], "icon": "versatil"})

# Constelaciones: piden atributos y sus nodos dan más.
for c in clusters:
    if c["size"] != "C":
        continue
    cdef = IDENTITY["constellations"][c["constellation"]]
    req = cdef["requires"]
    c["name"] = "Constelación: %s" % c["constellation"]
    attrs = [a for a, (stat, _l) in ATTR_STAT.items() if stat in req]
    for k, nid in enumerate(c["nodes"]):
        n = nodes[nid]
        n["requires"] = req
        n["constellation"] = c["name"]
        if n["kind"] == "notable":
            n.update({"name": c["constellation"], "flavor": cdef["flavor"], "mods": cdef["mods"], "icon": "atributos"})
        elif k % 2 == 0:
            n.update({"name": "Daño", "mods": [{"stat": "damage", "type": "increased", "value": 9}]})
        else:
            stat, label = ATTR_STAT[attrs[k % len(attrs)]]
            n.update({"name": label, "mods": [{"stat": stat, "type": "flat", "value": 12}]})

# Viaje: atributo de la región.
for n in nodes:
    if n["kind"] == "minor" and not n["mods"]:
        stat, label = ATTR_STAT[attr_at(n["x"], n["y"])]
        n.update({"name": label, "mods": [{"stat": stat, "type": "flat", "value": ATTRIBUTE_TRAVEL}], "theme": "atributos", "cluster": n["cluster"]})

missing = [n["key"] for n in nodes if n["kind"] in ("minor", "notable", "keystone") and not n["mods"] and not n.get("choices")]
assert not missing, "nodos sin efecto: %s" % missing[:5]
via = sum(1 for n in nodes if n["key"].startswith("via:") or n["key"].startswith("hub:"))

export_nodes = []
for n in nodes:
    e = {k: v for k, v in n.items() if v not in ("", None, [], {}, False) or k in ("mods", "id", "x", "y")}
    export_nodes.append(e)
themes_out = {k: {"name": v["name"], "color": v["color"]} for k, v in THEMES.items()}
clusters_out = [{"id": c["key"], "theme": c["theme"], "x": round(c["x"], 1), "y": round(c["y"], 1), "radius": SIZE_RADIUS[c["size"]] + 30,
                 "size": c["size"], "name": c.get("name", c["key"])} for c in clusters if c["size"] != "K"]
OUT.write_text(json.dumps({"version": TREE_VERSION, "themes": themes_out, "clusters": clusters_out,
                           "nodes": export_nodes, "edges": sorted([list(e) for e in edges])}, ensure_ascii=False, indent=0), encoding="utf-8")
print("nodos: %d  %s  (viaje: %d)" % (len(nodes), kinds, via))
print("clusters: %d  %s" % (len(clusters), sizes))
print("familias: %s" % dict(sorted(theme_count.items(), key=lambda kv: -kv[1])))
print("aristas: %d  conectados: %d/%d  solapes: %d" % (len(edges), len(seen), len(nodes), overlaps()))