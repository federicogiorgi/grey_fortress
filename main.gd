extends Node2D
# =============================================================
#  GREY FORTRESS - v11
#
#  New in this version:
#   - The Northern Reaches: eight procedurally generated wild
#     maps between Westmere and the Grey Fortress, linked in a
#     web rather than a line - up to four gates per map (east/
#     west gates and crossroads are new machinery), with several
#     routes north. The boarded gate opens when Dolm's last wish
#     is honored
#   - Six new monsters tuned for levels 6-10: dire wolf, orc,
#     orc shaman (ranged), cave bear, gargoyle, dread knight
#   - Suggested levels: every wilderness map advertises one on
#     the world map and in its "Entering..." banner; each
#     northern map hosts at least one Westmere quest target
#
#  v10: the story arc (parchment, the burning, Dolm's fate, quest
#  marks, intro parchment, journal by area), town portals,
#  backpack categories, Sable's scroll trade, rare mob drops.
#  v9: Westmere's eight vendors got real shops and quests (12
#  quests total), spell-damage wands, Bone Hollow + bone knights,
#  minimap fog of war, per-item world loot icons.
#  v8: area minimap + world map, the Sunken Crypt, spell/mob
#  line of sight, ranged mobs, mana regen, sound effects.
#  v7: three spells + spellbook + targeting + projectiles + mana
#  potions + HP bars; ranged weapons came and went; dual keybinds.
#  v6: title screen, save/load, death details, Westmere Village.
#  v5: minimap, mob icons, rain, two-tier vendors, respawns.
#  v4: unique vendors, sell/buyback, victory, clickable HUD.
# =============================================================

# The game version: bump alongside the header above, and use the
# same string as the GitHub release tag. Watermarked on the title
# screen and in the corner of the HUD bar.
const VERSION := "v11"

enum Mode { TITLE, INTRO, PLAY, INVENTORY, JOURNAL, SHOP, OPTIONS, SPELLBOOK, WORLDMAP, LOG }

const TILE := 32
const BAR_H := 84                 # must match hud.gd
const MOVE_DELAY_FIRST := 0.22    # delay before hold-to-walk kicks in
const MOVE_DELAY_REPEAT := 0.115  # steps per second while holding ~ 8.7

# ---- world definition -------------------------------------
# Maps connect through directional links (north/south/east/west for
# gates, down/up for stairs). The world map screen and all
# transitions are derived from these links, so adding a region or a
# dungeon level is one entry here plus its entrance tile. "tint" is
# the map's identity color on the minimap and the world map.
const MAP_DEFS := {
	"town": {
		# The west gate exists in the def but its "<" tiles are only
		# carved into the map once the town burns (the survivors break
		# it open as they flee to Westmere).
		# Villages are "no_fog": their minimap is fully drawn from the
		# start; everywhere else fog of war hides the unseen parts.
		"name": "Grey Fortress Town", "north": "wilds", "west": "west", "music": "town",
		"w": 42, "h": 30, "tint": Color(0.36, 0.42, 0.30),
		"tree_density": 0.040, "water_blobs": 0, "mobs": {}, "no_fog": true,
	},
	"wilds": {
		"name": "Northern Wilds", "south": "town", "north": "forest", "music": "wilds",
		"w": 125, "h": 94, "tint": Color(0.25, 0.37, 0.22), "level": 1,
		"tree_density": 0.040, "water_blobs": 3,
		"mobs": { "r": 12, "g": 8, "b": 5 },
		"outpost": { "x": 28, "y": 38, "item": "boots" },
	},
	"forest": {
		"name": "Dark Forest", "south": "wilds", "north": "ruins", "music": "forest",
		"w": 125, "h": 94, "tint": Color(0.14, 0.29, 0.15), "level": 2,
		"tree_density": 0.115, "water_blobs": 2,
		# darker ground, matching the deep green of its minimap tint
		"palette": { "floor": Color(0.14, 0.22, 0.13), "floor_hi": Color(0.17, 0.26, 0.16) },
		"mobs": { "w": 9, "g": 8, "b": 6, "a": 5 },
		"outpost": { "x": 88, "y": 50, "item": "belt" },
	},
	"ruins": {
		"name": "Ancient Ruins", "south": "forest", "down": "crypt", "music": "ruins",
		"w": 125, "h": 94, "tint": Color(0.33, 0.34, 0.39), "level": 3,
		"tree_density": 0.024, "water_blobs": 1, "ruin_walls": true,
		# grey, dusty ground: old stone showing through thin grass
		"palette": { "floor": Color(0.25, 0.27, 0.24), "floor_hi": Color(0.29, 0.31, 0.28) },
		"mobs": { "s": 14, "g": 6, "t": 4, "a": 4 },
		"outpost": { "x": 28, "y": 58, "item": "legplates" },
	},
	# Reached through the west gate of town, which only opens once the
	# town burns and the survivors flee here. Its north gate stays
	# boarded until Dolm's last wish is honored; then the Northern
	# Reaches open beyond it.
	"west": {
		"name": "Westmere Village", "east": "town", "north": "thorn", "music": "town",
		"w": 50, "h": 36, "tint": Color(0.36, 0.42, 0.30),
		"tree_density": 0.035, "water_blobs": 0, "mobs": {}, "no_fog": true,
	},
	# ---- The Northern Reaches: eight wild maps between Westmere and
	# the Grey Fortress, linked in a web rather than a line - up to
	# four gates each, with several routes north. "level" is the
	# suggested character level (shown on the world map and in the
	# area banner), and every map hosts at least one target of a
	# Westmere quest.
	"thorn": {
		"name": "Thornwood", "south": "west", "west": "mire", "north": "vale",
		"music": "forest", "level": 6,
		"w": 120, "h": 90, "tint": Color(0.16, 0.30, 0.16),
		"tree_density": 0.13, "water_blobs": 1,
		"palette": { "floor": Color(0.15, 0.23, 0.13), "floor_hi": Color(0.18, 0.27, 0.16) },
		"mobs": { "w": 10, "d": 8, "b": 6 },
	},
	"mire": {
		"name": "Blackmire", "east": "thorn", "north": "barrens",
		"music": "wilds", "level": 6,
		"w": 120, "h": 88, "tint": Color(0.20, 0.26, 0.15),
		"tree_density": 0.06, "water_blobs": 9,
		"palette": { "floor": Color(0.17, 0.21, 0.12), "floor_hi": Color(0.20, 0.24, 0.14) },
		"mobs": { "b": 9, "a": 7, "o": 6 },
	},
	"barrens": {
		"name": "Ashen Barrens", "south": "mire", "east": "vale", "west": "pines",
		"north": "graves", "music": "wilds", "level": 7,
		"w": 125, "h": 92, "tint": Color(0.30, 0.28, 0.24),
		"tree_density": 0.015, "water_blobs": 0,
		"palette": { "floor": Color(0.24, 0.22, 0.19), "floor_hi": Color(0.28, 0.26, 0.22) },
		"mobs": { "s": 11, "o": 8, "d": 6 },
	},
	"vale": {
		"name": "Hollow Vale", "south": "thorn", "west": "barrens", "north": "approach",
		"music": "forest", "level": 8,
		"w": 120, "h": 90, "tint": Color(0.24, 0.33, 0.22),
		"tree_density": 0.07, "water_blobs": 2,
		"mobs": { "t": 6, "o": 9, "h": 6 },
	},
	"pines": {
		"name": "Frostpine Reach", "east": "barrens", "north": "cliffs",
		"music": "forest", "level": 7,
		"w": 115, "h": 86, "tint": Color(0.44, 0.52, 0.50),
		"tree_density": 0.10, "water_blobs": 1,
		"palette": { "floor": Color(0.30, 0.35, 0.33), "floor_hi": Color(0.34, 0.39, 0.37) },
		"mobs": { "w": 8, "d": 8, "u": 5 },
	},
	"cliffs": {
		"name": "Greycliff Steps", "south": "pines", "east": "graves",
		"music": "ruins", "level": 8,
		"w": 115, "h": 86, "tint": Color(0.40, 0.40, 0.44),
		"tree_density": 0.02, "water_blobs": 0, "ruin_walls": true,
		"palette": { "floor": Color(0.26, 0.27, 0.26), "floor_hi": Color(0.30, 0.31, 0.30) },
		"mobs": { "t": 5, "x": 6, "o": 8 },
	},
	"graves": {
		"name": "Gravemarch", "west": "cliffs", "south": "barrens", "east": "approach",
		"music": "ruins", "level": 9,
		"w": 120, "h": 90, "tint": Color(0.21, 0.23, 0.21),
		"tree_density": 0.03, "water_blobs": 0, "ruin_walls": true,
		"palette": { "floor": Color(0.17, 0.19, 0.16), "floor_hi": Color(0.20, 0.22, 0.19) },
		"mobs": { "s": 12, "y": 8, "k": 6 },
	},
	"approach": {
		"name": "Fortress Approach", "west": "graves", "south": "vale",
		"music": "ruins", "level": 10,
		"w": 120, "h": 90, "tint": Color(0.30, 0.28, 0.34),
		"tree_density": 0.015, "water_blobs": 0, "ruin_walls": true,
		"palette": { "floor": Color(0.22, 0.21, 0.23), "floor_hi": Color(0.26, 0.25, 0.27) },
		"mobs": { "k": 8, "y": 8, "x": 6, "v": 4 },
	},
	# The first dungeon level: a cave carved under the Ancient Ruins,
	# reached by the sunken stairway ("O" tile) near its east side.
	# "loot" is the unique item hidden in the cave's farthest corner.
	"crypt": {
		"name": "Sunken Crypt", "up": "ruins", "down": "crypt2", "music": "ruins",
		"w": 60, "h": 44, "tint": Color(0.18, 0.15, 0.22), "level": 4,
		"tree_density": 0.0, "water_blobs": 0, "cave": true, "loot": "crown",
		"palette": { "floor": Color(0.16, 0.14, 0.19), "floor_hi": Color(0.20, 0.17, 0.23),
				"wall": Color(0.10, 0.09, 0.13), "wall_hi": Color(0.15, 0.13, 0.18) },
		"mobs": { "s": 10, "y": 6 },
	},
	# The second dungeon level, deeper and deadlier: bone knights
	# patrol it, the Runeblade lies in its farthest corner, and the
	# Mysterious Parchment - the item that turns the whole story -
	# waits in another ("quest_loot" is placed far from both the
	# entrance and the treasure).
	"crypt2": {
		"name": "Bone Hollow", "up": "crypt", "music": "ruins",
		"w": 70, "h": 52, "tint": Color(0.24, 0.15, 0.13), "level": 5,
		"tree_density": 0.0, "water_blobs": 0, "cave": true, "loot": "runeblade",
		"quest_loot": "parchment",
		"palette": { "floor": Color(0.19, 0.13, 0.12), "floor_hi": Color(0.23, 0.16, 0.14),
				"wall": Color(0.12, 0.08, 0.08), "wall_hi": Color(0.17, 0.12, 0.11) },
		"mobs": { "s": 12, "y": 7, "k": 5 },
	},
}

const RAIN_CHANCE := 0.10

# ---- magic ------------------------------------------------
# The active spell is cast with 5 (or middle mouse), then a click on
# the target tile. The spellbook (P) picks the active spell.
# "aoe" is a blast radius in tiles: 1 means the impact tile and its
# eight neighbors (a 3x3 burst) all take the damage.
const SPELLS := {
	"dart": { "name": "Magic Dart", "mana": 3, "dmg": 2, "range": 7,
			"desc": "A dart of pure force. Barely kills a rat." },
	"arrow": { "name": "Bone Arrow", "mana": 4, "dmg": 1, "range": 14,
			"desc": "A whistling sliver of bone. Weak, but flies half across the world." },
	"boulder": { "name": "Fire Ball", "mana": 10, "dmg": 5, "range": 7, "aoe": 1,
			"desc": "A roaring burst of flame, searing a full 3x3 area." },
}
const SPELL_ORDER := ["dart", "arrow", "boulder"]

const MOB_TYPES := {
	"r": { "name": "rat",       "hp": 2,  "dmg": 1, "sight": 10, "xp": 3,
			"coins": [1, 2],   "color": Color(0.50, 0.42, 0.32) },
	"g": { "name": "goblin",    "hp": 3,  "dmg": 1, "sight": 8,  "xp": 5,
			"coins": [2, 4],   "color": Color(0.32, 0.52, 0.20) },
	"b": { "name": "wild boar", "hp": 5,  "dmg": 2, "sight": 5,  "xp": 8,
			"coins": [3, 6],   "color": Color(0.38, 0.24, 0.14) },
	"w": { "name": "wolf",      "hp": 4,  "dmg": 2, "sight": 10, "xp": 10,
			"coins": [4, 7],   "color": Color(0.42, 0.44, 0.50) },
	"s": { "name": "skeleton",  "hp": 6,  "dmg": 2, "sight": 9,  "xp": 14,
			"coins": [5, 9],   "color": Color(0.80, 0.80, 0.72) },
	"t": { "name": "troll",     "hp": 10, "dmg": 3, "sight": 6,  "xp": 25,
			"coins": [10, 18], "color": Color(0.25, 0.40, 0.22) },
	# Ranged mobs: when the player is in range with a clear line of
	# sight they shoot instead of moving ("ranged": dmg/range/kind).
	"a": { "name": "goblin archer", "hp": 3, "dmg": 1, "sight": 10, "xp": 12,
			"coins": [4, 8],   "color": Color(0.24, 0.42, 0.16),
			"ranged": { "dmg": 2, "range": 6, "kind": "arrow", "verb": "shoots" } },
	"y": { "name": "wraith",    "hp": 5,  "dmg": 2, "sight": 11, "xp": 20,
			"coins": [6, 12],  "color": Color(0.55, 0.60, 0.75),
			"ranged": { "dmg": 2, "range": 5, "kind": "dart", "verb": "hexes" } },
	"k": { "name": "bone knight", "hp": 12, "dmg": 3, "sight": 8, "xp": 30,
			"coins": [12, 20], "color": Color(0.52, 0.52, 0.58) },
	# ---- Northern Reaches mobs, tuned for levels 6-10 ----
	"d": { "name": "dire wolf",  "hp": 8,  "dmg": 3, "sight": 11, "xp": 22,
			"coins": [6, 10],  "color": Color(0.30, 0.32, 0.38) },
	"o": { "name": "orc",        "hp": 9,  "dmg": 3, "sight": 9,  "xp": 26,
			"coins": [8, 14],  "color": Color(0.30, 0.45, 0.24) },
	"h": { "name": "orc shaman", "hp": 7,  "dmg": 2, "sight": 10, "xp": 30,
			"coins": [9, 16],  "color": Color(0.38, 0.52, 0.30),
			"ranged": { "dmg": 3, "range": 6, "kind": "dart", "verb": "hexes" } },
	"u": { "name": "cave bear",  "hp": 14, "dmg": 4, "sight": 6,  "xp": 36,
			"coins": [10, 20], "color": Color(0.35, 0.24, 0.15) },
	"x": { "name": "gargoyle",   "hp": 12, "dmg": 4, "sight": 7,  "xp": 34,
			"coins": [10, 18], "color": Color(0.48, 0.48, 0.55) },
	"v": { "name": "dread knight", "hp": 18, "dmg": 5, "sight": 9, "xp": 60,
			"coins": [20, 35], "color": Color(0.32, 0.28, 0.38) },
}

