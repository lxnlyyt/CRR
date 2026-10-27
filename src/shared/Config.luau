--!strict
-- Shared tuning for MONSTER EGG ESCAPE. Server and client both read this module.
local Config = {}

Config.Version = 2
Config.DataStoreName = "MonsterEggEscape_v2"
Config.MaxPlayers = 7 -- one personal base per player

-- Map layout (studs). The sanctuary sits between z = -100 and SafeZ; zones follow in a straight line.
Config.SafeZ = 80
Config.SanctuaryStart = -100
Config.ZoneLength = 180
Config.HalfWidth = 75
Config.WallHeight = 64
Config.SpawnPosition = Vector3.new(0, 0.5, -90) -- fallback; players spawn at their own base

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
Config.TreadSpeedPerLevel = 1.2 -- permanent WalkSpeed per treadmill level above 1

-- One look per treadmill level: frame colour, glowing accent. Higher levels add more features.
Config.TreadmillDesigns = {
	{ Name = "Rusty", Frame = Color3.fromRGB(150, 110, 80), Accent = Color3.fromRGB(230, 170, 100) },
	{ Name = "Steel", Frame = Color3.fromRGB(120, 130, 150), Accent = Color3.fromRGB(205, 220, 240) },
	{ Name = "Mint", Frame = Color3.fromRGB(60, 160, 120), Accent = Color3.fromRGB(130, 255, 200) },
	{ Name = "Ocean", Frame = Color3.fromRGB(40, 100, 180), Accent = Color3.fromRGB(90, 200, 255) },
	{ Name = "Neon", Frame = Color3.fromRGB(40, 40, 70), Accent = Color3.fromRGB(80, 255, 240) },
	{ Name = "Electric", Frame = Color3.fromRGB(40, 50, 120), Accent = Color3.fromRGB(130, 170, 255) },
	{ Name = "Sunset", Frame = Color3.fromRGB(200, 90, 60), Accent = Color3.fromRGB(255, 190, 80) },
	{ Name = "Gold", Frame = Color3.fromRGB(190, 140, 30), Accent = Color3.fromRGB(255, 225, 100) },
	{ Name = "Ruby", Frame = Color3.fromRGB(150, 20, 50), Accent = Color3.fromRGB(255, 80, 120) },
	{ Name = "Emerald", Frame = Color3.fromRGB(20, 120, 60), Accent = Color3.fromRGB(80, 255, 140) },
	{ Name = "Amethyst", Frame = Color3.fromRGB(90, 40, 150), Accent = Color3.fromRGB(200, 120, 255) },
	{ Name = "Inferno", Frame = Color3.fromRGB(120, 30, 10), Accent = Color3.fromRGB(255, 120, 30) },
	{ Name = "Galaxy", Frame = Color3.fromRGB(25, 15, 60), Accent = Color3.fromRGB(150, 110, 255) },
	{ Name = "Prism", Frame = Color3.fromRGB(235, 235, 250), Accent = Color3.fromRGB(255, 120, 220) },
	{ Name = "Divine", Frame = Color3.fromRGB(235, 195, 110), Accent = Color3.fromRGB(255, 225, 120) },
}

Config.BaseColors = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(110, 185, 255),
	Color3.fromRGB(130, 225, 110),
	Color3.fromRGB(255, 200, 90),
	Color3.fromRGB(195, 135, 255),
	Color3.fromRGB(100, 225, 215),
	Color3.fromRGB(255, 145, 205),
}

-- Sound effects and music generated with ForgeGUI and published to the creator's Roblox account.
Config.Sounds = {
	Pickup = { Id = "rbxassetid://70816746495935", Volume = 0.8 },
	Bank = { Id = "rbxassetid://138197500459499", Volume = 0.9 },
	Buy = { Id = "rbxassetid://119333597820380", Volume = 0.8 },
	Roar = { Id = "rbxassetid://128210121110691", Volume = 1 },
	Caught = { Id = "rbxassetid://123522285214631", Volume = 0.9 },
	Steal = { Id = "rbxassetid://91124564703227", Volume = 0.8 },
	LevelUp = { Id = "rbxassetid://127804802043960", Volume = 0.9 },
}

Config.Music = {
	Volume = 0.3,
	Sanctuary = "rbxassetid://88050341791687",
	Zones = {
		"rbxassetid://123352044620881", -- Forest
		"rbxassetid://137680556724186", -- Desert
		"rbxassetid://127572275830794", -- Ice
		"rbxassetid://118189778938559", -- Lava
		"rbxassetid://120719828334063", -- Toxic
		"rbxassetid://133369860649713", -- Shadow
	},
}

