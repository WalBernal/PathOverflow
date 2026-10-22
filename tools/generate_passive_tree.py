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
TREE_VERSION = 7
# Multiplicador de los aumentos de daño de las pasivas menores (que no se queden
# en un +4 % que no se nota).
DAMAGE_MINOR_SCALE = 1.5
ATTRIBUTE_TRAVEL = 12
DAMAGE_STATS = {"damage", "physical_damage", "elemental_damage", "fire_damage", "cold_damage", "lightning_damage",
                "chaos_damage", "minion_damage", "attack_speed", "cast_speed", "crit_chance", "area_of_effect"}

# id, nombre, atributos, temáticas de los 4 clusters cercanos, de los 4 lejanos y del cluster interior.
# Reparto de temáticas por vecindad. Orden alrededor del anillo: guerrero, duelista,
# exploradora, hacker, hechicero, templario (y el Full Stack en el centro, pegado a
# las puertas del templario). Cada temática de estados / aliados tiene 3-5 clusters
# y están del lado de las clases con ascendencias de ese tipo:
#   hemorragia      guerrero, duelista (puerta 0)
#   criogenia       exploradora, hechicero (puerta 1)
#   toxinas         exploradora, hacker (puerta 2)
#   sobrecarga      hacker, hechicero, templario (puente 3)
#   ignicion        hechicero, templario SRE (puente 4)
#   automatizacion  templario (robótica) y la puerta 5 hacia el centro (Full Stack, Tech Lead)
#   legion          templario (auras y SRE), puerta 4 y puente 5: aliados, reserva y auras
CLASSES = [
    ("guerrero", "Técnico de Soporte", ["str"],
     ["vida", "armadura", "hemorragia", "area"], ["robo_vida", "hemorragia", "armadura", "fisico"], "resistencias"),
    ("duelista", "Tester QA", ["str", "dex"],
     ["fisico", "velocidad_ataque", "evasion", "robo_vida"], ["critico", "hemorragia", "fisico", "velocidad_ataque"], "movilidad"),
    ("exploradora", "Desarrolladora Frontend", ["dex"],
     ["proyectiles", "criogenia", "evasion", "critico"], ["criogenia", "toxinas", "proyectiles", "toxinas"], "movilidad"),
    ("hacker", "Ingeniera de Prompts", ["dex", "int"],
     ["critico", "toxinas", "evasion", "rayo"], ["lanzamiento", "sobrecarga", "escudo", "tiempos"], "tiempos"),
    ("hechicero", "Científico de Datos", ["int"],
     ["rayo", "ignicion", "criogenia", "lanzamiento"], ["escudo", "fuego", "frio", "sobrecarga"], "mana"),
    ("templario", "Ingeniero DevOps", ["int", "str"],
     ["automatizacion", "legion", "vida", "automatizacion"], ["sobrecarga", "armadura", "legion", "ignicion"], "automatizacion"),
]
CENTER_CLASS = ("full_stack", "Desarrollador Full Stack")
GATE_THEMES = ["hemorragia", "criogenia", "toxinas", "resistencias", "legion", "automatizacion"]
BRIDGE_THEMES = ["resistencias", "atributos", "atributos", "sobrecarga", "ignicion", "legion"]

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
    "templario": ("Orquestación con Kubernetes", "Ya no programas: orquestas. Las máquinas hacen el resto.",
                  [("damage", "more", 40, ["automaton"]), ("extra_minions", "flat", 1), ("extra_devices", "flat", 1),
                   ("life", "more", -20)]),
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
T1_DIST, T1_R = 390, 75
T2_DIST, T2_R = 725, 88
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


def keystone_mods(raw):
    """(stat, tipo, valor[, tags]) -> mods del JSON."""
    out = []
    for entry in raw:
        md = {"stat": entry[0], "type": entry[1], "value": entry[2]}
        if len(entry) > 3:
            md["tags"] = entry[3]
        out.append(md)
    return out


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
    scaled = []
    for md in mods:
        md = dict(md)
        if md["stat"] in DAMAGE_STATS and md["type"] == "increased":
            md["value"] = round(md["value"] * DAMAGE_MINOR_SCALE)
        scaled.append(md)
    return add("minor", name, x, y, scaled, cluster=cluster, theme=theme)