# Vendor stock comes in two tiers per item type: the second tier is
# pricier but stronger. Unique world loot (found in outposts and
# dungeons, never sold in any stock) beats anything a vendor sells.
const ITEMS := {
	"bread":  { "name": "Fresh Bread",      "price": 4,  "heal": 4,
			"desc": "Restores 4 HP" },
	"stew":   { "name": "Hearty Stew",      "price": 10, "heal": 10,
			"desc": "Restores 10 HP" },
	"potion": { "name": "Healing Potion",   "price": 10, "heal": 8,
			"desc": "Restores 8 HP" },
	"gpotion": { "name": "Greater Potion",  "price": 25, "heal": 18,
			"desc": "Restores 18 HP" },
	"mpotion": { "name": "Mana Potion",     "price": 12, "mana_heal": 8,
			"desc": "Restores 8 mana" },
	"sword":  { "name": "Iron Sword",       "price": 25, "slot": 15, "dmg": 1,
			"desc": "+1 damage" },
	"ssword": { "name": "Steel Sword",      "price": 60, "slot": 15, "dmg": 2,
			"desc": "+2 damage" },
	"shield": { "name": "Wooden Shield",    "price": 15, "slot": 16, "hp": 3,
			"desc": "+3 max HP" },
	"tshield": { "name": "Tower Shield",    "price": 40, "slot": 16, "hp": 6,
			"desc": "+6 max HP" },
	"cap":    { "name": "Leather Cap",      "price": 10, "slot": 0,  "hp": 2,
			"desc": "+2 max HP" },
	"helm":   { "name": "Iron Helm",        "price": 28, "slot": 0,  "hp": 4,
			"desc": "+4 max HP" },
	"charm":  { "name": "Lucky Charm",      "price": 20, "slot": 12, "hp": 4,
			"desc": "+4 max HP" },
	"talisman": { "name": "Moon Talisman",  "price": 50, "slot": 12, "hp": 8,
			"desc": "+8 max HP" },
	"cloak":  { "name": "Traveler's Cloak", "price": 12, "slot": 14, "hp": 2,
			"desc": "+2 max HP" },
	"fcloak": { "name": "Fur-lined Cloak",  "price": 32, "slot": 14, "hp": 4,
			"desc": "+4 max HP" },
	"ring":   { "name": "Copper Ring",      "price": 8,  "slot": 10, "hp": 1,
			"desc": "+1 max HP" },
	"sring":  { "name": "Silver Ring",      "price": 22, "slot": 10, "hp": 2,
			"desc": "+2 max HP" },
	"bag":    { "name": "Small Bag",        "price": 18, "slot": 19, "bag_slots": 8,
			"desc": "+8 inventory slots" },
	"lbag":   { "name": "Traveler's Pack",  "price": 45, "slot": 19, "bag_slots": 14,
			"desc": "+14 inventory slots" },
	# Westmere wares: they fill the slots the town leaves empty
	# (Shirt, Neck, Gloves, Tabard, Ranged) and add spell damage.
	"shirt":  { "name": "Linen Shirt",      "price": 12, "slot": 3,  "hp": 2,
			"desc": "+2 max HP" },
	"sshirt": { "name": "Silk Shirt",       "price": 34, "slot": 3,  "hp": 4,
			"desc": "+4 max HP" },
	"tabard": { "name": "Westmere Tabard",  "price": 26, "slot": 18, "hp": 3,
			"desc": "+3 max HP" },
	"sausage": { "name": "Pork Sausage",    "price": 8,  "heal": 7,
			"desc": "Restores 7 HP" },
	"ham":    { "name": "Smoked Ham",       "price": 18, "heal": 16,
			"desc": "Restores 16 HP" },
	"salve":  { "name": "Herbal Salve",     "price": 15, "heal": 12,
			"desc": "Restores 12 HP" },
	"tonic":  { "name": "Bitterroot Tonic", "price": 8,  "mana_heal": 6,
			"desc": "Restores 6 mana" },
	"chain":  { "name": "Chainmail",        "price": 45, "slot": 4,  "hp": 6,
			"desc": "+6 max HP" },
	"plate":  { "name": "Platemail",        "price": 95, "slot": 4,  "hp": 9,
			"desc": "+9 max HP" },
	"gauntlets": { "name": "Iron Gauntlets", "price": 30, "slot": 9, "hp": 3,
			"desc": "+3 max HP" },
	"pendant": { "name": "Jade Pendant",    "price": 30, "slot": 1,  "hp": 3,
			"desc": "+3 max HP" },
	"amulet": { "name": "Sapphire Amulet",  "price": 75, "slot": 1,  "hp": 4, "mana": 4,
			"desc": "+4 max HP, +4 max mana" },
	"gring":  { "name": "Gold Ring",        "price": 45, "slot": 10, "hp": 3,
			"desc": "+3 max HP" },
	"wand":   { "name": "Oak Wand",         "price": 40, "slot": 17, "spell_dmg": 1,
			"desc": "+1 spell damage" },
	"bwand":  { "name": "Bone Wand",        "price": 95, "slot": 17, "spell_dmg": 2,
			"desc": "+2 spell damage" },
	"ale":    { "name": "Honey Ale",        "price": 6,  "heal": 5,
			"desc": "Restores 5 HP" },
	"gmpotion": { "name": "Greater Mana Potion", "price": 28, "mana_heal": 16,
			"desc": "Restores 16 mana" },
	"pie":    { "name": "Meat Pie",         "price": 15, "heal": 14,
			"desc": "Restores 14 HP" },
	"parchment": { "name": "Mysterious Parchment", "price": 0, "quest": true,
			"desc": "Quest item, sealed with grey wax" },
	"tpscroll": { "name": "Scroll of Town Portal", "price": 30, "portal": true,
			"desc": "Teleports you home and back" },
	# Unique world loot: never in any stock, but priced so it can be
	# sold (at half, like everything) if you really want to part with
	# it. Only the parchment is priceless: quest items are not goods.
	"armor":  { "name": "Leather Armor",    "price": 30, "slot": 4,  "hp": 4,
			"desc": "+4 max HP" },
	"boots":  { "name": "Scout's Boots",     "price": 70, "slot": 7,  "hp": 6,
			"desc": "+6 max HP" },
	"belt":   { "name": "Hunter's Belt",     "price": 90, "slot": 5,  "hp": 8,
			"desc": "+8 max HP" },
	"legplates": { "name": "Ancient Legplates", "price": 100, "slot": 6, "hp": 9,
			"desc": "+9 max HP" },
	"crown":  { "name": "Sunken Crown",      "price": 120, "slot": 0,  "hp": 10,
			"desc": "+10 max HP" },
	"runeblade": { "name": "Runeblade",      "price": 150, "slot": 15, "dmg": 3,
			"desc": "+3 damage" },
}

# World-of-Warcraft-style equipment slots, in canonical order.
const SLOT_NAMES := [
	"Head", "Neck", "Shoulder", "Shirt", "Chest", "Belt", "Legs",
	"Feet", "Wrist", "Gloves", "Finger 1", "Finger 2", "Trinket 1",
	"Trinket 2", "Back", "Main Hand", "Off Hand", "Ranged", "Tabard", "Bag",
]
const BASE_INV_SLOTS := 20


# Town vendors carry a second greeting ("greet_burned") for their
# days in the refugee camp, and each quest an "outro" line spoken
# when it is turned in - the story leaks through the small talk.
const VENDORS := [
	{
		"name": "Alda the baker", "short": "Alda", "symbol": "bread", "stock": ["bread", "stew"],
		"greet": "Alda: Fresh bread! Well, fresh-ish.",
		"greet_burned": "Alda: The oven burned with everything else. But bread rises, and so will we.",
		"quest": { "desc": "Kill 5 rats", "type": "kill", "target": "r", "need": 5,
				"intro": "Rats got into my flour again. Thin their numbers, would you?",
				"outro": "Alda: The flour is safe. You are welcome at my table, always.",
				"reward_coins": 20, "reward_xp": 15 },
	},
	{
		"name": "Borin the smith", "short": "Borin", "symbol": "anvil",
		"stock": ["sword", "ssword", "shield", "tshield", "cap", "helm"],
		"greet": "Borin: Steel solves most problems.",
		"greet_burned": "Borin: This anvil is borrowed. Mine sleeps under Dolm's rubble - as does Dolm. He never left his shop.",
		"quest": { "desc": "Kill 3 goblins", "type": "kill", "target": "g", "need": 3,
				"intro": "Goblins stole a crate of nails. Make them regret it.",
				"outro": "Borin: Good. Nails are small things - but wars are lost for small things.",
				"reward_coins": 25, "reward_xp": 15 },
	},
	{
		"name": "Cyra the alchemist", "short": "Cyra", "symbol": "flask",
		"stock": ["potion", "gpotion", "mpotion", "tpscroll", "charm", "talisman"],
		"greet": "Cyra: Potions brewing. Do not rush art.",
		"greet_burned": "Cyra: I bottled what I could the night of the fire. The rest fed the flames.",
		"quest": { "desc": "Bring me 10 coins", "type": "coins", "need": 10,
				"intro": "Reagents are expensive. Fund my research with 10 coins?",
				"outro": "Cyra: Splendid! Take these - and if a potion ever smells of almonds, do not drink it.",
				"reward_items": { "potion": 2, "tpscroll": 2 }, "reward_xp": 20 },
	},
	{
		"name": "Dolm the trader", "short": "Dolm", "symbol": "bag",
		"stock": ["cloak", "fcloak", "ring", "sring", "bag", "lbag"],
		"greet": "Dolm: Rare goods for discerning customers.",
		"quest": { "desc": "Recover the Mysterious Parchment from the depths below the ruins",
				"type": "item", "target": "parchment", "need": 1,
				"intro": "Old ledgers speak of a sealed parchment locked in a vault below the Ancient Ruins - deeper than the crypt, they say. Seals on such things are warnings as much as locks... but coin is coin. Bring it to me, whatever it takes.",
				"reward_coins": 60, "reward_items": { "armor": 1 }, "reward_xp": 50 },
	},
]

# Westmere's eight vendors. Together with the town's four they share
# one global index space (town first, then these) that keys quests[],
# buyback{} and current_shop; see vendor_def().
const WEST_VENDORS := [
	{
		# Wren also carries the cloaks and packs that used to be
		# Dolm's trade: someone had to, after the fire.
		"name": "Wren the weaver",    "short": "Wren",  "symbol": "bag",
		"stock": ["shirt", "sshirt", "cloak", "fcloak", "tabard", "bag", "lbag"],
		"greet": "Wren: Finest cloth west of the fortress.",
		"quest": { "desc": "Kill 4 wolves", "type": "kill", "target": "w", "need": 4,
				"intro": "My looms want wool, but the wolves have gotten bold since the fire drove everything wild. Cull 4 of them?",
				"outro": "Wren: Winter wool at last. I shall weave you into the tapestry - a small figure, mind.",
				"reward_coins": 30, "reward_xp": 20 },
	},
	{
		# Tobin and Pell joined forces: meat and bread under one roof.
		"name": "Tobin the provisioner", "short": "Tobin", "symbol": "bread",
		"stock": ["sausage", "ham", "bread", "pie"],
		"greet": "Tobin: Meat and bread under one roof - Pell and I joined forces.",
		"quest": { "desc": "Kill 3 wild boars", "type": "kill", "target": "b", "need": 3,
				"intro": "Boar sign all around my pens this morning. Bring down 3 and the smokehouse pays you back.",
				"outro": "Tobin: The smokehouse sings again. Pell is already kneading in your honor.",
				"reward_items": { "ham": 2 }, "reward_xp": 20 },
	},
	{
		"name": "Mira the herbalist", "short": "Mira",  "symbol": "flask",
		"stock": ["salve", "tonic", "tpscroll"],
		"greet": "Mira: Every ailment has its herb. Grief takes longest to steep.",
		"quest": { "desc": "Bring 2 Healing Potions", "type": "item", "target": "potion", "need": 2,
				"intro": "My whole shelf of potions spoiled in the damp. Bring me 2 Healing Potions to restock?",
				"outro": "Mira: Fresh stock. The road north will empty these shelves faster than I can fill them.",
				"reward_items": { "gpotion": 2 }, "reward_xp": 25 },
	},
	{
		"name": "Galt the armorer",   "short": "Galt",  "symbol": "anvil",
		"stock": ["chain", "plate", "gauntlets"],
		"greet": "Galt: Good armor is cheaper than a funeral. Ask the east.",
		"quest": { "desc": "Kill 2 trolls", "type": "kill", "target": "t", "need": 2,
				"intro": "They say troll hide turns my best steel. Fell 2 trolls and prove them wrong.",
				"outro": "Galt: Troll-tested, then. I will hammer that boast into the next breastplate I sell you.",
				"reward_coins": 50, "reward_xp": 35 },
	},
	{
		# Sela inherited the ring trade from poor Dolm's ashes.
		"name": "Sela the jeweler",   "short": "Sela",  "symbol": "bag",
		"stock": ["ring", "sring", "gring", "pendant", "amulet"],
		"greet": "Sela: Gems from the caravan - the last one, until the roads are safe again.",
		"quest": { "desc": "Bring me 30 coins", "type": "coins", "need": 30,
				"intro": "The caravan finally came - and emptied my coffers. Invest 30 coins and keep the first piece I finish?",
				"outro": "Sela: An investor with dirty boots. The caravan masters would faint. Here - your dividend.",
				"reward_items": { "gring": 1 }, "reward_xp": 30 },
	},
	{
		"name": "Odo the fletcher",   "short": "Odo",   "symbol": "anvil",
		"stock": ["wand", "bwand"],
		"greet": "Odo: Arrows are out of fashion. Wands, now...",
		"quest": { "desc": "Kill 6 skeletons", "type": "kill", "target": "s", "need": 6,
				"intro": "Nobody buys arrows anymore, so I carve wands. Good bone is scarce - shatter 6 skeletons for me?",
				"outro": "Odo: Good bone, this. If arrows ever come back into fashion, I owe you a quiver.",
				"reward_coins": 40, "reward_xp": 30 },
	},
	{
		"name": "Ivy the brewer",     "short": "Ivy",   "symbol": "flask",
		"stock": ["ale", "gmpotion"],
		"greet": "Ivy: The good barrel is always the next one.",
		"quest": { "desc": "Bring me 15 coins", "type": "coins", "need": 15,
				"intro": "The first batch needs better barrels than I can afford. Spare 15 coins for the cause?",
				"outro": "Ivy: To barrels, to bravery! The first pour is yours when the batch matures.",
				"reward_items": { "gmpotion": 2 }, "reward_xp": 20 },
	},
	{
		"name": "Sable the scribe",   "short": "Sable", "symbol": "scroll",
		"stock": ["tpscroll"],
		"greet": "Sable: Ink, wax, and ways home. Scrolls for the prepared.",
		"quest": { "desc": "Kill 4 wraiths", "type": "kill", "target": "y", "need": 4,
				"intro": "My portal ink calls for wraith-essence. Put 4 wraiths to rest for me - the crypt is full of them, and worse marches in the north.",
				"outro": "Sable: Wraith-essence... the ink almost writes itself now. Take these, and always leave a way home open.",
				"reward_items": { "tpscroll": 3 }, "reward_xp": 30 },
	},
]

# All vendors share one global index space: the town's four first,
# then Westmere's eight. quests[] is built in this order, and
# current_shop / buyback{} use the same indices.
func vendor_def(gidx: int) -> Dictionary:
	if gidx < VENDORS.size():
		return VENDORS[gidx]
	return WEST_VENDORS[gidx - VENDORS.size()]

func vendor_total() -> int:
	return VENDORS.size() + WEST_VENDORS.size()

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
var player_spell_dmg := 0 # computed: equipment only (wands)
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

# The story's hinge: picking up the Mysterious Parchment breaks the
# seal; the first time you set foot in town afterwards, it has been
# burned to the ground and the vendors have fled to Westmere.
var parchment_found := false
var town_burned := false
# Active town portal: {map, pos, home, home_pos}, or empty. Cast a
# Scroll of Town Portal anywhere to jump home; the portal waiting
# there returns you to the cast tile, then closes.
var portal := {}

var active_spell := "dart"
var spellbook_index := 0
var targeting := false  # aiming the active spell at a tile
# In-flight shots: {kind, from, to, t, dur, player, [target, dmg]}.
# The player's shot resolves on impact and blocks input; hostile
# shots are visual only (their damage lands when fired).
var projectiles := []
var minimap_dirty := true   # tells the HUD to rebuild its terrain texture

var messages := []
var game_over := false
var move_count := 0
var run_start_text := ""   # wall-clock time the run began / ended,
var run_end_text := ""     # shown on the death screen
var victory_banner := false
var victory_moves := 0
var title_index := 0
var title_screen := "main"   # "main" menu or the "load" slot picker
var held_dir := Vector2i.ZERO
var move_timer := 0.0

var ui_pane := 1          # inventory screen: 0 = equipment, 1 = backpack
var ui_index := 0
# Every action has up to two keybinds (KEY_NONE = unbound). Arrow keys
# are additional hardwired movement keys on top of these.
var keymap := {
	"up": [KEY_W, KEY_KP_8], "down": [KEY_S, KEY_KP_2],
	"left": [KEY_A, KEY_KP_4], "right": [KEY_D, KEY_KP_6],
	"up_left": [KEY_Q, KEY_KP_7], "up_right": [KEY_E, KEY_KP_9],
	"down_left": [KEY_Z, KEY_KP_1], "down_right": [KEY_C, KEY_KP_3],
	"wait": [KEY_SPACE, KEY_NONE], "character": [KEY_I, KEY_NONE],
	"journal": [KEY_J, KEY_NONE], "options": [KEY_O, KEY_NONE],
	"spell": [KEY_KP_5, KEY_NONE], "spellbook": [KEY_P, KEY_NONE],
	"map": [KEY_M, KEY_NONE], "log": [KEY_L, KEY_NONE],
}

# The first bound cast key, for UI hints ("Kp 5 casts").
func spell_key_label() -> String:
	for k in keymap["spell"]:
		if k != KEY_NONE:
			return OS.get_keycode_string(k)
	return "middle mouse"

func key_is(action: String, key: int) -> bool:
	return key != KEY_NONE and key in keymap[action]

func _action_down(action: String) -> bool:
	for k in keymap[action]:
		if k != KEY_NONE and Input.is_key_pressed(k):
			return true
	return false
var options_screen := "main"
var opt_index := 0
var opt_rebinding := false
var opt_bind_slot := 0    # which of the two keybind slots is being edited
var opt_slider_dragging := false
var master_volume := 1.0
# Gameplay toggles (Options > Gameplay), all persisted in settings.
var skip_intro := false        # skip the intro parchment on new runs
var show_quest_marks := true   # "!" and "?" floating over quest givers
var weather_enabled := true    # rain and thunder
var show_flashes := true       # lightning screen flashes
var opt_confirm := ""          # which action the are-you-sure screen guards
var visited := {}         # maps the player has entered at least once
var banner_text := ""
var banner_timer := 0.0

var music: AudioStreamPlayer
var music_track := ""
var combat_heat := 0   # turns of combat music left after last enemy sighting

# ---- sound effects ----
const SFX_NAMES := ["hit", "kill", "coin", "pickup", "levelup", "cast",
		"hurt", "death", "quest", "drink", "stairs"]
var sfx_streams := {}
var sfx_pool := []      # a few players so overlapping cues don't cut off
var sfx_idx := 0

# Current map's terrain palette (cached in _load_map: _draw_tile is hot).
var pal_floor := Color(0.20, 0.26, 0.18)
var pal_floor_hi := Color(0.24, 0.31, 0.21)
var pal_wall := Color(0.38, 0.38, 0.44)
var pal_wall_hi := Color(0.48, 0.48, 0.54)

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
	for n in SFX_NAMES:
		sfx_streams[n] = load("res://audio/sfx_%s.ogg" % n)
	for i in 5:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		sfx_pool.append(p)
	_apply_volume()
	_show_title()

func _sfx(sound: String) -> void:
	var p: AudioStreamPlayer = sfx_pool[sfx_idx]
	sfx_idx = (sfx_idx + 1) % sfx_pool.size()
	p.stream = sfx_streams[sound]
	p.play()

func _show_title() -> void:
	mode = Mode.TITLE
	title_index = 0
	title_screen = "main"
	game_over = false
	victory_banner = false
	projectiles.clear()
	_cancel_targeting()
	_set_rain(false)
	_play_track("title")
	_refresh()

