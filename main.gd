extends Node2D
# =============================================================
#  GREY FORTRESS - v5
#
#  New in this version:
#   - World minimap in the bottom-right corner: the four maps
#     stacked north-to-south, player dot, current area name
#   - Mobs have drawn face icons instead of letter glyphs;
#     more skeletons haunt the Ancient Ruins
#   - Weather: 10% chance of rain on entering an area (looping
#     rain ambience, animated streaks, occasional lightning
#     with a thunder rumble and a brief screen flash)
#   - Second, stronger item tier at every vendor; world loot
#     (outposts) is now clearly the most powerful gear
#   - Half of the slain mobs respawn when you re-enter a map
#
#  v4: unique vendor symbols, shop sell/buyback, victory screen,
#  clickable HUD buttons, Android support removed (Steam only)
# =============================================================

enum Mode { PLAY, INVENTORY, JOURNAL, SHOP, OPTIONS }

const TILE := 32
const BAR_H := 84                 # must match hud.gd
const MOVE_DELAY_FIRST := 0.22    # delay before hold-to-walk kicks in
const MOVE_DELAY_REPEAT := 0.115  # steps per second while holding ~ 8.7

# ---- world definition -------------------------------------
const MAP_DEFS := {
	"town": {
		"name": "Grey Fortress Town", "north": "wilds", "music": "town",
		"w": 42, "h": 30,
		"tree_density": 0.040, "water_blobs": 0, "mobs": {},
	},
	"wilds": {
		"name": "Northern Wilds", "south": "town", "north": "forest", "music": "wilds",
		"w": 125, "h": 94,
		"tree_density": 0.050, "water_blobs": 3,
		"mobs": { "r": 12, "g": 8, "b": 5 },
		"outpost": { "x": 28, "y": 38, "item": "boots" },
	},
	"forest": {
		"name": "Dark Forest", "south": "wilds", "north": "ruins", "music": "forest",
		"w": 125, "h": 94,
		"tree_density": 0.100, "water_blobs": 2,
		"mobs": { "w": 9, "g": 8, "b": 6 },
		"outpost": { "x": 88, "y": 50, "item": "bow" },
	},
	"ruins": {
		"name": "Ancient Ruins", "south": "forest", "music": "ruins",
		"w": 125, "h": 94,
		"tree_density": 0.030, "water_blobs": 1, "ruin_walls": true,
		"mobs": { "s": 14, "g": 6, "t": 4 },
		"outpost": { "x": 28, "y": 58, "item": "legplates" },
	},
}

# The world from north to south, for the HUD minimap.
const WORLD_ORDER := ["ruins", "forest", "wilds", "town"]
const RAIN_CHANCE := 0.10

const MOB_TYPES := {
	"r": { "name": "rat",       "hp": 2,  "dmg": 1, "sight": 10, "xp": 3,
			"coins": [1, 2],   "color": Color(0.50, 0.42, 0.32) },
	"g": { "name": "goblin",    "hp": 3,  "dmg": 1, "sight": 8,  "xp": 5,
			"coins": [2, 4],   "color": Color(0.70, 0.20, 0.18) },
	"b": { "name": "wild boar", "hp": 5,  "dmg": 2, "sight": 5,  "xp": 8,
			"coins": [3, 6],   "color": Color(0.38, 0.24, 0.14) },
	"w": { "name": "wolf",      "hp": 4,  "dmg": 2, "sight": 10, "xp": 10,
			"coins": [4, 7],   "color": Color(0.42, 0.44, 0.50) },
	"s": { "name": "skeleton",  "hp": 6,  "dmg": 2, "sight": 9,  "xp": 14,
			"coins": [5, 9],   "color": Color(0.80, 0.80, 0.72) },
	"t": { "name": "troll",     "hp": 10, "dmg": 3, "sight": 6,  "xp": 25,
			"coins": [10, 18], "color": Color(0.25, 0.40, 0.22) },
}

# Vendor stock comes in two tiers per item type: the second tier is
# pricier but stronger. World loot (price 0, found in outposts and
# ruins) beats anything a vendor sells.
const ITEMS := {
	"bread":  { "name": "Fresh Bread",      "price": 4,  "heal": 4,
			"desc": "Restores 4 HP" },
	"stew":   { "name": "Hearty Stew",      "price": 10, "heal": 10,
			"desc": "Restores 10 HP" },
	"potion": { "name": "Healing Potion",   "price": 10, "heal": 8,
			"desc": "Restores 8 HP" },
	"gpotion": { "name": "Greater Potion",  "price": 25, "heal": 18,
			"desc": "Restores 18 HP" },
	"sword":  { "name": "Iron Sword",       "price": 25, "slot": 16, "dmg": 1,
			"desc": "+1 damage" },
	"ssword": { "name": "Steel Sword",      "price": 60, "slot": 16, "dmg": 2,
			"desc": "+2 damage" },
	"shield": { "name": "Wooden Shield",    "price": 15, "slot": 17, "hp": 3,
			"desc": "+3 max HP" },
	"tshield": { "name": "Tower Shield",    "price": 40, "slot": 17, "hp": 6,
			"desc": "+6 max HP" },
	"cap":    { "name": "Leather Cap",      "price": 10, "slot": 1,  "hp": 2,
			"desc": "+2 max HP" },
	"helm":   { "name": "Iron Helm",        "price": 28, "slot": 1,  "hp": 4,
			"desc": "+4 max HP" },
	"charm":  { "name": "Lucky Charm",      "price": 20, "slot": 13, "hp": 4,
			"desc": "+4 max HP" },
	"talisman": { "name": "Moon Talisman",  "price": 50, "slot": 13, "hp": 8,
			"desc": "+8 max HP" },
	"cloak":  { "name": "Traveler's Cloak", "price": 12, "slot": 15, "hp": 2,
			"desc": "+2 max HP" },
	"fcloak": { "name": "Fur-lined Cloak",  "price": 32, "slot": 15, "hp": 4,
			"desc": "+4 max HP" },
	"ring":   { "name": "Copper Ring",      "price": 8,  "slot": 11, "hp": 1,
			"desc": "+1 max HP" },
	"sring":  { "name": "Silver Ring",      "price": 22, "slot": 11, "hp": 2,
			"desc": "+2 max HP" },
	"bag":    { "name": "Small Bag",        "price": 18, "slot": 20, "bag_slots": 8,
			"desc": "+8 inventory slots" },
	"lbag":   { "name": "Traveler's Pack",  "price": 45, "slot": 20, "bag_slots": 14,
			"desc": "+14 inventory slots" },
	"relic":  { "name": "Sunstone Relic",   "price": 0,
			"desc": "Quest item, warm to the touch" },
	"boots":  { "name": "Scout's Boots",     "price": 0, "slot": 8,  "hp": 6,
			"desc": "+6 max HP" },
	"bow":    { "name": "Hunter's Bow",      "price": 0, "slot": 18, "dmg": 3,
			"desc": "+3 damage" },
	"legplates": { "name": "Ancient Legplates", "price": 0, "slot": 7, "hp": 9,
			"desc": "+9 max HP" },
}

# World-of-Warcraft-style equipment slots, in canonical order.
const SLOT_NAMES := [
	"Ammo", "Head", "Neck", "Shoulder", "Shirt", "Chest", "Belt", "Legs",
	"Feet", "Wrist", "Gloves", "Finger 1", "Finger 2", "Trinket 1",
	"Trinket 2", "Back", "Main Hand", "Off Hand", "Ranged", "Tabard", "Bag",
]
const BASE_INV_SLOTS := 20


const VENDORS := [
	{
		"name": "Alda the baker", "short": "Alda", "symbol": "bread", "stock": ["bread", "stew"],
		"greet": "Alda: Fresh bread! Well, fresh-ish.",
		"quest": { "desc": "Kill 5 rats", "type": "kill", "target": "r", "need": 5,
				"intro": "Rats got into my flour again. Thin their numbers, would you?",
				"reward_coins": 20, "reward_xp": 15 },
	},
	{
		"name": "Borin the smith", "short": "Borin", "symbol": "anvil",
		"stock": ["sword", "ssword", "shield", "tshield", "cap", "helm"],
		"greet": "Borin: Steel solves most problems.",
		"quest": { "desc": "Kill 3 goblins", "type": "kill", "target": "g", "need": 3,
				"intro": "Goblins stole a crate of nails. Make them regret it.",
				"reward_coins": 25, "reward_xp": 15 },
	},
	{
		"name": "Cyra the alchemist", "short": "Cyra", "symbol": "flask",
		"stock": ["potion", "gpotion", "charm", "talisman"],
		"greet": "Cyra: Potions brewing. Do not rush art.",
		"quest": { "desc": "Bring me 10 coins", "type": "coins", "need": 10,
				"intro": "Reagents are expensive. Fund my research with 10 coins?",
				"reward_items": { "potion": 2 }, "reward_xp": 20 },
	},
	{
		"name": "Dolm the trader", "short": "Dolm", "symbol": "bag",
		"stock": ["cloak", "fcloak", "ring", "sring", "bag", "lbag"],
		"greet": "Dolm: Rare goods for discerning customers.",
		"quest": { "desc": "Recover the Sunstone Relic from the Ancient Ruins",
				"type": "item", "target": "relic", "need": 1,
				"intro": "Legend places the Sunstone Relic in the ruins far north, between two trees. Bring it to me.",
				"reward_coins": 60, "reward_xp": 50 },
	},
]

