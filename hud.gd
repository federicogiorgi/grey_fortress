extends Node2D
# HUD lives on a CanvasLayer, so it stays put while the camera
# scrolls over the world. It only reads state from the game node.

const BAR_H := 84

var game: Node2D
@onready var font: Font = ThemeDB.fallback_font


func _draw() -> void:
	if game == null:
		return
	if game.mode == game.Mode.TITLE:
		_draw_title()
		return
	if game.grid.is_empty():
		return
	if game.raining:
		_draw_rain()
	_draw_bar()
	_draw_minimap()
	match game.mode:
		game.Mode.INVENTORY:
			_draw_panel_character()
		game.Mode.JOURNAL:
			_draw_panel_journal()
		game.Mode.SHOP:
			_draw_panel_shop()
		game.Mode.OPTIONS:
			_draw_panel_options()
		game.Mode.SPELLBOOK:
			_draw_panel_spellbook()
		game.Mode.WORLDMAP:
			_draw_panel_worldmap()
	if game.mode == game.Mode.PLAY and game.targeting:
		_draw_targeting()
	if game.banner_timer > 0.0:
		_draw_banner()
	if game.victory_banner:
		_draw_victory()
	if game.game_over:
		_draw_game_over()
	if game.flash_alpha > 0.0:
		var vs := get_viewport_rect().size
		draw_rect(Rect2(0, 0, vs.x, vs.y), Color(1.0, 1.0, 0.94, game.flash_alpha * 0.35))


# ---------------- rain overlay ----------------
# Streaks fall over the world area; positions derive from hashed
# per-streak constants plus time, so no state is stored anywhere.
# All segments go into one draw_multiline call.
func _draw_rain() -> void:
	var vs := get_viewport_rect().size
	var t := Time.get_ticks_msec() / 1000.0
	var world_h := vs.y - BAR_H
	draw_rect(Rect2(0, 0, vs.x, world_h), Color(0.08, 0.10, 0.18, 0.16))
	var pts := PackedVector2Array()
	pts.resize(220)
	for i in 110:
		var sx: float = fposmod(sin(i * 127.1 + 311.7) * 43758.55, 1.0)
		var sy: float = fposmod(sin(i * 269.5 + 183.3) * 28001.83, 1.0)
		var speed: float = 540.0 + 380.0 * sx
		var x: float = fposmod(sx * vs.x + t * 30.0, vs.x)
		var y: float = fposmod(sy * world_h + t * speed, world_h)
		pts[i * 2] = Vector2(x, y)
		pts[i * 2 + 1] = Vector2(x - 2.5, y + 11.0)
	draw_multiline(pts, Color(0.62, 0.72, 0.92, 0.32), 1.0)


# ---------------- title screen ----------------
# A grey fortress on a hill under a crescent moon and a starry sky,
# all drawn with canvas primitives.
func _draw_title() -> void:
	var vs := get_viewport_rect().size
	var sky_top := Color(0.02, 0.03, 0.08)
	var sky_bottom := Color(0.07, 0.09, 0.20)
	var horizon := vs.y * 0.70

	# night sky: vertical gradient in bands
	var bands := 24
	for i in bands:
		var f := i / float(bands)
		draw_rect(Rect2(0, horizon * f, vs.x, horizon / bands + 1.0),
				sky_top.lerp(sky_bottom, f))

	# stars (deterministic scatter, denser near the top)
	for i in 150:
		var sx: float = fposmod(sin(i * 127.1 + 41.3) * 43758.55, 1.0) * vs.x
		var sy: float = pow(fposmod(sin(i * 269.5 + 17.7) * 28001.83, 1.0), 1.4) * horizon * 0.95
		var r: float = 0.5 + fposmod(sin(i * 7.31) * 971.5, 1.0) * 1.1
		var a: float = 0.35 + 0.55 * fposmod(sin(i * 3.7) * 337.1, 1.0)
		draw_circle(Vector2(sx, sy), r, Color(0.90, 0.92, 1.0, a))

	# crescent moon: a bright disc with a sky-colored disc biting it
	var mc := Vector2(vs.x * 0.615, vs.y * 0.26)
	draw_circle(mc, 58.0, Color(0.93, 0.91, 0.80))
	draw_circle(mc + Vector2(-22.0, -9.0), 52.0, sky_top.lerp(sky_bottom, 0.37))

	# ground: a dark hill the fortress stands on
	draw_rect(Rect2(0, horizon, vs.x, vs.y - horizon), Color(0.05, 0.07, 0.06))
	draw_colored_polygon(PackedVector2Array([
		Vector2(vs.x * 0.18, horizon), Vector2(vs.x * 0.82, horizon),
		Vector2(vs.x * 0.92, vs.y), Vector2(vs.x * 0.08, vs.y)]),
		Color(0.07, 0.10, 0.08))

	_draw_title_fortress(Vector2(vs.x * 0.5, horizon))

	# title
	var title := "GREY FORTRESS"
	var tw: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 58).x
	draw_string(font, Vector2((vs.x - tw) * 0.5 + 3, vs.y * 0.135 + 3), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 58, Color(0, 0, 0, 0.7))
	draw_string(font, Vector2((vs.x - tw) * 0.5, vs.y * 0.135), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 58, Color(0.88, 0.86, 0.78))
	var sub := "a tiny roguelike"
	var sw: float = font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2((vs.x - sw) * 0.5, vs.y * 0.135 + 28), sub,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55, 0.56, 0.65))

	# menu
	var rects: Array = game.title_menu_rects()
	for i in rects.size():
		var r: Rect2 = rects[i]
		var enabled: bool = i != 1 or game.has_save()
		var selected: bool = game.title_index == i
		draw_rect(r, Color(0.16, 0.19, 0.30, 0.92) if selected else Color(0.07, 0.08, 0.13, 0.88))
		draw_rect(r, Color(0.85, 0.72, 0.20) if selected else Color(0.32, 0.32, 0.40), false, 1.0)
		var label: String = game.TITLE_MENU[i]
		if i == 1 and not enabled:
			label += "  (no save)"
		var lw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, Vector2(r.position.x + (r.size.x - lw) * 0.5, r.position.y + 24.0),
				label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Color(0.92, 0.90, 0.80) if enabled else Color(0.42, 0.42, 0.50))