def notable(theme, x, y, cluster):
    pool = THEMES[theme]["notables"]
    k = _notable_counter.get(theme, 0)
    _notable_counter[theme] = k + 1
    name, flavor, mods = pool[k % len(pool)]
    return add("notable", name, x, y, mods, flavor, cluster=cluster, theme=theme, icon=theme)


def travel(attr, x, y):
    stat, label = ATTR_STAT[attr]
    return add("minor", label, x, y, [{"stat": stat, "type": "flat", "value": ATTRIBUTE_TRAVEL}], theme="atributos")


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


# --- Clusters con forma (estilo PoE 2): cada temática dibuja su símbolo ---
# Coordenadas normalizadas (-1..1, y hacia abajo). Cada plantilla da puntos,
# aristas y qué nodo es el notable. Las de contorno se remuestrean a `count`.

def _resample(pts, n, closed):
    """n puntos repartidos a distancia igual a lo largo de una polilínea."""
    seq = pts + ([pts[0]] if closed else [])
    seg = [math.dist(seq[i], seq[i + 1]) for i in range(len(seq) - 1)]
    total = sum(seg)
    out = []
    steps = n if closed else n - 1
    for k in range(n):
        d = total * k / steps
        i = 0
        while i < len(seg) - 1 and d > seg[i]:
            d -= seg[i]
            i += 1
        t = d / seg[i] if seg[i] else 0.0
        a, b = seq[i], seq[i + 1]
        out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return out


def _outline(pts, n, closed=True, notable_at=(0.0, 0.0)):
    """Contorno remuestreado + notable en `notable_at`, unido arriba y abajo."""
    ring = _resample(pts, n - 1, closed)
    m = len(ring)
    edges = [(i, i + 1) for i in range(m - 1)] + ([(m - 1, 0)] if closed else [])
    top = min(range(m), key=lambda i: ring[i][1])
    bottom = max(range(m), key=lambda i: ring[i][1])
    nodes = ring + [notable_at]
    edges += [(m, top), (m, bottom)]
    return nodes, edges, m, (ring if closed else None)


def _curve(fn, steps=40):
    return [fn(2 * math.pi * k / steps) for k in range(steps)]