# ---- state -------------------------------------------------
var mode: int = Mode.PLAY
var current_map := "town"
var map_state := {}
var grid := []
var mobs := []
var vendors := []       # [{pos, set_idx}]
var ground_items := []  # [{pos, id}]
var altar_positions := []

var player_pos := Vector2i.ZERO
var player_hp := 12
var player_max_hp := 12   # computed: base + equipment
var player_dmg := 1       # computed: base + equipment
var base_max_hp := 12
var base_dmg := 1
var player_mana := 10
var player_max_mana := 10
var base_max_mana := 10
var equipment := {}       # slot index -> item id
var player_level := 1
var player_xp := 0
var coins := 0
var inventory := {}     # item id -> count (each distinct id = one stack/slot)
var quests := []
var current_shop := -1
var shop_index := 0     # keyboard selection inside the shop panel
var buyback := {}       # vendor set_idx -> [{id, price}] items sold to them

var messages := []
var game_over := false
var move_count := 0
var victory_banner := false
var victory_moves := 0
var held_dir := Vector2i.ZERO
var move_timer := 0.0

var ui_pane := 1          # inventory screen: 0 = equipment, 1 = backpack
var ui_index := 0
var keymap := {
	"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D,
	"up_left": KEY_Q, "up_right": KEY_E, "down_left": KEY_Z, "down_right": KEY_C,
	"wait": KEY_SPACE, "character": KEY_I, "journal": KEY_J, "options": KEY_O,
}
var options_screen := "main"
var opt_index := 0
var opt_rebinding := false
var opt_slider_dragging := false
var master_volume := 1.0
var visited := {}         # maps the player has entered at least once
var banner_text := ""
var banner_timer := 0.0

var music: AudioStreamPlayer
var music_track := ""
var combat_heat := 0   # turns of combat music left after last enemy sighting

# ---- weather ----
var raining := false
var lightning_timer := 0.0
var flash_alpha := 0.0     # white screen flash, fades out after a strike
var rain_player: AudioStreamPlayer
var thunder_player: AudioStreamPlayer

@onready var camera: Camera2D = $Camera
@onready var hud: Node2D = $UI/HUD
@onready var font: Font = ThemeDB.fallback_font


# ---------------------------------------------------------
#  Setup
# ---------------------------------------------------------
func _ready() -> void:
	hud.game = self
	# Center the player in the area ABOVE the HUD bar, not the full window.
	camera.offset = Vector2(0, BAR_H * 0.5)
	_load_settings()
	music = AudioStreamPlayer.new()
	music.volume_db = -9.0
	add_child(music)
	rain_player = AudioStreamPlayer.new()
	rain_player.volume_db = -12.0
	var rain_stream: AudioStreamOggVorbis = load("res://audio/rain.ogg")
	rain_stream.loop = true
	rain_player.stream = rain_stream
	add_child(rain_player)
	thunder_player = AudioStreamPlayer.new()
	thunder_player.volume_db = -4.0
	thunder_player.stream = load("res://audio/thunder.ogg")
	add_child(thunder_player)
	_apply_volume()
	_start()

func _start() -> void:
	base_max_hp = 12
	base_dmg = 1
	base_max_mana = 10
	player_level = 1
	player_xp = 0
	coins = 0
	inventory = {}
	equipment = {}
	visited = {}
	banner_timer = 0.0
	_recalc_stats()
	player_hp = player_max_hp
	player_mana = player_max_mana
	game_over = false
	move_count = 0
	victory_banner = false
	victory_moves = 0
	buyback = {}
	shop_index = 0
	mode = Mode.PLAY
	messages = []
	map_state = {}
	quests = []
	for vd in VENDORS:
		var q: Dictionary = vd["quest"].duplicate()
		q["state"] = "hidden"
		q["progress"] = 0
		q["giver"] = vd["name"]
		quests.append(q)
	_load_map("town", "spawn")
	_log("Welcome to Grey Fortress.")
	_log("Arrows/WASD move. I character, J journal, O options, Space waits.")
	_update_music()
	_refresh()

func _refresh() -> void:
	camera.position = Vector2(player_pos) * TILE + Vector2(TILE, TILE) * 0.5
	# Push the new position to the viewport NOW: _draw culls tiles from
	# get_screen_center_position(), which is stale until the camera
	# scroll updates (visible as a grey world after a map transition).
	camera.force_update_scroll()
	queue_redraw()
	hud.queue_redraw()


# ---------------------------------------------------------
#  Hold-to-walk: poll movement keys every frame.
#  First step is instant, then a short pause, then repeat.
# ---------------------------------------------------------
func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		hud.queue_redraw()
	_weather_tick(delta)
	if game_over or victory_banner or mode != Mode.PLAY:
		held_dir = Vector2i.ZERO
		return
	var dir := _polled_dir()
	if dir == Vector2i.ZERO:
		held_dir = Vector2i.ZERO
		return
	if dir != held_dir:
		held_dir = dir
		move_timer = MOVE_DELAY_FIRST
		_try_player_move(dir)
		return
	move_timer -= delta
	if move_timer <= 0.0:
		move_timer = MOVE_DELAY_REPEAT
		_try_player_move(dir)

func _polled_dir() -> Vector2i:
	var dx := 0
	var dy := 0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(keymap["up"]) or Input.is_key_pressed(KEY_KP_8):
		dy -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(keymap["down"]) or Input.is_key_pressed(KEY_KP_2):
		dy += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(keymap["left"]) or Input.is_key_pressed(KEY_KP_4):
		dx -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(keymap["right"]) or Input.is_key_pressed(KEY_KP_6):
		dx += 1
	# Dedicated diagonal keys win over anything else.
	if Input.is_key_pressed(keymap["up_left"]) or Input.is_key_pressed(KEY_KP_7):
		dx = -1
		dy = -1
	elif Input.is_key_pressed(keymap["up_right"]) or Input.is_key_pressed(KEY_KP_9):
		dx = 1
		dy = -1
	elif Input.is_key_pressed(keymap["down_left"]) or Input.is_key_pressed(KEY_KP_1):
		dx = -1
		dy = 1
	elif Input.is_key_pressed(keymap["down_right"]) or Input.is_key_pressed(KEY_KP_3):
		dx = 1
		dy = 1
	return Vector2i(dx, dy)


# ---------------------------------------------------------
#  Map loading and procedural generation
# ---------------------------------------------------------
func _load_map(id: String, arrive: String) -> void:
	current_map = id
	var revisit := map_state.has(id)
	if not revisit:
		map_state[id] = _generate_map(id)
	var st: Dictionary = map_state[id]
	grid = st["grid"]
	mobs = st["mobs"]
	vendors = st["vendors"]
	ground_items = st["items"]
	altar_positions = st["altars"]
	match arrive:
		"spawn":
			player_pos = st["spawn"]
		"south_gate":
			player_pos = st["south_gate"] + Vector2i(0, -1)
		"north_gate":
			player_pos = st["north_gate"] + Vector2i(0, 1)
	if revisit:
		_respawn_mobs()
	camera.limit_left = 0
	# The camera has a +BAR_H/2 vertical offset (so the player is centered
	# in the area above the HUD bar). Offsets are applied AFTER limits in
	# Godot, so both vertical limits must shift by half a bar to match:
	# top row visible at screen top, bottom row visible just above the bar.
	camera.limit_top = -BAR_H / 2
	camera.limit_right = grid[0].size() * TILE
	camera.limit_bottom = grid.size() * TILE + BAR_H / 2
	combat_heat = 0
	_update_music()
	_set_rain(randf() < RAIN_CHANCE)
	if not visited.has(id):
		visited[id] = true
		banner_text = "Entering... %s" % MAP_DEFS[id]["name"]
		banner_timer = 3.2

