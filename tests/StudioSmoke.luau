-- Server-side smoke test. Run through Studio MCP (execute_luau, Server datamodel) during a solo
-- Play session. It changes temporary Studio progress only; the QA hook refuses cloud profiles.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsServer(), "Run on the Studio server during Play")
local player = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local qa = assert(game.ServerStorage:WaitForChild("MonsterEggStudioQA", 10), "Wait for server startup")
local Config = require(game.ReplicatedStorage.MonsterEgg.Config)
local world = workspace.MonsterEggEscape
local runtime = world.Runtime
while not player:GetAttribute("Base") do
	task.wait(0.2)
end

local passed, failed = {}, {}
local function check(name: string, condition: any)
	table.insert(if condition then passed else failed, name)
end

local function character()
	local char = player.Character or player.CharacterAdded:Wait()
	char:WaitForChild("HumanoidRootPart")
	return char
end
local function teleport(position: Vector3)
	character():PivotTo(CFrame.new(position) * CFrame.Angles(0, math.pi, 0))
	task.wait(0.15)
end
local function guardian(zone: number)
	return qa:Invoke("Guardian", player, zone)
end
local function waitFor(seconds: number, predicate: () -> boolean): boolean
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		if predicate() then
			return true
		end
		task.wait(0.1)
	end
	return predicate()
end
local SAFE = Vector3.new(0, 4, 40)

