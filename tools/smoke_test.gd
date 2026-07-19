extends SceneTree
# Headless smoke test. Run from the project directory:
#   godot --headless -s tools/smoke_test.gd
# Boots the main scene, starts a run, and sanity-checks the data
# tables: every vendor is complete and sells real items, every
# quest points at real content, every map generates, caves hold
# their loot and their stairs, and equipment stats compute.
# Exits 0 when everything passes, 1 otherwise.

var failures := 0

func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok: " + what)
	else:
		failures += 1
		printerr("FAIL: " + what)

func _initialize() -> void:
	var game: Node2D = (load("res://Main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	# run the checks on the first frame, once the scene is fully ready
	process_frame.connect(_run.bind(game), CONNECT_ONE_SHOT)

func _run(game: Node2D) -> void:
	game._start()

	_check(game.quests.size() == game.vendor_total(),
			"one quest per vendor (%d)" % game.quests.size())

	for i in game.vendor_total():
		var vd: Dictionary = game.vendor_def(i)
		_check(vd.has("stock") and vd.has("quest") and vd.has("greet"),
				"%s is a full vendor" % vd["name"])
		for id in vd["stock"]:
			_check(game.ITEMS.has(id), "%s sells a real item (%s)" % [vd["name"], id])
		var q: Dictionary = vd["quest"]
		if q["type"] == "kill":
			_check(game.MOB_TYPES.has(q["target"]),
					"%s's quest hunts a real mob (%s)" % [vd["name"], q["target"]])
		elif q["type"] == "item":
			_check(game.ITEMS.has(q["target"]),
					"%s's quest wants a real item (%s)" % [vd["name"], q["target"]])
		if q.has("reward_items"):
			for id in q["reward_items"]:
				_check(game.ITEMS.has(id),
						"%s's quest rewards a real item (%s)" % [vd["name"], id])
		if q.get("target", "") != "parchment":
			_check(q.has("outro"), "%s's quest has a completion line" % vd["name"])
		game.current_shop = i
		_check(game.shop_entries().size() > 0, "%s's shop panel builds" % vd["name"])

	# every link goes somewhere real AND links back the opposite way
	var opposite := { "north": "south", "south": "north", "east": "west",
			"west": "east", "up": "down", "down": "up" }
	for id in game.MAP_DEFS:
		for dir in opposite:
			if game.MAP_DEFS[id].has(dir):
				var other: String = game.MAP_DEFS[id][dir]
				_check(game.MAP_DEFS.has(other) \
						and game.MAP_DEFS[other].get(opposite[dir], "") == id,
						"%s.%s links back from %s" % [id, dir, other])

	for id in game.MAP_DEFS:
		var st: Dictionary = game._generate_map(id)
		_check(not st["grid"].is_empty(), "%s generates" % id)
		var def: Dictionary = game.MAP_DEFS[id]
		for mtype in def.get("mobs", {}):
			_check(game.MOB_TYPES.has(mtype), "%s spawns a real mob (%s)" % [id, mtype])
		if def.has("cave"):
			var ids := []
			for entry in st["items"]:
				ids.append(entry["id"])
				var lp: Vector2i = entry["pos"]
				_check(lp.x < def["w"] - 10 or lp.y < def["h"] - 8,
						"%s %s avoids the minimap corner" % [id, entry["id"]])
			_check(def["loot"] in ids, "%s holds its loot (%s)" % [id, def.get("loot", "?")])
			if def.has("quest_loot"):
				_check(def["quest_loot"] in ids,
						"%s holds its quest item (%s)" % [id, def["quest_loot"]])
			if def.has("down"):
				_check(st["stairs_down"].x >= 0, "%s has a stairway down" % id)
				_check(st["stairs_down"].x < def["w"] - 10 or st["stairs_down"].y < def["h"] - 8,
						"%s stairway avoids the minimap corner" % id)
			for m in st["mobs"]:
				_check(st["grid"][m["pos"].y][m["pos"].x] == ".",
						"%s mob stands on floor" % id)
		_check((st["explored"] as Array).size() == def["h"],
				"%s has an exploration grid" % id)

	# the Northern Reaches: eight maps, every gate carved, a suggested
	# level each, and at least one Westmere quest target per map
	var west_targets := []
	for i in range(game.VENDORS.size(), game.vendor_total()):
		var wq: Dictionary = game.vendor_def(i)["quest"]
		if wq["type"] == "kill":
			west_targets.append(wq["target"])
	var gate_keys := { "north": "north_gate", "south": "south_gate",
			"east": "east_gate", "west": "west_gate" }
	for id in ["thorn", "mire", "barrens", "vale", "pines", "cliffs", "graves", "approach"]:
		var st: Dictionary = game._generate_map(id)
		var def: Dictionary = game.MAP_DEFS[id]
		for dir in gate_keys:
			if def.has(dir):
				_check(st[gate_keys[dir]].x >= 0, "%s carves its %s gate" % [id, dir])
		_check(def.has("level"), "%s suggests a level" % id)
		var hosts := false
		for mtype in def["mobs"]:
			if mtype in west_targets:
				hosts = true
		_check(hosts, "%s hosts a Westmere quest target" % id)

	# the sealed fortress gate stands in the town's east wall
	var tst: Dictionary = game._generate_map("town")
	_check(tst["grid"][15][41] == "G" and tst["grid"][16][41] == "G",
			"the sealed fortress gate faces east from town")

	# the ruins stairway sits inside its shrine
	var rst: Dictionary = game._generate_map("ruins")
	_check(rst["grid"][23][99] == "O", "the ruins stairway sits at the shrine's heart")
	_check(rst["grid"][21][99] == "S" and rst["grid"][25][99] == "D",
			"the shrine has stone walls and a south door")
	_check(rst["stairs_down"] == Vector2i(99, 23), "the stairs_down marker matches")

	# fog of war: the view around the spawn is explored, far corners not
	game._load_map("wilds", "spawn")
	game._refresh()
	var expl: Array = game.map_state["wilds"]["explored"]
	_check(expl[game.player_pos.y][game.player_pos.x] == 1, "fog: the spawn view is explored")
	_check(expl[2][2] == 0, "fog: the far corner stays dark")
	_check(game.MAP_DEFS["town"].get("no_fog", false), "fog: town is exempt")
	_check(game.MAP_DEFS["west"].get("no_fog", false), "fog: Westmere is exempt")

	# the full dungeon chain loads
	game._load_map("crypt", "descend")
	_check(game.current_map == "crypt", "crypt loads")
	game._load_map("crypt2", "descend")
	_check(game.current_map == "crypt2", "crypt2 loads")
	_check(game.mobs.any(func(m): return m["type"] == "k"),
			"bone knights walk Bone Hollow")

	# wands feed the new spell-damage stat
	game._add_item("bwand")
	game._equip("bwand")
	_check(game.player_spell_dmg == 2, "Bone Wand grants +2 spell damage")
	game._add_item("amulet")
	game._equip("amulet")
	_check(game.player_max_mana == game.base_max_mana + 4, "Sapphire Amulet grants +4 mana")

	# a Westmere vendor: talk activates their quest and opens a shop
	game._load_map("west", "spawn")
	game._talk_to_vendor(0)
	_check(game.mode == game.Mode.SHOP, "west vendor opens a shop")
	_check(game.current_shop >= game.VENDORS.size(), "west vendor uses the global index")
	_check(game.quests[game.current_shop]["state"] == "active", "west quest activates on first talk")

	# buy, sell back, buy back at a Westmere shop
	game.coins = 200
	var first: String = game.vendor_def(game.current_shop)["stock"][0]
	game._buy_item(first)
	_check(game.inventory.get(first, 0) == 1, "bought a %s" % first)
	game._sell_item(first)
	_check(not game.buyback.get(game.current_shop, []).is_empty(), "buyback remembers the sale")
	game._buyback_item(0)
	_check(game.inventory.get(first, 0) == 1, "bought the %s back" % first)

	# Sable the scribe: portal scrolls for sale, wraith-ink to gather
	game._talk_to_vendor(7)   # first talk: quest activates, shop opens
	_check("tpscroll" in game.vendor_def(game.current_shop)["stock"], "Sable sells portal scrolls")
	game.quests[game.VENDORS.size() + 7]["progress"] = 4
	game._talk_to_vendor(7)   # wraiths dealt with: turn it in
	_check(game.quests[game.VENDORS.size() + 7]["state"] == "done", "Sable's wraith quest completes")
	_check(game.inventory.get("tpscroll", 0) >= 3, "the scroll reward arrived")

	# the backpack groups items under category headers
	game.inventory = {}
	game._add_item("sword")
	game._add_item("bread")
	game._add_item("chain")
	var cats := []
	for e in game.backpack_entries():
		if e["kind"] == "header":
			cats.append(e["text"])
	_check(cats == ["Weapons", "Armour", "Consumables"], "backpack groups by category")
	_check(game.item_category("parchment") == 3, "the parchment counts as a quest item")
	_check(game.item_category("wand") == 0, "wands count as weapons")
	_check(game.item_category("tpscroll") == 2, "portal scrolls count as consumables")

	# town portal: cast in the wilds, then step through to come back
	game._load_map("wilds", "spawn")
	var cast_pos: Vector2i = game.player_pos
	game._add_item("tpscroll")
	game._use_item("tpscroll")
	_check(game.current_map == "town", "the portal scroll drops you home")
	_check(not game.portal.is_empty(), "a return portal stands open at home")
	var hp: Vector2i = game.portal["home_pos"]
	game.player_pos = hp + Vector2i(-1, 0)
	game._try_player_move(Vector2i(1, 0))
	_check(game.current_map == "wilds" and game.player_pos == cast_pos,
			"stepping through returns you to the cast tile")
	_check(game.portal.is_empty(), "the portal closes after the round trip")

	# the fall of Grey Fortress: returning with the parchment burns it
	_check(not game.town_burned, "the town starts whole")
	game._add_item("parchment")
	game.parchment_found = true
	game._load_map("town", "spawn")
	_check(game.town_burned, "coming home with the parchment burns the town")
	_check(game.vendors.is_empty(), "the burned town is deserted")
	_check(game.map_state["town"]["west_gate"].x >= 0, "the west gate hangs broken open")
	_check(game.altar_positions.size() > 0, "the temple altar survived the fire")
	_check(game.grid[15][41] == "G", "the fortress gate outlasts the fire")
	_check(game.map_name("town") == "Ruins of Grey Fortress", "the town is renamed in its ruin")
	_check(game.portal_home() == "west", "portals now lead to Westmere")

	# Dolm did not make it out: walking over his body delivers the quest
	game.player_pos = game.DOLM_BODY + Vector2i(-1, 0)
	game._try_player_move(Vector2i(1, 0))
	_check(game.quests[3]["state"] == "done", "walking over Dolm's body delivers the parchment")
	_check(game.inventory.get("parchment", 0) == 0, "the parchment leaves your pack")
	_check(game.inventory.get("armor", 0) == 1, "Dolm's strongbox held the Leather Armor")

	# the survivors trade on in the Westmere refugee camp - without Dolm
	game._load_map("west", "spawn")
	_check(game.vendors.size() == 11, "Westmere holds 8 locals and 3 refugees")
	var refugees: Array = game.vendors.filter(func(v): return v.get("set", "") == "town")
	_check(refugees.size() == 3, "Dolm is not among the refugees")

	# the refugees speak of the fire, not of business as usual
	game._talk_to_vendor(8)   # Alda: first talk hands out her quest
	game._talk_to_vendor(8)   # second talk: her burned greeting
	_check("\n".join(game.messages).contains("bread rises"), "refugees speak of the fire")

	# the bar buttons stack in two rows in their own right-hand column
	var brects: Array = game.bar_button_rects()
	_check(brects.size() == 5, "five panel buttons")
	_check(brects[0].position.y != brects[3].position.y, "buttons stack in two rows")
	_check(brects[0].position.x == game.bar_buttons_left(), "the button column starts at bar_buttons_left")

	# Dolm's last wish opens the road north into the Reaches
	_check(game.fortress_road_open(), "Dolm's quest opens the fortress road")
	_check(game.map_state["west"]["north_gate"].x >= 0, "Westmere's north gate stands open")
	game._load_map("thorn", "south_gate")
	_check(game.current_map == "thorn", "the road north leads into Thornwood")
	_check(game.mobs.size() > 0, "Thornwood is populated")

	# the message log: opens, types-to-search, Esc clears then closes
	game._open_log()
	_check(game.mode == game.Mode.LOG, "the message log opens")
	var kev := InputEventKey.new()
	kev.keycode = KEY_R
	kev.unicode = 114
	game._log_panel_input(kev)
	_check(game.log_search == "r", "typing filters the log")
	var kesc := InputEventKey.new()
	kesc.keycode = KEY_ESCAPE
	game._log_panel_input(kesc)
	_check(game.log_search == "" and game.mode == game.Mode.LOG, "Esc clears the search first")
	game._log_panel_input(kesc)
	_check(game.mode == game.Mode.PLAY, "Esc then closes the log")
	for i in game.LOG_KEEP + 100:
		game._log("filler line %d" % i)
	_check(game.messages.size() == game.LOG_KEEP, "history caps at LOG_KEEP messages")
	_check(game.LOG_KEEP == 1000, "history keeps 1000 messages")

	# ten save slots; the message log travels inside the save.
	# (Slot 10 is used only if free, and its file is removed after.)
	game._refresh_slot_cache()
	_check(game.save_slot_cache.size() == game.SAVE_SLOTS, "the slot cache lists 10 slots")
	_check(game.title_slot_rects().size() == game.SAVE_SLOTS, "the load picker has 10 rows")
	if game._slot_read_path(10) == "":
		game._log("marker line for the save test")
		game._save_game(10)
		game._refresh_slot_cache()
		_check(game.save_slot_cache[9]["exists"], "saving fills slot 10")
		game._start()
		_check(not "\n".join(game.messages).contains("marker line"), "a new run starts with a fresh log")
		game._load_game(10)
		_check("\n".join(game.messages).contains("marker line for the save test"),
				"the message history survives save/load")
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save10.json"))

	# the intro parchment: shown for title-screen runs, skippable forever
	game.skip_intro = false
	game._start(true)
	_check(game.mode == game.Mode.INTRO, "a fresh run opens on the intro parchment")
	game._close_intro()
	_check(game.mode == game.Mode.PLAY, "any key dismisses the intro")
	_check(game.banner_timer > 0.0, "the area banner waits its turn behind the intro")
	game.skip_intro = true
	game._start(true)
	_check(game.mode == game.Mode.PLAY, "the option skips the intro entirely")

	if failures == 0:
		print("smoke test: all checks passed")
	else:
		printerr("smoke test: %d check(s) FAILED" % failures)
	quit(0 if failures == 0 else 1)