# from_title: only the title screen's New Game shows the intro
# parchment (death restarts and save loads go straight to play).
func _start(from_title := false) -> void:
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
	run_start_text = Time.get_datetime_string_from_system(false, true)
	run_end_text = ""
	victory_banner = false
	victory_moves = 0
	buyback = {}
	shop_index = 0
	active_spell = "dart"
	parchment_found = false
	town_burned = false
	portal = {}
	projectiles.clear()
	_cancel_targeting()
	mode = Mode.PLAY
	messages = []
	map_state = {}
	quests = []
	for i in vendor_total():
		var vd := vendor_def(i)
		var q: Dictionary = vd["quest"].duplicate()
		q["state"] = "hidden"
		q["progress"] = 0
		q["giver"] = vd["name"]
		quests.append(q)
	_load_map("town", "spawn")
	_log("Welcome to Grey Fortress.")
	_log("Arrows/WASD move. I character, J journal, P spells, M map, L log, O options.")
	_update_music()
	if from_title and not skip_intro:
		mode = Mode.INTRO
	_refresh()

func _close_intro() -> void:
	mode = Mode.PLAY
	_refresh()

func _refresh() -> void:
	camera.position = Vector2(player_pos) * TILE + Vector2(TILE, TILE) * 0.5
	# Push the new position to the viewport NOW: _draw culls tiles from
	# get_screen_center_position(), which is stale until the camera
	# scroll updates (visible as a grey world after a map transition).
	camera.force_update_scroll()
	_mark_explored()
	queue_redraw()
	hud.queue_redraw()

# Fog of war: every tile the camera has actually shown is marked in
# the map's "explored" grid, and stays revealed forever (the grid is
# part of the save). The minimap draws fog over the rest. Villages
# ("no_fog") are always fully drawn.
func _mark_explored() -> void:
	if grid.is_empty() or MAP_DEFS[current_map].get("no_fog", false):
		return
	var expl: Array = map_state[current_map]["explored"]
	var vsize := get_viewport_rect().size
	var topleft := camera.get_screen_center_position() - vsize * 0.5
	var mw: int = grid[0].size()
	var mh: int = grid.size()
	var x0: int = clamp(int(floor(topleft.x / TILE)), 0, mw - 1)
	var y0: int = clamp(int(floor(topleft.y / TILE)), 0, mh - 1)
	var x1: int = clamp(int(ceil((topleft.x + vsize.x) / TILE)), 0, mw - 1)
	# the strip behind the HUD bar is not actually visible
	var y1: int = clamp(int(ceil((topleft.y + vsize.y - BAR_H) / TILE)), 0, mh - 1)
	var changed := false
	for y in range(y0, y1 + 1):
		var row: Array = expl[y]
		for x in range(x0, x1 + 1):
			if row[x] == 0:
				row[x] = 1
				changed = true
	if changed:
		minimap_dirty = true

# A fresh all-fog exploration grid (0 = never seen on screen).
func _blank_explored(w: int, h: int) -> Array:
	var expl := []
	for y in h:
		var row := []
		row.resize(w)
		row.fill(0)
		expl.append(row)
	return expl


# ---------------------------------------------------------
#  Hold-to-walk: poll movement keys every frame.
#  First step is instant, then a short pause, then repeat.
# ---------------------------------------------------------
func _process(delta: float) -> void:
	# The area banner pauses while lore covers the screen (the intro
	# parchment), then plays in full once the page is turned.
	if banner_timer > 0.0 and mode != Mode.INTRO:
		banner_timer -= delta
		hud.queue_redraw()
	if not portal.is_empty() and current_map == portal["home"]:
		queue_redraw()   # keep the portal swirling
	_weather_tick(delta)
	if not projectiles.is_empty():
		_advance_projectiles(delta)
	if _shot_in_flight():
		held_dir = Vector2i.ZERO
		return
	if game_over or victory_banner or mode != Mode.PLAY:
		held_dir = Vector2i.ZERO
		return
	if targeting:
		hud.queue_redraw()   # the cursor icon and tile highlight follow the mouse
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
	if Input.is_key_pressed(KEY_UP) or _action_down("up"):
		dy -= 1
	if Input.is_key_pressed(KEY_DOWN) or _action_down("down"):
		dy += 1
	if Input.is_key_pressed(KEY_LEFT) or _action_down("left"):
		dx -= 1
	if Input.is_key_pressed(KEY_RIGHT) or _action_down("right"):
		dx += 1
	# Dedicated diagonal keys win over anything else.
	if _action_down("up_left"):
		dx = -1
		dy = -1
	elif _action_down("up_right"):
		dx = 1
		dy = -1
	elif _action_down("down_left"):
		dx = -1
		dy = 1
	elif _action_down("down_right"):
		dx = 1
		dy = 1
	return Vector2i(dx, dy)


# ---------------------------------------------------------
#  Map loading and procedural generation
# ---------------------------------------------------------
# Display name/color of a map; after the burning, the town shows as
# its own ruin everywhere (banner, minimap, world map, death screen).
func map_name(id: String) -> String:
	if id == "town" and town_burned:
		return "Ruins of Grey Fortress"
	return MAP_DEFS[id]["name"]

func map_tint(id: String) -> Color:
	if id == "town" and town_burned:
		return Color(0.17, 0.16, 0.16)
	return MAP_DEFS[id]["tint"]

func _load_map(id: String, arrive: String) -> void:
	# The story's turning point: the first return to town after the
	# parchment is taken finds it burned to the ground.
	var burn_now: bool = id == "town" and parchment_found and not town_burned
	if burn_now:
		town_burned = true
		map_state.erase("town")   # regenerate it in ashes
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
		"east_gate":
			player_pos = st["east_gate"] + Vector2i(-1, 0)
		"west_gate":
			player_pos = st["west_gate"] + Vector2i(1, 0)
		"descend":
			player_pos = st["stairs_up"]     # arrive on the up-stairs below
		"ascend":
			player_pos = st["stairs_down"]   # arrive on the down-stairs above
		"keep":
			pass   # loading a save: player_pos is restored by the caller
	if revisit and arrive != "keep":
		_respawn_mobs()
	# cache the map's terrain palette for the tile renderer
	var pal: Dictionary = MAP_DEFS[id].get("palette", {})
	if id == "town" and town_burned:
		pal = { "floor": Color(0.15, 0.14, 0.13), "floor_hi": Color(0.18, 0.17, 0.15),
				"wall": Color(0.24, 0.23, 0.24), "wall_hi": Color(0.30, 0.29, 0.30) }
	pal_floor = pal.get("floor", Color(0.20, 0.26, 0.18))
	pal_floor_hi = pal.get("floor_hi", Color(0.24, 0.31, 0.21))
	pal_wall = pal.get("wall", Color(0.38, 0.38, 0.44))
	pal_wall_hi = pal.get("wall_hi", Color(0.48, 0.48, 0.54))
	projectiles.clear()
	minimap_dirty = true
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
	_set_rain(weather_enabled and randf() < RAIN_CHANCE)
	if not visited.has(id):
		visited[id] = true
		banner_text = "Entering... %s" % map_name(id)
		if MAP_DEFS[id].has("level"):
			banner_text += "   (suggested Lv %d)" % MAP_DEFS[id]["level"]
		banner_timer = 3.2
	if burn_now:
		banner_text = "Grey Fortress Town... lies in ashes"
		banner_timer = 5.0
		flash_alpha = 1.0
		thunder_player.play()
		_log("You return to a nightmare: every roof is fallen, every wall charred.")
		_log("On a scorched door, a hasty scrawl: 'Gone west. Find us. - Alda'")
		_log("Not every door bears a message. Some are simply silent.")

func _generate_map(id: String) -> Dictionary:
	var def: Dictionary = MAP_DEFS[id]
	var w: int = def["w"]
	var h: int = def["h"]
	var gx: int = w / 2      # gates sit at columns gx, gx+1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)

	# Caves skip the surface steps entirely: solid rock, carved tunnels.
	if def.has("cave"):
		return _generate_cave(def, rng)

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

	# 5. Winding road between the gates (wilderness maps), plus a
	# second east-west road for maps with side gates; the two are
	# guaranteed to cross, so every gate connects.
	if id != "town":
		for y in range(1, h - 1):
			var cx: int = gx + int(round(3.0 * sin(y * 0.11) + 2.0 * sin(y * 0.031)))
			for x in range(cx - 1, cx + 3):
				g[y][x] = "."
	if id != "town" and id != "west" and (def.has("east") or def.has("west")):
		var road_gy: int = h / 2
		for x in range(1, w - 1):
			var cy: int = road_gy + int(round(3.0 * sin(x * 0.09) + 2.0 * sin(x * 0.027)))
			for y in range(cy - 1, cy + 3):
				g[y][x] = "."

	var vs := []
	var altars := []
	var items := []
	var spawn := Vector2i(gx, h - 3)
	var north_gate := Vector2i(-1, -1)
	var south_gate := Vector2i(-1, -1)
	var west_gate := Vector2i(-1, -1)
	var east_gate := Vector2i(-1, -1)

	# 6. The town: a compact village filling most of its small map.
	# After the burning it regenerates in ashes: charred shells where
	# the houses stood, burnt trees, no vendors - only the stone
	# temple still standing, and the west gate broken open by the
	# survivors as they fled to Westmere.
	if id == "town":
		for y in range(4, 27):
			for x in range(6, 36):
				g[y][x] = "."
		if town_burned:
			for hp in [Vector2i(9, 6), Vector2i(28, 6), Vector2i(9, 14), Vector2i(28, 14)]:
				_place_burned_house(g, hp.x, hp.y, rng)
			_place_temple(g, 18, 21, altars)   # the temple alone survived
			var gy: int = h / 2
			for y in range(gy - 1, gy + 3):
				for x in range(1, 7):
					g[y][x] = "."
			g[gy][0] = "<"
			g[gy + 1][0] = "<"
			west_gate = Vector2i(0, gy)
			for y in h:
				for x in w:
					if g[y][x] == "T":
						g[y][x] = "F"
		else:
			_place_house(g, 9, 6, vs)    # Alda
			_place_house(g, 28, 6, vs)   # Borin
			_place_house(g, 9, 14, vs)   # Cyra
			_place_house(g, 28, 14, vs)  # Dolm
			_place_temple(g, 18, 21, altars)
		# The sealed east gate: beyond it, the broken road that once
		# climbed to the Grey Fortress itself. Stone outlasts fire,
		# so it stands in both towns, flanked by old gateposts.
		var fgy: int = h / 2
		for y in range(fgy - 1, fgy + 3):
			for x in range(36, w - 1):
				g[y][x] = "."
		g[fgy][w - 1] = "G"
		g[fgy + 1][w - 1] = "G"
		g[fgy - 1][w - 2] = "S"
		g[fgy + 2][w - 2] = "S"
		spawn = Vector2i(gx, 12)
		# Short road from the plaza up to the north gate.
		for y in range(1, 7):
			for x in range(gx - 1, gx + 3):
				g[y][x] = "."

	# 6b. Westmere: a larger village. Eight vendor houses in two rows,
	# the temple at the bottom, an east gate back to town, and a
	# north gate to the Reaches (boarded until the story opens it).
	if id == "west":
		for y in range(4, 32):
			for x in range(5, 45):
				g[y][x] = "."
		for i in 4:
			_place_house(g, 7 + i * 10, 6, vs, "west")
			_place_house(g, 7 + i * 10, 16, vs, "west")
		_place_temple(g, 21, 27, altars)
		spawn = Vector2i(w / 2, 12)
		var ey := h / 2   # east gate row
		_clear_area(g, w - 5, ey - 1, 4, 4)
		g[ey][w - 1] = ">"
		g[ey + 1][w - 1] = ">"
		east_gate = Vector2i(w - 1, ey)
		# north gate: boarded until Dolm's last wish opens the road
		# to the Northern Reaches, with a road leading up to it
		_clear_area(g, gx - 2, 1, 6, 3)
		if fortress_road_open():
			g[0][gx] = "^"
			g[0][gx + 1] = "^"
			north_gate = Vector2i(gx, 0)
		else:
			g[0][gx] = "B"
			g[0][gx + 1] = "B"
		for y in range(1, 5):
			for x in range(gx - 1, gx + 3):
				g[y][x] = "."
		# The refugee camp: the town vendors who made it out - Alda,
		# Borin and Cyra - tents pitched on the green above the
		# temple. Dolm did not; he lies in his burned shop. Westmere
		# is only reachable after the fall, so the camp is always here.
		for i in 3:
			var cx := 12 + i * 9
			g[23][cx] = "E"
			vs.append({ "pos": Vector2i(cx, 24), "set_idx": i, "set": "town" })

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

	# 7c. The sunken stairway down to the crypt (ruins only), housed
	# inside a ruined shrine: stone walls, one south door, and the
	# stairs at its heart.
	var stairs_down := Vector2i(-1, -1)
	if def.has("down"):
		_clear_area(g, 94, 19, 11, 9)
		for x in range(96, 103):
			g[21][x] = "S"
			g[25][x] = "S"
		for y in range(22, 25):
			g[y][96] = "S"
			g[y][102] = "S"
		g[25][99] = "D"
		g[23][99] = "O"
		stairs_down = Vector2i(99, 23)

	# 8. Gates, with a small clearing around each. North/south sit on
	# the gx columns, east/west on the gy rows. Westmere's north gate
	# (boarded or open) and the villages' special gates were already
	# placed above, so anything pre-set is skipped here.
	if def.has("north") and north_gate.x < 0 and id != "west":
		_clear_area(g, gx - 2, 1, 6, 3)
		g[0][gx] = "^"
		g[0][gx + 1] = "^"
		north_gate = Vector2i(gx, 0)
	if def.has("south"):
		_clear_area(g, gx - 2, h - 4, 6, 3)
		g[h - 1][gx] = "v"
		g[h - 1][gx + 1] = "v"
		south_gate = Vector2i(gx, h - 1)
	var gy: int = h / 2
	if def.has("east") and east_gate.x < 0:
		_clear_area(g, w - 4, gy - 2, 3, 6)
		g[gy][w - 1] = ">"
		g[gy + 1][w - 1] = ">"
		east_gate = Vector2i(w - 1, gy)
	if def.has("west") and west_gate.x < 0 and id != "town":
		_clear_area(g, 1, gy - 2, 3, 6)
		g[gy][0] = "<"
		g[gy + 1][0] = "<"
		west_gate = Vector2i(0, gy)

	# 9. Mobs, kept away from the south entrance.
	var ms := _spawn_mobs(g, rng, def["mobs"], w, h,
			south_gate if south_gate.x >= 0 else spawn)

	return {
		"grid": g, "mobs": ms, "vendors": vs, "items": items, "altars": altars,
		"spawn": spawn, "north_gate": north_gate, "south_gate": south_gate,
		"west_gate": west_gate, "east_gate": east_gate,
		"stairs_down": stairs_down, "stairs_up": Vector2i(-1, -1),
		"explored": _blank_explored(w, h),
	}