def shape_template(theme, count):
    if theme == "vida":            # corazón
        pts = _curve(lambda t: (math.sin(t) ** 3, -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 16.0))
        return _outline(pts, count, True, (0.0, 0.05))
    if theme == "fuego":           # llama
        pts = _curve(lambda t: (math.sin(t) * math.sin(t / 2) * 0.85 + 0.12 * math.sin(3 * t) * math.sin(t / 2), -math.cos(t)))
        return _outline(pts, count, True, (0.0, 0.35))
    if theme == "mana":            # gota
        pts = _curve(lambda t: (math.sin(t) * math.sin(t / 2) * 0.9, -math.cos(t)))
        return _outline(pts, count, True, (0.0, 0.4))
    if theme == "armadura":        # escudo
        return _outline([(-0.85, -0.85), (0.0, -1.0), (0.85, -0.85), (0.8, 0.15), (0.0, 1.0), (-0.8, 0.15)], count, True, (0.0, -0.1))
    if theme == "escudo":          # hexágono (burbuja de energía)
        return _outline([(math.cos(math.radians(30 + 60 * k)), math.sin(math.radians(30 + 60 * k))) for k in range(6)], count, True)
    if theme == "area":            # estrella de cinco puntas
        pts = [(math.cos(math.radians(-90 + 36 * k)) * (1.0 if k % 2 == 0 else 0.45),
                math.sin(math.radians(-90 + 36 * k)) * (1.0 if k % 2 == 0 else 0.45)) for k in range(10)]
        return _outline(pts, max(count, 9), True, (0.0, 0.05))
    if theme == "resistencias":    # prisma
        return _outline([(0.0, -1.0), (0.95, 0.75), (-0.95, 0.75)], count, True, (0.0, 0.2))
    if theme == "rayo":            # rayo en zigzag (abierto, el notable en la punta): sus vértices + puntos intermedios
        pts = [(-0.15, -1.0), (0.45, -0.3), (-0.1, -0.15), (0.5, 0.55), (0.05, 0.4), (0.3, 1.0)]
        while len(pts) < count:
            k = max(range(len(pts) - 1), key=lambda q: math.dist(pts[q], pts[q + 1]))
            pts.insert(k + 1, ((pts[k][0] + pts[k + 1][0]) / 2.0, (pts[k][1] + pts[k + 1][1]) / 2.0))
        return pts, [(i, i + 1) for i in range(len(pts) - 1)], len(pts) - 1, None
    if theme == "sobrecarga":      # rayo clásico de cuatro vértices, con puntos intermedios en los tramos largos
        pts = [(0.3, -1.0), (-0.45, 0.05), (0.15, 0.05), (-0.3, 1.0)]
        while len(pts) < count:
            k = max(range(len(pts) - 1), key=lambda q: math.dist(pts[q], pts[q + 1]))
            pts.insert(k + 1, ((pts[k][0] + pts[k + 1][0]) / 2.0, (pts[k][1] + pts[k + 1][1]) / 2.0))
        return pts, [(i, i + 1) for i in range(len(pts) - 1)], len(pts) - 1, None
    if theme == "caos":            # espiral
        pts = [(math.cos(a) * r, math.sin(a) * r) for a, r in ((k * 1.25, 1.0 - k * 0.12) for k in range(count))]
        return pts, [(i, i + 1) for i in range(len(pts) - 1)], len(pts) - 1, None
    if theme == "evasion":         # pluma / media luna
        pts = [(math.cos(a) * 0.95, math.sin(a) * 0.95 * 0.75 + 0.1) for a in (math.radians(200 + 140 * k / (count - 1)) for k in range(count))]
        return pts, [(i, i + 1) for i in range(len(pts) - 1)], len(pts) - 1, None
    if theme == "frio":            # copo de nieve: centro + 6 brazos
        nodes = [(math.cos(math.radians(-90 + 60 * k)), math.sin(math.radians(-90 + 60 * k))) for k in range(6)] + [(0.0, 0.0)]
        return nodes, [(6, k) for k in range(6)], 6, None
    if theme == "critico":         # mira: aro de 4, cruz interior y centro
        outer = [(0.0, -1.0), (1.0, 0.0), (0.0, 1.0), (-1.0, 0.0)]
        inner = [(x * 0.48, y * 0.48) for x, y in outer]
        nodes = outer + inner + [(0.0, 0.0)]
        edges = [(i, (i + 1) % 4) for i in range(4)] + [(i, i + 4) for i in range(4)] + [(i + 4, 8) for i in range(4)]
        return nodes, edges, 8, None
    if theme == "proyectiles":     # flecha: astil, punta y aletas
        shaft = [(-0.9 + 1.6 * k / 4, 0.75 - 1.5 * k / 4) for k in range(5)]
        tip = shaft[-1]
        nodes = shaft + [(tip[0] - 0.55, tip[1] - 0.05), (tip[0] + 0.05, tip[1] + 0.55)]
        edges = [(i, i + 1) for i in range(4)] + [(4, 5), (4, 6)]
        return nodes, edges, 4, None
    if theme == "fisico":          # martillo: cabeza y mango
        nodes = [(-0.9, -0.7), (-0.3, -0.7), (0.3, -0.7), (0.9, -0.7), (0.0, -0.05), (0.0, 0.5), (0.0, 1.0)]
        edges = [(0, 1), (1, 2), (2, 3), (1, 4), (2, 4), (4, 5), (5, 6)]
        return nodes, edges, 4, None
    if theme in ("velocidad_ataque", "movilidad"):   # doble chevron ">>"
        nodes = [(-0.9, -0.8), (-0.3, 0.0), (-0.9, 0.8), (0.1, -0.8), (0.7, 0.0), (0.1, 0.8)]
        edges = [(0, 1), (1, 2), (3, 4), (4, 5), (1, 4)]
        return nodes, edges, 4, None
    if theme == "tiempos":         # reloj de arena
        nodes = [(-0.7, -0.9), (0.0, -0.9), (0.7, -0.9), (0.0, 0.0), (0.7, 0.9), (0.0, 0.9), (-0.7, 0.9)]
        edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 3), (3, 0)]
        return nodes, edges, 3, None
    if theme == "lanzamiento":     # libro abierto
        nodes = [(0.0, -0.55), (-0.95, -0.8), (-0.95, 0.55), (0.0, 0.8), (0.95, 0.55), (0.95, -0.8), (0.0, 0.1)]
        edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 6), (6, 3)]
        return nodes, edges, 6, None
    if theme == "ignicion":        # hoguera: llama de tres lenguas
        return _outline([(0.0, -1.0), (0.42, -0.4), (0.62, -0.75), (0.74, 0.1), (0.45, 0.85), (-0.45, 0.85),
                         (-0.74, 0.1), (-0.62, -0.75), (-0.42, -0.4)], count, True, (0.0, 0.05))
    if theme == "criogenia":       # cristal de hielo hexagonal con núcleo
        return _outline([(math.cos(math.radians(-90 + 60 * k)), math.sin(math.radians(-90 + 60 * k))) for k in range(6)], count, True)
    if theme == "toxinas":         # matraz de laboratorio
        return _outline([(-0.25, -1.0), (0.25, -1.0), (0.25, -0.35), (0.85, 0.85), (-0.85, 0.85), (-0.25, -0.35)], count, True, (0.0, 0.35))
    if theme == "hemorragia":      # gota de sangre
        return _outline([(0.0, -1.0), (0.45, -0.2), (0.6, 0.35), (0.35, 0.85), (-0.35, 0.85), (-0.6, 0.35), (-0.45, -0.2)], count, True, (0.0, 0.35))
    if theme == "automatizacion":  # engranaje
        pts = [(math.cos(math.radians(-90 + 22.5 * k)) * (1.0 if k % 2 == 0 else 0.72),
                math.sin(math.radians(-90 + 22.5 * k)) * (1.0 if k % 2 == 0 else 0.72)) for k in range(16)]
        return _outline(pts, max(count, 8), True, (0.0, 0.0))
    if theme == "legion":          # estandarte: asta y bandera triangular
        nodes = [(-0.55, 1.0), (-0.55, 0.35), (-0.55, -0.3), (-0.55, -1.0), (0.1, -0.85), (0.75, -0.55), (0.1, -0.2)]
        edges = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 2)]
        return nodes, edges, 5, None
    if theme == "robo_vida":       # colmillos
        nodes = [(-1.0, -0.7), (-0.6, 0.85), (-0.2, -0.45), (0.2, -0.45), (0.6, 0.85), (1.0, -0.7), (0.0, -0.95)]
        edges = [(0, 1), (1, 2), (2, 6), (6, 3), (3, 4), (4, 5)]
        return nodes, edges, 6, None
    return None