func _generate_map(id: String) -> Dictionary:
	var def: Dictionary = MAP_DEFS[id]
	var w: int = def["w"]
	var h: int = def["h"]
	var gx: int = w / 2      # gates sit at columns gx, gx+1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)

	# 1. Base: grass with a wall border.
	var g := []
	for y in h:
		var row := []
		for x in w:
			var edge := x == 0 or y == 0 or x == w - 1 or y == h - 1
			row.append("#" if edge else ".")
		g.append(row)

	# 2. Scatter trees.
	var density: float = def["tree_density"]
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if rng.randf() < density:
				g[y][x] = "T"

	# 3. Water blobs (random walks).
	for i in def["water_blobs"]:
		var wx := rng.randi_range(15, w - 16)
		var wy := rng.randi_range(15, h - 16)
		for j in 120:
			g[wy][wx] = "~"
			wx = clamp(wx + rng.randi_range(-1, 1), 2, w - 3)
			wy = clamp(wy + rng.randi_range(-1, 1), 2, h - 3)

	# 4. Ruin wall fragments (ruins map only).
	if def.has("ruin_walls"):
		for i in 26:
			var rx := rng.randi_range(8, w - 14)
			var ry := rng.randi_range(8, h - 14)
			var horizontal := rng.randf() < 0.5
			var length := rng.randi_range(3, 7)
			for j in length:
				var px := rx + (j if horizontal else 0)
				var py := ry + (0 if horizontal else j)
				g[py][px] = "S"

	# 5. Winding road between the gates (wilderness maps).
	if id != "town":
		for y in range(1, h - 1):
			var cx: int = gx + int(round(3.0 * sin(y * 0.11) + 2.0 * sin(y * 0.031)))
			for x in range(cx - 1, cx + 3):
				g[y][x] = "."

	var vs := []
	var altars := []
	var items := []
	var spawn := Vector2i(gx, h - 3)

	# 6. The town: a compact village filling most of its small map.
	if id == "town":
		for y in range(4, 27):
			for x in range(6, 36):
				g[y][x] = "."
		_place_house(g, 9, 6, vs)    # Alda
		_place_house(g, 28, 6, vs)   # Borin
		_place_house(g, 9, 14, vs)   # Cyra
		_place_house(g, 28, 14, vs)  # Dolm
		_place_temple(g, 18, 21, altars)
		spawn = Vector2i(gx, 12)
		# Short road from the plaza up to the north gate.
		for y in range(1, 7):
			for x in range(gx - 1, gx + 3):
				g[y][x] = "."

	# 7. The Sunstone Relic, between two trees (ruins map only).
	if id == "ruins":
		for y in range(10, 15):
			for x in range(gx - 4, gx + 6):
				g[y][x] = "."
		g[12][gx - 1] = "T"
		g[12][gx + 1] = "T"
		items.append({ "pos": Vector2i(gx, 12), "id": "relic" })

	# 7b. Loot outpost: a small stone keep holding a unique item,
	# with a carved corridor to the main road so it is always reachable.
	if def.has("outpost"):
		var op: Dictionary = def["outpost"]
		var ox: int = op["x"]
		var oy: int = op["y"]
		_clear_area(g, ox - 2, oy - 2, 13, 12)
		for x in range(ox, ox + 9):
			g[oy][x] = "S"
			g[oy + 6][x] = "S"
		for y in range(oy + 1, oy + 6):
			g[y][ox] = "S"
			g[y][ox + 8] = "S"
			for x in range(ox + 1, ox + 8):
				g[y][x] = "."
		g[oy][ox] = "#"          # corner towers
		g[oy][ox + 8] = "#"
		g[oy + 6][ox] = "#"
		g[oy + 6][ox + 8] = "#"
		g[oy + 6][ox + 4] = "D"
		items.append({ "pos": Vector2i(ox + 4, oy + 3), "id": op["item"] })
		var cy: int = oy + 8
		for y in range(oy + 7, cy + 1):
			g[y][ox + 4] = "."
		for x in range(min(ox + 4, gx - 7), max(ox + 4, gx + 7) + 1):
			g[cy][x] = "."

	# 8. Gates, with a small clearing around each.
	var north_gate := Vector2i(-1, -1)
	var south_gate := Vector2i(-1, -1)
	if def.has("north"):
		_clear_area(g, gx - 2, 1, 6, 3)
		g[0][gx] = "^"
		g[0][gx + 1] = "^"
		north_gate = Vector2i(gx, 0)
	if def.has("south"):
		_clear_area(g, gx - 2, h - 4, 6, 3)
		g[h - 1][gx] = "v"
		g[h - 1][gx + 1] = "v"
		south_gate = Vector2i(gx, h - 1)

	# 9. Mobs, kept away from the south entrance.
	var ms := _spawn_mobs(g, rng, def["mobs"], w, h,
			south_gate if south_gate.x >= 0 else spawn)

	return {
		"grid": g, "mobs": ms, "vendors": vs, "items": items, "altars": altars,
		"spawn": spawn, "north_gate": north_gate, "south_gate": south_gate,
	}

func _clear_area(g: Array, x0: int, y0: int, w: int, h: int) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			g[y][x] = "."

# 5x4 house with a bottom door and a vendor inside.
func _place_house(g: Array, x0: int, y0: int, vs: Array) -> void:
	for x in range(x0, x0 + 5):
		g[y0][x] = "H"
		g[y0 + 3][x] = "H"
	for y in range(y0 + 1, y0 + 3):
		g[y][x0] = "H"
		g[y][x0 + 4] = "H"
		for x in range(x0 + 1, x0 + 4):
			g[y][x] = "."
	g[y0 + 3][x0 + 2] = "D"
	vs.append({ "pos": Vector2i(x0 + 2, y0 + 1), "set_idx": vs.size() })

# 7x4 temple with an altar and a north-facing door (toward the plaza).
func _place_temple(g: Array, x0: int, y0: int, altars: Array) -> void:
	for x in range(x0, x0 + 7):
		g[y0][x] = "S"
		g[y0 + 3][x] = "S"
	for y in range(y0 + 1, y0 + 3):
		g[y][x0] = "S"
		g[y][x0 + 6] = "S"
		for x in range(x0 + 1, x0 + 6):
			g[y][x] = "."
	g[y0 + 2][x0 + 3] = "A"
	altars.append(Vector2i(x0 + 3, y0 + 2))
	g[y0][x0 + 3] = "D"

# Places counts of mobs on free grass, away from `avoid` (the player's
# entry point) and from any mob already in `existing`.
func _spawn_mobs(g: Array, rng: RandomNumberGenerator, counts: Dictionary, w: int, h: int, avoid: Vector2i, existing: Array = []) -> Array:
	var taken := {}
	for m in existing:
		taken[m["pos"]] = true
	var ms := []
	for type in counts.keys():
		var placed := 0
		var tries := 0
		while placed < counts[type] and tries < 4000:
			tries += 1
			var p := Vector2i(rng.randi_range(2, w - 3), rng.randi_range(2, h - 3))
			if g[p.y][p.x] != "." or taken.has(p):
				continue
			if abs(p.x - avoid.x) + abs(p.y - avoid.y) < 18:
				continue
			taken[p] = true
			ms.append({ "pos": p, "hp": MOB_TYPES[type]["hp"], "type": type })
			placed += 1
	return ms

# On re-entering a map, half of the slain mobs (rounded up, per type)
# come back, placed away from where the player arrives.
func _respawn_mobs() -> void:
	var counts: Dictionary = MAP_DEFS[current_map]["mobs"]
	if counts.is_empty():
		return
	var alive := {}
	for m in mobs:
		alive[m["type"]] = alive.get(m["type"], 0) + 1
	var to_spawn := {}
	for type in counts:
		var back := int(ceil((counts[type] - alive.get(type, 0)) * 0.5))
		if back > 0:
			to_spawn[type] = back
	if to_spawn.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	mobs.append_array(_spawn_mobs(grid, rng, to_spawn,
			grid[0].size(), grid.size(), player_pos, mobs))


# ---------------------------------------------------------
#  Input
# ---------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_click(event.position)
		else:
			opt_slider_dragging = false
		return
	if event is InputEventMouseMotion and mode == Mode.OPTIONS and opt_slider_dragging:
		_options_click(event.position, false)
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_F11:
		_toggle_fullscreen()
		_save_settings()
		return

	if game_over:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_start()
		return

	if victory_banner:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_ESCAPE:
			victory_banner = false
			_refresh()
		return

	match mode:
		Mode.PLAY:
			_play_input(event.keycode)
		Mode.INVENTORY:
			_inventory_input(event.keycode)
		Mode.SHOP:
			_shop_input(event.keycode)
		Mode.JOURNAL:
			_close_panel()
		Mode.OPTIONS:
			_options_input(event.keycode)

# All left-clicks funnel through here. Movement is deliberately NOT
# mouse-driven: clicks only operate the UI (HUD buttons and panels).
func _handle_click(mp: Vector2) -> void:
	if game_over:
		_start()
		return
	if victory_banner:
		victory_banner = false
		_refresh()
		return
	if _bar_click(mp):
		return
	match mode:
		Mode.INVENTORY:
			_char_sheet_click(mp)
		Mode.SHOP:
			_shop_click(mp)
		Mode.JOURNAL:
			_close_panel()
		Mode.OPTIONS:
			_options_click(mp, true)

# The three HUD buttons. Geometry is shared with hud.gd via
# bar_button_rects(), so drawing and hit-testing can never drift apart.
const BAR_BUTTONS := ["Inventory (I)", "Journal (J)", "Options (O)"]

