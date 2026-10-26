--!strict
-- Shared tuning for MONSTER EGG ESCAPE. Server and client both read this module.
local Config = {}

Config.Version = 2
Config.DataStoreName = "MonsterEggEscape_v2"
Config.MaxPlayers = 8

-- Map layout (studs). The sanctuary sits between z = -80 and SafeZ; zones follow in a straight line.
Config.SafeZ = 80
Config.SanctuaryStart = -80
Config.ZoneLength = 180
Config.HalfWidth = 75
Config.WallHeight = 64
Config.SpawnPosition = Vector3.new(0, 0.5, -64)

-- Gameplay
Config.BaseWalkSpeed = 20
Config.NestSlots = 3
Config.NestRespawn = 10
Config.WakeTime = 1.5
Config.StealProtection = 2
Config.StealRange = 12
Config.ReturnSpeed = 16
Config.BankBonusSeconds = 10 -- instant cash on banking = income * this
Config.SellSeconds = 25 -- selling a banked egg pays income * this
Config.OfflineCapSeconds = 3 * 60 * 60
Config.OfflineRate = 0.25

Config.SpeedPerLevel = 1.5
Config.MaxSpeedLevel = 30
Config.TrainingCap = 600
Config.TrainingDivisor = 40 -- max +15 WalkSpeed from training
Config.StartCapacity = 8
Config.MaxCapacity = 32
Config.CapacityStep = 4
Config.MaxTreadLevel = 15

Config.Sounds = {
	Pickup = { Id = "rbxasset://sounds/action_get_up.mp3", Pitch = 1.6, Volume = 0.7 },
	Bank = { Id = "rbxasset://sounds/action_jump_land.mp3", Pitch = 0.8, Volume = 1 },
	Buy = { Id = "rbxasset://sounds/volume_slider.ogg", Pitch = 1.2, Volume = 1 },
	Roar = { Id = "rbxasset://sounds/impact_explosion_03.mp3", Pitch = 0.45, Volume = 0.8 },
	Caught = { Id = "rbxasset://sounds/impact_explosion_03.mp3", Pitch = 1.1, Volume = 0.6 },
	Steal = { Id = "rbxasset://sounds/action_jump.mp3", Pitch = 1.4, Volume = 0.8 },
}

export type Zone = {
	Name: string,
	Monster: string,
	Color: Color3,
	Accent: Color3,
	Ground: Color3,
	Wall: Color3,
	WallAlt: Color3,
	Trim: Color3,
	Fog: Color3,
	Speed: number,
	Income: number,
	Reach: number,
}