MIN_GAP = 42.0   # separación mínima entre dos nodos de un mismo cluster (menores miden 10 px de radio, notables 22)


def _min_dist(pts):
    return min(math.dist(a, b) for i, a in enumerate(pts) for b in pts[i + 1:])


def fitted_template(theme, count, radius):
    """Plantilla sin nodos encimados: primero agranda el cluster hasta un 25 %, y si no basta,
    usa menos nodos (solo las siluetas de contorno lo admiten). Devuelve (plantilla, radio)."""
    c = count
    last_len = -1
    while c >= 5:
        tpl = shape_template(theme, c)
        pts = tpl[0]
        scale = max(1.0, MIN_GAP / (_min_dist(pts) * radius))
        if scale <= 1.25:
            return tpl, radius * scale
        if len(pts) == last_len:
            break   # plantilla de nodos fijos: no mejora con menos nodos
        last_len = len(pts)
        c -= 1
    # Sin solución cómoda: la variante con menos nodos, lo más grande que haga falta.
    tpl = shape_template(theme, 5)
    return tpl, radius * min(1.9, max(1.0, MIN_GAP / (_min_dist(tpl[0]) * radius)))


def shape_cluster(theme, cx, cy, radius, count, entry_deg):
    """Cluster con la forma de su temática. Devuelve (entrada, salida, ids)."""
    (nodes, edges, notable_i, fill), radius = fitted_template(theme, count, radius)
    cid = new_cluster(theme, cx, cy, radius)
    ids = []
    for j, (x, y) in enumerate(nodes):
        px, py = cx + x * radius, cy + y * radius
        if j == notable_i:
            ids.append(notable(theme, px, py, cid))
        else:
            ids.append(minor(theme, j, px, py, cid))
    for a, b in edges:
        link(ids[a], ids[b])
    # Para dibujar la silueta: aristas del símbolo y, si es cerrado, su relleno.
    clusters[-1]["segments"] = [[round(cx + nodes[a][0] * radius, 1), round(cy + nodes[a][1] * radius, 1),
                                 round(cx + nodes[b][0] * radius, 1), round(cy + nodes[b][1] * radius, 1)] for a, b in edges]
    if fill:
        clusters[-1]["fill"] = [[round(cx + x * radius, 1), round(cy + y * radius, 1)] for x, y in fill]
    # Entrada: el nodo (no notable) más orientado hacia de donde se llega; salida: el opuesto.
    back = (math.cos(math.radians(entry_deg)), math.sin(math.radians(entry_deg)))
    others = [j for j in range(len(ids)) if j != notable_i]
    entry_j = max(others, key=lambda j: nodes[j][0] * back[0] + nodes[j][1] * back[1])
    far_j = min(others, key=lambda j: nodes[j][0] * back[0] + nodes[j][1] * back[1])
    return ids[entry_j], ids[far_j], ids


