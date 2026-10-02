class_name MuseumLayout
extends RefCounted
## The level design of the Moonlight Museum, as data. World metres, floor y = 0, -Z = north, +X = east.
## Every builder reads from here so layout, navigation, minimap, guards and tests stay consistent.
##
##   N  (balcony + glider escape, z -40..-30)
##   +-----------+----------------+-----------+
##   |  CLOCK    |  MOONLIGHT     |  VAULT    |  z -30..-8   (vault door = laser grid; fuse in E service)
##   |  ROOM     |  GALLERY       |  (lasers) |
##   +--vent-----+-----arch-------+-----------+
##   | SCULPTURE |  GRAND ATRIUM  | PAINTING  |  z -8..20    (atrium = hub, Inspector loop)
##   |  HALL     |  (dome, statue)|  GALLERY  |
##   +---arch----+-----arch-------+--vent-----+
##   | EGYPTIAN  |     FOYER      | S.SERVICE |  z 20..32    (foyer = spawn, safe)
##   +-----------+----------------+-----------+
##   West service corridor x -42..-38 / East service corridor x 38..42 run the full depth (dark alt routes).

const WALL_T := 0.4
const HALL_H := 6.6       ## Gallery ceiling height.
const SERVICE_H := 3.2    ## Service corridor ceiling height.
const VENT_H := 1.05      ## Crawl-vent opening height (crouch only; guards are 1.8 m and can't path through).

## Rooms: id -> {rect: Rect2(x0, z0, w, d), height, theme, title}
const ROOMS := {
	"foyer": {"rect": Rect2(-10, 20, 20, 12), "height": HALL_H, "theme": "foyer", "title": "Grand Foyer"},
	"atrium": {"rect": Rect2(-14, -8, 28, 28), "height": 9.0, "theme": "atrium", "title": "Grand Atrium"},
	"moon_gallery": {"rect": Rect2(-14, -30, 28, 22), "height": HALL_H, "theme": "moon_gallery", "title": "Moonlight Gallery"},
	"balcony": {"rect": Rect2(-12, -40, 24, 10), "height": 0.0, "theme": "balcony", "title": "North Balcony"},
	"paintings": {"rect": Rect2(14, -8, 24, 32), "height": HALL_H, "theme": "paintings", "title": "Painting Gallery"},
	"sculpture": {"rect": Rect2(-38, -8, 24, 28), "height": HALL_H, "theme": "sculpture", "title": "Sculpture Hall"},
	"egyptian": {"rect": Rect2(-38, 20, 24, 12), "height": HALL_H, "theme": "egyptian", "title": "Egyptian Hall"},
	"clock": {"rect": Rect2(-38, -30, 24, 22), "height": HALL_H, "theme": "clock", "title": "Clock Tower Room"},
	"vault": {"rect": Rect2(14, -30, 24, 22), "height": HALL_H, "theme": "vault", "title": "The Vault"},
	"south_service": {"rect": Rect2(10, 26, 32, 6), "height": SERVICE_H, "theme": "service", "title": "Service Corridor"},
	"east_service": {"rect": Rect2(38, -30, 4, 56), "height": SERVICE_H, "theme": "service", "title": "East Service Corridor"},
	"west_service": {"rect": Rect2(-42, -30, 4, 62), "height": SERVICE_H, "theme": "service", "title": "West Service Corridor"},
}

