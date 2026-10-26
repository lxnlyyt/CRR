# MONSTER EGG ESCAPE

A colourful Roblox simulator: sneak into monster nests, steal eggs, outrun the guardian and bank your loot in the safe zone.

## Gameplay

- **One long, straight map** with high checker walls and six zones: Forest, Desert, Ice, Lava, Toxic and Shadow. Each zone has its own decor, lighting mood and a nest with three eggs.
- **Six slime guardians** — Mossmaw, Dune Gloop, Frostgloop, Magma Maw, Sludge King and Void Gloom. Each is an AI-generated textured mesh (Roblox Studio `generate_mesh`) coloured to match its biome, animated with squash & stretch and a red rage glow. Each nest and its guardian sit off the centre path at a different spot in its zone. They sleep beside their nest, wake up when an egg is taken, chase the carrier, stop at the safe zone and slide back to sleep. Getting caught knocks you back and the egg is lost.
- **Seven egg rarities:** Common, Uncommon, Rare, Epic, Legendary, Mythic and Divine. Deeper zones roll rarer eggs and pay more.
- **Monster Rage:** Epic and rarer eggs enrage the guardian (fire, red eyes, faster). Legendary and rarer eggs add charge dashes. Rage builds the longer the chase lasts.
- **Carrying and stealing:** the egg floats above your head. Other players can steal it with a prompt outside the safe zone, after a two-second grace period.
- **Safe zone:** crossing the green gate banks the egg with an instant bonus. Monsters can't enter.
- **Personal plots:** eight open plots with wooden fences. Banked eggs earn money every second, including a capped amount while offline. You can sell eggs from your own plot.
- **Treadmills:** Basic (free), Turbo and Hyper treadmills train speed and pay cash. You can unlock them, plus raise Treadmill Power, at the boards.
- **Upgrades:** Speed, Storage (8 → 32 eggs) and Treadmill Power boards.
- **Trail Shop:** six trails, from Mint (+10%) to Divine (+80%) running speed. Buy them at the booth or with the HUD button.
- **Saving:** session-locked DataStore with autosave every 60 seconds and a save on leave or shutdown. Unpublished Studio sessions clearly show that progress is temporary.

## Project layout

| Path | Studio location | Purpose |
| --- | --- | --- |
| `src/shared/Config.luau` | ReplicatedStorage.MonsterEgg | Zones, rarities, trails, treadmills, prices, formulas |
| `src/shared/Style.luau` | ReplicatedStorage.MonsterEgg | Part, sign, label and particle helpers |
| `src/shared/Eggs.luau` | ReplicatedStorage.MonsterEgg | Voxel egg models per rarity |
| `src/shared/Monsters.luau` | ReplicatedStorage.MonsterEgg | Guardian models (loaded from the mesh ids in Config, with a fallback blob) and their client-side animation |
| `src/shared/World.luau` | ReplicatedStorage.MonsterEgg | Map, plots, treadmills, shops, lighting, edit-time preview |
| `src/server/init.server.luau` | ServerScriptService.MonsterEggServer | Gameplay server |
| `src/server/Data.luau` | …MonsterEggServer.Data | DataStore loading/saving with session locks |
| `src/server/Guardians.luau` | …MonsterEggServer.Guardians | Guardian AI |
| `src/client/init.client.luau` | StarterPlayerScripts.MonsterEggClient | Client wiring, remotes, personal world labels |
| `src/client/Hud.luau` | …MonsterEggClient.Hud | HUD, toasts, chase warning, Trail Shop window |
| `src/client/Fx.luau` | …MonsterEggClient.Fx | Monster animation, sounds, shake, knockback, zone lighting |

`default.project.json` maps the same tree for Rojo.

## Installing

- **Open the place file:** `dist/MonsterEggEscape.rbxlx` contains all eleven scripts and has Workspace streaming turned off. Open it in Studio and press Play; the server builds the map on startup. Rebuild the file with `powershell -ExecutionPolicy Bypass -File tools/Build-Place.ps1`.
- **Install into an open place:** run `powershell -ExecutionPolicy Bypass -File tools/Build-Installer.ps1`, then run `build/Install.luau` in Studio's command bar (Edit mode) or through Studio MCP. It installs the scripts, turns off streaming and builds the map with sleeping guardians and nest eggs so the place looks complete in Edit mode.
- **Rojo:** `rojo serve` with `default.project.json`. Turn off `Workspace.StreamingEnabled` in the place.
- **Check Studio against the repo:** compare `python tools/source_hashes.py` with `tools/SourceHashes.luau` run in Studio.

Publish settings: set the maximum player count to **8** (one plot per player). Enable Studio API access in a test experience to try real saving.

## Testing

`tests/StudioSmoke.luau` runs on the Studio server during a solo Play session through a Studio-only QA hook that refuses cloud-backed profiles. It checks all six zones end to end, plus Rage, getting caught, treadmills, upgrades, trails, selling, storage limits and death handling. See `docs/PLAYTEST.md` for the latest results.