func bar_button_rects() -> Array:
	var vs := get_viewport_rect().size
	var bw := 110.0
	var bh := 26.0
	var gap := 8.0
	var x := vs.x - (bw + gap) * BAR_BUTTONS.size() - 4.0
	var y := vs.y - BAR_H + 50.0
	var rects := []
	for i in BAR_BUTTONS.size():
		rects.append(Rect2(x + i * (bw + gap), y, bw, bh))
	return rects

func _bar_click(mp: Vector2) -> bool:
	var rects := bar_button_rects()
	var targets := [Mode.INVENTORY, Mode.JOURNAL, Mode.OPTIONS]
	for i in rects.size():
		if not (rects[i] as Rect2).has_point(mp):
			continue
		if mode == Mode.SHOP:
			current_shop = -1
		if mode == targets[i]:
			_close_panel()
			return true
		match targets[i]:
			Mode.INVENTORY:
				mode = Mode.INVENTORY
				ui_pane = 1
				ui_index = 0
			Mode.JOURNAL:
				mode = Mode.JOURNAL
			Mode.OPTIONS:
				mode = Mode.OPTIONS
				options_screen = "main"
				opt_index = 0
		_refresh()
		return true
	return false

func _close_panel() -> void:
	mode = Mode.PLAY
	held_dir = _polled_dir()
	move_timer = MOVE_DELAY_FIRST
	_refresh()

func _play_input(key: int) -> void:
	if key == keymap["character"]:
		mode = Mode.INVENTORY
		ui_pane = 1
		ui_index = 0
		_refresh()
	elif key == keymap["journal"]:
		mode = Mode.JOURNAL
		_refresh()
	elif key == keymap["wait"]:
		_end_turn()
	elif key == keymap["options"] or key == KEY_ESCAPE:
		mode = Mode.OPTIONS
		options_screen = "main"
		opt_index = 0
		_refresh()

func _inventory_input(key: int) -> void:
	match key:
		KEY_ESCAPE, KEY_I:
			_close_panel()
		KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D:
			ui_pane = 1 - ui_pane
			ui_index = 0
			_refresh()
		KEY_UP, KEY_W:
			ui_index = max(ui_index - 1, 0)
			_refresh()
		KEY_DOWN, KEY_S:
			ui_index = min(ui_index + 1, _pane_len() - 1)
			_refresh()
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			_activate_selection()

# Geometry here must mirror _draw_panel_character in hud.gd.
func _char_sheet_click(mp: Vector2) -> void:
	var vs := get_viewport_rect().size
	var w := 980.0
	var h := 596.0
	var px := (vs.x - w) * 0.5
	var py := (vs.y - BAR_H - h) * 0.5
	var top := py + 60.0
	for i in SLOT_NAMES.size():
		if Rect2(px + 10, top + i * 23.0 - 15.0, 320, 21).has_point(mp):
			ui_pane = 0
			ui_index = i
			_activate_selection()
			return
	var list := inventory_list()
	for i in list.size():
		if Rect2(px + 504, top + i * 17.0 - 12.0, 456, 16).has_point(mp):
			ui_pane = 1
			ui_index = i
			_activate_selection()
			return

func _pane_len() -> int:
	if ui_pane == 0:
		return SLOT_NAMES.size()
	return max(inventory_list().size(), 1)

func _activate_selection() -> void:
	if ui_pane == 0:
		_unequip(ui_index)
	else:
		var list := inventory_list()
		if not list.is_empty():
			var id: String = list[min(ui_index, list.size() - 1)]
			var it: Dictionary = ITEMS[id]
			if it.has("slot"):
				_equip(id)
			elif it.has("heal"):
				_use_item(id)
			else:
				_log("The %s cannot be used or equipped." % it["name"])
	ui_index = min(ui_index, _pane_len() - 1)
	_refresh()

func _shop_input(key: int) -> void:
	if key == KEY_ESCAPE:
		current_shop = -1
		_close_panel()
		return
	if key >= KEY_1 and key <= KEY_9:
		var idx := key - KEY_1
		var stock: Array = VENDORS[current_shop]["stock"]
		if idx < stock.size():
			_buy_item(stock[idx])
		return
	match key:
		KEY_UP, KEY_W:
			shop_index = max(shop_index - 1, 0)
			_refresh()
		KEY_DOWN, KEY_S:
			shop_index = min(shop_index + 1, _shop_actionable().size() - 1)
			_refresh()
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			var actionable := _shop_actionable()
			if shop_index < actionable.size():
				_shop_action(actionable[shop_index])


# ---------------------------------------------------------
#  Shop panel data: one flat list of rows (headers, notes and
#  actionable buy/sell/buyback entries). hud.gd draws this list
#  and the click handler below hit-tests the same rows, using
#  the shared SHOP_* geometry so the two can never drift apart.
# ---------------------------------------------------------
const SHOP_W := 660.0      # panel width
const SHOP_TOP := 58.0     # y of the first row inside the panel
const SHOP_ROW_H := 20.0

func shop_entries() -> Array:
	var entries := []
	var vd: Dictionary = VENDORS[current_shop]
	entries.append({ "kind": "header", "text": "Buy" })
	var stock: Array = vd["stock"]
	for i in stock.size():
		entries.append({ "kind": "buy", "id": stock[i], "price": ITEMS[stock[i]]["price"], "num": i + 1 })
	entries.append({ "kind": "header", "text": "Sell (half price)" })
	var sellable := []
	for id in inventory_list():
		if ITEMS[id]["price"] > 0:
			sellable.append(id)
	if sellable.is_empty():
		entries.append({ "kind": "note", "text": "Nothing in your pack they will pay for." })
	for id in sellable:
		entries.append({ "kind": "sell", "id": id, "price": sell_price(id) })
	entries.append({ "kind": "header", "text": "Buyback" })
	var bb: Array = buyback.get(current_shop, [])
	if bb.is_empty():
		entries.append({ "kind": "note", "text": "You have not sold them anything." })
	for i in bb.size():
		entries.append({ "kind": "buyback", "id": bb[i]["id"], "price": bb[i]["price"], "bb_idx": i })
	return entries

# The buy/sell/buyback rows only, in display order; shop_index
# selects into this list.
func _shop_actionable() -> Array:
	return shop_entries().filter(
			func(e): return e["kind"] != "header" and e["kind"] != "note")

func _shop_action(e: Dictionary) -> void:
	match e["kind"]:
		"buy":
			_buy_item(e["id"])
		"sell":
			_sell_item(e["id"])
		"buyback":
			_buyback_item(e["bb_idx"])
	shop_index = clamp(shop_index, 0, max(_shop_actionable().size() - 1, 0))
	_refresh()

func _shop_click(mp: Vector2) -> void:
	var entries := shop_entries()
	var vs := get_viewport_rect().size
	var h := 96.0 + entries.size() * SHOP_ROW_H
	var px := (vs.x - SHOP_W) * 0.5
	var py := (vs.y - BAR_H - h) * 0.5
	var act := 0
	for i in entries.size():
		var e: Dictionary = entries[i]
		if e["kind"] == "header" or e["kind"] == "note":
			continue
		if Rect2(px + 8, py + SHOP_TOP + i * SHOP_ROW_H - 14.0, SHOP_W - 16.0, 18.0).has_point(mp):
			shop_index = act
			_shop_action(e)
			return
		act += 1

func sell_price(id: String) -> int:
	return max(1, int(ITEMS[id]["price"]) / 2)

func _sell_item(id: String) -> void:
	if inventory.get(id, 0) <= 0:
		return
	var sp := sell_price(id)
	_remove_item(id)
	coins += sp
	var bb: Array = buyback.get(current_shop, [])
	bb.push_front({ "id": id, "price": sp })
	if bb.size() > 8:
		bb.pop_back()
	buyback[current_shop] = bb
	_log("You sell the %s for %d coins." % [ITEMS[id]["name"], sp])

func _buyback_item(idx: int) -> void:
	var bb: Array = buyback.get(current_shop, [])
	if idx < 0 or idx >= bb.size():
		return
	var e: Dictionary = bb[idx]
	var id: String = e["id"]
	if coins < e["price"]:
		_log("Not enough coins. (%s costs %d)" % [ITEMS[id]["name"], e["price"]])
		return
	if not _pack_has_room(id):
		_log("Your pack is full.")
		return
	coins -= e["price"]
	_add_item(id)
	bb.remove_at(idx)
	_log("You buy back the %s for %d coins." % [ITEMS[id]["name"], e["price"]])


# ---------------------------------------------------------
#  Player turn
# ---------------------------------------------------------
func _try_player_move(dir: Vector2i) -> void:
	var target := player_pos + dir
	var tile: String = grid[target.y][target.x] if _in_bounds(target) else "#"

	var mi := _mob_at(target)
	var vi := _vendor_at(target)
	if mi >= 0:
		_attack_mob(mi)
	elif vi >= 0:
		_talk_to_vendor(vi)
		return   # talking does not pass a turn
	elif tile == "A":
		_pray()
	elif _is_walkable(target):
		player_pos = target
		_pickup_items()
		if _check_transition():
			return
	else:
		_refresh()
		return

	_end_turn()