# The fortress silhouette; `base` is the middle of its footprint.
func _draw_title_fortress(base: Vector2) -> void:
	var wall := Color(0.30, 0.31, 0.36)
	var wall_dark := Color(0.22, 0.23, 0.28)
	var window := Color(0.95, 0.80, 0.35)

	# curtain wall with crenellations
	draw_rect(Rect2(base + Vector2(-190, -95), Vector2(380, 95)), wall_dark)
	for i in 13:
		draw_rect(Rect2(base + Vector2(-190 + i * 30, -107), Vector2(16, 12)), wall_dark)
	# side towers
	for side in [-1.0, 1.0]:
		var tx: float = base.x + side * 190.0 - 27.0
		draw_rect(Rect2(Vector2(tx, base.y - 160), Vector2(54, 160)), wall)
		for i in 3:
			draw_rect(Rect2(Vector2(tx - 4 + i * 21, base.y - 174), Vector2(13, 14)), wall)
		draw_rect(Rect2(Vector2(tx + 21, base.y - 130), Vector2(9, 14)), window)
	# central keep
	draw_rect(Rect2(base + Vector2(-52, -200), Vector2(104, 200)), wall)
	for i in 4:
		draw_rect(Rect2(base + Vector2(-52 + i * 27, -215), Vector2(15, 15)), wall)
	draw_rect(Rect2(base + Vector2(-32, -170), Vector2(10, 16)), window)
	draw_rect(Rect2(base + Vector2(20, -140), Vector2(10, 16)), window)
	# banner pole on the keep
	draw_line(base + Vector2(0, -215), base + Vector2(0, -250), Color(0.5, 0.5, 0.55), 2.0)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(0, -250), base + Vector2(30, -243), base + Vector2(0, -236)]),
		Color(0.45, 0.14, 0.14))
	# gate: an arch in the curtain wall
	draw_rect(Rect2(base + Vector2(-22, -52), Vector2(44, 52)), Color(0.05, 0.05, 0.08))
	draw_circle(base + Vector2(0, -52), 22.0, Color(0.05, 0.05, 0.08))


# ---------------- "Entering..." area banner ----------------
func _draw_banner() -> void:
	var vs := get_viewport_rect().size
	var alpha: float = clamp(game.banner_timer, 0.0, 1.0)
	var text: String = game.banner_text
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	var pos := Vector2((vs.x - w) * 0.5, vs.y * 0.24)
	draw_string(font, pos + Vector2(2, 2), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0, 0, 0, 0.6 * alpha))
	draw_string(font, pos, text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.93, 0.88, 0.72, alpha))