# A dungeon level: solid rock with a drunkard's-walk cave carved out
# of it. The up-stairs sit at the center (also the arrival point);
# the treasure named by the def's "loot" lies in the farthest carved
# corner, and a def with a "down" link gets a stairway placed far
# from both the entrance and the treasure.
func _generate_cave(def: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var w: int = def["w"]
	var h: int = def["h"]
	var g := []
	for y in h:
		var row := []
		for x in w:
			row.append("#")
		g.append(row)
	var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var p := Vector2i(w / 2, h / 2)
	var carved := 0
	while carved < int(w * h * 0.34):
		if g[p.y][p.x] == "#":
			g[p.y][p.x] = "."
			carved += 1
		var step: Vector2i = dirs[rng.randi_range(0, 3)]
		p.x = clamp(p.x + step.x, 1, w - 2)
		p.y = clamp(p.y + step.y, 1, h - 2)

	var center := Vector2i(w / 2, h / 2)
	g[center.y][center.x] = "U"
	# The map's bottom-right corner sits behind the minimap overlay
	# whenever the camera is clamped there, so nothing important may
	# be placed in it.
	var ui_corner := Rect2i(w - 10, h - 8, 10, 8)
	var far := center
	var best := 0
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if g[y][x] == "." and not ui_corner.has_point(Vector2i(x, y)):
				var d: int = abs(x - center.x) + abs(y - center.y)
				if d > best:
					best = d
					far = Vector2i(x, y)
	var items := [{ "pos": far, "id": def["loot"] }]
	if def.has("quest_loot"):
		# the quest item hides in yet another corner, far from both
		# the entrance and the treasure
		var qbest := -1
		var qpos := center
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				if g[y][x] != "." or ui_corner.has_point(Vector2i(x, y)):
					continue
				var d: int = mini(abs(x - center.x) + abs(y - center.y),
						abs(x - far.x) + abs(y - far.y))
				if d > qbest:
					qbest = d
					qpos = Vector2i(x, y)
		items.append({ "pos": qpos, "id": def["quest_loot"] })
	var stairs_down := Vector2i(-1, -1)
	if def.has("down"):
		# the carved tile whose NEARER of (entrance, treasure) is farthest
		best = -1
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				if g[y][x] != "." or ui_corner.has_point(Vector2i(x, y)):
					continue
				var d: int = mini(abs(x - center.x) + abs(y - center.y),
						abs(x - far.x) + abs(y - far.y))
				if d > best:
					best = d
					stairs_down = Vector2i(x, y)
		g[stairs_down.y][stairs_down.x] = "O"
	var ms := _spawn_mobs(g, rng, def["mobs"], w, h, center, [], 10)
	return {
		"grid": g, "mobs": ms, "vendors": [], "items": items, "altars": [],
		"spawn": center, "north_gate": Vector2i(-1, -1), "south_gate": Vector2i(-1, -1),
		"west_gate": Vector2i(-1, -1), "east_gate": Vector2i(-1, -1),
		"stairs_down": stairs_down, "stairs_up": center,
		"explored": _blank_explored(w, h),
	}

func _clear_area(g: Array, x0: int, y0: int, w: int, h: int) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			g[y][x] = "."

# 5x4 house with a bottom door and a vendor inside. `set_name` picks
# which vendor roster (VENDORS or WEST_VENDORS) the occupant is from.
func _place_house(g: Array, x0: int, y0: int, vs: Array, set_name: String = "town") -> void:
	for x in range(x0, x0 + 5):
		g[y0][x] = "H"
		g[y0 + 3][x] = "H"
	for y in range(y0 + 1, y0 + 3):
		g[y][x0] = "H"
		g[y][x0 + 4] = "H"
		for x in range(x0 + 1, x0 + 4):
			g[y][x] = "."
	g[y0 + 3][x0 + 2] = "D"
	vs.append({ "pos": Vector2i(x0 + 2, y0 + 1), "set_idx": vs.size(), "set": set_name })

# The charred shell of a 5x4 house: its wall line with fire-eaten
# gaps, no vendor. Where the door was stays open, so the shell can
# always be entered. Used by the burned town.
func _place_burned_house(g: Array, x0: int, y0: int, rng: RandomNumberGenerator) -> void:
	for x in range(x0, x0 + 5):
		for y in [y0, y0 + 3]:
			if y == y0 + 3 and x == x0 + 2:
				continue   # the doorway
			if rng.randf() < 0.7:
				g[y][x] = "R"
	for y in range(y0 + 1, y0 + 3):
		for x in [x0, x0 + 4]:
			if rng.randf() < 0.7:
				g[y][x] = "R"

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

# Places counts of mobs on free floor, away from `avoid` (the player's
# entry point) and from any mob already in `existing`.
func _spawn_mobs(g: Array, rng: RandomNumberGenerator, counts: Dictionary, w: int, h: int, avoid: Vector2i, existing: Array = [], avoid_dist: int = 18) -> Array:
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
			if abs(p.x - avoid.x) + abs(p.y - avoid.y) < avoid_dist:
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
	# Middle mouse: start aiming the active spell; while aiming, it fires too.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		if mode == Mode.PLAY and not game_over and not victory_banner and not _shot_in_flight():
			if targeting:
				_try_fire_click(event.position)
			else:
				_begin_targeting()
		return
	# Right mouse is a universal "go back": whatever Esc dismisses,
	# it dismisses too.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_handle_right_click()
		return
	# Mouse wheel scrolls the message log panel.
	if event is InputEventMouseButton and event.pressed and mode == Mode.LOG:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			log_scroll += 3
			_refresh()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			log_scroll = max(log_scroll - 3, 0)
			_refresh()
			return
	if event is InputEventMouseMotion and mode == Mode.OPTIONS and opt_slider_dragging:
		_options_click(event.position, false)
		return

	# Key-repeat (echo) events are dropped everywhere except inside
	# the message log, which behaves like a text field: a held
	# Backspace keeps deleting, held arrows keep scrolling.
	if not (event is InputEventKey and event.pressed):
		return
	if event.echo and mode != Mode.LOG:
		return

	if event.keycode == KEY_F11:
		_toggle_fullscreen()
		_save_settings()
		return

	if mode == Mode.TITLE:
		_title_input(event.keycode)
		return

	if game_over:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_start()
		elif event.keycode == KEY_ESCAPE:
			_show_title()
		return

	if victory_banner:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_ESCAPE:
			victory_banner = false
			_refresh()
		return

	match mode:
		Mode.INTRO:
			_close_intro()
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
		Mode.SPELLBOOK:
			_spellbook_input(event.keycode)
		Mode.WORLDMAP:
			_close_panel()
		Mode.LOG:
			_log_panel_input(event)

# Right click mirrors Esc everywhere by forwarding KEY_ESCAPE to the
# same per-mode handlers the keyboard uses: it closes panels, steps
# options sub-screens back, cancels a rebind or an aimed spell, and
# leaves the death/victory screens. The one Esc behavior it does NOT
# copy is OPENING the options menu from plain play - a stray right
# click popping up a menu would feel like a misfire.
func _handle_right_click() -> void:
	if mode == Mode.TITLE:
		if title_screen == "load":
			title_screen = "main"
			_refresh()
		return
	if game_over:
		_show_title()
		return
	if victory_banner:
		victory_banner = false
		_refresh()
		return
	match mode:
		Mode.INTRO:
			_close_intro()
		Mode.PLAY:
			if targeting:
				_cancel_targeting()
				_refresh()
		Mode.INVENTORY:
			_inventory_input(KEY_ESCAPE)
		Mode.SHOP:
			_shop_input(KEY_ESCAPE)
		Mode.JOURNAL:
			_close_panel()
		Mode.OPTIONS:
			_options_input(KEY_ESCAPE)
		Mode.SPELLBOOK:
			_spellbook_input(KEY_ESCAPE)
		Mode.WORLDMAP:
			_close_panel()
		Mode.LOG:
			_log_panel_escape()

# All left-clicks funnel through here. Movement is deliberately NOT
# mouse-driven: clicks only operate the UI (HUD buttons and panels).
func _handle_click(mp: Vector2) -> void:
	if mode == Mode.TITLE:
		_title_click(mp)
		return
	if game_over:
		_start()
		return
	if victory_banner:
		victory_banner = false
		_refresh()
		return
	if mode == Mode.INTRO:
		_close_intro()
		return
	if mode == Mode.PLAY and targeting:
		_try_fire_click(mp)
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
		Mode.SPELLBOOK:
			_spellbook_click(mp)
		Mode.WORLDMAP:
			_close_panel()
		Mode.LOG:
			# clicking outside the panel closes it (geometry mirrors
			# _draw_panel_log in hud.gd); inside, the wheel scrolls
			var lvs := get_viewport_rect().size
			var lw: float = min(lvs.x - 200.0, 980.0)
			var lh: float = lvs.y - BAR_H - 80.0
			if not Rect2((lvs.x - lw) * 0.5, (lvs.y - BAR_H - lh) * 0.5, lw, lh).has_point(mp):
				_close_panel()

# The HUD buttons, stacked in two rows of three on the bar's right
# edge so they claim a narrow column instead of a full-width strip.
# Geometry is shared with hud.gd via bar_button_rects(), so drawing
# and hit-testing can never drift apart; bar_buttons_left() is the
# left edge of the column, which the message log must never cross.
const BAR_BUTTONS := ["Inventory (I)", "Journal (J)", "Spells (P)", "Map (M)", "Options (O)"]
const BAR_BTN_W := 92.0
const BAR_BTN_H := 26.0
const BAR_BTN_GAP := 5.0

func bar_buttons_left() -> float:
	return get_viewport_rect().size.x - (BAR_BTN_W + BAR_BTN_GAP) * 3.0 - 6.0

func bar_button_rects() -> Array:
	var vs := get_viewport_rect().size
	var x0 := bar_buttons_left()
	var y0 := vs.y - BAR_H + 12.0
	var rects := []
	for i in BAR_BUTTONS.size():
		rects.append(Rect2(x0 + (i % 3) * (BAR_BTN_W + BAR_BTN_GAP),
				y0 + (i / 3) * (BAR_BTN_H + 6.0), BAR_BTN_W, BAR_BTN_H))
	return rects

func _bar_click(mp: Vector2) -> bool:
	# Clicking the message column of the bar opens the full log.
	var vs := get_viewport_rect().size
	if Rect2(350.0, vs.y - BAR_H + 4.0, max(bar_buttons_left() - 358.0, 0.0), BAR_H - 8.0).has_point(mp):
		if mode == Mode.LOG:
			_close_panel()
		else:
			_open_log()
		return true
	# Clicking the active-spell block toggles the spellbook.
	if Rect2(207.0, vs.y - BAR_H + 4.0, 138.0, BAR_H - 8.0).has_point(mp):
		if mode == Mode.SPELLBOOK:
			_close_panel()
		else:
			if mode == Mode.SHOP:
				current_shop = -1
			mode = Mode.SPELLBOOK
			spellbook_index = SPELL_ORDER.find(active_spell)
			_refresh()
		return true
	var rects := bar_button_rects()
	var targets := [Mode.INVENTORY, Mode.JOURNAL, Mode.SPELLBOOK, Mode.WORLDMAP, Mode.OPTIONS]
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
			Mode.SPELLBOOK:
				mode = Mode.SPELLBOOK
				spellbook_index = SPELL_ORDER.find(active_spell)
			Mode.WORLDMAP:
				mode = Mode.WORLDMAP
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
	if targeting:
		if key == KEY_ESCAPE or key_is("spell", key):
			_cancel_targeting()
			_refresh()
		return
	if _shot_in_flight():
		return   # a shot is in flight; wait for it to land
	if key_is("character", key):
		mode = Mode.INVENTORY
		ui_pane = 1
		ui_index = 0
		_refresh()
	elif key_is("journal", key):
		mode = Mode.JOURNAL
		_refresh()
	elif key_is("spellbook", key):
		mode = Mode.SPELLBOOK
		spellbook_index = SPELL_ORDER.find(active_spell)
		_refresh()
	elif key_is("map", key):
		mode = Mode.WORLDMAP
		_refresh()
	elif key_is("log", key):
		_open_log()
	elif key_is("spell", key):
		_begin_targeting()
	elif key_is("wait", key):
		_end_turn()
	elif key_is("options", key) or key == KEY_ESCAPE:
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
	# clicking outside the sheet closes it, like Esc
	if not Rect2(px, py, w, h).has_point(mp):
		_close_panel()
		return
	var top := py + 60.0
	for i in SLOT_NAMES.size():
		if Rect2(px + 10, top + i * 23.0 - 15.0, 320, 21).has_point(mp):
			ui_pane = 0
			ui_index = i
			_activate_selection()
			return
	var entries := backpack_entries()
	var item_i := 0
	for i in entries.size():
		if entries[i]["kind"] == "header":
			continue
		if Rect2(px + 504, top + i * 16.0 - 12.0, 456, 15).has_point(mp):
			ui_pane = 1
			ui_index = item_i
			_activate_selection()
			return
		item_i += 1

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
			elif it.has("heal") or it.has("mana_heal") or it.has("portal"):
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
		var stock: Array = vendor_def(current_shop)["stock"]
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
	var vd: Dictionary = vendor_def(current_shop)
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
	# clicking outside the shop closes it, like Esc
	if not Rect2(px, py, SHOP_W, h).has_point(mp):
		current_shop = -1
		_close_panel()
		return
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
	_sfx("coin")
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
	_sfx("coin")
	bb.remove_at(idx)
	_log("You buy back the %s for %d coins." % [ITEMS[id]["name"], e["price"]])


# ---------------------------------------------------------
#  World map (M). Node positions are derived from the MAP_DEFS
#  links, so new regions and dungeon levels lay themselves out.
# ---------------------------------------------------------
const WORLD_LINK_DIRS := {
	"north": Vector2(0, -1), "south": Vector2(0, 1),
	"east": Vector2(1, 0), "west": Vector2(-1, 0),
	"down": Vector2(1.25, 0.55), "up": Vector2(-1.25, -0.55),
}

# id -> abstract grid position, BFS from town.
func world_layout() -> Dictionary:
	var pos := { "town": Vector2.ZERO }
	var queue := ["town"]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		var def: Dictionary = MAP_DEFS[id]
		for link in WORLD_LINK_DIRS:
			if def.has(link) and not pos.has(def[link]):
				pos[def[link]] = pos[id] + WORLD_LINK_DIRS[link]
				queue.append(def[link])
	return pos


# ---------------------------------------------------------
#  Magic. 5 (or middle mouse) aims the active spell; a click on
#  a tile casts it. While aiming, the OS cursor is hidden and
#  the HUD draws the spell icon in its place; Esc or right
#  click cancels. For now spells only hit monsters; interacting
#  with the environment is planned for later.
# ---------------------------------------------------------
func _begin_targeting() -> void:
	var sp: Dictionary = SPELLS[active_spell]
	if player_mana < sp["mana"]:
		_log("Not enough mana. (%s needs %d)" % [sp["name"], sp["mana"]])
		_refresh()
		return
	targeting = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_log("Aiming %s. Click a tile; Esc or right click cancels." % sp["name"])
	_refresh()

func _cancel_targeting() -> void:
	targeting = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# A click while aiming: clicks on the HUD bar are ignored.
func _try_fire_click(mp: Vector2) -> void:
	if mp.y >= get_viewport_rect().size.y - BAR_H:
		return
	_fire_at(screen_to_tile(mp))

func screen_to_tile(mp: Vector2) -> Vector2i:
	var topleft := camera.get_screen_center_position() - get_viewport_rect().size * 0.5
	return Vector2i(((mp + topleft) / TILE).floor())

func target_in_range(tile: Vector2i) -> bool:
	var d: int = max(abs(tile.x - player_pos.x), abs(tile.y - player_pos.y))
	return d > 0 and d <= SPELLS[active_spell]["range"] and _in_bounds(tile)

# In range AND with a clear flight path (trees and walls block spells).
func can_target(tile: Vector2i) -> bool:
	return target_in_range(tile) and los_blocker(player_pos, tile).x < 0

func _fire_at(tile: Vector2i) -> void:
	if not target_in_range(tile):
		_log("Out of range.")
		_refresh()
		return
	if los_blocker(player_pos, tile).x >= 0:
		_log("No clear line of fire.")
		_refresh()
		return
	var sp: Dictionary = SPELLS[active_spell]
	player_mana -= sp["mana"]
	_cancel_targeting()
	_sfx("cast")
	_spawn_projectile(active_spell, player_pos, tile, true, sp["dmg"] + player_spell_dmg)
	_refresh()

func _spawn_projectile(kind: String, from_tile: Vector2i, to_tile: Vector2i, is_player: bool, dmg: int = 0) -> void:
	var from := Vector2(from_tile) * TILE + Vector2(TILE, TILE) * 0.5
	var to := Vector2(to_tile) * TILE + Vector2(TILE, TILE) * 0.5
	projectiles.append({
		"kind": kind, "from": from, "to": to, "t": 0.0, "player": is_player,
		"target": to_tile, "dmg": dmg,
		"dur": max(from.distance_to(to) / 700.0, 0.12),
	})

func _shot_in_flight() -> bool:
	for p in projectiles:
		if p["player"]:
			return true
	return false

func _advance_projectiles(delta: float) -> void:
	queue_redraw()
	for i in range(projectiles.size() - 1, -1, -1):
		var p: Dictionary = projectiles[i]
		p["t"] += delta / p["dur"]
		if p["t"] < 1.0:
			continue
		projectiles.remove_at(i)
		if not p["player"]:
			continue   # hostile shots are visual; their damage already landed
		var kind: String = p["kind"]
		var verb: String = {
			"dart": "The magic dart hits", "arrow": "The bone arrow pierces",
			"boulder": "The fireball engulfs",
		}[kind]
		# Blast spells damage every mob within their radius of the
		# impact tile; single-target spells have radius 0. Iterate
		# backwards: kills remove mobs from the array.
		var radius: int = SPELLS[kind].get("aoe", 0)
		var target: Vector2i = p["target"]
		var hit_any := false
		for m in range(mobs.size() - 1, -1, -1):
			var mp: Vector2i = mobs[m]["pos"]
			if max(abs(mp.x - target.x), abs(mp.y - target.y)) <= radius:
				hit_any = true
				_damage_mob(m, p["dmg"], verb)
		if not hit_any:
			_log("The %s hits nothing." % SPELLS[kind]["name"].to_lower())
		_end_turn()

# Draws a projectile icon pointing along +x, rotated by `angle`.
# Reused for the flying shot, the aiming cursor, the spellbook and
# the active-spell indicator in the bar.
func draw_projectile_icon(ci: CanvasItem, kind: String, pos: Vector2, angle: float, s: float = 1.0) -> void:
	ci.draw_set_transform(pos, angle, Vector2(s, s))
	match kind:
		"arrow":   # bone arrow: a pale shaft with a bone-white head
			ci.draw_line(Vector2(-9, 0), Vector2(6, 0), Color(0.88, 0.86, 0.74), 2.0)
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(11, 0), Vector2(5, -3.5), Vector2(5, 3.5)]), Color(0.96, 0.95, 0.88))
			ci.draw_line(Vector2(-9, 0), Vector2(-12, -3), Color(0.70, 0.68, 0.58), 1.5)
			ci.draw_line(Vector2(-9, 0), Vector2(-12, 3), Color(0.70, 0.68, 0.58), 1.5)
		"dart":
			ci.draw_circle(Vector2(-8, 0), 2.0, Color(0.45, 0.55, 0.95, 0.35))
			ci.draw_circle(Vector2(-4, 0), 2.6, Color(0.55, 0.65, 1.0, 0.6))
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(9, 0), Vector2(0, -3), Vector2(-2, 0), Vector2(0, 3)]),
				Color(0.72, 0.80, 1.0))
			ci.draw_circle(Vector2(2, 0), 2.2, Color(0.95, 0.97, 1.0))
		"boulder":
			ci.draw_circle(Vector2(-9, 0), 3.0, Color(0.95, 0.75, 0.20, 0.45))
			ci.draw_circle(Vector2(-5, 0), 4.0, Color(0.95, 0.55, 0.15, 0.7))
			ci.draw_circle(Vector2(2, 0), 6.0, Color(0.45, 0.30, 0.22))
			ci.draw_circle(Vector2(2, 0), 6.0, Color(0.95, 0.45, 0.10), false, 1.6)
			ci.draw_circle(Vector2(4, -2), 1.8, Color(0.30, 0.18, 0.14))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------
#  Spellbook (P): pick the active spell.
# ---------------------------------------------------------
const SPB_W := 540.0
const SPB_TOP := 56.0
const SPB_ROW_H := 54.0

func _spellbook_input(key: int) -> void:
	if key == KEY_ESCAPE or key_is("spellbook", key):
		_close_panel()
		return
	match key:
		KEY_UP, KEY_W:
			spellbook_index = max(spellbook_index - 1, 0)
			_refresh()
		KEY_DOWN, KEY_S:
			spellbook_index = min(spellbook_index + 1, SPELL_ORDER.size() - 1)
			_refresh()
		KEY_ENTER, KEY_KP_ENTER:
			_set_active_spell(SPELL_ORDER[spellbook_index])

