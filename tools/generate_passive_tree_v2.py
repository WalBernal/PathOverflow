"""Árbol pasivo 2.0 (T88): prototipo de DISPOSICIÓN (sin efectos todavía).

Uso:  python tools/generate_passive_tree_v2.py
Escribe data/passive_tree_v2_layout.json, con el mismo formato que
passive_tree.json (lo carga PassiveTree.load_from_json) pero que el juego NO usa:
sirve para ver y aprobar la forma antes de llenarla (T89 añade los efectos y la
migración). Ver docs/arbol_2.md.

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
OUT = ROOT / "data" / "passive_tree_v2_layout.json"
THEMES = json.loads((ROOT / "data" / "passive_themes.json").read_text(encoding="utf-8"))["themes"]

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
R_START = 1150
# Familias por región, en el orden en que se reparten por sus clusters (corazón primero).
REGION_THEMES = {
    "guerrero": ["vida", "armadura", "fisico", "hemorragia", "resistencias", "vida", "armadura", "fisico", "robo_vida", "legion", "hemorragia", "resistencias", "vida", "fisico"],
    "duelista": ["velocidad_ataque", "fisico", "critico", "hemorragia", "evasion", "robo_vida", "armadura", "velocidad_ataque", "critico", "movilidad", "fisico", "hemorragia", "evasion", "robo_vida"],
    "exploradora": ["proyectiles", "evasion", "critico", "toxinas", "movilidad", "velocidad_ataque", "proyectiles", "evasion", "frio", "toxinas", "critico", "movilidad", "proyectiles", "tiempos"],
    "hacker": ["caos", "toxinas", "critico", "lanzamiento", "evasion", "escudo", "caos", "rayo", "toxinas", "tiempos", "mana", "lanzamiento", "critico", "caos"],
    "hechicero": ["lanzamiento", "fuego", "frio", "rayo", "mana", "escudo", "ignicion", "criogenia", "sobrecarga", "area", "fuego", "frio", "rayo", "mana"],
    "templario": ["automatizacion", "legion", "escudo", "area", "mana", "armadura", "automatizacion", "legion", "fuego", "resistencias", "tiempos", "escudo", "area", "mana"],
}
GATE_THEMES = ["hemorragia", "resistencias", "toxinas", "movilidad", "criogenia", "sobrecarga", "mana", "ignicion", "legion", "automatizacion", "armadura", "atributos"]
INNER_THEMES = ["mana", "vida", "atributos", "resistencias", "escudo", "versatil", "tiempos", "area", "atributos", "mana", "robo_vida", "movilidad"]
CONSTELLATIONS = [("Pentester", "str+dex"), ("Hacker Ético", "dex+int"), ("Arquitecto", "int+str"),
                  ("Full Stack", "str+dex+int"), ("Rubber Duck", "dex+int"), ("Pager de Guardia", "int+str")]

# Anillos de cada región: (radio, [(desplazamiento angular, tamaño)]).
REGION_RINGS = [
    ("A", 1520, [(-19, "M"), (0, "XL"), (19, "M")]),
    ("B", 1900, [(-23, "S"), (-8, "M"), (8, "M"), (23, "S")]),
    ("C", 2300, [(-22, "L"), (-7, "M"), (7, "M"), (22, "L")]),
    ("D", 2700, [(-16, "S"), (0, "K"), (16, "S")]),
]
SIZE_RADIUS = {"S": 70, "M": 105, "L": 150, "XL": 185, "K": 40, "C": 150}
PATH_STEP = 85
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
    size = "M" if k % 2 == 0 else "S"
    x, y = polar(720, ang)
    inner_clusters.append(build_cluster("centro.I%d" % k, INNER_THEMES[k], x, y, size, k, math.radians(ang)))

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
        x, y = polar(radius, border)
        gates.append(build_cluster("puerta.%s%d" % (cid, gi), GATE_THEMES[(ci * 2 + gi) % len(GATE_THEMES)], x, y, "M", ci + gi, math.radians(border)))
    x, y = polar(2950, border)
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
            if math.hypot(other[0], other[1]) < math.hypot(sx, sy) - 1:
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

# El juego no tiene tipo «maestría» suelto: en la disposición se exporta como notable.
export_nodes = []
for n in nodes:
    e = dict(n)
    if e["kind"] == "mastery":
        e["kind"] = "notable"
        e["name"] = "Maestría"
    export_nodes.append(e)
themes_out = {k: {"name": v["name"], "color": v["color"]} for k, v in THEMES.items()}
clusters_out = [{"id": c["key"], "theme": c["theme"], "x": round(c["x"], 1), "y": round(c["y"], 1), "size": c["size"], "radius": SIZE_RADIUS[c["size"]] + 30,
                 "name": c.get("constellation", c["key"]), "heart": c.get("heart", False), "requires": c.get("requires", "")} for c in clusters]
OUT.write_text(json.dumps({"version": 8, "layout_only": True, "themes": themes_out, "clusters": clusters_out,
                           "nodes": export_nodes, "edges": sorted([list(e) for e in edges])}, ensure_ascii=False), encoding="utf-8")
print("nodos: %d  %s" % (len(nodes), kinds))
print("clusters: %d  %s" % (len(clusters), sizes))
print("familias: %s" % dict(sorted(theme_count.items(), key=lambda kv: -kv[1])))
print("aristas: %d  conectados: %d/%d  solapes: %d" % (len(edges), len(seen), len(nodes), overlaps()))
