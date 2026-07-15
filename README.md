# Grey Fortress

![Grey Fortress](docs/banner.png)

A turn-based roguelike prototype in the style of Castle of the Winds,
built with Godot 4. Desktop-only, targeting a Steam release (the Android
export was removed).

## How to run

1. Install Godot 4.2+ (standard version) from godotengine.org.
2. Open Godot, Import, select `project.godot`, press F5.

## Controls

The game opens on a title screen (the fortress under a crescent moon)
with New Game / Continue / Quit — arrows + Enter or mouse.

Movement is keyboard-only; the mouse operates the UI.

- Arrows / WASD: move (bump to attack, talk, pray, pick up)
- Diagonals: Q/E/Z/C, the numpad (1-9, roguelike layout), or two
  cardinal keys held together
- Space: wait a turn
- Numpad 5 (or middle mouse): aim the active spell, then click a tile
  to cast. While aiming the cursor becomes the spell icon, an aim
  line runs from the hero to the cursor, and the hovered tile is
  highlighted gold (clear shot) or red (out of range, or a tree or
  wall in the way); Esc or right click cancels
- P: spellbook — click a spell (or Up/Down + Enter) to make it the
  active one; the active spell and its mana cost are always visible
  in the HUD bar
- M: world map — every region and dungeon you have visited, laid out
  by their connections; neighboring places you have only heard of
  show as "???"
- I: character sheet (equipment paper-doll left, backpack right;
  arrows navigate, Left/Right switch side, Enter equips/uses/removes)
- J: quest journal
- Esc: close panels / open options
- Right click: universal "go back" — everything Esc dismisses, it
  dismisses too (close any panel, step an options sub-screen back,
  cancel a rebind or an aimed spell, leave the death screen); the
  one thing it never does is open a menu
- Mouse: the Inventory / Journal / Spells / Map / Options buttons in
  the HUD bar are clickable (click again to close); click items in
  the character sheet to equip/unequip/use; click rows in a shop to
  buy/sell/buy back; click options menu entries and drag the volume
  slider
- Every action can be given up to two keybinds in the options menu
- F11: toggle fullscreen
- Enter: restart after death, dismiss the victory screen
- Esc on the death screen: back to the title screen

## The world (camera follows you)

1. Grey Fortress Town: 4 vendor houses, healing temple, north gate
2. Northern Wilds: rats, goblins, wild boars
3. Dark Forest: wolves and goblin archers, the densest trees
4. Ancient Ruins: swarming with skeletons, plus goblins, archers and
   trolls; the Sunstone Relic lies between two trees near the north
   end, and a sunken stairway near the east side leads underground
5. Sunken Crypt: the first dungeon — a dark cave carved beneath the
   ruins, haunted by skeletons and hexing wraiths, with the Sunken
   Crown (+10 max HP) hidden in its farthest corner and a second
   stairway leading even deeper
6. Bone Hollow: the second dungeon level, deeper and deadlier —
   bone knights patrol it alongside the dead of the crypt above,
   and the Runeblade (+3 damage) lies in its farthest corner
7. Westmere Village (west of town, unlocked by the Sunstone Relic
   quest): larger than town, eight vendors each with a real shop
   and a quest of their own; their wares fill the equipment slots
   the town leaves empty (shirts, necklaces, gauntlets, a tabard),
   and Odo the fletcher sells wands that add spell damage. A temple
   at the bottom, and a boarded-up north gate to a future region
   (work in progress)

A winding road connects the south and north gates of every surface
map, so you can never be walled in by the procedural generation.
Every mob is drawn with its own face icon (rat whiskers, goblin
ears, boar tusks, wolf muzzle, skull, troll underbite, archer
headband, wraith glow).

Maps connect through data-driven links (gates and stairs), and both
the world map screen and all transitions derive from them — adding
a region or another dungeon level is one entry in `MAP_DEFS` plus
its entrance tile.

## Systems

- Coins: every kill drops some (amount depends on the mob)
- XP and levels: +3 max HP per level, +1 damage every 2 levels
- Magic: three spells for now — Magic Dart (3 mana, 2 damage,
  range 7), Bone Arrow (5 mana, 3 damage, range 9) and Fire Boulder
  (7 mana, 5 damage, range 5); projectiles animate to the target,
  rotated to point at it (spells only hit monsters for now;
  interacting with the environment is planned)