# ---------------- bottom status bar ----------------
func _draw_bar() -> void:
	var vs := get_viewport_rect().size
	var y := vs.y - BAR_H
	draw_rect(Rect2(0, y, vs.x, BAR_H), Color(0.06, 0.06, 0.08, 0.92))
	draw_line(Vector2(0, y), Vector2(vs.x, y), Color(0.3, 0.3, 0.35), 2.0)

	_meter(Vector2(10, y + 7), 190.0, float(max(game.player_hp, 0)) / game.player_max_hp,
			Color(0.72, 0.16, 0.14), "%d/%d" % [max(game.player_hp, 0), game.player_max_hp])
	_meter(Vector2(10, y + 26), 190.0, float(game.player_mana) / game.player_max_mana,
			Color(0.16, 0.32, 0.78), "%d/%d" % [game.player_mana, game.player_max_mana])
	_meter(Vector2(10, y + 45), 190.0, float(game.player_xp) / game.xp_needed(),
			Color(0.20, 0.55, 0.22), "%d/%d" % [game.player_xp, game.xp_needed()])
	# The area name lives on the minimap now, so this line stays short
	# and can no longer collide with the message log.
	draw_string(font, Vector2(10, y + 76),
			"Lv %d   Dmg %d   Coins %d" % [game.player_level, game.player_dmg, game.coins],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.72, 0.70, 0.60))

	var start: int = max(0, game.messages.size() - 4)
	var line := 0
	for i in range(start, game.messages.size()):
		draw_string(font, Vector2(230, y + 18 + line * 17), game.messages[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.78, 0.80))
		line += 1

	# The active spell, castable with the cast key or middle mouse.
	var sp: Dictionary = game.SPELLS[game.active_spell]
	var spell_x := vs.x - 489.0
	draw_rect(Rect2(spell_x, y + 10, 26, 26), Color(0.13, 0.13, 0.18))
	draw_rect(Rect2(spell_x, y + 10, 26, 26), Color(0.38, 0.38, 0.44), false, 1.0)
	game.draw_projectile_icon(self, game.active_spell, Vector2(spell_x + 13, y + 23), 0.0, 1.0)
	draw_string(font, Vector2(spell_x + 34, y + 22), sp["name"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.82, 0.82, 0.90))
	draw_string(font, Vector2(spell_x + 34, y + 37),
			"%d mana - %s casts" % [sp["mana"], game.spell_key_label()],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.55, 0.62))

	# Clickable panel buttons (movement itself stays keyboard-only).
	var rects: Array = game.bar_button_rects()
	var target_modes := [game.Mode.INVENTORY, game.Mode.JOURNAL, game.Mode.SPELLBOOK,
			game.Mode.WORLDMAP, game.Mode.OPTIONS]
	for i in rects.size():
		var r: Rect2 = rects[i]
		var active: bool = game.mode == target_modes[i]
		draw_rect(r, Color(0.22, 0.26, 0.36) if active else Color(0.14, 0.14, 0.18))
		draw_rect(r, Color(0.55, 0.55, 0.62) if active else Color(0.38, 0.38, 0.44), false, 1.0)
		var label: String = game.BAR_BUTTONS[i]
		var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(r.position.x + (r.size.x - tw) * 0.5, r.position.y + 17.5),
				label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.82, 0.82, 0.86))

# One resource meter: dark trough, colored fill, thin border, value inside.
func _meter(pos: Vector2, w: float, frac: float, col: Color, label: String) -> void:
	var h := 15.0
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.11, 0.11, 0.14))
	draw_rect(Rect2(pos, Vector2(w * clamp(frac, 0.0, 1.0), h)), col)
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.38, 0.38, 0.44), false, 1.0)
	var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, pos + Vector2((w - tw) * 0.5, 11.5), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.88))


# ---------------- area minimap ----------------
# The current area only: its real terrain, rendered once into a
# texture (one pixel block per tile, integer zoom, nearest-neighbor)
# and rebuilt when the map changes. The world overview lives in the
# world map screen (M).
var mini_tex: ImageTexture
var mini_for := ""       # which map the texture was built for
var mini_zoom := 1       # screen pixels per tile

const MINI_TILE_COLORS := {
	"T": Color(0.10, 0.30, 0.12), "~": Color(0.16, 0.30, 0.50),
	"S": Color(0.55, 0.57, 0.66), "H": Color(0.45, 0.29, 0.15),
	"D": Color(0.62, 0.44, 0.22), "A": Color(0.95, 0.80, 0.35),
	"^": Color(0.85, 0.78, 0.55), "v": Color(0.85, 0.78, 0.55),
	"<": Color(0.85, 0.78, 0.55), ">": Color(0.85, 0.78, 0.55),
	"B": Color(0.40, 0.30, 0.15), "O": Color(0.04, 0.04, 0.06),
	"U": Color(0.80, 0.78, 0.72), "R": Color(0.16, 0.15, 0.14),
	"F": Color(0.11, 0.09, 0.08), "E": Color(0.62, 0.54, 0.38),
}
const FOG_COLOR := Color(0.05, 0.05, 0.07)