## Openings in walls. axis "x" = the wall runs along x at constant z (`at` = z); axis "z" = runs along z at
## constant x (`at` = x). `from`/`to` = extent along the wall. kind: arch | door | service | gate | vent | laser.
const OPENINGS := [
	{"rooms": ["foyer", "atrium"], "axis": "x", "at": 20.0, "from": -3.0, "to": 3.0, "kind": "arch"},
	{"rooms": ["foyer", "south_service"], "axis": "z", "at": 10.0, "from": 28.0, "to": 30.0, "kind": "service"},
	{"rooms": ["atrium", "moon_gallery"], "axis": "x", "at": -8.0, "from": -3.0, "to": 3.0, "kind": "arch"},
	{"rooms": ["atrium", "paintings"], "axis": "z", "at": 14.0, "from": 3.0, "to": 7.0, "kind": "arch"},
	{"rooms": ["atrium", "sculpture"], "axis": "z", "at": -14.0, "from": 3.0, "to": 7.0, "kind": "arch"},
	{"rooms": ["moon_gallery", "balcony"], "axis": "x", "at": -30.0, "from": -2.0, "to": 2.0, "kind": "gate"},
	{"rooms": ["moon_gallery", "vault"], "axis": "z", "at": 14.0, "from": -22.0, "to": -18.0, "kind": "laser"},
	{"rooms": ["moon_gallery", "clock"], "axis": "z", "at": -14.0, "from": -22.0, "to": -18.0, "kind": "arch"},
	{"rooms": ["paintings", "east_service"], "axis": "z", "at": 38.0, "from": -5.0, "to": -3.0, "kind": "service"},
	{"rooms": ["sculpture", "egyptian"], "axis": "x", "at": 20.0, "from": -28.0, "to": -24.0, "kind": "arch"},
	{"rooms": ["egyptian", "west_service"], "axis": "z", "at": -38.0, "from": 25.0, "to": 27.0, "kind": "service"},
	{"rooms": ["clock", "west_service"], "axis": "z", "at": -38.0, "from": -20.0, "to": -18.0, "kind": "service"},
	{"rooms": ["sculpture", "west_service"], "axis": "z", "at": -38.0, "from": 8.0, "to": 10.0, "kind": "service"},
	# Crawl vents: crouch-only shortcuts guards can't follow.
	{"rooms": ["sculpture", "clock"], "axis": "x", "at": -8.0, "from": -21.0, "to": -19.8, "kind": "vent"},
	{"rooms": ["paintings", "south_service"], "axis": "x", "at": 24.0, "from": 30.0, "to": 31.2, "kind": "vent"},
]
## The south and east service corridors meet in an open L at x 38..42, z 26..32 (no wall between them).

## Windows (opening centres in outer walls; normal = outward). Tall arched gallery windows.
const WINDOWS := [
	{"pos": Vector3(-8, 3.3, -30), "normal": Vector3(0, 0, -1), "size": Vector2(2.6, 4.2)},
	{"pos": Vector3(8, 3.3, -30), "normal": Vector3(0, 0, -1), "size": Vector2(2.6, 4.2)},
	{"pos": Vector3(-26, 3.3, -30), "normal": Vector3(0, 0, -1), "size": Vector2(2.6, 4.2)},
	{"pos": Vector3(26, 4.6, -30), "normal": Vector3(0, 0, -1), "size": Vector2(1.6, 1.4)},
	{"pos": Vector3(-6, 3.3, 32), "normal": Vector3(0, 0, 1), "size": Vector2(2.6, 4.2)},
	{"pos": Vector3(6, 3.3, 32), "normal": Vector3(0, 0, 1), "size": Vector2(2.6, 4.2)},
	{"pos": Vector3(-26, 3.3, 32), "normal": Vector3(0, 0, 1), "size": Vector2(2.6, 4.2)},
	{"pos": Vector3(42, 1.9, 12), "normal": Vector3(1, 0, 0), "size": Vector2(1.6, 1.6)},
	{"pos": Vector3(42, 1.9, -12), "normal": Vector3(1, 0, 0), "size": Vector2(1.6, 1.6)},
	{"pos": Vector3(-42, 1.9, 0), "normal": Vector3(-1, 0, 0), "size": Vector2(1.6, 1.6)},
	{"pos": Vector3(-42, 1.9, 22), "normal": Vector3(-1, 0, 0), "size": Vector2(1.6, 1.6)},
]
## Atrium dome skylight (horizontal opening in the 9 m ceiling).
const SKYLIGHT := {"pos": Vector3(0, 9.0, 6), "size": Vector2(10, 10)}

const SPAWN := Vector3(0, 0, 29)          ## Facing north.
const EXIT_GATE := Vector3(0, 0, -30)     ## ExitGlider origin; its -Z points onto the balcony.