- Spell damage as a stat: wands (sold by Odo in Westmere) occupy
  the Ranged slot and add +1/+2 damage to every spell; the
  spellbook and character sheet show the bonus
- Line of sight: trees and walls block spell flight, for you and
  for the enemy
- Ranged mobs: goblin archers shoot arrows and wraiths hex from
  afar whenever they can see you
- Mana: slowly regenerates as you take turns (1 per 6), and is fully
  restored by leveling up, praying at the altar, or mana potions
  (sold by Cyra the alchemist)
- Mobs show a little green HP bar underneath
- Inventory: bread and potions heal; the relic is a quest item
- Equipment: 20 WoW-style slots (head through bag); items give
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
  Hunter's Belt, Ancient Legplates) and the dungeons (Sunken Crown,
  Runeblade) outclasses everything in shops
- Weather: entering an area has a 10% chance of rain — a cozy
  synthesized rain loop with animated streaks, plus occasional
  distant lightning (thunder rumble and a brief screen flash)
- Quests: every vendor gives one on first talk; return when done.
  The town's four (kill 5 rats, kill 3 goblins, bring 10 coins,
  fetch the relic) are joined by Westmere's eight (wolves, boars,
  trolls, skeletons, potions and bread to fetch, coins to invest),
  twelve in all; the relic quest rewards Leather Armor (+4 max HP,
  chest slot, drawn on the hero) and opens the west gate of town
- Save / load: "Save Game" in the options menu writes
  user://save.json; "Continue" on the title screen restores it
  (the world regenerates deterministically, so only the dynamic
  state — player, quests, surviving mobs, remaining loot — is saved)
- Death screen: shows when the run began and ended, steps taken,
  and the level you reached
- Victory: finishing all twelve quests shows a "Victory!" screen
  with the number of moves the run took; you can keep exploring
  after
- Temple altar: full heal, free, the only healing besides food/potions
- Per-map persistence with respawns: each time you re-enter a map,
  half of the slain mobs (per type, rounded up) come back, placed
  away from where you arrive
- "Entering..." banner the first time you reach each area
- HP (red), Mana (blue), XP (green) bars in the HUD, plus clickable
  Inventory / Journal / Spells / Map / Options buttons
- Minimap (bottom-right): the real terrain of the current area,
  rendered once into a texture, with your position and the area
  name; the world overview lives on the world map screen (M)
- Options menu (O or Esc): master volume, keybinds, fullscreen;
  menu items and the sound slider also respond to mouse click/drag;
  settings persist to user://settings.cfg
- Each wilderness map hides a loot outpost: a small stone keep
  holding a unique item (boots, belt, legplates)

## Code layout

- `main.gd`: game logic, procedural map generation, world rendering
- `hud.gd`: status bar and panels, on a CanvasLayer (does not scroll)
- Maps are generated from `MAP_DEFS` with a seed = hash(map id),
  so the world is identical every run
- Mob types, items, vendors and quests are data dictionaries;
  extending content means adding entries, not code
- `tools/smoke_test.gd`: headless sanity checks over the data
  tables and map generation — run with
  `godot --headless -s tools/smoke_test.gd` from the project dir

## Music

Five original tracks (town waltz, wilds ambience, dark forest theme,
eerie ruins theme, combat), composed
for this project and synthesized by tools/make_music.py. Public domain (CC0).
Combat music triggers when any enemy has you inside its sight range and
relaxes a few turns after you break contact.

The weather ambience (seamless rain loop, distant thunder) is likewise
synthesized from scratch by tools/make_ambience.py, the epic title
theme by tools/make_title.py, and the sound effects (combat, items,
magic, trading, quests, stairs, dying) by tools/make_sfx.py.
Public domain (CC0).

## Next steps

- A third dungeon level below Bone Hollow, with a boss guarding it
- The region beyond Westmere's boarded north gate
- Spells that interact with the environment (burning trees,
  freezing water)
- Random item drops from mobs (potions, gear with rolled stats)
- A repeatable quest or two after victory, so late runs have goals
- Steam integration (achievements, cloud saves)
