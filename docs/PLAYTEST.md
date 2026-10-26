# Studio verification — 2026-10-26 (v2 rebuild)

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
