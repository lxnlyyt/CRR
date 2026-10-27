# MONSTER EGG ESCAPE

A colourful Roblox simulator: sneak into monster nests, steal eggs, outrun the guardian and bank your loot in the safe zone.

## Gameplay

- **One long, straight map** with high checker walls and six zones: Forest, Desert, Ice, Lava, Toxic and Shadow. Each zone has its own decor, lighting mood and a nest with three eggs.
- **Six slime guardians** — Mossmaw, Dune Gloop, Frostgloop, Magma Maw, Sludge King and Void Gloom. Each is an AI-generated textured mesh (Roblox Studio `generate_mesh`) coloured to match its biome, animated with squash & stretch and a red rage glow. Each nest and its guardian sit off the centre path at a different spot in its zone. They sleep beside their nest, wake up when an egg is taken, chase the carrier, stop at the safe zone and slide back to sleep. Getting caught knocks you back and the egg is lost.
- **Seven egg rarities:** Common, Uncommon, Rare, Epic, Legendary, Mythic and Divine. Deeper zones roll rarer eggs and pay more.
- **Monster Rage:** Epic and rarer eggs enrage the guardian (fire, red eyes, faster). Legendary and rarer eggs add charge dashes. Rage builds the longer the chase lasts.
- **Carrying and stealing:** the egg floats above your head. Other players can steal it with a prompt outside the safe zone, after a two-second grace period.
- **Safe zone:** crossing the green gate banks the egg with an instant bonus. Monsters can't enter.
- **Personal bases (max 7 players):** every player gets their own coloured base and spawns there. A base has a fenced egg pen, a spawn pad, a name arch and a personal treadmill. Banked eggs earn money every second, including a capped amount while offline. You can sell eggs from your own pen.
- **Personal treadmills (level 1–15):** only your own treadmill trains you and pays cash. Upgrade it at its screen; each level adds +1.2 walk speed permanently (+16.8 at level 15). Each level has its own design (Rusty, Steel, Mint, Ocean, Neon, Electric, Sunset, Gold, Ruby, Emerald, Amethyst, Inferno, Galaxy, Prism, Divine). Higher levels add side lights, sparkles, pylons, an arch, speed rings, flames and finally wings, a halo and a light beam. Running on it shows speed lines and widens the view.
- **Upgrades:** Speed and Storage (8 → 32 eggs) boards on the plaza, or the Upgrades tab of the Shop.
- **Base props:** every base has a black treadmill **Upgrade board** ("Level 8 > Level 9" with a clickable red $ button and purple R$ button), a **SELL stall** that sells every egg in your pen at once, and a **Fuse Machine** that turns 3 eggs of one rarity into 1 egg of the next rarity (its counter shows x/3 or READY!). Each egg in the pen shows its +$/s, and the treadmill shows its +$/step.
- **ForgeGUI assets:** seven sound effects (pickup, bank, buy, roar, caught, steal, level-up), a looping music track for the safe zone and for every zone (cross-faded on zone change, with a music on/off button), HUD icons (coin, egg, speed, trail, rage) and textured 3D landmarks for the Ice, Lava, Toxic and Shadow zones. All are published to the creator's Roblox account, and their ids live in `Config` (`Sounds`, `Music`, `Icons`, `Zones[i].Landmark`). Landmarks load at build time with `InsertService:LoadAsset`, so they need the place to be owned by the same account.
- **Map details:** a fountain plaza with a giant Divine egg, benches, planters and lamps, wall banners per base, path edging, and per-zone wall decor (vines, hieroglyphs, icicles, lavafalls, hazard panels, crystals and torches) with ambient particles (leaves, sand, snow, embers, bubbles, motes).
- **HUD (real GUI objects):** `HudBuilder` creates the `MonsterEggHUD` ScreenGui with stable names, so it can be built into StarterGui and tweaked in Studio. Speed (with trail multiplier), cash and eggs sit bottom-left; Shop, Index and Trails buttons plus a **Slow Mode** switch on the left; Gift and Settings on the right; a free-gift countdown top-right. Windows: **Shop** (tabs: Robux cash packs, Robux speed packs, Upgrades), **Trail Shop** (tall horizontal cards with rarity, x speed, $ and R$ prices, buy/equip/owned states), **Egg Index**, **Free Gift** (every 15 minutes) and **Settings** (music, sounds, camera shake, zone particles).
- **Trail Shop:** six trails, from Mint (x1.1) to Divine (x1.8) running speed. Buy them with cash or Robux at the booth or from the HUD.
- **Robux products:** trails, five cash packs, six permanent speed packs and one treadmill level are developer products. Create them in the Creator Hub (Monetization → Developer Products) and put their ids in `Config` (`Trails[i].ProductId`, `CashPacks[i].ProductId`, `SpeedPacks[i].ProductId`, `TreadRobux.ProductId`). Until an id is set, the button shows "Robux purchases are not set up yet". Receipts are granted once (purchase ids are saved) and saved straight away.
- **Saving:** session-locked DataStore with autosave every 60 seconds and a save on leave or shutdown. Unpublished Studio sessions clearly show that progress is temporary.