func _build_minimap() -> void:
	var g: Array = game.grid
	var gw: int = g[0].size()
	var gh: int = g.size()
	mini_zoom = clamp(int(min(180.0 / gw, 126.0 / gh)), 1, 4)
	var def: Dictionary = game.MAP_DEFS[game.current_map]
	var floor_col: Color = game.map_tint(game.current_map)
	var wall_col: Color = def.get("palette", {}).get("wall", Color(0.45, 0.45, 0.50))
	# fog of war: tiles never shown on screen stay dark (villages exempt)
	var fog: bool = not def.get("no_fog", false)
	var expl: Array = game.map_state[game.current_map]["explored"]
	var img := Image.create(gw * mini_zoom, gh * mini_zoom, false, Image.FORMAT_RGB8)
	for y in gh:
		for x in gw:
			var col: Color
			if fog and expl[y][x] == 0:
				col = FOG_COLOR
			else:
				var c: String = g[y][x]
				col = MINI_TILE_COLORS.get(c, floor_col)
				if c == "#":
					col = wall_col
			img.fill_rect(Rect2i(x * mini_zoom, y * mini_zoom, mini_zoom, mini_zoom), col)
	mini_tex = ImageTexture.create_from_image(img)
	mini_for = game.current_map
	game.minimap_dirty = false

func _draw_minimap() -> void:
	if mini_for != game.current_map or game.minimap_dirty or mini_tex == null:
		_build_minimap()
	var vs := get_viewport_rect().size
	var pad := 7.0
	var tw: float = mini_tex.get_width()
	var th: float = mini_tex.get_height()
	var label: String = game.map_name(game.current_map)
	var label_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var w: float = max(tw, label_w) + pad * 2
	var h: float = th + pad * 2 + 17.0
	var px := vs.x - w - 10.0
	var py := vs.y - BAR_H - h - 10.0

	# translucent enough that loot lying under the overlay shines through
	draw_rect(Rect2(px, py, w, h), Color(0.06, 0.06, 0.09, 0.55))
	draw_rect(Rect2(px, py, w, h), Color(0.35, 0.35, 0.42), false, 1.0)
	var mx: float = px + (w - tw) * 0.5
	var my: float = py + pad
	draw_texture(mini_tex, Vector2(mx, my), Color(1, 1, 1, 0.80))
	var dot := Vector2(mx, my) + (Vector2(game.player_pos) + Vector2(0.5, 0.5)) * mini_zoom
	draw_circle(dot, 2.4, Color(1.0, 0.95, 0.75))
	draw_circle(dot, 2.4, Color(0.3, 0.2, 0.0), false, 0.8)
	draw_string(font, Vector2(px + (w - label_w) * 0.5, py + h - 6.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.92, 0.88, 0.75))


# ---------------- world map (M) ----------------
# Nodes come from game.world_layout(), which follows the MAP_DEFS
# links: any future region or dungeon level appears automatically.
# Visited areas show their name; areas merely glimpsed from a
# neighbor show "???", and Westmere's boarded gate shows the
# work-in-progress region to its north.
func _draw_panel_worldmap() -> void:
	var vs := get_viewport_rect().size
	var w: float = vs.x - 240.0
	var h: float = vs.y - BAR_H - 90.0
	var p := _panel(w, h, "World Map")

	var layout: Dictionary = game.world_layout()
	# what to show: visited areas, plus unvisited neighbors as "???"
	var shown := {}
	for id in layout:
		if game.visited.has(id):
			shown[id] = "known"
	for id in layout.keys():
		if not shown.has(id):
			continue
		for link in game.WORLD_LINK_DIRS:
			var def: Dictionary = game.MAP_DEFS[id]
			if def.has(link) and not shown.has(def[link]):
				shown[def[link]] = "mystery"
	# the boarded gate north of Westmere hints at the future region
	var extra := {}
	if game.visited.has("west"):
		extra["wip"] = layout["west"] + Vector2(0, -1)

	# fit the abstract grid into the panel
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for id in shown:
		lo = lo.min(layout[id])
		hi = hi.max(layout[id])
	for id in extra:
		lo = lo.min(extra[id])
		hi = hi.max(extra[id])
	var span := (hi - lo).max(Vector2.ONE)
	var cell := Vector2(min(200.0, (w - 220.0) / span.x), min(105.0, (h - 140.0) / span.y))
	var origin := Vector2(p.x, p.y + 30.0) + Vector2(w, h - 30.0) * 0.5 \
			- (lo + span * 0.5) * cell
	var node_size := Vector2(158, 52)

	# connections first, so nodes draw over them
	for id in shown:
		var def: Dictionary = game.MAP_DEFS[id]
		for link in game.WORLD_LINK_DIRS:
			if def.has(link) and shown.has(def[link]):
				draw_line(origin + layout[id] * cell, origin + layout[def[link]] * cell,
						Color(0.40, 0.40, 0.48), 2.0)
	if extra.has("wip"):
		draw_line(origin + layout["west"] * cell, origin + extra["wip"] * cell,
				Color(0.30, 0.30, 0.36), 2.0)

	for id in shown:
		var center: Vector2 = origin + layout[id] * cell
		var r := Rect2(center - node_size * 0.5, node_size)
		if shown[id] == "known":
			draw_rect(r, game.map_tint(id))
			var cur: bool = id == game.current_map
			draw_rect(r, Color(0.95, 0.82, 0.25) if cur else Color(0.55, 0.55, 0.62),
					false, 2.0 if cur else 1.0)
			var label: String = game.map_name(id)
			var lw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(font, center + Vector2(-lw * 0.5, -2 if cur else 5), label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.93, 0.85))
			if cur:
				var you := "* you are here *"
				var yw: float = font.get_string_size(you, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
				draw_string(font, center + Vector2(-yw * 0.5, 15), you,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.85, 0.45))
		else:
			draw_rect(r, Color(0.10, 0.10, 0.14))
			draw_rect(r, Color(0.30, 0.30, 0.36), false, 1.0)
			var qw: float = font.get_string_size("???", HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(font, center + Vector2(-qw * 0.5, 5), "???",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.50, 0.50, 0.58))
	if extra.has("wip"):
		var center: Vector2 = origin + extra["wip"] * cell
		var r := Rect2(center - node_size * 0.5, node_size)
		draw_rect(r, Color(0.08, 0.08, 0.11))
		draw_rect(r, Color(0.26, 0.26, 0.32), false, 1.0)
		var wt := "work in progress"
		var ww: float = font.get_string_size(wt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, center + Vector2(-ww * 0.5, 5), wt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.48, 0.48, 0.55))

	draw_string(font, Vector2(p.x + 16, p.y + h - 16), "Press any key or click to close.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- shared panel frame ----------------
func _panel(w: float, h: float, title: String) -> Vector2:
	var vs := get_viewport_rect().size
	var x := (vs.x - w) * 0.5
	var y := (vs.y - BAR_H - h) * 0.5
	draw_rect(Rect2(x - 4, y - 4, w + 8, h + 8), Color(0.35, 0.35, 0.42))
	draw_rect(Rect2(x, y, w, h), Color(0.09, 0.09, 0.12, 0.97))
	draw_string(font, Vector2(x + 16, y + 28), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.92, 0.88, 0.75))
	return Vector2(x, y)