func _attack_mob(index: int) -> void:
	var mob = mobs[index]
	var t: Dictionary = MOB_TYPES[mob["type"]]
	mob["hp"] -= player_dmg
	if mob["hp"] <= 0:
		mobs.remove_at(index)
		var drop := randi_range(t["coins"][0], t["coins"][1])
		coins += drop
		_log("You slay the %s! +%d coins." % [t["name"], drop])
		_count_kill(mob["type"])
		_gain_xp(t["xp"])
	else:
		_log("You hit the %s for %d. (%d HP left)" % [t["name"], player_dmg, mob["hp"]])

func _pray() -> void:
	if player_hp < player_max_hp or player_mana < player_max_mana:
		player_hp = player_max_hp
		player_mana = player_max_mana
		_log("You pray at the altar. Warmth flows through you. (fully restored)")
	else:
		_log("You pray at the altar. The gods seem pleased.")

func _pickup_items() -> void:
	for i in range(ground_items.size() - 1, -1, -1):
		if ground_items[i]["pos"] == player_pos:
			var id: String = ground_items[i]["id"]
			if not _pack_has_room(id):
				_log("You see the %s, but your pack is full!" % ITEMS[id]["name"])
				continue
			_add_item(id)
			ground_items.remove_at(i)
			_log("You found the %s!" % ITEMS[id]["name"])
			_gain_xp(10)

func _check_transition() -> bool:
	var tile: String = grid[player_pos.y][player_pos.x]
	var def: Dictionary = MAP_DEFS[current_map]
	if tile == "^" and def.has("north"):
		_load_map(def["north"], "south_gate")
		_log("You travel north to the %s." % MAP_DEFS[current_map]["name"])
		_refresh()
		return true
	if tile == "v" and def.has("south"):
		_load_map(def["south"], "north_gate")
		_log("You head south to %s." % MAP_DEFS[current_map]["name"])
		_refresh()
		return true
	return false

func _end_turn() -> void:
	move_count += 1
	_mob_turn()
	_update_music()
	_refresh()


# ---------------------------------------------------------
#  Vendors, shops, quests
# ---------------------------------------------------------
func _talk_to_vendor(index: int) -> void:
	var v = vendors[index]
	var set_idx: int = v["set_idx"]
	var data: Dictionary = VENDORS[set_idx % VENDORS.size()]
	var q: Dictionary = quests[set_idx % quests.size()]

	if q["state"] == "hidden":
		q["state"] = "active"
		_log("%s: \"%s\"" % [data["name"], q["intro"]])
		_log("New quest: %s. Press J for the journal." % q["desc"])
	elif q["state"] == "active" and _quest_fulfilled(q):
		_complete_quest(q)
		_refresh()
		return
	else:
		_log(data["greet"])

	current_shop = set_idx % VENDORS.size()
	shop_index = 0
	mode = Mode.SHOP
	_refresh()

func _quest_fulfilled(q: Dictionary) -> bool:
	match q["type"]:
		"kill":
			return q["progress"] >= q["need"]
		"coins":
			return coins >= q["need"]
		"item":
			return inventory.get(q["target"], 0) >= q["need"]
	return false

func _complete_quest(q: Dictionary) -> void:
	match q["type"]:
		"coins":
			coins -= q["need"]
		"item":
			_remove_item(q["target"], q["need"])
	var reward_bits := []
	if q.has("reward_coins"):
		coins += q["reward_coins"]
		reward_bits.append("%d coins" % q["reward_coins"])
	if q.has("reward_items"):
		var ri: Dictionary = q["reward_items"]
		for id in ri.keys():
			_add_item(id, ri[id])
			reward_bits.append("%dx %s" % [ri[id], ITEMS[id]["name"]])
	q["state"] = "done"
	_log("Quest complete: %s! Reward: %s." % [q["desc"], ", ".join(reward_bits)])
	_gain_xp(q["reward_xp"])
	_check_victory()

func _check_victory() -> void:
	for q in quests:
		if q["state"] != "done":
			return
	victory_banner = true
	victory_moves = move_count
	_log("Victory! All quests complete in %d moves." % victory_moves)

func _count_kill(type: String) -> void:
	for q in quests:
		if q["state"] == "active" and q["type"] == "kill" and q["target"] == type:
			if q["progress"] < q["need"]:
				q["progress"] += 1
				if q["progress"] >= q["need"]:
					_log("Quest goal reached! Return to %s." % q["giver"])

func _buy_item(id: String) -> void:
	var item: Dictionary = ITEMS[id]
	if coins < item["price"]:
		_log("Not enough coins. (%s costs %d)" % [item["name"], item["price"]])
		_refresh()
		return
	if not _pack_has_room(id):
		_log("Your pack is full.")
		_refresh()
		return
	coins -= item["price"]
	_add_item(id)
	if item.has("slot"):
		_log("You buy a %s. Equip it from the inventory (I)." % item["name"])
	else:
		_log("You buy a %s." % item["name"])
	_refresh()

func _use_item(id: String) -> void:
	var item: Dictionary = ITEMS[id]
	if not item.has("heal"):
		_log("The %s cannot be used." % item["name"])
		_refresh()
		return
	if player_hp >= player_max_hp:
		_log("You are already at full health.")
		_refresh()
		return
	_remove_item(id)
	player_hp = min(player_hp + item["heal"], player_max_hp)
	_log("You use the %s. (+%d HP, now %d/%d)" % [item["name"], item["heal"], player_hp, player_max_hp])
	_refresh()

func inventory_list() -> Array:
	var keys := inventory.keys()
	keys.sort()
	return keys

func inv_capacity() -> int:
	var cap := BASE_INV_SLOTS
	if equipment.has(20):
		var bag_item: Dictionary = ITEMS[equipment[20]]
		cap += bag_item.get("bag_slots", 0)
	return cap

# Every stack change goes through these two, so the "erase empty
# stacks" rule lives in exactly one place.
func _add_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + count

func _remove_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) - count
	if inventory[id] <= 0:
		inventory.erase(id)

# Whether one more `id` fits: existing stacks always take one more.
func _pack_has_room(id: String) -> bool:
	return inventory.has(id) or inventory.size() < inv_capacity()

func _recalc_stats() -> void:
	player_dmg = base_dmg
	var bonus_hp := 0
	var bonus_mana := 0
	for slot in equipment:
		var it: Dictionary = ITEMS[equipment[slot]]
		player_dmg += it.get("dmg", 0)
		bonus_hp += it.get("hp", 0)
		bonus_mana += it.get("mana", 0)
	player_max_hp = base_max_hp + bonus_hp
	player_max_mana = base_max_mana + bonus_mana
	player_hp = min(player_hp, player_max_hp)
	player_mana = min(player_mana, player_max_mana)

func _equip(id: String) -> void:
	var it: Dictionary = ITEMS[id]
	var slot: int = it["slot"]
	# Rings and trinkets have a second slot; use it if the first is taken.
	if slot == 11 and equipment.has(11) and not equipment.has(12):
		slot = 12
	elif slot == 13 and equipment.has(13) and not equipment.has(14):
		slot = 14
	_remove_item(id)
	if equipment.has(slot):
		var old: String = equipment[slot]
		_add_item(old)
		_log("You swap %s for %s." % [ITEMS[old]["name"], it["name"]])
	else:
		_log("Equipped: %s (%s)." % [it["name"], SLOT_NAMES[slot]])
	equipment[slot] = id
	_recalc_stats()

func _unequip(slot: int) -> void:
	if not equipment.has(slot):
		return
	var id: String = equipment[slot]
	var needs_new_stack: bool = not inventory.has(id)
	var cap_after := BASE_INV_SLOTS if slot == 20 else inv_capacity()
	var size_after: int = inventory.size() + (1 if needs_new_stack else 0)
	if size_after > cap_after:
		_log("Not enough room in your pack to remove that.")
		return
	equipment.erase(slot)
	_add_item(id)
	_recalc_stats()
	_log("Unequipped: %s." % ITEMS[id]["name"])


# ---------------------------------------------------------
#  XP and leveling
# ---------------------------------------------------------
func _gain_xp(amount: int) -> void:
	player_xp += amount
	while player_xp >= xp_needed():
		player_xp -= xp_needed()
		player_level += 1
		base_max_hp += 3
		base_max_mana += 2
		if player_level % 2 == 0:
			base_dmg += 1
			_log("Level %d! Max HP +3, damage +1. Fully healed." % player_level)
		else:
			_log("Level %d! Max HP +3. Fully healed." % player_level)
		_recalc_stats()
		player_hp = player_max_hp
		player_mana = player_max_mana

func xp_needed() -> int:
	return 20 + player_level * 10




# ---------------------------------------------------------
#  Options: sound (master volume), keybinds, graphics.
#  Settings persist to user://settings.cfg.
# ---------------------------------------------------------
const OPT_MAIN := ["Graphics", "Sound", "Keybinds", "Back"]
const REBIND_ACTIONS := ["up", "down", "left", "right",
		"up_left", "up_right", "down_left", "down_right",
		"wait", "character", "journal", "options"]