-- HUD icons generated with ForgeGUI (transparent PNGs published as Roblox images).
Config.Icons = {
	Coin = "rbxassetid://93798547146982",
	Egg = "rbxassetid://113334298264334",
	Speed = "rbxassetid://122080941241155",
	Trail = "rbxassetid://123178772277358",
	Rage = "rbxassetid://75951493333340",
	Shop = "SHOP_ICON",
	Index = "rbxassetid://116639459091707",
	Rewards = "REWARDS_ICON",
	Settings = "SETTINGS_ICON",
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
	MeshId: string, -- AI-generated guardian mesh (Studio generate_mesh)
	TextureId: string,
	MeshYaw: number, -- turns the mesh so its face looks down -Z
	Height: number,
	Nest: Vector2, -- nest position: X across the corridor, Y = depth into the zone
	Landmark: { AssetId: number, Height: number, Spot: Vector2 }, -- ForgeGUI model (0 = none yet)
}

Config.Zones = {
	{
		Name = "Forest", Monster = "Mossmaw",
		Color = Color3.fromRGB(76, 201, 92), Accent = Color3.fromRGB(255, 214, 92),
		Ground = Color3.fromRGB(96, 196, 74), Wall = Color3.fromRGB(214, 128, 92), WallAlt = Color3.fromRGB(196, 110, 80),
		Trim = Color3.fromRGB(70, 178, 64), Fog = Color3.fromRGB(190, 236, 200),
		Speed = 18, Income = 2, Reach = 8,
		MeshId = "rbxassetid://100729813706841", TextureId = "rbxassetid://126990797373067", MeshYaw = 0, Height = 13, Nest = Vector2.new(-30, 70),
		Landmark = { AssetId = 0, Height = 26, Spot = Vector2.new(44, 120) },
	},
	{
		Name = "Desert", Monster = "Dune Gloop",
		Color = Color3.fromRGB(246, 196, 92), Accent = Color3.fromRGB(196, 92, 52),
		Ground = Color3.fromRGB(240, 206, 128), Wall = Color3.fromRGB(226, 168, 98), WallAlt = Color3.fromRGB(208, 150, 84),
		Trim = Color3.fromRGB(250, 222, 150), Fog = Color3.fromRGB(255, 228, 180),
		Speed = 23, Income = 6, Reach = 8,
		MeshId = "rbxassetid://129056952654925", TextureId = "rbxassetid://118340515848657", MeshYaw = 0, Height = 12, Nest = Vector2.new(28, 100),
		Landmark = { AssetId = 0, Height = 22, Spot = Vector2.new(-46, 88) },
	},
	{
		Name = "Ice", Monster = "Frostgloop",
		Color = Color3.fromRGB(110, 210, 255), Accent = Color3.fromRGB(220, 248, 255),
		Ground = Color3.fromRGB(212, 238, 252), Wall = Color3.fromRGB(128, 176, 226), WallAlt = Color3.fromRGB(112, 160, 212),
		Trim = Color3.fromRGB(245, 252, 255), Fog = Color3.fromRGB(205, 232, 255),
		Speed = 28, Income = 15, Reach = 8.5,
		MeshId = "rbxassetid://103432994982097", TextureId = "rbxassetid://123146596024982", MeshYaw = 0, Height = 14, Nest = Vector2.new(-26, 138),
		Landmark = { AssetId = 97776129887795, Height = 30, Spot = Vector2.new(46, 45) },
	},
	{
		Name = "Lava", Monster = "Magma Maw",
		Color = Color3.fromRGB(255, 104, 46), Accent = Color3.fromRGB(255, 214, 64),
		Ground = Color3.fromRGB(74, 52, 58), Wall = Color3.fromRGB(92, 58, 62), WallAlt = Color3.fromRGB(78, 48, 54),
		Trim = Color3.fromRGB(255, 120, 40), Fog = Color3.fromRGB(255, 150, 110),
		Speed = 33, Income = 40, Reach = 9,
		MeshId = "rbxassetid://80319563283730", TextureId = "rbxassetid://112963067084381", MeshYaw = 0, Height = 14, Nest = Vector2.new(20, 92),
		Landmark = { AssetId = 120889398323352, Height = 22, Spot = Vector2.new(-24, 150) },
	},
	{
		Name = "Toxic", Monster = "Sludge King",
		Color = Color3.fromRGB(162, 255, 46), Accent = Color3.fromRGB(140, 70, 200),
		Ground = Color3.fromRGB(92, 52, 130), Wall = Color3.fromRGB(70, 36, 104), WallAlt = Color3.fromRGB(58, 120, 40),
		Trim = Color3.fromRGB(150, 245, 60), Fog = Color3.fromRGB(170, 230, 120),
		Speed = 38, Income = 100, Reach = 9,
		MeshId = "rbxassetid://94540360805246", TextureId = "rbxassetid://116288831429704", MeshYaw = 0, Height = 15, Nest = Vector2.new(-30, 86),
		Landmark = { AssetId = 78189333204811, Height = 24, Spot = Vector2.new(42, 85) },
	},
	{
		Name = "Shadow", Monster = "Void Gloom",
		Color = Color3.fromRGB(176, 92, 255), Accent = Color3.fromRGB(70, 230, 255),
		Ground = Color3.fromRGB(42, 30, 66), Wall = Color3.fromRGB(46, 34, 74), WallAlt = Color3.fromRGB(36, 26, 60),
		Trim = Color3.fromRGB(180, 100, 255), Fog = Color3.fromRGB(120, 80, 170),
		Speed = 44, Income = 260, Reach = 9.5,
		MeshId = "rbxassetid://123214066275963", TextureId = "rbxassetid://87795194151672", MeshYaw = math.pi / 2, Height = 13, Nest = Vector2.new(26, 124),
		Landmark = { AssetId = 72214084210424, Height = 28, Spot = Vector2.new(-44, 125) },
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

export type Trail = {
	Name: string,
	Rarity: string, -- matches a Config.Rarities name, used for the card colours
	Cost: number,
	Multiplier: number,
	Colors: { Color3 },
	Robux: number, -- display price; the real price comes from the developer product
	ProductId: number, -- Roblox developer product id (0 = Robux purchase not set up yet)
}

Config.Trails = {
	{ Name = "Mint", Rarity = "Common", Cost = 250, Multiplier = 1.1, Robux = 25, ProductId = 0, Colors = { Color3.fromRGB(120, 255, 200), Color3.fromRGB(60, 210, 160) } },
	{ Name = "Ocean", Rarity = "Uncommon", Cost = 1500, Multiplier = 1.2, Robux = 49, ProductId = 0, Colors = { Color3.fromRGB(80, 200, 255), Color3.fromRGB(40, 90, 255) } },
	{ Name = "Prism", Rarity = "Rare", Cost = 8000, Multiplier = 1.3, Robux = 99, ProductId = 0, Colors = { Color3.fromRGB(255, 90, 200), Color3.fromRGB(90, 220, 255) } },
	{ Name = "Solar", Rarity = "Epic", Cost = 40000, Multiplier = 1.45, Robux = 199, ProductId = 0, Colors = { Color3.fromRGB(255, 230, 80), Color3.fromRGB(255, 110, 40) } },
	{ Name = "Void", Rarity = "Legendary", Cost = 200000, Multiplier = 1.6, Robux = 399, ProductId = 0, Colors = { Color3.fromRGB(190, 100, 255), Color3.fromRGB(30, 10, 60) } },
	{ Name = "Divine", Rarity = "Divine", Cost = 1000000, Multiplier = 1.8, Robux = 799, ProductId = 0, Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 200, 240) } },
} :: { Trail }

