"""Prints a checksum per source file; compare with the output of tools/SourceHashes.luau in Studio."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
FILES = {
    "ReplicatedStorage.MonsterEgg.Config": "src/shared/Config.luau",
    "ReplicatedStorage.MonsterEgg.Style": "src/shared/Style.luau",
    "ReplicatedStorage.MonsterEgg.Eggs": "src/shared/Eggs.luau",
    "ReplicatedStorage.MonsterEgg.Monsters": "src/shared/Monsters.luau",
    "ReplicatedStorage.MonsterEgg.World": "src/shared/World.luau",
    "ServerScriptService.MonsterEggServer": "src/server/init.server.luau",
    "ServerScriptService.MonsterEggServer.Data": "src/server/Data.luau",
    "ServerScriptService.MonsterEggServer.Guardians": "src/server/Guardians.luau",
    "StarterPlayer.StarterPlayerScripts.MonsterEggClient": "src/client/init.client.luau",
    "StarterPlayer.StarterPlayerScripts.MonsterEggClient.Hud": "src/client/Hud.luau",
    "StarterPlayer.StarterPlayerScripts.MonsterEggClient.HudBuilder": "src/client/HudBuilder.luau",
    "StarterPlayer.StarterPlayerScripts.MonsterEggClient.Fx": "src/client/Fx.luau",
}

def checksum(data: bytes) -> int:
    h = 0
    for b in data:
        h = (h * 31 + b) % 1000000007
    return h

for path, rel in FILES.items():
    data = (ROOT / rel).read_bytes().replace(b"\r\n", b"\n")
    print(f"{path} {len(data)} {checksum(data)}")
