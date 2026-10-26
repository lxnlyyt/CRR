# MONSTER EGG ESCAPE

Roblox simulator source: six zones, chasing guardians, six egg rarities, carried egg theft, safe banking, passive income, eight personal fenced plots, treadmills, speed/storage upgrades and four trail multipliers.

Use egg proximity prompts, then return across the green sanctuary boundary. Stand on treadmills for cash and training. Purchase upgrades at sanctuary boards. Banked eggs are safe; carried eggs can be stolen outside sanctuary after a two-second protection period.

## Installation

`default.project.json` maps source for Rojo. Alternatively run `powershell -File tools/Build-Installer.ps1`, then execute generated `build/Install.luau` through Studio MCP in Edit mode. Save the resulting place in Studio. The installer adds a namespaced world and disables legacy top-level spawn points. To regenerate geometry, remove only `Workspace.MonsterEggEscape` before reinstalling.

Set the published experience's maximum player count to **8**. Persistent DataStores require a published experience. Test Studio API access in a separate test experience. API-disabled Studio sessions clearly label temporary progress. Live servers reject failed loads to protect saved progress. Session locks expire after 180 seconds and renew on 60-second autosaves.

## Verification status

MCP connected to Place1 (PlaceId 0) and read Workspace: Camera, Terrain, Baseplate, SpawnLocation. Installation and runtime tests are pending confirmation that Place1 is the intended destination. Gameplay and persistence are not yet verified.