def cluster(theme, cx, cy, radius, count, entry_deg, fallback):
    """Con forma si la temática tiene plantilla; si no, anillo o rueda."""
    if shape_template(theme, count) is not None:
        return shape_cluster(theme, cx, cy, radius, count, entry_deg)
    return fallback(theme, cx, cy, radius, count, entry_deg)


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
ks_center = add("keystone", ks_name, kx, ky, keystone_mods(ks_mods), ks_flavor,
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
        entry, far, ring = cluster(tier1[bi], cx, cy, T1_R, count, back_deg, shape)
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
        entry2, far2, ring2 = cluster(tier2[bi], cx2, cy2, T2_R, count2, back_deg, shape2)
        link(prev, entry2)
        if bi in (0, 3):
            far_sides[bi] = ring2
        # Piedra angular al final de la rama 2.
        if bi == 2:
            fx, fy = pos(far2)
            prev = walk(far2, fx, fy, dx, dy, [90, 180], attrs)
            ks_name, ks_flavor, ks_mods = KEYSTONES[cid]
            ks = add("keystone", ks_name, fx + dx * 290, fy + dy * 290,
                     keystone_mods(ks_mods), ks_flavor, icon="ks_" + cid)
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
    i_entry, i_far, i_ring = cluster(inner_theme, ix, iy, 70, 7, entry_deg, ring_cluster)
    walk_between(hub_node(ang), i_entry, 2, attrs)

# --- Puertas entre clases vecinas y puentes exteriores ---
for i in range(N_OUTER):
    j = (i + 1) % N_OUTER
    gate_ang = -90 + SECTOR * i + SECTOR / 2.0
    gx, gy = polar(GATE_R, gate_ang)
    g_entry, g_far, g_ring = cluster(GATE_THEMES[i], gx, gy, 62, 6, gate_ang + 180, ring_cluster)
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
    e1, e2, ring = cluster(BRIDGE_THEMES[i], mx, my, 55, 6, entry_deg, ring_cluster)
    for side in (a, b):
        target = min(ring, key=lambda n: dist(side, n))
        walk_between(side, target, 1, shared)

# --- Sin nodos encimados ---
NODE_R = {"minor": 10.0, "notable": 22.0, "keystone": 30.0, "start": 30.0}
CLEARANCE = 8.0


def overlaps():
    """Pares de nodos más juntos de lo que permiten sus radios (más un margen)."""
    out = []
    for i in range(len(nodes)):
        for j in range(i + 1, len(nodes)):
            need = NODE_R[nodes[i]["kind"]] + NODE_R[nodes[j]["kind"]] + CLEARANCE
            if dist(i, j) < need:
                out.append((i, j, need))
    return out


# Los nodos de viaje (sin cluster) se apartan de lo que tengan encima; los de un cluster ya
# salen separados por fitted_template.
for _ in range(300):
    moved = False
    for i, j, need in overlaps():
        free = [k for k in (i, j) if not nodes[k].get("cluster") and nodes[k]["kind"] == "minor"]
        if not free:
            continue
        k = free[0]
        o = j if k == i else i
        (kx, ky), (ox, oy) = pos(k), pos(o)
        d = math.hypot(kx - ox, ky - oy) or 1.0
        push = (need - d) * 0.6 + 1.0
        nodes[k]["x"] = round(kx + (kx - ox) / d * push, 1)
        nodes[k]["y"] = round(ky + (ky - oy) / d * push, 1)
        moved = True
    if not moved:
        break
def seg_clearance(n, a, b):
    """Distancia del nodo n al segmento a-b."""
    (ax, ay), (bx, by), (px, py) = pos(a), pos(b), pos(n)
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / ((dx * dx + dy * dy) or 1.0)))
    return math.hypot(ax + t * dx - px, ay + t * dy - py)