# ---------------- character sheet: equipment + backpack ----------------
func _draw_panel_character() -> void:
	var w := 980.0
	var h := 596.0
	var p := _panel(w, h, "Character")
	var eq_x := p.x + 16
	var inv_x := p.x + 510.0
	var top := p.y + 60.0
	var row_h := 23.0

	# divider
	draw_line(Vector2(inv_x - 18, p.y + 44), Vector2(inv_x - 18, p.y + h - 40),
			Color(0.28, 0.28, 0.34), 1.0)

	# --- left: the hero, stats, and the 20 equipment slots ---
	game.draw_hero_on(self, Vector2(p.x + 410, p.y + 150), 4.5)
	draw_string(font, Vector2(p.x + 356, p.y + 250), "Dmg %d" % game.player_dmg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.7, 0.6))
	draw_string(font, Vector2(p.x + 356, p.y + 270), "HP %d/%d" % [max(game.player_hp, 0), game.player_max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.85, 0.7))
	if game.player_spell_dmg > 0:
		draw_string(font, Vector2(p.x + 356, p.y + 290), "Spell +%d" % game.player_spell_dmg,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.65, 0.72, 0.92))

	for i in game.SLOT_NAMES.size():
		var yy : int = top + i * row_h
		var selected: bool = game.mode == game.Mode.INVENTORY and game.ui_pane == 0 and game.ui_index == i
		if selected:
			draw_rect(Rect2(eq_x - 6, yy - 15, 320, row_h - 2), Color(0.22, 0.26, 0.36))
		var slot_col := Color(0.55, 0.55, 0.62)
		draw_string(font, Vector2(eq_x, yy), game.SLOT_NAMES[i] + ":",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, slot_col)
		var val := "-"
		var val_col := Color(0.4, 0.4, 0.46)
		if game.equipment.has(i):
			var it: Dictionary = game.ITEMS[game.equipment[i]]
			val = it["name"] + "  (" + it["desc"] + ")"
			val_col = Color(0.85, 0.85, 0.88)
		draw_string(font, Vector2(eq_x + 92, yy), val,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, val_col)

	# --- right: the backpack ---
	draw_string(font, Vector2(inv_x, p.y + 44), "Backpack  %d/%d slots     Coins %d"
			% [game.inventory.size(), game.inv_capacity(), game.coins],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.78, 0.65))
	# One flat row list: category headers with their items beneath.
	# Geometry mirrors _char_sheet_click in main.gd (16 px rows).
	var entries: Array = game.backpack_entries()
	if entries.is_empty():
		draw_string(font, Vector2(inv_x, top + 4), "Your pack is empty.",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.55, 0.6))
	var item_i := 0
	for i in entries.size():
		var yy := top + i * 16.0
		var e: Dictionary = entries[i]
		if e["kind"] == "header":
			draw_string(font, Vector2(inv_x, yy), e["text"],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.72, 0.35))
			continue
		var id: String = e["id"]
		var it: Dictionary = game.ITEMS[id]
		var selected: bool = game.mode == game.Mode.INVENTORY and game.ui_pane == 1 and game.ui_index == item_i
		if selected:
			draw_rect(Rect2(inv_x + 8, yy - 12, 444, 15), Color(0.22, 0.26, 0.36))
		var usable: bool = it.has("heal") or it.has("mana_heal") or it.has("portal")
		var tag := ""
		if it.has("slot"):
			tag = "  [" + game.SLOT_NAMES[it["slot"]] + "]"
		elif usable:
			tag = "  [use]"
		draw_string(font, Vector2(inv_x + 14, yy), "%s x%d%s - %s" % [it["name"], game.inventory[id], tag, it["desc"]],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color(0.85, 0.85, 0.88) if (it.has("slot") or usable) else Color(0.62, 0.62, 0.68))
		item_i += 1

	draw_string(font, Vector2(p.x + 16, p.y + h - 14),
			"Up/Down: select     Left/Right: switch side     Enter: equip / use / remove     Esc / right click / I: close",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- spellbook ----------------
# Row geometry comes from the SPB_* constants shared with
# _spellbook_click in main.gd.
func _draw_panel_spellbook() -> void:
	var w: float = game.SPB_W
	var h: float = 96.0 + game.SPELL_ORDER.size() * game.SPB_ROW_H
	var p := _panel(w, h, "Spellbook     (your mana: %d/%d)" % [game.player_mana, game.player_max_mana])
	for i in game.SPELL_ORDER.size():
		var id: String = game.SPELL_ORDER[i]
		var sp: Dictionary = game.SPELLS[id]
		var ry: float = p.y + game.SPB_TOP + i * game.SPB_ROW_H
		var row := Rect2(p.x + 8, ry, w - 16.0, game.SPB_ROW_H - 6.0)
		if i == game.spellbook_index:
			draw_rect(row, Color(0.22, 0.26, 0.36))
		if id == game.active_spell:
			draw_rect(row, Color(0.85, 0.72, 0.20), false, 1.0)
		game.draw_projectile_icon(self, id, row.position + Vector2(26, row.size.y * 0.5), 0.0, 1.4)
		var name_text: String = sp["name"] + ("   [active]" if id == game.active_spell else "")
		draw_string(font, row.position + Vector2(54, 20), name_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
				Color(0.95, 0.88, 0.60) if id == game.active_spell else Color(0.88, 0.88, 0.92))
		var dmg_text := str(sp["dmg"]) if game.player_spell_dmg == 0 \
				else "%d+%d" % [sp["dmg"], game.player_spell_dmg]
		draw_string(font, row.position + Vector2(54, 38),
				"%d mana, %s damage, range %d - %s" % [sp["mana"], dmg_text, sp["range"], sp["desc"]],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.62, 0.68))
	draw_string(font, Vector2(p.x + 16, p.y + h - 16),
			"Click a spell (or Up/Down + Enter) to make it the active one. Esc or right click closes.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- aiming overlay ----------------
# While targeting, the OS cursor is hidden: the spell icon takes its
# place, an aim line runs from the player to the cursor, and the
# hovered tile is highlighted (gold when castable, red when out of
# range or with a tree/wall in the way).
func _draw_targeting() -> void:
	var vs := get_viewport_rect().size
	var mp := get_viewport().get_mouse_position()
	if mp.y < vs.y - BAR_H:
		var tile: Vector2i = game.screen_to_tile(mp)
		var topleft: Vector2 = game.camera.get_screen_center_position() - vs * 0.5
		var spos := Vector2(tile) * float(game.TILE) - topleft
		var ok: bool = game.can_target(tile)
		var col := Color(0.95, 0.85, 0.30) if ok else Color(0.90, 0.25, 0.20)
		var player_screen := (Vector2(game.player_pos) + Vector2(0.5, 0.5)) * float(game.TILE) - topleft
		draw_line(player_screen, spos + Vector2(game.TILE, game.TILE) * 0.5,
				Color(col.r, col.g, col.b, 0.35), 2.0)
		draw_rect(Rect2(spos, Vector2(game.TILE, game.TILE)), col, false, 2.0)
	game.draw_projectile_icon(self, game.active_spell, mp, 0.0, 1.5)
	var hint := "Click a tile to cast. Esc or right click cancels."
	var hw: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, Vector2((vs.x - hw) * 0.5 + 1, 25), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.7))
	draw_string(font, Vector2((vs.x - hw) * 0.5, 24), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.92, 0.88, 0.72))