const JEWELS := [
	{"name": "Blue Wonder", "color": Color(0.15, 0.45, 1.0), "pos": Vector3(33, 0, -3), "room": "paintings"},
	{"name": "Scarlet Lady", "color": Color(0.95, 0.1, 0.18), "pos": Vector3(-26, 0, 6), "room": "sculpture"},
	{"name": "Emerald Empress", "color": Color(0.1, 0.85, 0.4), "pos": Vector3(-33, 0, 27), "room": "egyptian"},
	{"name": "Black Star", "color": Color(0.45, 0.25, 0.75), "pos": Vector3(-26, 0, -25), "room": "clock"},
	{"name": "Moonstone of Pandora", "color": Color(0.85, 0.9, 1.0), "pos": Vector3(28, 0, -25), "room": "vault"},
]
const LASER := {"pos": Vector3(14, 0, -20), "width": 4.0, "height": 3.0, "axis": "z"}
const FUSE := {"pos": Vector3(38.2, 1.4, -24), "normal": Vector3(1, 0, 0)}   ## On the corridor side of the vault's east wall.
const CAMERAS := [
	{"pos": Vector3(15.0, 5.0, 9.5), "yaw_deg": -60.0, "room": "paintings"},
	{"pos": Vector3(-15.0, 5.0, -9.5), "yaw_deg": 120.0, "room": "clock"},
	{"pos": Vector3(12.5, 5.0, -10.0), "yaw_deg": 135.0, "room": "moon_gallery"},
]
const PICKUPS := [
	{"kind": "rose", "pos": Vector3(7, 0, 23)},
	{"kind": "rose", "pos": Vector3(-40, 0, 0)},
	{"kind": "rose", "pos": Vector3(-17, 0, 30)},
	{"kind": "smoke", "pos": Vector3(40, 0, 10)},
	{"kind": "smoke", "pos": Vector3(-35, 0, -10)},
	{"kind": "smoke", "pos": Vector3(-12, 0, -6)},
]
## Guard routes: designed so each jewel room has one readable patrol with a gap the player can time.
const GUARD_ROUTES := [
	{"kind": KK.EnemyKind.GUARD, "points": [Vector3(18, 0, 18), Vector3(34, 0, 18), Vector3(34, 0, 6), Vector3(18, 0, 6)], "wait": 1.6},
	{"kind": KK.EnemyKind.GUARD, "points": [Vector3(-18, 0, -4), Vector3(-34, 0, -4), Vector3(-34, 0, 16), Vector3(-18, 0, 16)], "wait": 1.4},
	{"kind": KK.EnemyKind.GUARD, "points": [Vector3(-18, 0, 25), Vector3(-34, 0, 23)], "wait": 2.2},
	{"kind": KK.EnemyKind.GUARD, "points": [Vector3(-18, 0, -12), Vector3(-34, 0, -12), Vector3(-34, 0, -20)], "wait": 1.8},
	{"kind": KK.EnemyKind.GUARD, "points": [Vector3(18, 0, -12), Vector3(34, 0, -12), Vector3(34, 0, -20), Vector3(22, 0, -27)], "wait": 1.5},
	{"kind": KK.EnemyKind.GUARD, "points": [Vector3(40, 0, 22), Vector3(40, 0, -26)], "wait": 2.5},
	{"kind": KK.EnemyKind.INSPECTOR, "points": [Vector3(-9, 0, 15), Vector3(9, 0, 15), Vector3(9, 0, -22), Vector3(-9, 0, -22)], "wait": 1.2},
]
## Atrium centrepiece (fountain + statue) — a solid navigation obstacle used by the tests.
const CENTREPIECE := {"pos": Vector3(0, 0, 6), "radius": 3.2, "height": 1.4}
const TEST_POINTS := {
	"open_a": Vector3(-7, 0, 13),
	"obstacle_a": Vector3(0, 0, 0.5),
	"obstacle_b": Vector3(0, 0, 11.5),
	"far": Vector3(-40, 0, -26),
	"lobby": Vector3(0, 0, 29),
}