Config.Zones = {
	{
		Name = "Forest", Monster = "Bramble Beast",
		Color = Color3.fromRGB(76, 201, 92), Accent = Color3.fromRGB(255, 214, 92),
		Ground = Color3.fromRGB(96, 196, 74), Wall = Color3.fromRGB(214, 128, 92), WallAlt = Color3.fromRGB(196, 110, 80),
		Trim = Color3.fromRGB(70, 178, 64), Fog = Color3.fromRGB(190, 236, 200),
		Speed = 18, Income = 2, Reach = 8,
	},
	{
		Name = "Desert", Monster = "Dune Scorpion",
		Color = Color3.fromRGB(246, 196, 92), Accent = Color3.fromRGB(196, 92, 52),
		Ground = Color3.fromRGB(240, 206, 128), Wall = Color3.fromRGB(226, 168, 98), WallAlt = Color3.fromRGB(208, 150, 84),
		Trim = Color3.fromRGB(250, 222, 150), Fog = Color3.fromRGB(255, 228, 180),
		Speed = 23, Income = 6, Reach = 8,
	},
	{
		Name = "Ice", Monster = "Frost Yeti",
		Color = Color3.fromRGB(110, 210, 255), Accent = Color3.fromRGB(220, 248, 255),
		Ground = Color3.fromRGB(212, 238, 252), Wall = Color3.fromRGB(128, 176, 226), WallAlt = Color3.fromRGB(112, 160, 212),
		Trim = Color3.fromRGB(245, 252, 255), Fog = Color3.fromRGB(205, 232, 255),
		Speed = 28, Income = 15, Reach = 8.5,
	},
	{
		Name = "Lava", Monster = "Magma Drake",
		Color = Color3.fromRGB(255, 104, 46), Accent = Color3.fromRGB(255, 214, 64),
		Ground = Color3.fromRGB(74, 52, 58), Wall = Color3.fromRGB(92, 58, 62), WallAlt = Color3.fromRGB(78, 48, 54),
		Trim = Color3.fromRGB(255, 120, 40), Fog = Color3.fromRGB(255, 150, 110),
		Speed = 33, Income = 40, Reach = 9,
	},
	{
		Name = "Toxic", Monster = "Sludge Mech",
		Color = Color3.fromRGB(162, 255, 46), Accent = Color3.fromRGB(140, 70, 200),
		Ground = Color3.fromRGB(92, 52, 130), Wall = Color3.fromRGB(70, 36, 104), WallAlt = Color3.fromRGB(58, 120, 40),
		Trim = Color3.fromRGB(150, 245, 60), Fog = Color3.fromRGB(170, 230, 120),
		Speed = 38, Income = 100, Reach = 9,
	},
	{
		Name = "Shadow", Monster = "Void Reaper",
		Color = Color3.fromRGB(176, 92, 255), Accent = Color3.fromRGB(70, 230, 255),
		Ground = Color3.fromRGB(42, 30, 66), Wall = Color3.fromRGB(46, 34, 74), WallAlt = Color3.fromRGB(36, 26, 60),
		Trim = Color3.fromRGB(180, 100, 255), Fog = Color3.fromRGB(120, 80, 170),
		Speed = 44, Income = 260, Reach = 9.5,
	},
} :: { Zone }

export type Rarity = { Name: string, Color: Color3, Shade: Color3, Weight: number, Multiplier: number }

Config.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(226, 230, 238), Shade = Color3.fromRGB(176, 184, 198), Weight = 50, Multiplier = 1 },
	{ Name = "Uncommon", Color = Color3.fromRGB(110, 232, 120), Shade = Color3.fromRGB(56, 170, 84), Weight = 25, Multiplier = 2 },
	{ Name = "Rare", Color = Color3.fromRGB(80, 170, 255), Shade = Color3.fromRGB(40, 104, 214), Weight = 13, Multiplier = 4 },
	{ Name = "Epic", Color = Color3.fromRGB(184, 98, 255), Shade = Color3.fromRGB(116, 50, 200), Weight = 7, Multiplier = 8 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 196, 46), Shade = Color3.fromRGB(226, 128, 24), Weight = 3.5, Multiplier = 16 },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 74, 104), Shade = Color3.fromRGB(176, 24, 70), Weight = 1.2, Multiplier = 35 },
	{ Name = "Divine", Color = Color3.fromRGB(255, 246, 196), Shade = Color3.fromRGB(255, 170, 232), Weight = 0.3, Multiplier = 80 },
} :: { Rarity }

Config.RageRarity = 4 -- Epic and above enrage the guardian
Config.ChargeRarity = 5 -- Legendary and above add charge dashes

export type Trail = { Name: string, Cost: number, Multiplier: number, Colors: { Color3 } }

Config.Trails = {
	{ Name = "Mint", Cost = 250, Multiplier = 1.1, Colors = { Color3.fromRGB(120, 255, 200), Color3.fromRGB(60, 210, 160) } },
	{ Name = "Ocean", Cost = 1500, Multiplier = 1.2, Colors = { Color3.fromRGB(80, 200, 255), Color3.fromRGB(40, 90, 255) } },
	{ Name = "Prism", Cost = 8000, Multiplier = 1.3, Colors = { Color3.fromRGB(255, 90, 200), Color3.fromRGB(90, 220, 255) } },
	{ Name = "Solar", Cost = 40000, Multiplier = 1.45, Colors = { Color3.fromRGB(255, 230, 80), Color3.fromRGB(255, 110, 40) } },
	{ Name = "Void", Cost = 200000, Multiplier = 1.6, Colors = { Color3.fromRGB(190, 100, 255), Color3.fromRGB(30, 10, 60) } },
	{ Name = "Divine", Cost = 1000000, Multiplier = 1.8, Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 200, 240) } },
} :: { Trail }

