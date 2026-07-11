extends Node2D
# HUD lives on a CanvasLayer, so it stays put while the camera
# scrolls over the world. It only reads state from the game node.

const BAR_H := 84

var game: Node2D
@onready var font: Font = ThemeDB.fallback_font


func _draw() -> void:
	if game == null or game.grid.is_empty():
		return
	_draw_bar()
	match game.mode:
		game.Mode.INVENTORY:
			_draw_panel_character()
		game.Mode.JOURNAL:
			_draw_panel_journal()
		game.Mode.SHOP:
			_draw_panel_shop()
		game.Mode.OPTIONS:
			_draw_panel_options()
	if game.banner_timer > 0.0:
		_draw_banner()
	if game.game_over:
		_draw_game_over()


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
	draw_string(font, Vector2(10, y + 76),
			"Lv %d   Dmg %d   Coins %d   -   %s" % [game.player_level, game.player_dmg,
			game.coins, game.MAP_DEFS[game.current_map]["name"]],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.72, 0.70, 0.60))

	var start: int = max(0, game.messages.size() - 4)
	var line := 0
	for i in range(start, game.messages.size()):
		draw_string(font, Vector2(230, y + 18 + line * 17), game.messages[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.78, 0.80))
		line += 1

	draw_string(font, Vector2(vs.x - 260, y + 76), "I character   J journal   O options",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))

# One resource meter: dark trough, colored fill, thin border, value inside.
func _meter(pos: Vector2, w: float, frac: float, col: Color, label: String) -> void:
	var h := 15.0
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.11, 0.11, 0.14))
	draw_rect(Rect2(pos, Vector2(w * clamp(frac, 0.0, 1.0), h)), col)
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.38, 0.38, 0.44), false, 1.0)
	var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, pos + Vector2((w - tw) * 0.5, 11.5), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.88))


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

	# --- left: the hero, stats, and the 21 equipment slots ---
	game.draw_hero_on(self, Vector2(p.x + 410, p.y + 150), 4.5)
	draw_string(font, Vector2(p.x + 356, p.y + 250), "Dmg %d" % game.player_dmg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.7, 0.6))
	draw_string(font, Vector2(p.x + 356, p.y + 270), "HP %d/%d" % [max(game.player_hp, 0), game.player_max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.85, 0.7))

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
	var list: Array = game.inventory_list()
	if list.is_empty():
		draw_string(font, Vector2(inv_x, top + 4), "Your pack is empty.",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.55, 0.6))
	for i in list.size():
		var yy := top + i * 17.0
		var id: String = list[i]
		var it: Dictionary = game.ITEMS[id]
		var selected: bool = game.mode == game.Mode.INVENTORY and game.ui_pane == 1 and game.ui_index == i
		if selected:
			draw_rect(Rect2(inv_x - 6, yy - 12, 450, 16), Color(0.22, 0.26, 0.36))
		var tag := ""
		if it.has("slot"):
			tag = "  [" + game.SLOT_NAMES[it["slot"]] + "]"
		elif it.has("heal"):
			tag = "  [use]"
		draw_string(font, Vector2(inv_x, yy), "%s x%d%s - %s" % [it["name"], game.inventory[id], tag, it["desc"]],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color(0.85, 0.85, 0.88) if (it.has("slot") or it.has("heal")) else Color(0.62, 0.62, 0.68))

	draw_string(font, Vector2(p.x + 16, p.y + h - 14),
			"Up/Down: select     Left/Right: switch side     Enter: equip / use / remove     Esc or I: close",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- quest journal ----------------
func _draw_panel_journal() -> void:
	var h: float = 90.0 + game.quests.size() * 26.0
	var p := _panel(560.0, h, "Quest Journal")
	for i in game.quests.size():
		var q: Dictionary = game.quests[i]
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
		draw_string(font, Vector2(p.x + 16, p.y + 58 + i * 26), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	draw_string(font, Vector2(p.x + 16, p.y + h - 16), "Press any key to close.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- vendor shop ----------------
func _draw_panel_shop() -> void:
	var vd: Dictionary = game.VENDORS[game.current_shop]
	var stock: Array = vd["stock"]
	var h: float = 100.0 + stock.size() * 22.0
	var p := _panel(620.0, h, "%s     (your coins: %d)" % [vd["name"], game.coins])
	for i in stock.size():
		var id: String = stock[i]
		var item: Dictionary = game.ITEMS[id]
		var tag := ""
		if item.has("slot"):
			tag = " [" + game.SLOT_NAMES[item["slot"]] + "]"
		var text := "%d. %s - %d coins   (%s)%s" % [i + 1, item["name"], item["price"], item["desc"], tag]
		draw_string(font, Vector2(p.x + 16, p.y + 58 + i * 22), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.85, 0.88))
	draw_string(font, Vector2(p.x + 16, p.y + h - 16), "Press a number to buy. Esc to close.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))


# ---------------- game over ----------------
func _draw_game_over() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.05, 0.02, 0.02, 0.55))
	var text := "You died in %s" % game.MAP_DEFS[game.current_map]["name"]
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string(font, Vector2((vs.x - w) * 0.5, vs.y * 0.45), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.9, 0.75, 0.7))
	var hint := "Press Enter to restart"
	var w2: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2((vs.x - w2) * 0.5, vs.y * 0.45 + 34), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.7, 0.7, 0.72))