# ---------------- quest journal ----------------
func _draw_panel_journal() -> void:
	# Build each line first, then size the box to the widest one so
	# long quest names (e.g. the Mysterious Parchment) never overflow.
	var lines := []
	for q in game.quests:
		var text := ""
		var col := Color(0.85, 0.85, 0.88)
		match q["state"]:
			"hidden":
				text = "%s: ??? (go talk to them)" % q["giver"]
				col = Color(0.5, 0.5, 0.58)
			"active":
				match q["type"]:
					"kill":
						text = "%s: %s (%d/%d)" % [q["giver"], q["desc"], q["progress"], q["need"]]
					"coins":
						text = "%s: %s (you have %d)" % [q["giver"], q["desc"], game.coins]
					"item":
						var have: int = game.inventory.get(q["target"], 0)
						text = "%s: %s (%s)" % [q["giver"], q["desc"],
								"found it! return to them" if have > 0 else "not found yet"]
				if game._quest_fulfilled(q):
					col = Color(0.55, 0.9, 0.55)
			"done":
				text = "%s: %s  [completed]" % [q["giver"], q["desc"]]
				col = Color(0.45, 0.6, 0.45)
		lines.append({ "text": text, "col": col })

	var content_w := 0.0
	for ln in lines:
		content_w = max(content_w, font.get_string_size(ln["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
	var w: float = clamp(content_w + 32.0, 560.0, get_viewport_rect().size.x - 40.0)
	var h: float = 90.0 + lines.size() * 26.0
	var p := _panel(w, h, "Quest Journal")
	for i in lines.size():
		draw_string(font, Vector2(p.x + 16, p.y + 58 + i * 26), lines[i]["text"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, lines[i]["col"])
	draw_string(font, Vector2(p.x + 16, p.y + h - 16), "Press any key or click to close.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- vendor shop (buy / sell / buyback) ----------------
# Row geometry comes from the SHOP_* constants shared with
# _shop_click in main.gd.
func _draw_panel_shop() -> void:
	var vd: Dictionary = game.vendor_def(game.current_shop)
	var entries: Array = game.shop_entries()
	var w: float = game.SHOP_W
	var h: float = 96.0 + entries.size() * game.SHOP_ROW_H
	var p := _panel(w, h, "%s     (your coins: %d)" % [vd["name"], game.coins])
	var act := 0
	for i in entries.size():
		var e: Dictionary = entries[i]
		var yy: float = p.y + game.SHOP_TOP + i * game.SHOP_ROW_H
		match e["kind"]:
			"header":
				draw_string(font, Vector2(p.x + 16, yy), e["text"],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.72, 0.35))
			"note":
				draw_string(font, Vector2(p.x + 30, yy), e["text"],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.5, 0.58))
			_:
				if act == game.shop_index:
					draw_rect(Rect2(p.x + 8, yy - 14, w - 16.0, 18), Color(0.22, 0.26, 0.36))
				var item: Dictionary = game.ITEMS[e["id"]]
				var tag := ""
				if item.has("slot"):
					tag = " [" + game.SLOT_NAMES[item["slot"]] + "]"
				var text := ""
				match e["kind"]:
					"buy":
						text = "%d. %s - %d coins   (%s)%s" % [e["num"], item["name"], e["price"], item["desc"], tag]
					"sell":
						text = "%s x%d - sells for %d coins   (%s)%s" % [item["name"],
								game.inventory.get(e["id"], 0), e["price"], item["desc"], tag]
					"buyback":
						text = "%s - %d coins   (%s)%s" % [item["name"], e["price"], item["desc"], tag]
				draw_string(font, Vector2(p.x + 30, yy), text,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.85, 0.88))
				act += 1
	draw_string(font, Vector2(p.x + 16, p.y + h - 16),
			"Up/Down + Enter or click a row. Numbers quick-buy. Esc or right click closes.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- victory ----------------
func _draw_victory() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.04, 0.04, 0.02, 0.55))
	var text := "Victory!"
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	draw_string(font, Vector2((vs.x - w) * 0.5 + 2, vs.y * 0.40 + 2), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0, 0, 0, 0.6))
	draw_string(font, Vector2((vs.x - w) * 0.5, vs.y * 0.40), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.98, 0.85, 0.35))
	var sub := "All quests complete in %d moves" % game.victory_moves
	var w2: float = font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2((vs.x - w2) * 0.5, vs.y * 0.40 + 36), sub,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.92, 0.90, 0.80))
	var hint := "Press Enter (or click) to keep exploring"
	var w3: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2((vs.x - w3) * 0.5, vs.y * 0.40 + 64), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.72))