Config.Treadmills = {
	{ Name = "Basic", Cost = 0, Power = 1, Color = Color3.fromRGB(80, 220, 255) },
	{ Name = "Turbo", Cost = 1500, Power = 3, Color = Color3.fromRGB(255, 196, 46) },
	{ Name = "Hyper", Cost = 20000, Power = 8, Color = Color3.fromRGB(255, 80, 200) },
}

function Config.SpeedCost(level: number): number
	return math.floor(60 * (level + 1) ^ 2.1)
end

function Config.StorageCost(capacity: number): number
	return math.floor(400 * 3 ^ ((capacity - Config.StartCapacity) / Config.CapacityStep))
end

function Config.TreadCost(level: number): number
	return math.floor(250 * 2.2 ^ level)
end

function Config.TreadPower(tier: number, level: number): number
	return Config.Treadmills[tier].Power * (1 + 0.25 * level)
end

function Config.EggIncome(zone: number, rarity: number): number
	return Config.Zones[zone].Income * Config.Rarities[rarity].Multiplier
end

-- Deeper zones shift the weights toward rarer eggs.
function Config.RarityWeights(zone: number): { number }
	local luck = 1 + (zone - 1) * 0.12
	local weights = {}
	for index, rarity in Config.Rarities do
		weights[index] = rarity.Weight * luck ^ (index - 1)
	end
	return weights
end

function Config.RollRarity(zone: number, rng: Random): number
	local weights = Config.RarityWeights(zone)
	local total = 0
	for _, w in weights do
		total += w
	end
	local roll = rng:NextNumber(0, total)
	for index, w in weights do
		roll -= w
		if roll <= 0 then
			return index
		end
	end
	return 1
end

function Config.WalkSpeed(speedLevel: number, training: number, trail: number): number
	local base = Config.BaseWalkSpeed + speedLevel * Config.SpeedPerLevel
		+ math.min(training, Config.TrainingCap) / Config.TrainingDivisor
	local multiplier = if trail > 0 then Config.Trails[trail].Multiplier else 1
	return base * multiplier
end

function Config.ZoneStart(index: number): number
	return Config.SafeZ + (index - 1) * Config.ZoneLength
end

function Config.ZoneCenter(index: number): number
	return Config.ZoneStart(index) + Config.ZoneLength / 2
end

-- Returns 0 inside the sanctuary, otherwise the zone index.
function Config.ZoneAt(z: number): number
	if z <= Config.SafeZ then
		return 0
	end
	return math.clamp(math.floor((z - Config.SafeZ) / Config.ZoneLength) + 1, 1, #Config.Zones)
end

function Config.NestCenter(index: number): Vector3
	return Vector3.new(0, 0, Config.ZoneStart(index) + 112)
end

function Config.NestSlot(index: number, slot: number): Vector3
	local center = Config.NestCenter(index)
	return center + Vector3.new((slot - 2) * 6.5, 2.9, if slot == 2 then -1.5 else 0)
end

function Config.GuardianHome(index: number): CFrame
	local center = Config.NestCenter(index)
	-- Sleeps behind its nest, facing the sanctuary.
	local position = center + Vector3.new(0, 0, 17)
	return CFrame.lookAt(position, position - Vector3.zAxis)
end

local suffixes = { "", "K", "M", "B", "T", "Qd", "Qn" }
function Config.Format(value: number): string
	value = math.floor(value)
	if value < 1000 then
		return tostring(value)
	end
	local tier = math.min(math.floor(math.log10(value) / 3), #suffixes - 1)
	local scaled = value / 10 ^ (tier * 3)
	local text = if scaled >= 100 then string.format("%d", scaled) else string.format("%.1f", scaled)
	text = text:gsub("%.0$", "")
	return text .. suffixes[tier + 1]
end

return Config