# Geometry mirrors _draw_panel_spellbook in hud.gd via the SPB_* consts.
func _spellbook_click(mp: Vector2) -> void:
	var vs := get_viewport_rect().size
	var h := 96.0 + SPELL_ORDER.size() * SPB_ROW_H
	var px := (vs.x - SPB_W) * 0.5
	var py := (vs.y - BAR_H - h) * 0.5
	# clicking outside the spellbook closes it, like Esc
	if not Rect2(px, py, SPB_W, h).has_point(mp):
		_close_panel()
		return
	for i in SPELL_ORDER.size():
		if Rect2(px + 8, py + SPB_TOP + i * SPB_ROW_H, SPB_W - 16.0, SPB_ROW_H - 6.0).has_point(mp):
			spellbook_index = i
			_set_active_spell(SPELL_ORDER[i])
			return

func _set_active_spell(id: String) -> void:
	active_spell = id
	_log("Active spell: %s. Cast it with %s or the middle mouse button."
			% [SPELLS[id]["name"], spell_key_label()])
	_refresh()


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
	elif tile == "B":
		_log("The gate is boarded shut. Whatever Dolm began, it is not yet finished.")
		_refresh()
		return
	elif tile == "G":
		if town_burned:
			_log("The fortress gate stands unburned amid the ashes. Stone remembers its orders.")
			_log("Beyond it, the road hangs in pieces over empty air. Nothing crosses that lacks wings or sorcery.")
		else:
			_log("The old east gate, sealed for a hundred years. Behind it climbed the road to the Grey Fortress -")
			_log("broken now: shattered spans over empty air, crossed by nothing that cannot fly or work magic.")
		_refresh()
		return
	elif _is_walkable(target):
		player_pos = target
		_pickup_items()
		if town_burned and current_map == "town" and player_pos == DOLM_BODY:
			_visit_dolm_body()
		if not portal.is_empty() and current_map == portal["home"] and player_pos == portal["home_pos"]:
			_travel_portal()
			return
		if _check_transition():
			return
	else:
		_refresh()
		return

	_end_turn()

func _attack_mob(index: int) -> void:
	_damage_mob(index, player_dmg, "You hit")

func _damage_mob(index: int, dmg: int, verb: String) -> void:
	var mob = mobs[index]
	var t: Dictionary = MOB_TYPES[mob["type"]]
	mob["hp"] -= dmg
	# Pain is remembered: a struck monster turns hostile, pursuing
	# the player even from beyond its sight range (and keeping the
	# combat music burning). Announced once, when the anger is news.
	if mob["hp"] > 0 and not mob.get("angry", false):
		mob["angry"] = true
		var mdist: int = abs(mob["pos"].x - player_pos.x) + abs(mob["pos"].y - player_pos.y)
		if mdist > t["sight"]:
			_log("The %s snaps around, enraged, and comes for you!" % t["name"])
	if mob["hp"] <= 0:
		var mpos: Vector2i = mob["pos"]
		mobs.remove_at(index)
		var drop := randi_range(t["coins"][0], t["coins"][1])
		coins += drop
		_sfx("kill")
		_log("You slay the %s! +%d coins." % [t["name"], drop])
		# rare drops: the fallen sometimes leave something behind
		var roll := randf()
		if roll < 0.03:
			ground_items.append({ "pos": mpos, "id": "tpscroll" })
			_log("The %s dropped a Scroll of Town Portal!" % t["name"])
		elif roll < 0.09:
			ground_items.append({ "pos": mpos, "id": "potion" })
			_log("The %s dropped a Healing Potion!" % t["name"])
		_count_kill(mob["type"])
		_gain_xp(t["xp"])
	else:
		_sfx("hit")
		_log("%s the %s for %d. (%d HP left)" % [verb, t["name"], dmg, mob["hp"]])

func _pray() -> void:
	if player_hp < player_max_hp or player_mana < player_max_mana:
		player_hp = player_max_hp
		player_mana = player_max_mana
		_sfx("quest")
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
			_sfx("pickup")
			_log("You found the %s!" % ITEMS[id]["name"])
			_gain_xp(10)
			if id == "parchment" and not parchment_found:
				# the moment the story turns: the seal breaks
				parchment_found = true
				flash_alpha = 1.0
				thunder_player.play()
				_log("The wax seal splinters in your hand. The runes flare -")
				_log("- and far above, something answers with a sound like thunder.")

func _check_transition() -> bool:
	var tile: String = grid[player_pos.y][player_pos.x]
	var def: Dictionary = MAP_DEFS[current_map]
	if tile == "^" and def.has("north"):
		_load_map(def["north"], "south_gate")
		_log("You travel north to the %s." % map_name(current_map))
	elif tile == "v" and def.has("south"):
		_load_map(def["south"], "north_gate")
		_log("You head south to %s." % map_name(current_map))
	elif tile == "<" and def.has("west"):
		_load_map(def["west"], "east_gate")
		_log("After days of journey west, you arrive at %s." % map_name(current_map))
	elif tile == ">" and def.has("east"):
		_load_map(def["east"], "west_gate")
		_log("After days of journey east, you return to %s." % map_name(current_map))
	elif tile == "O" and def.has("down"):
		_load_map(def["down"], "descend")
		_sfx("stairs")
		_log("You descend the sunken stairway into the %s." % map_name(current_map))
	elif tile == "U" and def.has("up"):
		_load_map(def["up"], "ascend")
		_sfx("stairs")
		_log("You climb back up to the %s." % map_name(current_map))
	else:
		return false
	_refresh()
	return true

func _end_turn() -> void:
	move_count += 1
	if move_count % 6 == 0 and player_mana < player_max_mana:
		player_mana += 1   # slow natural mana regeneration
	_mob_turn()
	_update_music()
	_refresh()

func _player_died() -> bool:
	if player_hp > 0:
		return false
	game_over = true
	run_end_text = Time.get_datetime_string_from_system(false, true)
	_sfx("death")
	_log("You died. Press Enter to restart.")
	return true


# ---------------------------------------------------------
#  Vendors, shops, quests
# ---------------------------------------------------------
func _talk_to_vendor(index: int) -> void:
	var v = vendors[index]
	var gidx: int = v["set_idx"]
	if v.get("set", "town") == "west":
		gidx += VENDORS.size()   # Westmere vendors follow the town's
	var data: Dictionary = vendor_def(gidx)
	var q: Dictionary = quests[gidx % quests.size()]

	if q["state"] == "hidden":
		q["state"] = "active"
		_log("%s: \"%s\"" % [data["name"], q["intro"]])
		_log("New quest: %s. Press J for the journal." % q["desc"])
	elif q["state"] == "active" and _quest_fulfilled(q):
		_complete_quest(q)
		_refresh()
		return
	else:
		# refugees speak of the fire, not of business as usual
		var greet: String = data["greet"]
		if town_burned and data.has("greet_burned"):
			greet = data["greet_burned"]
		_log(greet)

	current_shop = gidx
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
	_sfx("quest")
	_log("Quest complete: %s! Reward: %s." % [q["desc"], ", ".join(reward_bits)])
	if q.has("outro"):
		_log(q["outro"])
	_gain_xp(q["reward_xp"])
	if q.get("target", "") == "parchment":
		_open_fortress_road()
	_check_victory()

# The road to the Northern Reaches (and, one day, the Fortress):
# Westmere's boarded north gate opens once Dolm's quest is done.
func fortress_road_open() -> bool:
	return not quests.is_empty() and quests[3]["state"] == "done"

# If Westmere is already generated, swap its boards for a real gate.
# (When it generates later, fortress_road_open() handles it.)
func _open_fortress_road() -> void:
	if not map_state.has("west"):
		return
	var st: Dictionary = map_state["west"]
	if st["north_gate"].x >= 0:
		return
	var g: Array = st["grid"]
	var road_gx: int = g[0].size() / 2
	g[0][road_gx] = "^"
	g[0][road_gx + 1] = "^"
	st["north_gate"] = Vector2i(road_gx, 0)

# Dolm did not make it out of the fire. His body lies where his shop
# stood; walking over it delivers the parchment - the reward waits in
# his strongbox, and his last note carries the reveal. Once the quest
# is done, a cairn marks the spot.
const DOLM_BODY := Vector2i(30, 15)

func _visit_dolm_body() -> void:
	var q: Dictionary = quests[3]
	if q["state"] == "done":
		return
	if q["state"] == "hidden":
		q["state"] = "active"   # you understand, now, what he wanted
	if _quest_fulfilled(q):
		_log("Dolm lies where his shop stood, shielding his strongbox to the last.")
		_complete_quest(q)
		_log("In his hand, a note: 'It is a page of the Covenant that sealed the Fortress.'")
		_log("'We broke it, and the price was mine. Beyond Westmere's boarded gate - end what we began.'")
		_log("You pile stones over Dolm the trader. The road west through Westmere is open.")
	else:
		_log("Dolm the trader lies among the ashes. Whatever he sought, it cost him everything.")

func _check_victory() -> void:
	for q in quests:
		if q["state"] != "done":
			return
	victory_banner = true
	victory_moves = move_count
	_sfx("levelup")
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
	_sfx("coin")
	if item.has("slot"):
		_log("You buy a %s. Equip it from the inventory (I)." % item["name"])
	else:
		_log("You buy a %s." % item["name"])
	_refresh()

func _use_item(id: String) -> void:
	var item: Dictionary = ITEMS[id]
	if item.has("heal"):
		if player_hp >= player_max_hp:
			_log("You are already at full health.")
		else:
			_remove_item(id)
			_sfx("drink")
			player_hp = min(player_hp + item["heal"], player_max_hp)
			_log("You use the %s. (+%d HP, now %d/%d)" % [item["name"], item["heal"], player_hp, player_max_hp])
	elif item.has("mana_heal"):
		if player_mana >= player_max_mana:
			_log("Your mana is already full.")
		else:
			_remove_item(id)
			_sfx("drink")
			player_mana = min(player_mana + item["mana_heal"], player_max_mana)
			_log("You drink the %s. (+%d mana, now %d/%d)" % [item["name"], item["mana_heal"], player_mana, player_max_mana])
	elif item.has("portal"):
		_cast_town_portal(id)
	else:
		_log("The %s cannot be used." % item["name"])
	_refresh()


# ---------------------------------------------------------
#  Town portal (a la Diablo): using a scroll teleports you home
#  at once and leaves a shimmering portal there; stepping into
#  it returns you to the very tile you cast from, then it
#  closes. One round trip per scroll.
# ---------------------------------------------------------
func portal_home() -> String:
	return "west" if town_burned else "town"

func _cast_town_portal(id: String) -> void:
	var home := portal_home()
	if current_map == home:
		_log("You are already home. The scroll stays in your pack.")
		return
	_remove_item(id)
	if not portal.is_empty():
		_log("Your old portal winks shut.")
	portal = { "map": current_map, "pos": player_pos, "home": home }
	_sfx("cast")
	_load_map(home, "spawn")
	portal["home_pos"] = map_state[home]["spawn"] + Vector2i(2, 0)
	_log("The scroll burns away, and the world folds: you are home.")
	_log("A shimmering portal waits to carry you back.")
	if mode != Mode.PLAY:
		_close_panel()

func _travel_portal() -> void:
	var dest: String = portal["map"]
	player_pos = portal["pos"]
	portal = {}
	_sfx("stairs")
	_load_map(dest, "keep")
	_log("The portal folds shut behind you.")
	_refresh()

# ---- backpack categories: no more potions rubbing elbows with
# swords. Weapons, Armour, Consumables, Quest Items - in that order.
const ITEM_CATEGORIES := ["Weapons", "Armour", "Consumables", "Quest Items"]

func item_category(id: String) -> int:
	var it: Dictionary = ITEMS[id]
	if it.get("quest", false):
		return 3
	if it.has("slot"):
		return 0 if (it.has("dmg") or it.has("spell_dmg")) else 1
	return 2   # heal, mana and portal scrolls

# Backpack ids grouped by category, alphabetical inside each. Shop
# sell lists inherit the same order.
func inventory_list() -> Array:
	var keys := inventory.keys()
	keys.sort_custom(func(a, b):
		var ca := item_category(a)
		var cb := item_category(b)
		if ca != cb:
			return ca < cb
		return ITEMS[a]["name"] < ITEMS[b]["name"])
	return keys

# The backpack as one flat list of rows: category headers with their
# items beneath. hud.gd draws this list and _char_sheet_click
# hit-tests the same rows, so the two can never drift apart.
func backpack_entries() -> Array:
	var entries := []
	var last := -1
	for id in inventory_list():
		var cat := item_category(id)
		if cat != last:
			last = cat
			entries.append({ "kind": "header", "text": ITEM_CATEGORIES[cat] })
		entries.append({ "kind": "item", "id": id })
	return entries

func inv_capacity() -> int:
	var cap := BASE_INV_SLOTS
	if equipment.has(19):
		var bag_item: Dictionary = ITEMS[equipment[19]]
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
	player_spell_dmg = 0
	var bonus_hp := 0
	var bonus_mana := 0
	for slot in equipment:
		var it: Dictionary = ITEMS[equipment[slot]]
		player_dmg += it.get("dmg", 0)
		player_spell_dmg += it.get("spell_dmg", 0)
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
	if slot == 10 and equipment.has(10) and not equipment.has(11):
		slot = 11
	elif slot == 12 and equipment.has(12) and not equipment.has(13):
		slot = 13
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
	var cap_after := BASE_INV_SLOTS if slot == 19 else inv_capacity()
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
		_sfx("levelup")
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
#  Title screen menu. Geometry is shared with hud.gd via
#  title_menu_rects().
# ---------------------------------------------------------
const TITLE_MENU := ["New Game", "Continue", "Quit"]

func title_menu_rects() -> Array:
	var vs := get_viewport_rect().size
	var rects := []
	for i in TITLE_MENU.size():
		rects.append(Rect2(vs.x * 0.5 - 120.0, vs.y * 0.74 + i * 44.0, 240.0, 36.0))
	return rects

# Row geometry of the load-game slot picker, shared with hud.gd.
func title_slot_rects() -> Array:
	var vs := get_viewport_rect().size
	var rects := []
	for i in SAVE_SLOTS:
		rects.append(Rect2(vs.x * 0.5 - 270.0, vs.y * 0.26 + i * 40.0, 540.0, 34.0))
	return rects

func _title_input(key: int) -> void:
	if title_screen == "load":
		match key:
			KEY_ESCAPE:
				title_screen = "main"
				_refresh()
			KEY_UP, KEY_W:
				title_index = max(title_index - 1, 0)
				_refresh()
			KEY_DOWN, KEY_S:
				title_index = min(title_index + 1, SAVE_SLOTS - 1)
				_refresh()
			KEY_ENTER, KEY_KP_ENTER:
				if save_slot_cache[title_index]["exists"]:
					_load_game(title_index + 1)
		return
	match key:
		KEY_UP, KEY_W:
			title_index = max(title_index - 1, 0)
			_refresh()
		KEY_DOWN, KEY_S:
			title_index = min(title_index + 1, TITLE_MENU.size() - 1)
			_refresh()
		KEY_ENTER, KEY_KP_ENTER:
			_title_activate(title_index)

func _title_click(mp: Vector2) -> void:
	if title_screen == "load":
		var rects := title_slot_rects()
		for i in rects.size():
			if (rects[i] as Rect2).has_point(mp):
				title_index = i
				if save_slot_cache[i]["exists"]:
					_load_game(i + 1)
				else:
					_refresh()
				return
		return
	var rects := title_menu_rects()
	for i in rects.size():
		if (rects[i] as Rect2).has_point(mp):
			title_index = i
			_title_activate(i)
			return

func _title_activate(i: int) -> void:
	match i:
		0:
			_start(true)
		1:
			if has_save():
				title_screen = "load"
				title_index = 0
				_refresh_slot_cache()
				_refresh()
		2:
			get_tree().quit()


# ---------------------------------------------------------
#  Save / load. The world regenerates deterministically, so a
#  save only stores the dynamic state: player, quests, message
#  history, and the surviving mobs / remaining ground items of
#  each visited map. Ten slots; the pre-slot save.json stands
#  in for slot 1 until something is saved over it.
# ---------------------------------------------------------
const SAVE_SLOTS := 10

var save_slot_cache := []   # [{exists, label}] rebuilt when a picker opens

func _slot_path(slot: int) -> String:
	return "user://save%d.json" % slot

# The file to READ for a slot (the numbered file, or the legacy
# single save standing in for slot 1); "" when the slot is empty.
func _slot_read_path(slot: int) -> String:
	if FileAccess.file_exists(_slot_path(slot)):
		return _slot_path(slot)
	if slot == 1 and FileAccess.file_exists("user://save.json"):
		return "user://save.json"
	return ""

func has_save() -> bool:
	for i in range(1, SAVE_SLOTS + 1):
		if _slot_read_path(i) != "":
			return true
	return false

# One line per slot for the pickers: level, place, save time.
func _refresh_slot_cache() -> void:
	save_slot_cache = []
	for i in range(1, SAVE_SLOTS + 1):
		var entry := { "exists": false, "label": "- empty -" }
		var path := _slot_read_path(i)
		if path != "":
			entry["exists"] = true
			entry["label"] = "a save"
			var f := FileAccess.open(path, FileAccess.READ)
			if f != null:
				var data = JSON.parse_string(f.get_as_text())
				f.close()
				if typeof(data) == TYPE_DICTIONARY:
					var mapid: String = data.get("current_map", "town")
					var mname: String = MAP_DEFS[mapid]["name"] if MAP_DEFS.has(mapid) else "?"
					if mapid == "town" and data.get("town_burned", false):
						mname = "Ruins of Grey Fortress"
					entry["label"] = "Lv %d  -  %s  -  %s" % [int(data.get("player_level", 1)),
							mname, str(data.get("saved_at", "an older save"))]
		save_slot_cache.append(entry)

