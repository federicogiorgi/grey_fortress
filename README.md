# Grey Fortress

A turn-based roguelike prototype in the style of Castle of the Winds, built with Godot 4.

## How to run

1. Install Godot 4.2+ (standard version) from godotengine.org.
2. Open Godot, Import, select `project.godot`, press F5.

## Controls

- Arrows / WASD: move (bump to attack, talk, pray, pick up)
- Diagonals: Q/E/Z/C, the numpad (1-9, roguelike layout), or two
  cardinal keys held together
- Touch or click-and-hold: the hero walks toward your finger/cursor
  (this is the Android control scheme; it works on desktop too)
- Mouse: click items in the character sheet to equip/unequip/use
- Space: wait a turn
- I: character sheet (equipment paper-doll left, backpack right;
  arrows navigate, Left/Right switch side, Enter equips/uses/removes)
- J: quest journal
- Esc: close panels / open options
- F11: toggle fullscreen
- Enter: restart after death

## The world (4 maps, each 4000x3008 px, camera follows you)

1. Grey Fortress Town: 4 vendor houses, healing temple, north gate
2. Northern Wilds: rats, goblins, wild boars
3. Dark Forest: wolves join in, denser trees
4. Ancient Ruins: skeletons and trolls; the Sunstone Relic lies
   between two trees near the north end

A winding road connects the south and north gates of every map,
so you can never be walled in by the procedural generation.

## Systems

- Coins: every kill drops some (amount depends on the mob)
- XP and levels: +3 max HP per level, +1 damage every 2 levels
- Inventory: bread and potions heal; the relic is a quest item
- Equipment: all 21 WoW-style slots (ammo through bag); items give
  damage or max HP bonuses; a bag in the Bag slot raises backpack
  capacity from 20 to 28 stacks (no weight limits)
- Shops: bump a vendor, buy with number keys
  (Alda: bread; Borin: sword, shield, cap; Cyra: potions, charm;
  Dolm: cloak, ring, bag)
- Quests: each vendor gives one on first talk; return when done
  (kill 5 rats, kill 3 goblins, bring 10 coins, fetch the relic)
- Temple altar: full heal, free, the only healing besides food/potions
- Per-map persistence: dead mobs stay dead
- "Entering..." banner the first time you reach each area
- HP (red), Mana (blue), XP (green) bars in the HUD
- Options menu (O or Esc): master volume, keybinds, fullscreen;
  menu items and the sound slider also respond to mouse click/drag
  (or finger on Android); settings persist to user://settings.cfg
- Each wilderness map hides a loot outpost: a small stone keep
  holding a unique item (boots, bow, legplates)

## Code layout

- `main.gd`: game logic, procedural map generation, world rendering
- `hud.gd`: status bar and panels, on a CanvasLayer (does not scroll)
- Maps are generated from `MAP_DEFS` with a seed = hash(map id),
  so the world is identical every run
- Mob types, items, vendors and quests are data dictionaries;
  extending content means adding entries, not code

## Music

Five original tracks (town waltz, wilds ambience, dark forest theme,
eerie ruins theme, combat), composed
for this project and synthesized by tools/make_music.py. Public domain (CC0).
Combat music triggers when any enemy has you inside its sight range and
relaxes a few turns after you break contact.

## Next steps

- Mob variety per map depth, ranged enemies
- Equipment slots instead of one-time buys
- Save/load (serialize map_state + player dict to JSON)
- Sound effects, title screen