function Config.RarityInfo(name: string): Rarity
	for _, rarity in Config.Rarities do
		if rarity.Name == name then
			return rarity
		end
	end
	return Config.Rarities[1]
end

-- Free gift from the Rewards menu.
Config.RewardCooldown = 15 * 60
function Config.RewardCash(incomePerSecond: number): number
	return math.max(500, math.floor(incomePerSecond * 120))
end

function Config.SpeedCost(level: number): number
	return math.floor(60 * (level + 1) ^ 2.1)
end

function Config.StorageCost(capacity: number): number
	return math.floor(400 * 3 ^ ((capacity - Config.StartCapacity) / Config.CapacityStep))
end

-- Cost to upgrade a treadmill from `level` to `level + 1`.
function Config.TreadCost(level: number): number
	return math.floor(200 * 1.85 ^ (level - 1))
end

-- Training points per second while running on your own treadmill.
function Config.TreadPower(level: number): number
	return level
end

function Config.TreadCash(level: number, speedLevel: number): number
	return 2 * level + speedLevel
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

function Config.WalkSpeed(speedLevel: number, training: number, trail: number, treadLevel: number): number
	local base = Config.BaseWalkSpeed + speedLevel * Config.SpeedPerLevel
		+ math.min(training, Config.TrainingCap) / Config.TrainingDivisor
		+ (math.max(treadLevel, 1) - 1) * Config.TreadSpeedPerLevel
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
	local nest = Config.Zones[index].Nest
	return Vector3.new(nest.X, 0, Config.ZoneStart(index) + nest.Y)
end

function Config.NestSlot(index: number, slot: number): Vector3
	local center = Config.NestCenter(index)
	return center + Vector3.new((slot - 2) * 6.5, 2.9, if slot == 2 then -1.5 else 0)
end

function Config.GuardianHome(index: number): CFrame
	local center = Config.NestCenter(index)
	-- Sleeps beside its nest (wall side), looking out over the path toward the sanctuary.
	local side = if center.X < 0 then -1 else 1
	local position = center + Vector3.new(side * 12, 0, 14)
	return CFrame.lookAt(position, Vector3.new(center.X * 0.3, 0, position.Z - 40))
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