# ---------------- game over ----------------
func _draw_game_over() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.05, 0.02, 0.02, 0.60))
	var w := 460.0
	var h := 240.0
	var px := (vs.x - w) * 0.5
	var py := vs.y * 0.30
	draw_rect(Rect2(px - 4, py - 4, w + 8, h + 8), Color(0.42, 0.28, 0.26))
	draw_rect(Rect2(px, py, w, h), Color(0.10, 0.06, 0.06, 0.96))

	var text := "You died in %s" % game.map_name(game.current_map)
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(font, Vector2(px + (w - tw) * 0.5, py + 42), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.9, 0.72, 0.66))

	var lines := [
		["Journey began", game.run_start_text],
		["Journey ended", game.run_end_text],
		["Steps taken", str(game.move_count)],
		["Level reached", str(game.player_level)],
	]
	for i in lines.size():
		var yy: float = py + 84 + i * 26
		draw_string(font, Vector2(px + 40, yy), lines[i][0] + ":",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.62, 0.55, 0.52))
		draw_string(font, Vector2(px + 190, yy), lines[i][1],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.88, 0.85, 0.80))

	var hint := "Enter: try again      Esc: title screen"
	var hw: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(px + (w - hw) * 0.5, py + h - 22), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.68, 0.62, 0.60))


