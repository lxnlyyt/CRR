-- Run in Studio (Edit mode) and compare the output with `python tools/source_hashes.py`.
-- Matching lines prove the scripts in Studio are identical to the files in src/.
local paths = {
	"ReplicatedStorage.MonsterEgg.Config",
	"ReplicatedStorage.MonsterEgg.Style",
	"ReplicatedStorage.MonsterEgg.Eggs",
	"ReplicatedStorage.MonsterEgg.Monsters",
	"ReplicatedStorage.MonsterEgg.World",
	"ServerScriptService.MonsterEggServer",
	"ServerScriptService.MonsterEggServer.Data",
	"ServerScriptService.MonsterEggServer.Guardians",
	"StarterPlayer.StarterPlayerScripts.MonsterEggClient",
	"StarterPlayer.StarterPlayerScripts.MonsterEggClient.Hud",
	"StarterPlayer.StarterPlayerScripts.MonsterEggClient.HudBuilder",
	"StarterPlayer.StarterPlayerScripts.MonsterEggClient.Fx",
}
local out = {}
for _, path in paths do
	local node = game
	for part in path:gmatch("[^%.]+") do
		node = node:FindFirstChild(part)
	end
	local source = node.Source
	local h = 0
	for i = 1, #source do
		h = (h * 31 + string.byte(source, i)) % 1000000007
	end
	table.insert(out, path .. " " .. #source .. " " .. h)
end
return table.concat(out, "\n")