func _save_game(slot: int) -> void:
	var maps := {}
	for id in map_state:
		var st: Dictionary = map_state[id]
		var ms := []
		for m in st["mobs"]:
			ms.append({ "x": m["pos"].x, "y": m["pos"].y, "hp": m["hp"], "type": m["type"],
					"angry": m.get("angry", false) })
		var its := []
		for it in st["items"]:
			its.append({ "x": it["pos"].x, "y": it["pos"].y, "id": it["id"] })
		maps[id] = { "mobs": ms, "items": its }
		# fog of war, one "01110..." string per row (villages have none)
		if not MAP_DEFS[id].get("no_fog", false):
			var ex := []
			for row in st["explored"]:
				var s := ""
				for v in row:
					s += "1" if v == 1 else "0"
				ex.append(s)
			maps[id]["explored"] = ex
	var equip := {}
	for eq_slot in equipment:
		equip[str(eq_slot)] = equipment[eq_slot]
	var qs := []
	for q in quests:
		qs.append({ "state": q["state"], "progress": q["progress"] })
	var portal_data := {}
	if not portal.is_empty():
		portal_data = { "map": portal["map"], "x": portal["pos"].x, "y": portal["pos"].y,
				"home": portal["home"], "hx": portal["home_pos"].x, "hy": portal["home_pos"].y }
	var data := {
		"version": 3,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"base_max_hp": base_max_hp, "base_dmg": base_dmg, "base_max_mana": base_max_mana,
		"player_level": player_level, "player_xp": player_xp,
		"player_hp": player_hp, "player_mana": player_mana,
		"coins": coins, "inventory": inventory, "equipment": equip,
		"quests": qs, "buyback": buyback,
		"current_map": current_map, "px": player_pos.x, "py": player_pos.y,
		"move_count": move_count, "run_start_text": run_start_text,
		"active_spell": active_spell,
		"parchment_found": parchment_found, "town_burned": town_burned,
		"portal": portal_data,
		"log": messages,
		"visited": visited.keys(), "maps": maps,
	}
	var f := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	_log("Game saved to slot %d." % slot)

func _load_game(slot: int) -> void:
	var path := _slot_read_path(slot)
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		_log("The save file could not be read.")
		return
	_start()   # clean slate: quests rebuilt, town generated
	base_max_hp = int(data["base_max_hp"])
	base_dmg = int(data["base_dmg"])
	base_max_mana = int(data["base_max_mana"])
	player_level = int(data["player_level"])
	player_xp = int(data["player_xp"])
	coins = int(data["coins"])
	move_count = int(data["move_count"])
	run_start_text = data["run_start_text"]
	active_spell = data.get("active_spell", "dart")
	# Unknown item ids (e.g. from saves made before an item was
	# removed from the game) are silently dropped.
	inventory = {}
	for id in data["inventory"]:
		if ITEMS.has(id):
			inventory[id] = int(data["inventory"][id])
	# Equipment slots are re-derived from each item's own definition
	# rather than trusted from the file, so saves survive any
	# renumbering of SLOT_NAMES (e.g. the removal of the Ammo slot).
	equipment = {}
	for eq_slot in data["equipment"]:
		var eq_id: String = data["equipment"][eq_slot]
		if not ITEMS.has(eq_id):
			continue
		var s: int = ITEMS[eq_id]["slot"]
		if s == 10 and equipment.has(10) and not equipment.has(11):
			s = 11   # second ring
		elif s == 12 and equipment.has(12) and not equipment.has(13):
			s = 13   # second trinket
		if equipment.has(s):
			_add_item(eq_id)   # no slot left: back into the pack
		else:
			equipment[s] = eq_id
	for i in mini(quests.size(), data["quests"].size()):
		quests[i]["state"] = data["quests"][i]["state"]
		quests[i]["progress"] = int(data["quests"][i]["progress"])
	# Story flags come before map regeneration: the town generates
	# burned or whole depending on them. Saves from the relic era
	# (before the parchment) had the west unlocked by Dolm's quest,
	# which in the new story means the burning already happened.
	parchment_found = data.get("parchment_found", false)
	town_burned = data.get("town_burned", false)
	if not town_burned and quests[3]["state"] == "done":
		parchment_found = true
		town_burned = true
	buyback = {}
	for key in data["buyback"]:
		var bb := []
		for e in data["buyback"][key]:
			if ITEMS.has(e["id"]):
				bb.append({ "id": e["id"], "price": int(e["price"]) })
		buyback[int(key)] = bb
	visited = {}
	for id in data["visited"]:
		visited[id] = true
	# regenerate each visited map, then overwrite its dynamic state
	map_state = {}
	for id in data["maps"]:
		map_state[id] = _generate_map(id)
		var st: Dictionary = map_state[id]
		var ms := []
		for m in data["maps"][id]["mobs"]:
			ms.append({ "pos": Vector2i(int(m["x"]), int(m["y"])), "hp": int(m["hp"]),
					"type": m["type"], "angry": bool(m.get("angry", false)) })
		st["mobs"] = ms
		var its := []
		for it in data["maps"][id]["items"]:
			if ITEMS.has(it["id"]):
				its.append({ "pos": Vector2i(int(it["x"]), int(it["y"])), "id": it["id"] })
		st["items"] = its
		# restore the fog of war (older saves simply re-explore)
		if data["maps"][id].has("explored"):
			var expl: Array = st["explored"]
			var rows: Array = data["maps"][id]["explored"]
			for y in mini(rows.size(), expl.size()):
				var s: String = rows[y]
				var row: Array = expl[y]
				for x in mini(s.length(), row.size()):
					if s[x] == "1":
						row[x] = 1
	portal = {}
	var pd: Dictionary = data.get("portal", {})
	if not pd.is_empty() and MAP_DEFS.has(pd.get("map", "")):
		portal = { "map": pd["map"], "pos": Vector2i(int(pd["x"]), int(pd["y"])),
				"home": pd["home"], "home_pos": Vector2i(int(pd["hx"]), int(pd["hy"])) }
	player_pos = Vector2i(int(data["px"]), int(data["py"]))
	_load_map(data["current_map"], "keep")
	_recalc_stats()
	player_hp = int(data["player_hp"])
	player_mana = int(data["player_mana"])
	# restore the message history the run had when it was saved
	messages = []
	for m in data.get("log", []):
		messages.append(str(m))
	_log("Game loaded. Welcome back.")
	_refresh()


# ---------------------------------------------------------
#  Options: sound (master volume), keybinds, graphics.
#  Settings persist to user://settings.cfg.
# ---------------------------------------------------------
const OPT_MAIN := ["Gameplay", "Graphics", "Sound", "Keybinds", "Save Game",
		"Load Game", "Restart", "Quit Game"]

# The Gameplay group: checkbox toggles, with room to grow.
const OPT_GAMEPLAY := [
	{ "key": "intro",   "label": "Intro story on new runs" },
	{ "key": "marks",   "label": "Quest markers over givers (! and ?)" },
	{ "key": "weather", "label": "Weather (rain and thunder)" },
	{ "key": "flashes", "label": "Screen flashes (lightning)" },
]

func _gameplay_get(key: String) -> bool:
	match key:
		"intro": return not skip_intro   # ticked means the intro shows
		"marks": return show_quest_marks
		"weather": return weather_enabled
		"flashes": return show_flashes
	return false

func _gameplay_toggle(key: String) -> void:
	match key:
		"intro":
			skip_intro = not skip_intro
		"marks":
			show_quest_marks = not show_quest_marks
		"weather":
			weather_enabled = not weather_enabled
			if not weather_enabled:
				_set_rain(false)
		"flashes":
			show_flashes = not show_flashes
			flash_alpha = 0.0
	_save_settings()

# One entry point for the main options rows, shared by keyboard and
# mouse so the two can never drift apart.
func _options_activate(entry: String) -> void:
	match entry:
		"Gameplay":
			options_screen = "gameplay"
			opt_index = 0
		"Graphics":
			options_screen = "graphics"
			opt_index = 0
		"Sound":
			options_screen = "sound"
			opt_index = 0
		"Keybinds":
			options_screen = "keybinds"
			opt_index = 0
		"Save Game":
			options_screen = "saves"
			opt_index = 0
			_refresh_slot_cache()
		"Load Game":
			options_screen = "loads"
			opt_index = 0
			_refresh_slot_cache()
		"Restart":
			options_screen = "confirm"
			opt_confirm = "restart"
			opt_index = 0
		"Quit Game":
			options_screen = "confirm"
			opt_confirm = "quit"
			opt_index = 0
	_refresh()

# Yes on the are-you-sure screen: back to the title, or leave the game.
func _confirm_yes() -> void:
	match opt_confirm:
		"quit":
			get_tree().quit()
		"restart":
			_show_title()

# The on-screen rectangle of the current options panel; sizes must
# match what hud.gd draws. A click outside it behaves like Esc.
func _options_panel_rect() -> Rect2:
	var vs := get_viewport_rect().size
	var w := 420.0
	var h := 340.0
	match options_screen:
		"gameplay":
			w = 460.0
			h = 108.0 + OPT_GAMEPLAY.size() * 30.0
		"graphics":
			h = 150.0
		"sound":
			h = 160.0
		"keybinds":
			w = 560.0
			h = 110.0 + REBIND_ACTIONS.size() * 26.0
		"saves", "loads":
			w = 560.0
			h = 108.0 + SAVE_SLOTS * 26.0
		"confirm":
			w = 460.0
			h = 200.0
	return Rect2((vs.x - w) * 0.5, (vs.y - BAR_H - h) * 0.5, w, h)
const REBIND_ACTIONS := ["up", "down", "left", "right",
		"up_left", "up_right", "down_left", "down_right",
		"wait", "character", "journal", "options",
		"spell", "spellbook", "map", "log"]
const REBIND_LABELS := ["Move up", "Move down", "Move left", "Move right",
		"Move up-left", "Move up-right", "Move down-left", "Move down-right",
		"Wait", "Character sheet", "Quest journal", "Options menu",
		"Cast spell", "Spellbook", "World map", "Message log"]

func _options_input(key: int) -> void:
	if opt_rebinding:
		if key != KEY_ESCAPE:
			keymap[REBIND_ACTIONS[opt_index]][opt_bind_slot] = key
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
				_options_activate(OPT_MAIN[opt_index])
				return
			elif key == KEY_ESCAPE:
				_close_panel()
				return
			_refresh()
		"gameplay":
			if key == KEY_UP:
				opt_index = max(opt_index - 1, 0)
			elif key == KEY_DOWN:
				opt_index = min(opt_index + 1, OPT_GAMEPLAY.size() - 1)
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				_gameplay_toggle(OPT_GAMEPLAY[opt_index]["key"])
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = OPT_MAIN.find("Gameplay")
			_refresh()
		"confirm":
			if key == KEY_UP or key == KEY_DOWN:
				opt_index = 1 - opt_index
				_refresh()
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				if opt_index == 1:
					_confirm_yes()
					return
				options_screen = "main"
				opt_index = OPT_MAIN.find("Restart" if opt_confirm == "restart" else "Quit Game")
				_refresh()
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = OPT_MAIN.find("Restart" if opt_confirm == "restart" else "Quit Game")
				_refresh()
		"graphics":
			if key == KEY_ENTER or key == KEY_KP_ENTER:
				_toggle_fullscreen()
				_save_settings()
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = OPT_MAIN.find("Graphics")
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
				opt_index = OPT_MAIN.find("Sound")
			_refresh()
		"keybinds":
			if key == KEY_UP:
				opt_index = max(opt_index - 1, 0)
			elif key == KEY_DOWN:
				opt_index = min(opt_index + 1, REBIND_ACTIONS.size() - 1)
			elif key == KEY_LEFT or key == KEY_RIGHT:
				opt_bind_slot = 1 - opt_bind_slot
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				opt_rebinding = true
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = OPT_MAIN.find("Keybinds")
			_refresh()
		"saves":
			if key == KEY_UP:
				opt_index = max(opt_index - 1, 0)
			elif key == KEY_DOWN:
				opt_index = min(opt_index + 1, SAVE_SLOTS - 1)
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				_save_game(opt_index + 1)
				_close_panel()
				return
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = OPT_MAIN.find("Save Game")
			_refresh()
		"loads":
			if key == KEY_UP:
				opt_index = max(opt_index - 1, 0)
			elif key == KEY_DOWN:
				opt_index = min(opt_index + 1, SAVE_SLOTS - 1)
			elif key == KEY_ENTER or key == KEY_KP_ENTER:
				if save_slot_cache[opt_index]["exists"]:
					_load_game(opt_index + 1)
				return
			elif key == KEY_ESCAPE:
				options_screen = "main"
				opt_index = OPT_MAIN.find("Load Game")
			_refresh()

# Click/tap handling for the options menu. Geometry here must mirror
# _draw_panel_options in hud.gd. is_press is true for the initial click/tap
# and false for a drag/motion update (used to slide the volume meter).
func _options_click(mp: Vector2, is_press: bool) -> void:
	var vs := get_viewport_rect().size
	# a click outside the current panel behaves exactly like Esc:
	# sub-screens step back, the main screen closes
	if is_press and not _options_panel_rect().has_point(mp):
		_options_input(KEY_ESCAPE)
		return
	match options_screen:
		"main":
			if not is_press:
				return
			var w := 420.0
			var h := 340.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in OPT_MAIN.size():
				var yy := py + 62 + i * 30
				if Rect2(px + 8, yy - 18, 404, 26).has_point(mp):
					opt_index = i
					_options_activate(OPT_MAIN[i])
					return
		"gameplay":
			if not is_press:
				return
			var w := 460.0
			var h := 108.0 + OPT_GAMEPLAY.size() * 30.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in OPT_GAMEPLAY.size():
				var yy := py + 62 + i * 30
				if Rect2(px + 8, yy - 18, 444, 26).has_point(mp):
					opt_index = i
					_gameplay_toggle(OPT_GAMEPLAY[i]["key"])
					_refresh()
					return
		"confirm":
			if not is_press:
				return
			var w := 460.0
			var h := 200.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in 2:
				var yy := py + 100 + i * 34
				if Rect2(px + 8, yy - 20, 444, 30).has_point(mp):
					if i == 1:
						_confirm_yes()
						return
					options_screen = "main"
					opt_index = OPT_MAIN.find("Restart" if opt_confirm == "restart" else "Quit Game")
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
			var w := 560.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in REBIND_ACTIONS.size():
				var yy := py + 62 + i * 26
				# one clickable cell per keybind slot
				for slot in 2:
					if Rect2(px + 240 + slot * 156, yy - 17, 148, 24).has_point(mp):
						opt_index = i
						opt_bind_slot = slot
						opt_rebinding = true
						_refresh()
						return
		"saves":
			if not is_press:
				return
			var h := 108.0 + SAVE_SLOTS * 26.0
			var w := 560.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in SAVE_SLOTS:
				var yy := py + 62 + i * 26
				if Rect2(px + 8, yy - 17, 544, 24).has_point(mp):
					_save_game(i + 1)
					_close_panel()
					return
		"loads":
			if not is_press:
				return
			var h := 108.0 + SAVE_SLOTS * 26.0
			var w := 560.0
			var px := (vs.x - w) * 0.5
			var py := (vs.y - BAR_H - h) * 0.5
			for i in SAVE_SLOTS:
				var yy := py + 62 + i * 26
				if Rect2(px + 8, yy - 17, 544, 24).has_point(mp):
					opt_index = i
					if save_slot_cache[i]["exists"]:
						_load_game(i + 1)
					else:
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
	cf.set_value("game", "skip_intro", skip_intro)
	cf.set_value("game", "quest_marks", show_quest_marks)
	cf.set_value("game", "weather", weather_enabled)
	cf.set_value("game", "flashes", show_flashes)
	for a in REBIND_ACTIONS:
		cf.set_value("keys", a, keymap[a])
	cf.save("user://settings.cfg")

func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://settings.cfg") != OK:
		return
	master_volume = cf.get_value("sound", "master", 1.0)
	skip_intro = cf.get_value("game", "skip_intro", false)
	show_quest_marks = cf.get_value("game", "quest_marks", true)
	weather_enabled = cf.get_value("game", "weather", true)
	show_flashes = cf.get_value("game", "flashes", true)
	for a in REBIND_ACTIONS:
		var v = cf.get_value("keys", a, keymap[a])
		if typeof(v) == TYPE_INT:
			# settings written before dual keybinds stored a single key
			keymap[a] = [v, keymap[a][1]]
		elif typeof(v) == TYPE_ARRAY and v.size() >= 2:
			keymap[a] = [int(v[0]), int(v[1])]
	if keymap["spell"] == [KEY_5, KEY_KP_5]:
		keymap["spell"] = [KEY_KP_5, KEY_NONE]   # old default; 5 was retired
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
	elif current_map == "town" and town_burned:
		_play_track("ruins")   # no more waltzes in the ashes
	else:
		_play_track(MAP_DEFS[current_map]["music"])

func _enemy_in_sight() -> bool:
	for mob in mobs:
		var t: Dictionary = MOB_TYPES[mob["type"]]
		var mp: Vector2i = mob["pos"]
		var d: int = abs(player_pos.x - mp.x) + abs(player_pos.y - mp.y)
		# angry mobs count too, out to the same distance where they
		# stop acting at all
		if d <= t["sight"] or (mob.get("angry", false) and d <= 40):
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
			_sfx("hurt")
			_log("The %s hits you for %d! (%d/%d HP)"
					% [t["name"], t["dmg"], max(player_hp, 0), player_max_hp])
			if _player_died():
				return
			continue

		# Far-away mobs stand still; saves work on a big map.
		if abs(diff.x) + abs(diff.y) > 40:
			continue

		# Ranged mobs shoot instead of moving when they see the player.
		# The damage lands now; the flying shot is a visual echo.
		if t.has("ranged"):
			var rd: Dictionary = t["ranged"]
			if max(abs(diff.x), abs(diff.y)) <= rd["range"] and los_blocker(mp, player_pos).x < 0:
				player_hp -= rd["dmg"]
				_sfx("hurt")
				_spawn_projectile(rd["kind"], mp, player_pos, false)
				_log("The %s %s you for %d! (%d/%d HP)"
						% [t["name"], rd["verb"], rd["dmg"], max(player_hp, 0), player_max_hp])
				if _player_died():
					return
				continue

		var step := Vector2i.ZERO
		if abs(diff.x) + abs(diff.y) <= t["sight"] or mob.get("angry", false):
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
	return grid[p.y][p.x] in [".", "D", "^", "v", "<", ">", "O", "U"]