# ---------------- options ----------------
func _draw_panel_options() -> void:
	match game.options_screen:
		"main":
			var p := _panel(420.0, 250.0, "Options")
			for i in game.OPT_MAIN.size():
				var yy: float = p.y + 62 + i * 30
				if game.opt_index == i:
					draw_rect(Rect2(p.x + 8, yy - 18, 404, 26), Color(0.22, 0.26, 0.36))
				draw_string(font, Vector2(p.x + 20, yy), game.OPT_MAIN[i],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.88, 0.88, 0.9))
			draw_string(font, Vector2(p.x + 16, p.y + 234), "Up/Down + Enter, or click/tap. Esc or right click closes.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
		"graphics":
			var p := _panel(420.0, 150.0, "Options - Graphics")
			var fs: bool = get_window().mode == Window.MODE_FULLSCREEN
			draw_rect(Rect2(p.x + 8, p.y + 46, 404, 26), Color(0.22, 0.26, 0.36))
			draw_string(font, Vector2(p.x + 20, p.y + 64), "Fullscreen: %s" % ("On" if fs else "Off"),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.88, 0.88, 0.9))
			draw_string(font, Vector2(p.x + 16, p.y + 134), "Enter or click/tap toggles. Esc or right click goes back.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
		"sound":
			var p := _panel(420.0, 160.0, "Options - Sound")
			draw_string(font, Vector2(p.x + 20, p.y + 62), "Master Volume   %d%%" % int(round(game.master_volume * 100)),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.88, 0.88, 0.9))
			_meter(Vector2(p.x + 20, p.y + 76), 380.0, game.master_volume,
					Color(0.75, 0.62, 0.20), "")
			draw_string(font, Vector2(p.x + 16, p.y + 144), "Left/Right adjust, or click/drag the bar. Esc or right click goes back.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
		"keybinds":
			# Every action has two keybind cells; cell geometry must
			# mirror the "keybinds" branch of _options_click in main.gd.
			var h: float = 110.0 + game.REBIND_ACTIONS.size() * 26.0
			var p := _panel(560.0, h, "Options - Keybinds")
			for i in game.REBIND_ACTIONS.size():
				var yy: float = p.y + 62 + i * 26
				if game.opt_index == i:
					draw_rect(Rect2(p.x + 8, yy - 17, 544, 24), Color(0.16, 0.18, 0.24))
				draw_string(font, Vector2(p.x + 20, yy), game.REBIND_LABELS[i],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.75, 0.8))
				for slot in 2:
					var cell := Rect2(p.x + 240 + slot * 156, yy - 17, 148, 24)
					var editing: bool = game.opt_rebinding and game.opt_index == i and game.opt_bind_slot == slot
					var selected: bool = game.opt_index == i and game.opt_bind_slot == slot
					if selected:
						draw_rect(cell, Color(0.22, 0.26, 0.36))
					draw_rect(cell, Color(0.55, 0.55, 0.62) if selected else Color(0.30, 0.30, 0.36), false, 1.0)
					var k: int = game.keymap[game.REBIND_ACTIONS[i]][slot]
					var keyname := "press a key..." if editing \
							else ("-" if k == KEY_NONE else OS.get_keycode_string(k))
					draw_string(font, cell.position + Vector2(10, 17), keyname,
							HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
							Color(0.95, 0.85, 0.5) if editing else Color(0.88, 0.88, 0.9))
			draw_string(font, Vector2(p.x + 16, p.y + h - 16),
					"Up/Down row, Left/Right slot, Enter rebind - or click a cell. Esc or right click goes back.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
