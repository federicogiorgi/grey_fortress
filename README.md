# Grey Fortress

A turn-based roguelike prototype in the style of Castle of the Winds,
built with Godot 4. Desktop-only, targeting a Steam release (the Android
export was removed).

## How to run

1. Install Godot 4.2+ (standard version) from godotengine.org.
2. Open Godot, Import, select `project.godot`, press F5.

## Controls

Movement is keyboard-only; the mouse operates the UI.

- Arrows / WASD: move (bump to attack, talk, pray, pick up)
- Diagonals: Q/E/Z/C, the numpad (1-9, roguelike layout), or two
  cardinal keys held together
- Space: wait a turn
- I: character sheet (equipment paper-doll left, backpack right;
  arrows navigate, Left/Right switch side, Enter equips/uses/removes)
- J: quest journal
- Esc: close panels / open options
- Mouse: the Inventory / Journal / Options buttons in the HUD bar are
  clickable (click again to close); click items in the character sheet
  to equip/unequip/use; click rows in a shop to buy/sell/buy back;
  click options menu entries and drag the volume slider
- F11: toggle fullscreen
- Enter: restart after death, dismiss the victory screen

## The world (4 maps, each 4000x3008 px, camera follows you)

1. Grey Fortress Town: 4 vendor houses, healing temple, north gate
2. Northern Wilds: rats, goblins, wild boars
3. Dark Forest: wolves join in, denser trees
4. Ancient Ruins: swarming with skeletons, plus goblins and trolls;
   the Sunstone Relic lies between two trees near the north end

A winding road connects the south and north gates of every map,
so you can never be walled in by the procedural generation.
Every mob is drawn with its own face icon (rat whiskers, goblin
ears, boar tusks, wolf muzzle, skull, troll underbite).

## Systems

- Coins: every kill drops some (amount depends on the mob)
- XP and levels: +3 max HP per level, +1 damage every 2 levels
- Inventory: bread and potions heal; the relic is a quest item
- Equipment: all 21 WoW-style slots (ammo through bag); items give
  damage or max HP bonuses; a bag in the Bag slot raises backpack
  capacity from 20 to 28 stacks (no weight limits)
- Vendors: each is unique, drawn as a gold badge with a symbol for
  their trade (Alda: bread loaf; Borin: anvil; Cyra: alchemy flask;
  Dolm: coin bag) and their name underneath
- Shops: bump a vendor to trade; buy from their stock (number keys
  quick-buy), sell your items at half price, and buy back anything
  you sold at the same price (each vendor remembers the last 8 items
  you sold them); navigate with Up/Down + Enter or click a row
- Two item tiers per vendor: every item type has a pricier, stronger
  variant (e.g. Iron Sword +1 dmg for 25c, Steel Sword +2 dmg for
  60c); the unique loot hidden in the world outposts (Scout's Boots,
  Hunter's Bow, Ancient Legplates) outclasses everything in shops
- Weather: entering an area has a 10% chance of rain — a cozy
  synthesized rain loop with animated streaks, plus occasional
  distant lightning (thunder rumble and a brief screen flash)
- Quests: each vendor gives one on first talk; return when done
  (kill 5 rats, kill 3 goblins, bring 10 coins, fetch the relic)
- Victory: finishing all four quests shows a "Victory!" screen with
  the number of moves the run took; you can keep exploring after
- Temple altar: full heal, free, the only healing besides food/potions
- Per-map persistence with respawns: each time you re-enter a map,
  half of the slain mobs (per type, rounded up) come back, placed
  away from where you arrive
- "Entering..." banner the first time you reach each area
- HP (red), Mana (blue), XP (green) bars in the HUD, plus clickable
  Inventory / Journal / Options buttons
- World minimap (bottom-right): the four maps stacked north-to-south,
  visited areas colored, a dot for your position in the current map,
  and the area name underneath
- Options menu (O or Esc): master volume, keybinds, fullscreen;
  menu items and the sound slider also respond to mouse click/drag;
  settings persist to user://settings.cfg
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

The weather ambience (seamless rain loop, distant thunder) is likewise
synthesized from scratch by tools/make_ambience.py. Public domain (CC0).

## Next steps

- Mob variety per map depth, ranged enemies
- Save/load (serialize map_state + player dict to JSON)
- Sound effects, title screen
- Steam integration (achievements, cloud saves)
