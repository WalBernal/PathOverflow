class_name KeystoneRules
## Cuentas de las piedras angulares de T92, sin nodos (las usan Player y EnemyManager
## y las prueban los tests).

## Caché Fría: el primer golpe a cada enemigo y los siguientes.
const COLD_CACHE_FIRST := 2.0
const COLD_CACHE_LATER := 0.8
## Rate Limiting: segundos tras un golpe en los que los demás no dañan.
const RATE_LIMIT_WINDOW := 0.4
## Consistencia Eventual: parte del daño que se aplaza y en cuánto se cobra (más o menos).
const DEFERRED_FRACTION := 0.5
const DEFERRED_TIME := 3.0


static func cold_cache_mult(first_hit: bool) -> float:
	return COLD_CACHE_FIRST if first_hit else COLD_CACHE_LATER


static func rate_limited(since_damage: float) -> bool:
	return since_damage < RATE_LIMIT_WINDOW


## Consistencia Eventual: [ahora, aplazado].
static func defer_split(amount: float) -> Vector2:
	return Vector2(amount * (1.0 - DEFERRED_FRACTION), amount * DEFERRED_FRACTION)


## Cuánto del daño aplazado se cobra en `delta` segundos: al menos lo que tocaría
## repartido en DEFERRED_TIME, para que no se quede colgando para siempre.
static func deferred_drain(pending: float, delta: float) -> float:
	return minf(pending, maxf(pending * delta * 2.0 / DEFERRED_TIME, 5.0 * delta))
