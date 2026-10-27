# Studio verification — 2026-10-26 (v2 rebuild)

## Update 2026-10-27: simulator-style HUD, Robux shop and base props (place ST)

- New HUD built as real GUI objects (`MonsterEggHUD` in StarterGui, 1100+ objects): bottom-left stats, Shop/Index/Trails menu with Slow Mode, Gift/Settings buttons and a gift countdown. Windows checked in Play with screenshots: Shop (Cash, Speed and Upgrades tabs), horizontal Trail Shop, Egg Index, Free Gift and Settings.
- 6 new ForgeGUI images (cash stack, money bag, cash chest, shoe pile, shoe chest, fuse machine) were published as approved Roblox Images; 5 are used on the pack cards. The Index button icon was published too. The shop, rewards and settings icon jobs stayed "running" and those buttons use emoji.
- Base props in every base: an upgrade board, a SELL stall and a Fuse Machine.
  - Real mouse clicks on the board's $ and R$ buttons worked in Play: $ upgraded the treadmill; R$ showed the "not set up yet" notice, because the developer product ids are still 0.
  - The HUD buttons were clicked as well: Shop, its tabs, Upgrades → Speed, Trails, the Settings toggles and Gift → Claim.
- `tests/StudioSmoke.luau`: **123 of 123 checks passed**. New checks:
  - HUD upgrades;
  - the free gift and its cooldown;
  - the props in every base;
  - the board showing max level;
  - fuse 3 Common → 1 Uncommon, and fusing needs 3 of a kind;
  - sell all;
  - cash, speed, trail and treadmill Robux grants;
  - Slow Mode on and off.
- No game errors in the log. All 12 Studio scripts match `src/`.

## Update 2026-10-27: ForgeGUI audio, icons and landmarks (place ST, 77852204695857)

- 7 sound effects and 7 music tracks were generated with ForgeGUI and published as Roblox Audio. The Desert and Ice tracks failed on the first try and succeeded on a retry. All 14 report `AssetFetchStatus.Success` in Play; the safe-zone music starts at volume 0.3.
- 5 HUD icons were published as Roblox Images, are approved and are visible in the HUD screenshot. The treadmill icon generation stayed "running" and is unused.
- 4 of 6 landmark models (Ice, Lava, Toxic, Shadow) were published as approved Roblox Models and load at map build. Forest and Desert stayed "running" at ForgeGUI and are not in the game yet (`AssetId = 0`).
- `tests/StudioSmoke.luau`: **107 of 107 checks passed** on ST. No game errors in the log; the only warning (asset 203785492) comes from the Ro-Defender plugin.
- Security: ST also contained the obfuscated `Workspace.Terrain.Converter` backdoor; it was removed with the owner's approval. The Studio plugin 5608087464 (a GUI-to-Lua converter) contains a script with the same name and is the likely source; the owner should uninstall it and republish ST.

## Update: personal bases and treadmills

The sanctuary was rebuilt with seven personal bases (max 7 players). Each has its own spawn pad, egg pen and treadmill, and the treadmills upgrade from level 1 to 15, each with its own design and +1.2 walk speed per level. The plaza gained a fountain and props; the zones gained wall decor and ambient particles.

- `tests/StudioSmoke.luau`: **107 of 107 checks passed**. New checks:
  - seven bases, each with a treadmill;
  - spawning and respawning at your own base;
  - your own treadmill pays and someone else's doesn't;
  - level 2 rebuilds the design and adds +1.2 speed;
  - level 15 has the light beam, can't go higher and gives +16.8 speed.
- Visual: top-down base layout, a level 15 treadmill in a base, and a showcase of levels 1, 3, 5, 7, 9, 11, 13 and 15. The level 15 frame and light were toned down after the first look was overexposed.
- No client or server errors in the log. All 11 Studio scripts match `src/`.

## Update: generated slime guardians

The part-built monsters were replaced by six AI-generated textured meshes (Studio `generate_mesh`), one per biome in matching colours. Nests and guardians moved off the centre path. The game loads each mesh at runtime with `AssetService:CreateMeshPartAsync` from the ids in `Config`, so a published place needs those assets to stay available to the experience owner.

- `tests/StudioSmoke.luau`: **100 of 100 checks passed**. New checks: every guardian uses its generated mesh and sleeps off the centre path.
- Visual: sleeping squash pose in Forest and Lava, and a Sludge King chase leaning forward with the Rage highlight and fire.
- All 11 Studio scripts match `src/`.

## Original v2 verification

Target: Place1 (unpublished, PlaceId 0) in Roblox Studio, driven through the Roblox Studio MCP server. All scripts were installed into the Edit datamodel and verified byte-for-byte against `src/` with `tools/source_hashes.py` / `tools/SourceHashes.luau` (11 of 11 match). All eleven compile.

## Passed

- **`tests/StudioSmoke.luau`: 88 of 88 checks passed.**
  - World: six zones, six guardians, 18 nest eggs, eight plots, plot assignment.
  - Each of the six zones: pickup, the guardian wakes on theft, the egg is carried visibly, chase with the HUD warning, Rage on for Epic/Legendary/Divine and off for Common/Uncommon/Rare, the guardian moves toward the carrier, banking in the safe zone and the guardian giving up at the gate.
  - All guardians return to their nest and sleep again.
  - Banked eggs appear in the plot and pay income.
  - Standing still gets you caught and the egg is lost.
  - The Basic treadmill trains, a locked treadmill does nothing, and an unlocked Turbo treadmill trains faster.
  - Speed, Storage and Treadmill Power upgrades.
  - Buying a trail multiplies speed and shows a visible trail; equipping another trail and blocking double purchases both work.
  - Selling an egg, a full plot rejecting new eggs, death dropping the egg and respawn keeping progress.
- **Real input:**
  - Walked to the Forest nest and held E to take an egg.
  - Standing still: the Bramble Beast woke, chased, caught and knocked back the player, then went back to sleep.
  - Second run: grabbed an Epic egg, ran back, and the egg was banked with a +$160 bonus and placed in the plot.
  - Bought Speed level 1 at the board with E (WalkSpeed 20 → 21.5).
- **Visual checks:**
  - HUD, zone banner, chase warning with Rage meter, red vignette, carried-egg card with distance to safety, Trail Shop window, toasts and plot eggs.
  - Monster walk and sleep poses.
  - Lava, Toxic and Shadow zone moods.
- **Small phone (Samsung Galaxy A06, 705×338 viewport):** the HUD fits with no clipping, and the touch controls stay clear.

## Fixed during testing

- Two "ambiguous syntax" lines (statements starting with `(`) that stopped the server and client scripts.
- `Workspace.StreamingEnabled` was on, so board prices stayed "Loading..." and other client-side edits could be undone. Streaming is now off in the place, the installer and the place file.
- Carried rare eggs had a PointLight that washed out the camera. Carried and plot eggs no longer get lights, and nest-egg lights and bloom are softer.
- Plot egg labels cluttered the view; the sell prompt now shows the egg and its price.
- The first zone's entry arch overlapped the safe-zone gate, and the zone name on the walls was oversized.

## Not yet verified (needs a published test experience or several clients)

- Persistent save/rejoin, offline earnings, disconnect recovery and cross-server session locking (DataStores are unavailable in an unpublished place).
- Stealing between two real players and contention when several players grab eggs at once. The server path exists and validates distance, the safe zone, the grace period and capacity, but solo Play can't exercise it. Use Studio's Test → Clients and Servers with 2 players.
- Performance on low-end mobile devices with eight players.

No GitHub push or Roblox publication has been performed.