const REBIND_LABELS := ["Move up", "Move down", "Move left", "Move right",
		"Move up-left", "Move up-right", "Move down-left", "Move down-right",
		"Wait", "Character sheet", "Quest journal", "Options menu"]

func _options_input(key: int) -> void:
	if opt_rebinding:
		if key != KEY_ESCAPE:
			keymap[REBIND_ACTIONS[opt_index]] = key
			_save_settings()
		opt_rebinding = false
		_refresh()
		return
	match options_screen:
		"main":
			if key == KEY_UP:
				opt_index = max(opt_index - 1, 0)
			elif key == KEY_DOWN:
				opt_index = min(opt_index + 1, OPT_MAIN.size() - 1)
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				match opt_index:
					0: options_screen = "graphics"
					1: options_screen = "sound"
					2: options_screen = "keybinds"
					3:
						_close_panel()
						return
				opt_index = 0
			elif key == KEY_ESCAPE:
				_close_panel()
				return
			_refresh()
		"graphics":
			if key == KEY_ENTER or key == KEY_KP_ENTER:
				_toggle_fullscreen()
				_save_settings()
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = 0
			_refresh()
		"sound":
			if key == KEY_LEFT:
				master_volume = clamp(master_volume - 0.1, 0.0, 1.0)
				_apply_volume()
				_save_settings()
			elif key == KEY_RIGHT:
				master_volume = clamp(master_volume + 0.1, 0.0, 1.0)
				_apply_volume()
				_save_settings()
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = 1
			_refresh()
		"keybinds":
			if key == KEY_UP:
				opt_index = max(opt_index - 1, 0)
			elif key == KEY_DOWN:
				opt_index = min(opt_index + 1, REBIND_ACTIONS.size() - 1)
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				opt_rebinding = true
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = 2
			_refresh()

# Click/tap handling for the options menu. Geometry here must mirror
# _draw_panel_options in hud.gd. is_press is true for the initial click/tap
# and false for a drag/motion update (used to slide the volume meter).
func _options_click(mp: Vector2, is_press: bool) -> void:
	var vs := get_viewport_rect().size
	match options_screen:
		"main":
			if not is_press:
				return
			var w := 420.0
			var h := 220.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in OPT_MAIN.size():
				var yy := py + 62 + i * 30
				if Rect2(px + 8, yy - 18, 404, 26).has_point(mp):
					opt_index = i
					match i:
						0: options_screen = "graphics"
						1: options_screen = "sound"
						2: options_screen = "keybinds"
						3:
							_close_panel()
							return
					opt_index = 0
					_refresh()
					return
		"graphics":
			if not is_press:
				return
			var w := 420.0
			var h := 150.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			if Rect2(px + 8, py + 46, 404, 26).has_point(mp):
				_toggle_fullscreen()
				_save_settings()
				_refresh()
		"sound":
			var w := 420.0
			var h := 160.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			var slider := Rect2(px + 20, py + 76, 380.0, 15.0)
			if is_press:
				if not slider.grow(6.0).has_point(mp):
					return
				opt_slider_dragging = true
			elif not opt_slider_dragging:
				return
			master_volume = clamp((mp.x - slider.position.x) / slider.size.x, 0.0, 1.0)
			_apply_volume()
			_save_settings()
			_refresh()
		"keybinds":
			if not is_press:
				return
			var h := 110.0 + REBIND_ACTIONS.size() * 26.0
			var w := 460.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in REBIND_ACTIONS.size():
				var yy := py + 62 + i * 26
				if Rect2(px + 8, yy - 17, 444, 24).has_point(mp):
					opt_index = i
					opt_rebinding = true
					_refresh()
					return

func _toggle_fullscreen() -> void:
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_MAXIMIZED
	else:
		win.mode = Window.MODE_FULLSCREEN

func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(master_volume, 0.001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.005)

func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("sound", "master", master_volume)
	cf.set_value("graphics", "fullscreen", get_window().mode == Window.MODE_FULLSCREEN)
	for a in REBIND_ACTIONS:
		cf.set_value("keys", a, keymap[a])
	cf.save("user://settings.cfg")

func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://settings.cfg") != OK:
		return
	master_volume = cf.get_value("sound", "master", 1.0)
	for a in REBIND_ACTIONS:
		keymap[a] = cf.get_value("keys", a, keymap[a])
	if cf.get_value("graphics", "fullscreen", false):
		get_window().mode = Window.MODE_FULLSCREEN


# ---------------------------------------------------------
#  Weather: each time you enter an area there is a 10% chance
#  of rain (looping ambience + animated streaks). While it
#  rains, distant lightning strikes now and then: a thunder
#  rumble and a brief flash of the screen.
# ---------------------------------------------------------
func _set_rain(on: bool) -> void:
	raining = on
	flash_alpha = 0.0
	if on:
		lightning_timer = randf_range(4.0, 14.0)
		if not rain_player.playing:
			rain_player.play()
		_log("Rain begins to fall.")
	else:
		rain_player.stop()

func _weather_tick(delta: float) -> void:
	if flash_alpha > 0.0:
		flash_alpha = max(flash_alpha - delta * 2.2, 0.0)
		hud.queue_redraw()   # keep fading even if the rain just stopped
	if not raining:
		return
	hud.queue_redraw()   # animate the rain streaks
	lightning_timer -= delta
	if lightning_timer <= 0.0:
		lightning_timer = randf_range(8.0, 24.0)
		flash_alpha = 1.0
		thunder_player.play()


# ---------------------------------------------------------
#  Music: town theme in town, exploration outside,
#  combat as soon as any enemy has the player in sight.
#  Tracks were composed for this project (tools/make_music.py)
#  and are public domain.
# ---------------------------------------------------------
func _update_music() -> void:
	if _enemy_in_sight():
		combat_heat = 5
	elif combat_heat > 0:
		combat_heat -= 1
	if combat_heat > 0:
		_play_track("combat")
	else:
		_play_track(MAP_DEFS[current_map]["music"])

func _enemy_in_sight() -> bool:
	for mob in mobs:
		var t: Dictionary = MOB_TYPES[mob["type"]]
		var mp: Vector2i = mob["pos"]
		var d: int = abs(player_pos.x - mp.x) + abs(player_pos.y - mp.y)
		if d <= t["sight"]:
			return true
	return false

func _play_track(track: String) -> void:
	if music_track == track:
		return
	music_track = track
	var stream: AudioStreamOggVorbis = load("res://audio/%s.ogg" % track)
	stream.loop = true
	music.stream = stream
	music.play()


# ---------------------------------------------------------
#  Mob turn
# ---------------------------------------------------------
func _mob_turn() -> void:
	for mob in mobs:
		var t: Dictionary = MOB_TYPES[mob["type"]]
		var mp: Vector2i = mob["pos"]
		var diff := player_pos - mp

		if max(abs(diff.x), abs(diff.y)) == 1:
			player_hp -= t["dmg"]
			_log("The %s hits you for %d! (%d/%d HP)"
					% [t["name"], t["dmg"], max(player_hp, 0), player_max_hp])
			if player_hp <= 0:
				game_over = true
				_log("You died. Press Enter to restart.")
				return
			continue

		# Far-away mobs stand still; saves work on a big map.
		if abs(diff.x) + abs(diff.y) > 40:
			continue

		var step := Vector2i.ZERO
		if abs(diff.x) + abs(diff.y) <= t["sight"]:
			var options := []
			if diff.x != 0 and diff.y != 0:
				options.append(Vector2i(sign(diff.x), sign(diff.y)))
			if abs(diff.x) >= abs(diff.y):
				if diff.x != 0:
					options.append(Vector2i(sign(diff.x), 0))
				if diff.y != 0:
					options.append(Vector2i(0, sign(diff.y)))
			else:
				if diff.y != 0:
					options.append(Vector2i(0, sign(diff.y)))
				if diff.x != 0:
					options.append(Vector2i(sign(diff.x), 0))
			for o in options:
				if _is_free(mp + o):
					step = o
					break
		else:
			var o: Vector2i = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
			if _is_free(mp + o):
				step = o

		mob["pos"] = mp + step


# ---------------------------------------------------------
#  Grid queries
# ---------------------------------------------------------
func _in_bounds(p: Vector2i) -> bool:
	return p.y >= 0 and p.y < grid.size() and p.x >= 0 and p.x < grid[p.y].size()

func _is_walkable(p: Vector2i) -> bool:
	if not _in_bounds(p):
		return false
	var c: String = grid[p.y][p.x]
	return c == "." or c == "D" or c == "^" or c == "v"

func _is_free(p: Vector2i) -> bool:
	if not _is_walkable(p):
		return false
	if p == player_pos:
		return false
	if _vendor_at(p) >= 0:
		return false
	return _mob_at(p) == -1

func _mob_at(p: Vector2i) -> int:
	for i in mobs.size():
		if mobs[i]["pos"] == p:
			return i
	return -1