-- World ------------------------------------------------------------------------------
check("Six zone folders", #world.Zones:GetChildren() == #Config.Zones)
check("Six guardians spawned", #runtime.Monsters:GetChildren() == #Config.Zones)
check("Eighteen nest eggs", waitFor(Config.NestRespawn + 1, function()
	return #runtime.NestEggs:GetChildren() == #Config.Zones * Config.NestSlots
end))
local World = require(game.ReplicatedStorage.MonsterEgg.World)
local baseIndex = player:GetAttribute("Base")
check("Seven personal bases", #world.Sanctuary.Bases:GetChildren() == Config.MaxPlayers and Config.MaxPlayers == 7)
check("Player owns a base", baseIndex ~= nil and world.Sanctuary.Bases["Base" .. baseIndex]:GetAttribute("Owner") == player.UserId)
check("Every base has its own treadmill", (function()
	for _, base in world.Sanctuary.Bases:GetChildren() do
		if not base:FindFirstChild("Treadmill") then
			return false
		end
	end
	return true
end)())
check("Spawned at own base", (character().HumanoidRootPart.Position - World.SpawnPoint(baseIndex)).Magnitude < 10)
for zone = 1, #Config.Zones do
	local name = Config.Zones[zone].Monster
	local model = runtime.Monsters:FindFirstChild(name)
	check(name .. " starts asleep", guardian(zone).State == "Sleeping")
	check(name .. " uses its generated mesh", model ~= nil and model:FindFirstChild("Body") ~= nil and model.Body:IsA("MeshPart"))
	check(name .. " sleeps off the centre path", math.abs(guardian(zone).Position.X) > 15)
end

-- Every zone: steal, wake, chase (rage for rare eggs), bank in the safe zone ---------------
local rarities = { 1, 4, 2, 5, 3, 7 }
for zone, rarity in rarities do
	local name = Config.Zones[zone].Monster
	teleport(Vector3.new(30, 4, Config.ZoneStart(zone) + 15))
	local before = player:GetAttribute("EggCount")
	check(name .. ": pickup " .. Config.Rarities[rarity].Name, qa:Invoke("Carry", player, { Zone = zone, Rarity = rarity }))
	task.wait(0.15)
	check(name .. ": wakes on theft", guardian(zone).State == "Waking")
	check(name .. ": egg is carried visibly", #runtime.CarriedEggs:GetChildren() == 1)
	task.wait(Config.WakeTime + 0.3)
	local g = guardian(zone)
	check(name .. ": chases", g.State == "Chasing" and g.Target == player)
	check(name .. ": chase warning", player:GetAttribute("Chaser") == name)
	local raging = rarity >= Config.RageRarity
	local model = runtime.Monsters:FindFirstChild(name)
	check(name .. ": rage " .. (if raging then "on" else "off"), (g.Rage > 0) == raging and model.Root.RageFire.Enabled == raging)
	local start = g.Position
	task.wait(0.4)
	check(name .. ": moves toward carrier", (guardian(zone).Position - start).Magnitude > 2)
	teleport(SAFE)
	task.wait(0.2)
	check(name .. ": banked in safe zone", player:GetAttribute("EggCount") == before + 1 and player:GetAttribute("Carrying") == "")
	check(name .. ": gives up at safe zone", guardian(zone).State == "Returning")
end
check("All guardians return to sleep", waitFor(20, function()
	for zone = 1, #Config.Zones do
		if guardian(zone).State ~= "Sleeping" then
			return false
		end
	end
	return true
end))
check("Banked eggs shown in base pen", #qa:Invoke("Snapshot", player).Base.Eggs:GetChildren() == player:GetAttribute("EggCount"))
check("Banked eggs give income", (player:GetAttribute("Income") or 0) > 0)

-- Getting caught ---------------------------------------------------------------------------
local caughtBefore = qa:Invoke("Snapshot", player).Profile.Stats.Caught
teleport(Config.NestCenter(1) + Vector3.new(0, 4, -8))
qa:Invoke("Carry", player, { Zone = 1, Rarity = 1 })
check("Standing still gets you caught", waitFor(Config.WakeTime + 3, function()
	return qa:Invoke("Snapshot", player).Profile.Stats.Caught == caughtBefore + 1
end))
check("Caught egg is lost", player:GetAttribute("Carrying") == "")
task.wait(1.5) -- let the client-side knockback finish
teleport(SAFE)

-- Treadmills, upgrades and trails ------------------------------------------------------------
local function standOnTreadmill(index: number)
	teleport((World.TreadmillCFrame(index) * CFrame.new(0, 4, 0)).Position)
end
local training = player:GetAttribute("Training")
standOnTreadmill(baseIndex)
task.wait(2.2)
check("Own treadmill trains and pays", player:GetAttribute("Training") > training)
training = player:GetAttribute("Training")
standOnTreadmill(if baseIndex == 1 then 2 else 1)
task.wait(2.2)
check("Someone else's treadmill does nothing", player:GetAttribute("Training") == training)
teleport(SAFE)

qa:Invoke("GrantCash", player, 1e7)
local walkBefore = player:GetAttribute("WalkSpeed")
check("Upgrade treadmill to level 2", qa:Invoke("UpgradeTreadmill", player) == 2)
check("Treadmill upgrade adds walk speed", math.abs(player:GetAttribute("WalkSpeed") - walkBefore - Config.TreadSpeedPerLevel) < 0.01)
local myBase = world.Sanctuary.Bases["Base" .. baseIndex]
check("Treadmill rebuilt with level 2 design", myBase.Treadmill:GetAttribute("Level") == 2)
for _ = 3, Config.MaxTreadLevel do
	qa:Invoke("UpgradeTreadmill", player)
end
check("Treadmill reaches level 15", player:GetAttribute("TreadLevel") == Config.MaxTreadLevel)
check("Level 15 design has its divine beam", myBase.Treadmill:FindFirstChild("LightBeam") ~= nil)
check("Treadmill can't pass level 15", qa:Invoke("UpgradeTreadmill", player) == Config.MaxTreadLevel)
check("Max treadmill gives +16.8 speed", math.abs(player:GetAttribute("WalkSpeed") - walkBefore - 14 * Config.TreadSpeedPerLevel) < 0.01)

local speed, capacity = player:GetAttribute("SpeedLevel"), player:GetAttribute("Capacity")
qa:Invoke("Purchase", player, "Speed")
qa:Invoke("Purchase", player, "Storage")
check("Speed upgrade", player:GetAttribute("SpeedLevel") == speed + 1)
check("Storage upgrade", player:GetAttribute("Capacity") == capacity + Config.CapacityStep)
check("HUD Upgrade button buys speed", (qa:Invoke("Shop", player, { Action = "Upgrade", Index = "Speed" })) and player:GetAttribute("SpeedLevel") == speed + 2)
capacity += Config.CapacityStep
check("HUD Upgrade button buys storage", (qa:Invoke("Shop", player, { Action = "Upgrade", Index = "Storage" })) and player:GetAttribute("Capacity") == capacity + Config.CapacityStep)

local giftCash = player:GetAttribute("Cash")
check("Free gift can be claimed", (qa:Invoke("Shop", player, { Action = "Claim", Index = 0 })) and player:GetAttribute("Cash") > giftCash)
check("Free gift starts its cooldown", not (qa:Invoke("Shop", player, { Action = "Claim", Index = 0 })) and player:GetAttribute("NextReward") > os.time())

local walk = character().Humanoid.WalkSpeed
check("Buy Mint trail", (qa:Invoke("Shop", player, { Action = "Buy", Index = 1 })))
check("Trail multiplies speed", math.abs(character().Humanoid.WalkSpeed - walk * Config.Trails[1].Multiplier) < 0.05)
check("Trail is visible", character().HumanoidRootPart:FindFirstChild("EggTrail", true) ~= nil)
qa:Invoke("Shop", player, { Action = "Buy", Index = 3 })
check("Buy Prism trail equips it", player:GetAttribute("Trail") == 3)
qa:Invoke("Shop", player, { Action = "Equip", Index = 1 })
check("Re-equip owned trail", player:GetAttribute("Trail") == 1)
check("Cannot buy twice", not (qa:Invoke("Shop", player, { Action = "Buy", Index = 1 })))

-- Selling and storage limits -------------------------------------------------------------------
local count, cash = player:GetAttribute("EggCount"), player:GetAttribute("Cash")
local slotOne = World.SlotPosition(baseIndex, 1)
teleport(slotOne + Vector3.new(0, 2, -3))
qa:Invoke("Sell", player, 1)
check("Sell banked egg", player:GetAttribute("EggCount") == count - 1 and player:GetAttribute("Cash") > cash)
while player:GetAttribute("EggCount") < player:GetAttribute("Capacity") do
	teleport(SAFE)
	qa:Invoke("Carry", player, { Zone = 1, Rarity = 1 })
	task.wait(0.1)
end
teleport(Vector3.new(30, 4, Config.ZoneStart(1) + 60))
check("Full plot rejects new eggs", not qa:Invoke("Carry", player, { Zone = 1, Rarity = 1 }))

-- Death drops the egg ------------------------------------------------------------------------
teleport(slotOne + Vector3.new(0, 2, -3))
qa:Invoke("Sell", player, 1)
teleport(Vector3.new(30, 4, Config.ZoneStart(1) + 60))
check("Carry again after selling", qa:Invoke("Carry", player, { Zone = 1, Rarity = 2 }))
character().Humanoid.Health = 0
task.wait(0.3)
check("Death drops carried egg", player:GetAttribute("Carrying") == "")
player.CharacterAdded:Wait()
task.wait(0.5)
check("Respawn keeps progress", player:GetAttribute("Capacity") == capacity + Config.CapacityStep and player:GetAttribute("TreadLevel") == Config.MaxTreadLevel)
task.wait(0.3)
check("Respawn at own base", (character().HumanoidRootPart.Position - World.SpawnPoint(baseIndex)).Magnitude < 10)
teleport(SAFE)

return { passed = #passed, failed = failed, temporaryProgress = true }