## Project layout

| Path | Studio location | Purpose |
| --- | --- | --- |
| `src/shared/Config.luau` | ReplicatedStorage.MonsterEgg | Zones, rarities, trails, treadmills, prices, formulas |
| `src/shared/Style.luau` | ReplicatedStorage.MonsterEgg | Part, sign, label and particle helpers |
| `src/shared/Eggs.luau` | ReplicatedStorage.MonsterEgg | Voxel egg models per rarity |
| `src/shared/Monsters.luau` | ReplicatedStorage.MonsterEgg | Guardian models (loaded from the mesh ids in Config, with a fallback blob) and their client-side animation |
| `src/shared/World.luau` | ReplicatedStorage.MonsterEgg | Map, personal bases, treadmill designs, shops, zone details, lighting, edit-time preview |
| `src/server/init.server.luau` | ServerScriptService.MonsterEggServer | Gameplay server |
| `src/server/Data.luau` | …MonsterEggServer.Data | DataStore loading/saving with session locks |
| `src/server/Guardians.luau` | …MonsterEggServer.Guardians | Guardian AI |
| `src/client/init.client.luau` | StarterPlayerScripts.MonsterEggClient | Client wiring, remotes, personal world labels |
| `src/client/HudBuilder.luau` | …MonsterEggClient.HudBuilder | Builds the MonsterEggHUD ScreenGui (stats, menu, windows) as real GUI objects |
| `src/client/Hud.luau` | …MonsterEggClient.Hud | Binds the HUD: counters, windows, shop tabs, Robux buttons, Slow Mode, toasts, chase warning |
| `src/client/Fx.luau` | …MonsterEggClient.Fx | Monster animation, sounds, shake, knockback, zone lighting |

`default.project.json` maps the same tree for Rojo.

## Installing

- **Open the place file:** `dist/MonsterEggEscape.rbxlx` contains all twelve scripts and has Workspace streaming turned off. Open it in Studio and press Play; the server builds the map on startup. Rebuild the file with `powershell -ExecutionPolicy Bypass -File tools/Build-Place.ps1`.
- **Install into an open place:** run `powershell -ExecutionPolicy Bypass -File tools/Build-Installer.ps1`, then run `build/Install.luau` in Studio's command bar (Edit mode) or through Studio MCP. It installs the scripts, turns off streaming and builds the map with sleeping guardians and nest eggs so the place looks complete in Edit mode.
- **Rojo:** `rojo serve` with `default.project.json`. Turn off `Workspace.StreamingEnabled` in the place.
- **Check Studio against the repo:** compare `python tools/source_hashes.py` with `tools/SourceHashes.luau` run in Studio.

Publish settings: set the maximum player count to **7** (one base per player). Enable Studio API access in a test experience to try real saving.

## Testing

`tests/StudioSmoke.luau` runs on the Studio server during a solo Play session through a Studio-only QA hook that refuses cloud-backed profiles. It checks all six zones end to end, plus Rage, getting caught, personal bases and spawning, treadmill levels 1–15 and their speed bonus, upgrades, the free gift, trails, selling, storage limits, death handling, the base props (upgrade board, sell stall, fuse machine), every Robux product type and Slow Mode. See `docs/PLAYTEST.md` for the latest results.