# ---------------- options ----------------
func _draw_panel_options() -> void:
	match game.options_screen:
		"main":
			var p := _panel(420.0, 220.0, "Options")
			for i in game.OPT_MAIN.size():
				var yy: float = p.y + 62 + i * 30
				if game.opt_index == i:
					draw_rect(Rect2(p.x + 8, yy - 18, 404, 26), Color(0.22, 0.26, 0.36))
				draw_string(font, Vector2(p.x + 20, yy), game.OPT_MAIN[i],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.88, 0.88, 0.9))
			draw_string(font, Vector2(p.x + 16, p.y + 204), "Up/Down + Enter. Esc closes.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
		"graphics":
			var p := _panel(420.0, 150.0, "Options - Graphics")
			var fs: bool = get_window().mode == Window.MODE_FULLSCREEN
			draw_rect(Rect2(p.x + 8, p.y + 46, 404, 26), Color(0.22, 0.26, 0.36))
			draw_string(font, Vector2(p.x + 20, p.y + 64), "Fullscreen: %s" % ("On" if fs else "Off"),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.88, 0.88, 0.9))
			draw_string(font, Vector2(p.x + 16, p.y + 134), "Enter toggles. Esc goes back.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
		"sound":
			var p := _panel(420.0, 160.0, "Options - Sound")
			draw_string(font, Vector2(p.x + 20, p.y + 62), "Master Volume   %d%%" % int(round(game.master_volume * 100)),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.88, 0.88, 0.9))
			_meter(Vector2(p.x + 20, p.y + 76), 380.0, game.master_volume,
					Color(0.75, 0.62, 0.20), "")
			draw_string(font, Vector2(p.x + 16, p.y + 144), "Left/Right adjust. Esc goes back.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
		"keybinds":
			var h: float = 110.0 + game.REBIND_ACTIONS.size() * 26.0
			var p := _panel(460.0, h, "Options - Keybinds")
			for i in game.REBIND_ACTIONS.size():
				var yy: float = p.y + 62 + i * 26
				if game.opt_index == i:
					draw_rect(Rect2(p.x + 8, yy - 17, 444, 24), Color(0.22, 0.26, 0.36))
				draw_string(font, Vector2(p.x + 20, yy), game.REBIND_LABELS[i],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.75, 0.8))
				var keyname := "..."
				if not (game.opt_rebinding and game.opt_index == i):
					keyname = OS.get_keycode_string(game.keymap[game.REBIND_ACTIONS[i]])
				else:
					keyname = "press a key..."
				draw_string(font, Vector2(p.x + 280, yy), keyname,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
						Color(0.95, 0.85, 0.5) if (game.opt_rebinding and game.opt_index == i) else Color(0.88, 0.88, 0.9))
			draw_string(font, Vector2(p.x + 16, p.y + h - 16),
					"Up/Down select, Enter rebind, Esc goes back. Arrow keys always move.",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.58))