func _vendor_at(p: Vector2i) -> int:
	for i in vendors.size():
		if vendors[i]["pos"] == p:
			return i
	return -1


# ---------------------------------------------------------
#  Messages
# ---------------------------------------------------------
func _log(text: String) -> void:
	messages.append(text)
	if messages.size() > 8:
		messages.pop_front()


# ---------------------------------------------------------
#  World rendering (only the tiles the camera can see)
# ---------------------------------------------------------
func _draw() -> void:
	if grid.is_empty():
		return
	var vsize := get_viewport_rect().size
	# get_screen_center_position() is the REAL view center after the
	# camera limits clamp it; camera.position is only the target.
	var topleft := camera.get_screen_center_position() - vsize * 0.5
	var mw: int = grid[0].size()
	var mh: int = grid.size()
	var x0: int = clamp(int(floor(topleft.x / TILE)) - 2, 0, mw - 1)
	var y0: int = clamp(int(floor(topleft.y / TILE)) - 2, 0, mh - 1)
	var x1: int = clamp(int(ceil((topleft.x + vsize.x) / TILE)) + 2, 0, mw - 1)
	var y1: int = clamp(int(ceil((topleft.y + vsize.y) / TILE)) + 2, 0, mh - 1)

	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_draw_tile(x, y)

	var view := Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)
	for it in ground_items:
		if view.has_point(it["pos"]):
			_draw_ground_item(it)
	for v in vendors:
		if view.has_point(v["pos"]):
			_draw_vendor(v)
	for mob in mobs:
		if view.has_point(mob["pos"]):
			_draw_mob(mob)
	_draw_player()

func _draw_tile(x: int, y: int) -> void:
	var c: String = grid[y][x]
	var pos := Vector2(x * TILE, y * TILE)
	var r := Rect2(pos, Vector2(TILE, TILE))
	var inner := Rect2(pos + Vector2(2, 2), Vector2(TILE - 4, TILE - 4))

	draw_rect(r, Color(0.20, 0.26, 0.18))
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(TILE - 2, TILE - 2)), Color(0.24, 0.31, 0.21))

	match c:
		"#":
			draw_rect(r, Color(0.38, 0.38, 0.44))
			draw_rect(inner, Color(0.48, 0.48, 0.54))
		"H":
			draw_rect(r, Color(0.32, 0.20, 0.10))
			draw_rect(inner, Color(0.45, 0.29, 0.15))
		"S":
			draw_rect(r, Color(0.40, 0.42, 0.50))
			draw_rect(inner, Color(0.55, 0.57, 0.66))
		"A":
			draw_rect(r, Color(0.40, 0.42, 0.50))
			draw_rect(Rect2(pos + Vector2(8, 12), Vector2(16, 14)), Color(0.62, 0.64, 0.72))
			draw_rect(Rect2(pos + Vector2(14, 8), Vector2(4, 6)), Color(0.90, 0.88, 0.70))
			draw_circle(pos + Vector2(16, 6), 3.0, Color(1.0, 0.65, 0.15))
		"D":
			draw_rect(Rect2(pos + Vector2(7, 3), Vector2(TILE - 14, TILE - 6)), Color(0.55, 0.38, 0.16))
			draw_circle(pos + Vector2(TILE - 12, TILE * 0.5), 2.0, Color(0.85, 0.75, 0.3))
		"T":
			draw_rect(Rect2(pos + Vector2(13, 18), Vector2(6, 12)), Color(0.35, 0.22, 0.10))
			draw_circle(pos + Vector2(16, 12), 11.0, Color(0.10, 0.38, 0.14))
			draw_circle(pos + Vector2(11, 15), 7.0, Color(0.13, 0.45, 0.17))
			draw_circle(pos + Vector2(21, 15), 7.0, Color(0.13, 0.45, 0.17))
		"~":
			draw_rect(r, Color(0.12, 0.24, 0.42))
			draw_rect(inner, Color(0.16, 0.30, 0.50))
			draw_rect(Rect2(pos + Vector2(6, 12), Vector2(10, 2)), Color(0.35, 0.50, 0.70))
			draw_rect(Rect2(pos + Vector2(16, 22), Vector2(10, 2)), Color(0.35, 0.50, 0.70))
		"^", "v":
			draw_rect(inner, Color(0.42, 0.34, 0.22))
			var mid := pos + Vector2(TILE, TILE) * 0.5
			var pts: PackedVector2Array
			if c == "^":
				pts = PackedVector2Array([mid + Vector2(0, -9), mid + Vector2(8, 7), mid + Vector2(-8, 7)])
			else:
				pts = PackedVector2Array([mid + Vector2(0, 9), mid + Vector2(8, -7), mid + Vector2(-8, -7)])
			draw_colored_polygon(pts, Color(0.85, 0.78, 0.55))

func _draw_ground_item(it: Dictionary) -> void:
	var mid := Vector2(it["pos"]) * TILE + Vector2(TILE, TILE) * 0.5
	var pts := PackedVector2Array([
		mid + Vector2(0, -9), mid + Vector2(8, 0), mid + Vector2(0, 9), mid + Vector2(-8, 0)])
	draw_colored_polygon(pts, Color(1.0, 0.82, 0.20))
	draw_circle(mid, 3.0, Color(1.0, 0.95, 0.6))

# Each vendor is unique: a gold badge holding a symbol for their
# trade (bread loaf, anvil, alchemy flask, coin bag) with their
# name written underneath.
func _draw_vendor(v: Dictionary) -> void:
	var data: Dictionary = VENDORS[v["set_idx"] % VENDORS.size()]
	var center := Vector2(v["pos"]) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(center, 12.0, Color(0.85, 0.72, 0.20))
	draw_circle(center, 12.0, Color(0.4, 0.32, 0.05), false, 2.0)
	match data["symbol"]:
		"bread":
			draw_rect(Rect2(center + Vector2(-6, -3), Vector2(12, 7)), Color(0.55, 0.34, 0.13))
			draw_rect(Rect2(center + Vector2(-6, -3), Vector2(12, 3)), Color(0.80, 0.58, 0.28))
			for i in 3:
				draw_line(center + Vector2(-4 + i * 4, -2.5), center + Vector2(-2.5 + i * 4, -0.5),
						Color(0.45, 0.27, 0.10), 1.0)
		"anvil":
			draw_rect(Rect2(center + Vector2(-7, -5), Vector2(14, 4)), Color(0.22, 0.22, 0.26))
			draw_rect(Rect2(center + Vector2(-2.5, -1), Vector2(5, 4)), Color(0.30, 0.30, 0.34))
			draw_rect(Rect2(center + Vector2(-5, 3), Vector2(10, 3)), Color(0.22, 0.22, 0.26))
		"flask":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-1.8, -6), center + Vector2(1.8, -6),
				center + Vector2(1.8, -1), center + Vector2(5.5, 6),
				center + Vector2(-5.5, 6), center + Vector2(-1.8, -1)]),
				Color(0.75, 0.85, 0.92, 0.85))
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(2.9, 1), center + Vector2(5.5, 6),
				center + Vector2(-5.5, 6), center + Vector2(-2.9, 1)]),
				Color(0.25, 0.68, 0.30))
			draw_rect(Rect2(center + Vector2(-2.4, -7.5), Vector2(4.8, 1.8)), Color(0.50, 0.36, 0.18))
		"bag":
			draw_circle(center + Vector2(0, 1.5), 5.5, Color(0.48, 0.32, 0.14))
			draw_rect(Rect2(center + Vector2(-2.5, -6), Vector2(5, 3)), Color(0.36, 0.24, 0.10))
			draw_circle(center + Vector2(0, 2), 2.2, Color(0.95, 0.82, 0.30))
		_:
			_draw_glyph(center, "V", Color(0.15, 0.12, 0.02))
	# name plate under the symbol
	var label: String = data["short"]
	var lw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, center + Vector2(-lw * 0.5 + 1, 24), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.75))
	draw_string(font, center + Vector2(-lw * 0.5, 23), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.92, 0.78))

func _draw_mob(mob: Dictionary) -> void:
	var t: Dictionary = MOB_TYPES[mob["type"]]
	var center := Vector2(mob["pos"]) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(center, 11.0, t["color"])
	draw_circle(center, 11.0, Color(0, 0, 0, 0.5), false, 2.0)
	_draw_mob_icon(center, mob["type"], t["color"])
	var maxhp: int = MOB_TYPES[mob["type"]]["hp"]
	var frac: float = float(mob["hp"]) / float(maxhp)
	draw_rect(Rect2(center + Vector2(-10, -17), Vector2(20, 3)), Color(0.2, 0.05, 0.05))
	draw_rect(Rect2(center + Vector2(-10, -17), Vector2(20.0 * frac, 3)), Color(0.9, 0.25, 0.2))

