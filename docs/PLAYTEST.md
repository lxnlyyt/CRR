# Studio verification — 2026-10-26

Target: Place1, PlaceId 0, Roblox Studio MCP. All game objects and scripts were installed in the actual Edit datamodel, then executed in Studio Play mode.

## Passed

- Sleeping guardian update: all 23 smoke assertions passed in Studio. Guardians lie beside a three-egg cluster, close their eyes and stay asleep when approached. Pickup starts a 1.15-second wake-up, followed by upright pursuit. Banking ends the threat; the guardian returns to the nest and sleeps again.
- Actual E-key retest: guardian was Sleeping before pickup, Waking after taking a Common Forest egg, and the egg banked successfully with 100 health. The updated scene export matches all four current source scripts.

- Actual egg prompt activated using the E key. Player carried an Uncommon Forest egg visibly, walked back to sanctuary, retained 100 health, banked one egg and earned $6 per second.
- Treadmill awarded cash and training over three seconds.
- Actual speed prompt purchased level 1.
- Death removed the carried egg; respawn restored 100 health, retained the session profile and faced the zones.
- Actual storage prompt purchased capacity 12.
- Actual Mint, Prism and Solar trail prompts deducted money, equipped progressively faster trails and created a visible Trail. Speed level 1 plus Solar produced WalkSpeed 36.3. These purchase tests used explicitly granted temporary Studio cash.
- `tests/StudioSmoke.luau`: 17 assertions passed. Six zones and guardians, Divine pickup, guardian movement, Rage particles, banking, ending Rage, guardian safety boundary, income, visible plot egg, treadmill training and rejecting pickup at full capacity. This script uses a server-only Studio test hook to exercise gameplay functions and refuses cloud-backed profiles.
- All four game source scripts compiled through Studio's Luau compiler.

## Fixed during testing

- Unpublished DataStore initialization originally stopped server startup. Initialization now runs inside pcall; unpublished Studio runs show temporary progress explicitly.
- Overlapping default Baseplate caused ground artifacts. It is hidden and made non-collidable when generating this map.
- Spawn orientation now faces the zones.
- Billboard labels now scale in world space; title, zone and shop signs use SurfaceGui text.
- Saving now correctly releases the session lock; shutdown waits for pending saves up to 25 seconds.

## Still requires a published test experience

- Persistent save/rejoin round trip, disconnect recovery and cross-server session locking.
- Two-client theft, simultaneous egg pickup contention, joining/leaving plot reuse and eight-player load testing. The server implements these paths, but solo Play is insufficient proof.
- Device-specific touch/gamepad usability and performance on low-end devices.

No Roblox publication or GitHub push was performed.

## Local artifacts

`dist/MonsterEggEscape.rbxlx` is exported from the actual Studio Edit hierarchy: 1,188 owned instances plus service containers, including scenery, edit previews and all four scripts. XML structure and script/source equality were validated locally. Opening this exported file in a second Studio instance has not been tested. The procedural source and installer remain the reproducible build path.

`tools/ExportPlace.luau` exports the owned scene into `_G.MonsterEggPlaceXML`; MCP reads it in newline-aligned chunks to avoid the tool's output limit. `tools/Build-Place.ps1` produces a smaller source-only place instead and will replace the scene export if run with its default output path.
