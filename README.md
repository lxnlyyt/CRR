# MONSTER EGG ESCAPE

Roblox simulator source: six zones, chasing guardians, six egg rarities, carried egg theft, safe banking, passive income, eight personal fenced plots, treadmills, speed/storage upgrades and four trail multipliers.

Use egg proximity prompts, then return across the green sanctuary boundary. Stand on treadmills for cash and training. Purchase upgrades at sanctuary boards. Banked eggs are safe; carried eggs can be stolen outside sanctuary after a two-second protection period.

## Installation

`default.project.json` maps source for Rojo. Alternatively run `powershell -ExecutionPolicy Bypass -File tools/Build-Installer.ps1`, then execute generated `build/Install.luau` through Studio MCP in Edit mode. The installer rebuilds only its own `Workspace.MonsterEggEscape`, adds edit-time previews and disables legacy top-level spawn points. The original Baseplate is hidden and made non-collidable.

`dist/MonsterEggEscape.rbxlx` contains the actual exported Studio scene, with geometry, edit-time previews and all four scripts. Open it in Roblox Studio and press Play. The XML and embedded sources have been checked; reopening this export in another Studio session remains unverified.

`powershell -ExecutionPolicy Bypass -File tools/Build-Place.ps1 -OutputPath dist/SourceOnly.rbxlx` builds a smaller alternative containing the four scripts; its world appears when Play starts. `tools/ExportPlace.luau` is the scene exporter used through MCP.

Set the published experience's maximum player count to **8**. Persistent DataStores require a published experience. Test Studio API access in a separate test experience. API-disabled Studio sessions clearly label temporary progress. Live servers reject failed loads to protect saved progress. Session locks expire after 180 seconds and renew on 60-second autosaves.

## Verification status

Installed and played in Place1 through Roblox Studio MCP. Actual egg pickup, escape, banking, income, treadmill and upgrade prompts passed. The reproducible Studio smoke test passed 17 assertions. See `docs/PLAYTEST.md` for evidence and remaining published multiplayer/persistence checks. No GitHub push or Roblox publication has been performed.