# A small face icon per mob type, drawn on the colored disc.
func _draw_mob_icon(c: Vector2, type: String, base: Color) -> void:
	var dark := Color(0.08, 0.06, 0.05)
	match type:
		"r":  # rat: round ears, beady eyes, pink nose, whiskers
			draw_circle(c + Vector2(-5.5, -6.5), 3.2, base.darkened(0.25))
			draw_circle(c + Vector2(5.5, -6.5), 3.2, base.darkened(0.25))
			draw_circle(c + Vector2(-5.5, -6.5), 1.6, Color(0.85, 0.60, 0.60))
			draw_circle(c + Vector2(5.5, -6.5), 1.6, Color(0.85, 0.60, 0.60))
			draw_circle(c + Vector2(-3, -1), 1.1, dark)
			draw_circle(c + Vector2(3, -1), 1.1, dark)
			draw_circle(c + Vector2(0, 4), 1.6, Color(0.90, 0.55, 0.55))
			draw_line(c + Vector2(-2, 4), c + Vector2(-8, 2.5), Color(0.9, 0.88, 0.8), 0.8)
			draw_line(c + Vector2(-2, 5), c + Vector2(-8, 6), Color(0.9, 0.88, 0.8), 0.8)
			draw_line(c + Vector2(2, 4), c + Vector2(8, 2.5), Color(0.9, 0.88, 0.8), 0.8)
			draw_line(c + Vector2(2, 5), c + Vector2(8, 6), Color(0.9, 0.88, 0.8), 0.8)
		"g":  # goblin: pointed ears, slanted yellow eyes, jagged grin
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-9, -2), c + Vector2(-14, -8), c + Vector2(-7, -6)]), base.darkened(0.15))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(9, -2), c + Vector2(14, -8), c + Vector2(7, -6)]), base.darkened(0.15))
			draw_line(c + Vector2(-5.5, -4), c + Vector2(-1.5, -2), Color(0.95, 0.85, 0.25), 2.2)
			draw_line(c + Vector2(5.5, -4), c + Vector2(1.5, -2), Color(0.95, 0.85, 0.25), 2.2)
			draw_line(c + Vector2(-4.5, 4.5), c + Vector2(-1.5, 3), dark, 1.4)
			draw_line(c + Vector2(-1.5, 3), c + Vector2(1.5, 4.5), dark, 1.4)
			draw_line(c + Vector2(1.5, 4.5), c + Vector2(4.5, 3), dark, 1.4)
		"b":  # boar: broad snout with nostrils, upward tusks
			draw_circle(c + Vector2(-4, -3.5), 1.3, dark)
			draw_circle(c + Vector2(4, -3.5), 1.3, dark)
			draw_rect(Rect2(c + Vector2(-4.5, 0.5), Vector2(9, 6)), base.darkened(0.3))
			draw_circle(c + Vector2(-2, 3.5), 1.1, dark)
			draw_circle(c + Vector2(2, 3.5), 1.1, dark)
			draw_line(c + Vector2(-5.5, 4), c + Vector2(-8, -0.5), Color(0.95, 0.92, 0.82), 2.0)
			draw_line(c + Vector2(5.5, 4), c + Vector2(8, -0.5), Color(0.95, 0.92, 0.82), 2.0)
		"w":  # wolf: pointed ears, amber eyes, long muzzle
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-7, -5), c + Vector2(-8.5, -12), c + Vector2(-2.5, -7)]), base.darkened(0.2))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(7, -5), c + Vector2(8.5, -12), c + Vector2(2.5, -7)]), base.darkened(0.2))
			draw_circle(c + Vector2(-3.5, -2), 1.4, Color(0.95, 0.75, 0.25))
			draw_circle(c + Vector2(3.5, -2), 1.4, Color(0.95, 0.75, 0.25))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-3, 1), c + Vector2(3, 1), c + Vector2(0, 8)]), base.darkened(0.3))
			draw_circle(c + Vector2(0, 6.5), 1.3, dark)
		"s":  # skeleton: skull with hollow sockets and teeth
			draw_circle(c + Vector2(0, -2), 7.0, Color(0.94, 0.93, 0.85))
			draw_rect(Rect2(c + Vector2(-4.5, 3), Vector2(9, 5)), Color(0.94, 0.93, 0.85))
			draw_circle(c + Vector2(-3, -3), 2.1, dark)
			draw_circle(c + Vector2(3, -3), 2.1, dark)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-1.2, 1.5), c + Vector2(1.2, 1.5), c + Vector2(0, 3.5)]), dark)
			for i in 3:
				draw_line(c + Vector2(-2.4 + i * 2.4, 5), c + Vector2(-2.4 + i * 2.4, 8), dark, 0.9)
		"t":  # troll: heavy brow, sunken eyes, underbite tusks
			draw_rect(Rect2(c + Vector2(-7, -6), Vector2(14, 3.5)), base.darkened(0.35))
			draw_circle(c + Vector2(-3.5, -0.5), 1.3, Color(0.95, 0.55, 0.2))
			draw_circle(c + Vector2(3.5, -0.5), 1.3, Color(0.95, 0.55, 0.2))
			draw_line(c + Vector2(-4.5, 5.5), c + Vector2(4.5, 5.5), base.darkened(0.4), 2.5)
			draw_rect(Rect2(c + Vector2(-4.5, 2.8), Vector2(2, 3)), Color(0.95, 0.92, 0.82))
			draw_rect(Rect2(c + Vector2(2.5, 2.8), Vector2(2, 3)), Color(0.95, 0.92, 0.82))

func _draw_player() -> void:
	var center := Vector2(player_pos) * TILE + Vector2(TILE, TILE) * 0.5
	draw_hero_on(self, center, 1.0)

# Draws the hero on any canvas item (the world here, the paper doll in the
# HUD). Androgynous by design: shoulder-length hair, bare torso, soft face.
# Equipped gear that has a visible form is drawn on the figure.
func draw_hero_on(ci: CanvasItem, c: Vector2, s: float) -> void:
	var skin := Color(0.87, 0.71, 0.57)
	var skin_sh := Color(0.76, 0.59, 0.46)
	var hair := Color(0.42, 0.28, 0.15)
	var pants := Color(0.30, 0.34, 0.42)
	if equipment.has(15):  # cloak behind everything
		ci.draw_rect(Rect2(c + Vector2(-7, -7) * s, Vector2(14, 17) * s), Color(0.35, 0.16, 0.14))
	ci.draw_rect(Rect2(c + Vector2(-4.5, 3) * s, Vector2(3.5, 9) * s), pants)
	ci.draw_rect(Rect2(c + Vector2(1, 3) * s, Vector2(3.5, 9) * s), pants)
	ci.draw_rect(Rect2(c + Vector2(-5, -5) * s, Vector2(10, 8) * s), skin)
	ci.draw_rect(Rect2(c + Vector2(-8, -5) * s, Vector2(3, 8) * s), skin_sh)   # arms
	ci.draw_rect(Rect2(c + Vector2(5, -5) * s, Vector2(3, 8) * s), skin_sh)
	ci.draw_circle(c + Vector2(0, -11) * s, 5.2 * s, hair)                     # hair behind head
	ci.draw_rect(Rect2(c + Vector2(-6.5, -12) * s, Vector2(2, 9) * s), hair)   # strands
	ci.draw_rect(Rect2(c + Vector2(4.5, -12) * s, Vector2(2, 9) * s), hair)
	ci.draw_circle(c + Vector2(0, -10) * s, 4.4 * s, skin)                     # face
	ci.draw_rect(Rect2(c + Vector2(-4.2, -14.6) * s, Vector2(8.4, 2.6) * s), hair)  # fringe
	ci.draw_circle(c + Vector2(-1.7, -10) * s, 0.6 * s, Color(0.15, 0.12, 0.10))
	ci.draw_circle(c + Vector2(1.7, -10) * s, 0.6 * s, Color(0.15, 0.12, 0.10))
	ci.draw_rect(Rect2(c + Vector2(-5, 2) * s, Vector2(10, 1.8) * s), Color(0.26, 0.18, 0.10))
	if equipment.has(1):   # leather cap
		ci.draw_rect(Rect2(c + Vector2(-5, -16) * s, Vector2(10, 3.4) * s), Color(0.45, 0.30, 0.14))
	if equipment.has(16):  # sword in the main hand
		ci.draw_line(c + Vector2(7, 3) * s, c + Vector2(11.5, -9) * s, Color(0.75, 0.78, 0.85), 1.6 * s)
		ci.draw_line(c + Vector2(6, -1.5) * s, c + Vector2(9.5, -0.2) * s, Color(0.45, 0.32, 0.14), 1.4 * s)
	if equipment.has(17):  # shield on the off hand
		ci.draw_circle(c + Vector2(-8.5, 0) * s, 4.2 * s, Color(0.48, 0.34, 0.16))
		ci.draw_circle(c + Vector2(-8.5, 0) * s, 4.2 * s, Color(0.28, 0.19, 0.08), false, 1.2 * s)

func _draw_glyph(center: Vector2, ch: String, col: Color) -> void:
	var size := 16
	var w: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, center + Vector2(-w * 0.5, 6), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