# Tiles that stop a projectile's flight (trees, all kinds of walls,
# rubble, burnt trunks, tents, the sealed fortress gate).
const BLOCKS_FLIGHT := ["#", "T", "H", "S", "B", "R", "F", "E", "G"]

# First blocking tile strictly between `from` and `to` (Bresenham),
# or Vector2i(-1, -1) if the line is clear. The endpoints themselves
# never block.
func los_blocker(from: Vector2i, to: Vector2i) -> Vector2i:
	if from == to:
		return Vector2i(-1, -1)
	var d := (to - from).abs()
	var sx := 1 if to.x > from.x else -1
	var sy := 1 if to.y > from.y else -1
	var err := d.x - d.y
	var p := from
	while true:
		var e2 := 2 * err
		if e2 > -d.y:
			err -= d.y
			p.x += sx
		if e2 < d.x:
			err += d.x
			p.y += sy
		if p == to:
			return Vector2i(-1, -1)
		if _in_bounds(p) and grid[p.y][p.x] in BLOCKS_FLIGHT:
			return p
	return Vector2i(-1, -1)

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
#  Messages. The bar shows the tail; the full history lives in
#  the scrollable, searchable log panel (L).
# ---------------------------------------------------------
const LOG_KEEP := 1000  # how much history the log panel remembers

var log_scroll := 0     # lines scrolled up from the bottom
var log_search := ""    # live filter typed inside the log panel

func _log(text: String) -> void:
	messages.append(text)
	if messages.size() > LOG_KEEP:
		messages.pop_front()

func _open_log() -> void:
	mode = Mode.LOG
	log_scroll = 0
	log_search = ""
	_refresh()

# Esc (and right click) inside the log: clear the search first,
# close the panel second.
func _log_panel_escape() -> void:
	if log_search != "":
		log_search = ""
		log_scroll = 0
		_refresh()
	else:
		_close_panel()

# The log panel takes the whole keyboard: arrows and PgUp/PgDn
# scroll, Home/End jump, Backspace edits, and every printable key
# types into the search box (so W/S type rather than scroll).
func _log_panel_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_ESCAPE:
			_log_panel_escape()
			return
		KEY_UP:
			log_scroll += 1
		KEY_DOWN:
			log_scroll = max(log_scroll - 1, 0)
		KEY_PAGEUP:
			log_scroll += 10
		KEY_PAGEDOWN:
			log_scroll = max(log_scroll - 10, 0)
		KEY_HOME:
			log_scroll = 1 << 20   # the renderer clamps this to the top
		KEY_END:
			log_scroll = 0
		KEY_BACKSPACE:
			log_search = log_search.substr(0, max(log_search.length() - 1, 0))
			log_scroll = 0
		_:
			if event.unicode >= 32:
				log_search += char(event.unicode)
				log_scroll = 0
	_refresh()


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
	if not portal.is_empty() and current_map == portal["home"]:
		_draw_portal()
	if town_burned and current_map == "town" and view.has_point(DOLM_BODY):
		_draw_dolm_body()
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
	for pr in projectiles:
		var p: Vector2 = pr["from"].lerp(pr["to"], clampf(pr["t"], 0.0, 1.0))
		var ang: float = (pr["to"] - pr["from"]).angle()
		draw_projectile_icon(self, pr["kind"], p, ang, 1.2)

func _draw_tile(x: int, y: int) -> void:
	var c: String = grid[y][x]
	var pos := Vector2(x * TILE, y * TILE)
	var r := Rect2(pos, Vector2(TILE, TILE))
	var inner := Rect2(pos + Vector2(2, 2), Vector2(TILE - 4, TILE - 4))

	draw_rect(r, pal_floor)
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(TILE - 2, TILE - 2)), pal_floor_hi)

	match c:
		"#":
			draw_rect(r, pal_wall)
			draw_rect(inner, pal_wall_hi)
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
		"^", "v", "<", ">":
			draw_rect(inner, Color(0.42, 0.34, 0.22))
			var mid := pos + Vector2(TILE, TILE) * 0.5
			var pts: PackedVector2Array
			match c:
				"^":
					pts = PackedVector2Array([mid + Vector2(0, -9), mid + Vector2(8, 7), mid + Vector2(-8, 7)])
				"v":
					pts = PackedVector2Array([mid + Vector2(0, 9), mid + Vector2(8, -7), mid + Vector2(-8, -7)])
				"<":
					pts = PackedVector2Array([mid + Vector2(-9, 0), mid + Vector2(7, 8), mid + Vector2(7, -8)])
				">":
					pts = PackedVector2Array([mid + Vector2(9, 0), mid + Vector2(-7, 8), mid + Vector2(-7, -8)])
			draw_colored_polygon(pts, Color(0.85, 0.78, 0.55))
		"B":
			# boarded-up gate: dark timber with crossed planks
			draw_rect(inner, Color(0.30, 0.22, 0.12))
			draw_line(pos + Vector2(4, 6), pos + Vector2(TILE - 4, TILE - 6), Color(0.48, 0.36, 0.18), 3.0)
			draw_line(pos + Vector2(4, TILE - 6), pos + Vector2(TILE - 4, 6), Color(0.48, 0.36, 0.18), 3.0)
			draw_rect(Rect2(pos + Vector2(3, 13), Vector2(TILE - 6, 5)), Color(0.55, 0.42, 0.22))
		"G":
			# the sealed fortress gate: an aged stone arch, barred shut,
			# moss creeping up it; the broken fortress road lies beyond
			draw_rect(r, Color(0.30, 0.30, 0.36))
			draw_rect(inner, Color(0.38, 0.38, 0.45))
			draw_rect(Rect2(pos + Vector2(6, 12), Vector2(20, 18)), Color(0.10, 0.10, 0.14))
			draw_circle(pos + Vector2(16, 13), 10.0, Color(0.10, 0.10, 0.14))
			for i in 4:
				draw_line(pos + Vector2(8.5 + i * 5.0, 6), pos + Vector2(8.5 + i * 5.0, 30),
						Color(0.24, 0.24, 0.30), 2.0)
			draw_line(pos + Vector2(6, 19), pos + Vector2(26, 19), Color(0.24, 0.24, 0.30), 2.0)
			draw_circle(pos + Vector2(8, 27), 2.0, Color(0.25, 0.40, 0.22))
			draw_circle(pos + Vector2(25, 29), 1.6, Color(0.25, 0.40, 0.22))
		"R":
			# charred rubble: broken black walls, embers still winking
			draw_rect(inner, Color(0.11, 0.10, 0.10))
			draw_rect(Rect2(pos + Vector2(4, 15), Vector2(11, 9)), Color(0.17, 0.16, 0.15))
			draw_rect(Rect2(pos + Vector2(18, 7), Vector2(9, 13)), Color(0.15, 0.14, 0.13))
			draw_circle(pos + Vector2(9, 11), 1.2, Color(0.95, 0.45, 0.10, 0.8))
			draw_circle(pos + Vector2(23, 23), 1.0, Color(0.95, 0.30, 0.08, 0.6))
		"F":
			# burnt tree: a bare blackened trunk, branches like claws
			draw_rect(Rect2(pos + Vector2(14, 9), Vector2(4, 21)), Color(0.11, 0.09, 0.08))
			draw_line(pos + Vector2(16, 13), pos + Vector2(8, 5), Color(0.11, 0.09, 0.08), 2.2)
			draw_line(pos + Vector2(16, 15), pos + Vector2(24, 6), Color(0.11, 0.09, 0.08), 2.2)
			draw_line(pos + Vector2(12, 9), pos + Vector2(10, 12), Color(0.11, 0.09, 0.08), 1.4)
		"E":
			# refugee tent: canvas over a ridgepole, a dark opening
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(16, 4), pos + Vector2(29, 28), pos + Vector2(3, 28)]),
				Color(0.62, 0.54, 0.38))
			draw_line(pos + Vector2(16, 4), pos + Vector2(16, 28), Color(0.45, 0.38, 0.25), 1.5)
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(16, 14), pos + Vector2(21, 28), pos + Vector2(11, 28)]),
				Color(0.16, 0.13, 0.09))
		"O", "U":
			# stairways: shrinking steps into darkness (O, down) or
			# widening steps toward the light (U, up)
			draw_rect(inner, Color(0.06, 0.05, 0.08) if c == "O" else Color(0.30, 0.28, 0.34))
			for i in 4:
				var sw: float = TILE - 8.0 - i * 5.0
				var step_col := Color(0.42, 0.42, 0.48).darkened(i * 0.22) if c == "O" \
						else Color(0.30, 0.30, 0.36).lightened(i * 0.16)
				draw_rect(Rect2(pos + Vector2((TILE - sw) * 0.5, 5.0 + i * 6.0), Vector2(sw, 5.0)), step_col)

# WoW-style quest marks, drawn above quest givers: "!" means a quest
# waits here, "?" means it is ready to turn in.
func _draw_quest_mark(center: Vector2, mark: String) -> void:
	var w: float = font.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(font, center + Vector2(-w * 0.5 + 1, 7), mark,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0, 0, 0, 0.8))
	draw_string(font, center + Vector2(-w * 0.5, 6), mark,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1.0, 0.85, 0.15))

# Dolm's body in his burned shop (a cairn, once he is at peace).
func _draw_dolm_body() -> void:
	var c := Vector2(DOLM_BODY) * TILE + Vector2(TILE, TILE) * 0.5
	var q: Dictionary = quests[3]
	if q["state"] == "done":
		draw_circle(c + Vector2(-5, 4), 4.0, Color(0.42, 0.42, 0.48))
		draw_circle(c + Vector2(4, 4), 4.5, Color(0.38, 0.38, 0.44))
		draw_circle(c + Vector2(0, -1), 5.0, Color(0.46, 0.46, 0.52))
		draw_circle(c + Vector2(0, -6), 3.4, Color(0.52, 0.52, 0.58))
		return
	draw_circle(c + Vector2(2, 6), 8.0, Color(0.28, 0.10, 0.08, 0.5))
	draw_rect(Rect2(c + Vector2(-9, -2), Vector2(13, 6)), Color(0.35, 0.16, 0.14))
	draw_rect(Rect2(c + Vector2(2, -1), Vector2(7, 4)), Color(0.30, 0.34, 0.42))
	draw_circle(c + Vector2(-10, 1), 3.4, Color(0.76, 0.59, 0.46))
	draw_circle(c + Vector2(-1, 6), 2.2, Color(0.95, 0.82, 0.30))
	draw_circle(c + Vector2(3, 8), 1.8, Color(0.95, 0.82, 0.30))
	if show_quest_marks and inventory.get("parchment", 0) > 0:
		_draw_quest_mark(c + Vector2(0, -16), "?")

# The town portal: a swirling blue oval standing in the home village.
func _draw_portal() -> void:
	var c := Vector2(portal["home_pos"]) * TILE + Vector2(TILE, TILE) * 0.5
	var t := Time.get_ticks_msec() / 1000.0
	draw_set_transform(c, 0.0, Vector2(0.62, 1.0))
	draw_circle(Vector2.ZERO, 14.5, Color(0.25, 0.45, 0.95, 0.22))
	draw_circle(Vector2.ZERO, 11.0, Color(0.35, 0.60, 1.0, 0.50))
	draw_circle(Vector2.ZERO, 8.0, Color(0.70, 0.86, 1.0, 0.85))
	draw_circle(Vector2.ZERO, 4.5, Color(0.95, 0.99, 1.0))
	for i in 3:
		var a := t * 2.4 + i * TAU / 3.0
		draw_arc(Vector2.ZERO, 12.5, a, a + 1.6, 10, Color(0.55, 0.75, 1.0, 0.9), 1.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Every unique piece of world loot gets its own little icon, matching
# its description (the parchment's wax seal, the crown's prongs, a pair of
# boots...). A soft gold halo behind each keeps them easy to spot.
func _draw_ground_item(it: Dictionary) -> void:
	var mid := Vector2(it["pos"]) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(mid, 11.0, Color(1.0, 0.88, 0.35, 0.20))
	match it["id"]:
		"parchment":  # a rolled scroll, sealed with grey wax
			draw_rect(Rect2(mid + Vector2(-8, -5), Vector2(16, 10)), Color(0.87, 0.81, 0.63))
			draw_rect(Rect2(mid + Vector2(-8, -5), Vector2(2.5, 10)), Color(0.71, 0.64, 0.46))
			draw_rect(Rect2(mid + Vector2(5.5, -5), Vector2(2.5, 10)), Color(0.71, 0.64, 0.46))
			for i in 3:
				draw_line(mid + Vector2(-4, -2.4 + i * 2.4), mid + Vector2(3.5, -2.4 + i * 2.4),
						Color(0.44, 0.40, 0.32), 0.8)
			draw_circle(mid + Vector2(0, 5.5), 2.6, Color(0.46, 0.46, 0.52))
			draw_circle(mid + Vector2(0, 5.5), 1.1, Color(0.62, 0.62, 0.68))
		"crown":   # the Sunken Crown: gold band, three prongs, a red gem
			for px in [-5.0, 0.0, 5.0]:
				draw_colored_polygon(PackedVector2Array([
					mid + Vector2(px - 2.5, 1), mid + Vector2(px, -7),
					mid + Vector2(px + 2.5, 1)]), Color(0.92, 0.76, 0.22))
			for px in [-5.0, 0.0, 5.0]:
				draw_circle(mid + Vector2(px, -6), 1.2, Color(0.98, 0.90, 0.55))
			draw_rect(Rect2(mid + Vector2(-7.5, 1), Vector2(15, 5)), Color(0.92, 0.76, 0.22))
			draw_rect(Rect2(mid + Vector2(-7.5, 1), Vector2(15, 5)), Color(0.55, 0.42, 0.08), false, 1.0)
			draw_circle(mid + Vector2(0, 3.5), 1.7, Color(0.85, 0.18, 0.14))
		"runeblade":  # a pale blade with a glowing blue rune
			draw_line(mid + Vector2(-5, 6), mid + Vector2(6, -7), Color(0.72, 0.75, 0.85), 3.2)
			draw_line(mid + Vector2(6, -7), mid + Vector2(7.5, -8.8), Color(0.92, 0.94, 1.0), 2.0)
			draw_line(mid + Vector2(-7, 1.5), mid + Vector2(-1, 7.5), Color(0.42, 0.30, 0.13), 2.4)
			draw_line(mid + Vector2(-5, 6), mid + Vector2(-8.5, 9.5), Color(0.28, 0.20, 0.09), 2.6)
			draw_circle(mid + Vector2(0.5, -0.5), 2.4, Color(0.35, 0.65, 1.0, 0.55))
			draw_circle(mid + Vector2(0.5, -0.5), 1.2, Color(0.75, 0.90, 1.0))
		"boots":   # Scout's Boots: a leather pair, soles and all
			for off in [-6.0, 1.0]:
				var o := mid + Vector2(off, 0)
				draw_rect(Rect2(o + Vector2(0, -7), Vector2(4, 9)), Color(0.44, 0.28, 0.12))
				draw_rect(Rect2(o + Vector2(0, 2), Vector2(6.5, 4)), Color(0.38, 0.24, 0.10))
				draw_rect(Rect2(o + Vector2(0, 5), Vector2(6.5, 1.6)), Color(0.20, 0.13, 0.06))
				draw_line(o + Vector2(0.5, -5.5), o + Vector2(3.5, -5.5), Color(0.30, 0.19, 0.08), 1.0)
		"belt":    # Hunter's Belt: a strap with a gold buckle
			draw_rect(Rect2(mid + Vector2(-9, -2.2), Vector2(18, 4.6)), Color(0.42, 0.27, 0.11))
			draw_line(mid + Vector2(-9, -1), mid + Vector2(9, -1), Color(0.32, 0.20, 0.08), 0.8)
			draw_line(mid + Vector2(-9, 1.4), mid + Vector2(9, 1.4), Color(0.32, 0.20, 0.08), 0.8)
			draw_rect(Rect2(mid + Vector2(-2.8, -3.8), Vector2(5.6, 7.6)), Color(0.92, 0.80, 0.30), false, 1.8)
			draw_line(mid + Vector2(0, -1.5), mid + Vector2(0, 1.5), Color(0.92, 0.80, 0.30), 1.4)
		"legplates":  # Ancient Legplates: two riveted steel greaves
			for off in [-5.5, 1.0]:
				var r := Rect2(mid + Vector2(off, -7.5), Vector2(4.6, 15))
				draw_rect(r, Color(0.55, 0.57, 0.63))
				draw_rect(r, Color(0.30, 0.32, 0.38), false, 1.0)
				draw_line(mid + Vector2(off, -1), mid + Vector2(off + 4.6, -1), Color(0.38, 0.40, 0.46), 1.0)
				draw_circle(mid + Vector2(off + 2.3, -5), 0.8, Color(0.78, 0.80, 0.86))
				draw_circle(mid + Vector2(off + 2.3, 4.5), 0.8, Color(0.78, 0.80, 0.86))
		"armor":   # Leather Armor: a stitched cuirass
			draw_rect(Rect2(mid + Vector2(-6, -5.5), Vector2(12, 11.5)), Color(0.46, 0.30, 0.14))
			draw_rect(Rect2(mid + Vector2(-8.2, -5.5), Vector2(2.2, 4.5)), Color(0.40, 0.26, 0.12))
			draw_rect(Rect2(mid + Vector2(6, -5.5), Vector2(2.2, 4.5)), Color(0.40, 0.26, 0.12))
			draw_rect(Rect2(mid + Vector2(-2.4, -5.5), Vector2(4.8, 2)), Color(0.28, 0.18, 0.08))
			draw_line(mid + Vector2(-6, -1), mid + Vector2(6, -1), Color(0.32, 0.20, 0.09), 1.0)
			draw_line(mid + Vector2(0, -3.5), mid + Vector2(0, 6), Color(0.32, 0.20, 0.09), 1.0)
		"potion":  # a healing draught: red liquid in a corked flask
			draw_colored_polygon(PackedVector2Array([
				mid + Vector2(-2, -7), mid + Vector2(2, -7), mid + Vector2(2, -2),
				mid + Vector2(5.5, 5), mid + Vector2(-5.5, 5), mid + Vector2(-2, -2)]),
				Color(0.80, 0.88, 0.94, 0.9))
			draw_colored_polygon(PackedVector2Array([
				mid + Vector2(3.2, 0), mid + Vector2(5.5, 5),
				mid + Vector2(-5.5, 5), mid + Vector2(-3.2, 0)]),
				Color(0.80, 0.20, 0.16))
			draw_rect(Rect2(mid + Vector2(-2.4, -9), Vector2(4.8, 2.2)), Color(0.50, 0.36, 0.18))
		"tpscroll":  # a portal scroll: pale roll with a glowing blue ribbon
			draw_rect(Rect2(mid + Vector2(-7, -4), Vector2(14, 8)), Color(0.86, 0.84, 0.72))
			draw_rect(Rect2(mid + Vector2(-7, -4), Vector2(2.2, 8)), Color(0.70, 0.67, 0.55))
			draw_rect(Rect2(mid + Vector2(4.8, -4), Vector2(2.2, 8)), Color(0.70, 0.67, 0.55))
			draw_rect(Rect2(mid + Vector2(-1.2, -5), Vector2(2.4, 10)), Color(0.35, 0.60, 1.0))
			draw_circle(mid, 1.6, Color(0.75, 0.90, 1.0))
		_:         # anything else: the classic gold diamond
			draw_colored_polygon(PackedVector2Array([
				mid + Vector2(0, -9), mid + Vector2(8, 0),
				mid + Vector2(0, 9), mid + Vector2(-8, 0)]), Color(1.0, 0.82, 0.20))
			draw_circle(mid, 3.0, Color(1.0, 0.95, 0.6))

# Each vendor is unique: a gold badge holding a symbol for their
# trade (bread loaf, anvil, alchemy flask, coin bag) with their
# name written underneath.
func _draw_vendor(v: Dictionary) -> void:
	var roster: Array = WEST_VENDORS if v.get("set", "town") == "west" else VENDORS
	var data: Dictionary = roster[v["set_idx"] % roster.size()]
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
		"scroll":
			draw_rect(Rect2(center + Vector2(-6, -4), Vector2(12, 8)), Color(0.90, 0.87, 0.75))
			draw_rect(Rect2(center + Vector2(-6, -4), Vector2(2, 8)), Color(0.72, 0.68, 0.55))
			draw_rect(Rect2(center + Vector2(4, -4), Vector2(2, 8)), Color(0.72, 0.68, 0.55))
			for i in 2:
				draw_line(center + Vector2(-3, -1.5 + i * 3), center + Vector2(3, -1.5 + i * 3),
						Color(0.45, 0.42, 0.34), 0.9)
		_:
			_draw_glyph(center, "V", Color(0.15, 0.12, 0.02))
	# name plate under the symbol
	var label: String = data["short"]
	var lw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, center + Vector2(-lw * 0.5 + 1, 24), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.75))
	draw_string(font, center + Vector2(-lw * 0.5, 23), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.92, 0.78))
	# quest mark above the badge: "!" = quest to give, "?" = turn-in ready
	if show_quest_marks and not quests.is_empty():
		var gidx: int = v["set_idx"] + (VENDORS.size() if v.get("set", "town") == "west" else 0)
		var q: Dictionary = quests[gidx % quests.size()]
		if q["state"] == "hidden":
			_draw_quest_mark(center + Vector2(0, -21), "!")
		elif q["state"] == "active" and _quest_fulfilled(q):
			_draw_quest_mark(center + Vector2(0, -21), "?")