def crossings():
    """Aristas que pasan por encima de un nodo que no es de ninguno de sus extremos."""
    out = []
    for a, b in edges:
        for n in range(len(nodes)):
            if n in (a, b):
                continue
            if seg_clearance(n, a, b) < NODE_R[nodes[n]["kind"]] + 3.0:
                out.append((a, b, n))
    return out


# Una arista que atraviesa un nodo: se desplaza el nodo de viaje de la arista hacia un lado.
for _ in range(60):
    moved = False
    for a, b, n in crossings():
        free = [k for k in (a, b) if not nodes[k].get("cluster") and nodes[k]["kind"] == "minor"]
        if not free:
            continue
        k = free[0]
        other = b if k == a else a
        (kx, ky), (ox, oy), (nx, ny) = pos(k), pos(other), pos(n)
        ex, ey = kx - ox, ky - oy
        el = math.hypot(ex, ey) or 1.0
        px, py = -ey / el, ex / el   # perpendicular a la arista
        side = 1.0 if (nx - ox) * px + (ny - oy) * py < 0 else -1.0   # hacia el lado contrario al nodo
        nodes[k]["x"] = round(kx + px * side * 12.0, 1)
        nodes[k]["y"] = round(ky + py * side * 12.0, 1)
        moved = True
    if not moved:
        break
for a, b, n in crossings():
    print("ARISTA SOBRE NODO", nodes[a].get("theme"), nodes[b].get("theme"), "->", nodes[n].get("theme"), nodes[n].get("cluster"))

leftover = overlaps()
if leftover:
    for i, j, need in leftover:
        print("ENCIMADOS", nodes[i].get("theme"), nodes[i].get("cluster"), nodes[i]["kind"], nodes[j].get("theme"), nodes[j].get("cluster"), nodes[j]["kind"], round(dist(i, j), 1), "necesita", need)
assert not leftover, "nodos encimados"

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