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
		game.current_shop = i
		_check(game.shop_entries().size() > 0, "%s's shop panel builds" % vd["name"])

	for id in game.MAP_DEFS:
		var st: Dictionary = game._generate_map(id)
		_check(not st["grid"].is_empty(), "%s generates" % id)
		var def: Dictionary = game.MAP_DEFS[id]
		for link in ["north", "south", "east", "west", "down", "up"]:
			if def.has(link):
				_check(game.MAP_DEFS.has(def[link]),
						"%s's %s link goes somewhere real" % [id, link])
		if def.has("cave"):
			_check(st["items"].size() == 1 and st["items"][0]["id"] == def["loot"],
					"%s holds its loot (%s)" % [id, def.get("loot", "?")])
			if def.has("down"):
				_check(st["stairs_down"].x >= 0, "%s has a stairway down" % id)
			for m in st["mobs"]:
				_check(st["grid"][m["pos"].y][m["pos"].x] == ".",
						"%s mob stands on floor" % id)

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

	# Pell's fetch quest: bring 3 bread, get 2 pies
	game._add_item("bread", 3)
	game._talk_to_vendor(7)   # first talk: quest activates
	game._talk_to_vendor(7)   # second talk: fulfilled, hand it over
	_check(game.quests[game.VENDORS.size() + 7]["state"] == "done", "Pell's bread quest completes")
	_check(game.inventory.get("bread", 0) == 0, "the bread was handed over")
	_check(game.inventory.get("pie", 0) == 2, "the pie reward arrived")

	if failures == 0:
		print("smoke test: all checks passed")
	else:
		printerr("smoke test: %d check(s) FAILED" % failures)
	quit(0 if failures == 0 else 1)