func _draw_mob(mob: Dictionary) -> void:
	var t: Dictionary = MOB_TYPES[mob["type"]]
	var center := Vector2(mob["pos"]) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(center, 11.0, t["color"])
	draw_circle(center, 11.0, Color(0, 0, 0, 0.5), false, 2.0)
	_draw_mob_icon(center, mob["type"], t["color"])
	# little green health bar under the mob
	var frac: float = float(mob["hp"]) / float(t["hp"])
	draw_rect(Rect2(center + Vector2(-10, 13), Vector2(20, 3)), Color(0.05, 0.14, 0.05))
	draw_rect(Rect2(center + Vector2(-10, 13), Vector2(20.0 * frac, 3)), Color(0.30, 0.85, 0.30))
	draw_rect(Rect2(center + Vector2(-10, 13), Vector2(20, 3)), Color(0, 0, 0, 0.5), false, 1.0)

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
		"a":  # goblin archer: pointed ears, headband, a bow at the side
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-9, -2), c + Vector2(-13, -7), c + Vector2(-7, -5)]), base.darkened(0.15))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(9, -2), c + Vector2(13, -7), c + Vector2(7, -5)]), base.darkened(0.15))
			draw_rect(Rect2(c + Vector2(-6, -6.5), Vector2(12, 2.6)), Color(0.65, 0.22, 0.15))
			draw_circle(c + Vector2(-3, -1), 1.2, Color(0.95, 0.85, 0.25))
			draw_circle(c + Vector2(3, -1), 1.2, Color(0.95, 0.85, 0.25))
			draw_arc(c + Vector2(6.5, 3), 4.5, -PI * 0.6, PI * 0.6, 10, Color(0.62, 0.44, 0.20), 1.6)
			draw_line(c + Vector2(6.5, -1.5), c + Vector2(6.5, 7.5), Color(0.85, 0.83, 0.75), 0.9)
		"k":  # bone knight: a skull under a dark helm, ember-red eyes
			draw_circle(c + Vector2(0, 0.5), 6.5, Color(0.90, 0.89, 0.82))
			draw_rect(Rect2(c + Vector2(-7, -8.5), Vector2(14, 6)), Color(0.28, 0.28, 0.34))
			draw_rect(Rect2(c + Vector2(-8, -4), Vector2(2.6, 6)), Color(0.28, 0.28, 0.34))
			draw_rect(Rect2(c + Vector2(5.4, -4), Vector2(2.6, 6)), Color(0.28, 0.28, 0.34))
			draw_rect(Rect2(c + Vector2(-1.2, -10.5), Vector2(2.4, 3)), Color(0.65, 0.18, 0.14))
			draw_circle(c + Vector2(-2.7, -0.5), 1.5, Color(0.85, 0.25, 0.12))
			draw_circle(c + Vector2(2.7, -0.5), 1.5, Color(0.85, 0.25, 0.12))
			for i in 3:
				draw_line(c + Vector2(-2.4 + i * 2.4, 3.8), c + Vector2(-2.4 + i * 2.4, 6.6), dark, 0.9)
		"y":  # wraith: hollow glowing eyes, a wispy trailing shroud
			draw_circle(c + Vector2(0, -2), 7.0, base.lightened(0.15))
			draw_circle(c + Vector2(-3, -3), 2.0, Color(0.75, 0.95, 1.0))
			draw_circle(c + Vector2(3, -3), 2.0, Color(0.75, 0.95, 1.0))
			draw_circle(c + Vector2(-3, -3), 0.9, Color(0.10, 0.15, 0.25))
			draw_circle(c + Vector2(3, -3), 0.9, Color(0.10, 0.15, 0.25))
			for i in 3:
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(-6 + i * 5, 3), c + Vector2(-3.5 + i * 5, 3),
					c + Vector2(-4.75 + i * 5, 8.5)]), base.lightened(0.1))
		"d":  # dire wolf: bigger ears than its cousin, ember eyes, bared fangs
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-7, -4), c + Vector2(-10, -13), c + Vector2(-2, -7)]), base.darkened(0.25))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(7, -4), c + Vector2(10, -13), c + Vector2(2, -7)]), base.darkened(0.25))
			draw_circle(c + Vector2(-3.5, -2), 1.5, Color(0.95, 0.35, 0.15))
			draw_circle(c + Vector2(3.5, -2), 1.5, Color(0.95, 0.35, 0.15))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-3.5, 1), c + Vector2(3.5, 1), c + Vector2(0, 8.5)]), base.darkened(0.35))
			draw_line(c + Vector2(-2.2, 3.4), c + Vector2(-1.6, 5.8), Color(0.95, 0.93, 0.85), 1.2)
			draw_line(c + Vector2(2.2, 3.4), c + Vector2(1.6, 5.8), Color(0.95, 0.93, 0.85), 1.2)
			draw_circle(c + Vector2(0, 7.2), 1.3, dark)
		"o":  # orc: heavy underjaw, upward tusks, a warrior's topknot
			draw_rect(Rect2(c + Vector2(-2, -12), Vector2(4, 4.5)), Color(0.15, 0.10, 0.08))
			draw_circle(c + Vector2(-3.5, -2.5), 1.4, Color(0.90, 0.75, 0.20))
			draw_circle(c + Vector2(3.5, -2.5), 1.4, Color(0.90, 0.75, 0.20))
			draw_rect(Rect2(c + Vector2(-5, 2.5), Vector2(10, 4)), base.darkened(0.3))
			draw_line(c + Vector2(-3.5, 3), c + Vector2(-4.5, -1), Color(0.95, 0.92, 0.82), 1.8)
			draw_line(c + Vector2(3.5, 3), c + Vector2(4.5, -1), Color(0.95, 0.92, 0.82), 1.8)
		"h":  # orc shaman: orc face beneath a bone circlet and feathers
			draw_rect(Rect2(c + Vector2(-6.5, -8), Vector2(13, 3)), Color(0.92, 0.90, 0.80))
			for i in 3:
				draw_line(c + Vector2(-4 + i * 4, -8), c + Vector2(-4 + i * 4, -12.5),
						Color(0.92, 0.90, 0.80), 1.6)
			draw_circle(c + Vector2(-3.5, -2), 1.4, Color(0.55, 0.95, 0.65))
			draw_circle(c + Vector2(3.5, -2), 1.4, Color(0.55, 0.95, 0.65))
			draw_rect(Rect2(c + Vector2(-4.5, 3), Vector2(9, 3.4)), base.darkened(0.3))
			draw_line(c + Vector2(-2.8, 3.4), c + Vector2(-3.6, 0.5), Color(0.95, 0.92, 0.82), 1.5)
			draw_line(c + Vector2(2.8, 3.4), c + Vector2(3.6, 0.5), Color(0.95, 0.92, 0.82), 1.5)
		"u":  # cave bear: round ears, small dark eyes, broad pale snout
			draw_circle(c + Vector2(-6, -7), 3.4, base.darkened(0.2))
			draw_circle(c + Vector2(6, -7), 3.4, base.darkened(0.2))
			draw_circle(c + Vector2(-3.5, -2.5), 1.2, dark)
			draw_circle(c + Vector2(3.5, -2.5), 1.2, dark)
			draw_circle(c + Vector2(0, 3.5), 4.6, base.lightened(0.25))
			draw_circle(c + Vector2(0, 2), 1.7, dark)
			draw_line(c + Vector2(0, 3.5), c + Vector2(0, 6), dark, 1.0)
		"x":  # gargoyle: horned stone face, blank glowing eyes, an old crack
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-6, -6), c + Vector2(-9, -12), c + Vector2(-3, -8)]), base.darkened(0.2))
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(6, -6), c + Vector2(9, -12), c + Vector2(3, -8)]), base.darkened(0.2))
			draw_circle(c + Vector2(-3.2, -2), 1.7, Color(0.95, 0.95, 0.85))
			draw_circle(c + Vector2(3.2, -2), 1.7, Color(0.95, 0.95, 0.85))
			draw_line(c + Vector2(1, -9), c + Vector2(3.5, 6), base.darkened(0.35), 1.2)
			draw_line(c + Vector2(-3.5, 4.5), c + Vector2(3.5, 4.5), dark, 1.4)
		"v":  # dread knight: darker helm than the bone knight's, red plume
			draw_circle(c + Vector2(0, 0.5), 6.5, Color(0.30, 0.28, 0.36))
			draw_rect(Rect2(c + Vector2(-7, -8.5), Vector2(14, 6)), Color(0.16, 0.15, 0.20))
			draw_rect(Rect2(c + Vector2(-8, -4), Vector2(2.6, 7)), Color(0.16, 0.15, 0.20))
			draw_rect(Rect2(c + Vector2(5.4, -4), Vector2(2.6, 7)), Color(0.16, 0.15, 0.20))
			draw_rect(Rect2(c + Vector2(-1.4, -13.5), Vector2(2.8, 5.5)), Color(0.75, 0.16, 0.12))
			draw_circle(c + Vector2(-2.7, -0.5), 1.6, Color(0.95, 0.30, 0.10))
			draw_circle(c + Vector2(2.7, -0.5), 1.6, Color(0.95, 0.30, 0.10))
			draw_line(c + Vector2(-3, 4.2), c + Vector2(3, 4.2), dark, 1.5)

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
	if equipment.has(14):  # cloak behind everything
		ci.draw_rect(Rect2(c + Vector2(-7, -7) * s, Vector2(14, 17) * s), Color(0.35, 0.16, 0.14))
	ci.draw_rect(Rect2(c + Vector2(-4.5, 3) * s, Vector2(3.5, 9) * s), pants)
	ci.draw_rect(Rect2(c + Vector2(1, 3) * s, Vector2(3.5, 9) * s), pants)
	ci.draw_rect(Rect2(c + Vector2(-5, -5) * s, Vector2(10, 8) * s), skin)
	ci.draw_rect(Rect2(c + Vector2(-8, -5) * s, Vector2(3, 8) * s), skin_sh)   # arms
	ci.draw_rect(Rect2(c + Vector2(5, -5) * s, Vector2(3, 8) * s), skin_sh)
	if equipment.has(4):   # leather armor over the torso
		var leather := Color(0.46, 0.30, 0.14)
		ci.draw_rect(Rect2(c + Vector2(-5, -5) * s, Vector2(10, 8) * s), leather)
		ci.draw_line(c + Vector2(-5, -2) * s, c + Vector2(5, -2) * s, leather.darkened(0.35), 1.0 * s)
		ci.draw_line(c + Vector2(0, -5) * s, c + Vector2(0, 3) * s, leather.darkened(0.35), 1.0 * s)
	ci.draw_circle(c + Vector2(0, -11) * s, 5.2 * s, hair)                     # hair behind head
	ci.draw_rect(Rect2(c + Vector2(-6.5, -12) * s, Vector2(2, 9) * s), hair)   # strands
	ci.draw_rect(Rect2(c + Vector2(4.5, -12) * s, Vector2(2, 9) * s), hair)
	ci.draw_circle(c + Vector2(0, -10) * s, 4.4 * s, skin)                     # face
	ci.draw_rect(Rect2(c + Vector2(-4.2, -14.6) * s, Vector2(8.4, 2.6) * s), hair)  # fringe
	ci.draw_circle(c + Vector2(-1.7, -10) * s, 0.6 * s, Color(0.15, 0.12, 0.10))
	ci.draw_circle(c + Vector2(1.7, -10) * s, 0.6 * s, Color(0.15, 0.12, 0.10))
	ci.draw_rect(Rect2(c + Vector2(-5, 2) * s, Vector2(10, 1.8) * s), Color(0.26, 0.18, 0.10))
	if equipment.has(0):   # headgear: gold crown or leather/iron cap
		if equipment[0] == "crown":
			ci.draw_rect(Rect2(c + Vector2(-5, -16) * s, Vector2(10, 3.0) * s), Color(0.90, 0.75, 0.25))
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-4.4 + i * 3.6, -18) * s, Vector2(1.6, 2.4) * s), Color(0.90, 0.75, 0.25))
		else:
			ci.draw_rect(Rect2(c + Vector2(-5, -16) * s, Vector2(10, 3.4) * s), Color(0.45, 0.30, 0.14))
	if equipment.has(15):  # sword in the main hand
		ci.draw_line(c + Vector2(7, 3) * s, c + Vector2(11.5, -9) * s, Color(0.75, 0.78, 0.85), 1.6 * s)
		ci.draw_line(c + Vector2(6, -1.5) * s, c + Vector2(9.5, -0.2) * s, Color(0.45, 0.32, 0.14), 1.4 * s)
	if equipment.has(16):  # shield on the off hand
		if equipment[16] == "tshield":
			# the tower shield: a tall brown rectangle, banded
			ci.draw_rect(Rect2(c + Vector2(-12, -6) * s, Vector2(7, 13) * s), Color(0.48, 0.34, 0.16))
			ci.draw_rect(Rect2(c + Vector2(-12, -6) * s, Vector2(7, 13) * s), Color(0.28, 0.19, 0.08), false, 1.2 * s)
			ci.draw_line(c + Vector2(-12, 0.5) * s, c + Vector2(-5, 0.5) * s, Color(0.28, 0.19, 0.08), 1.0 * s)
		else:
			ci.draw_circle(c + Vector2(-8.5, 0) * s, 4.2 * s, Color(0.48, 0.34, 0.16))
			ci.draw_circle(c + Vector2(-8.5, 0) * s, 4.2 * s, Color(0.28, 0.19, 0.08), false, 1.2 * s)
	if equipment.has(17):  # wand tucked into the belt
		ci.draw_line(c + Vector2(-4, 2.5) * s, c + Vector2(-8, -4.5) * s, Color(0.58, 0.40, 0.18), 1.5 * s)
		ci.draw_circle(c + Vector2(-8, -4.5) * s, 1.3 * s, Color(0.65, 0.75, 1.0))

func _draw_glyph(center: Vector2, ch: String, col: Color) -> void:
	var size := 16
	var w: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, center + Vector2(-w * 0.5, 6), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
