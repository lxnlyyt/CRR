-- Builds the static map: sanctuary (safe zone), plots, treadmills, shops and six themed zones.
local Lighting = game:GetService("Lighting")

local Config = require(script.Parent.Config)
local Style = require(script.Parent.Style)
local Eggs = require(script.Parent.Eggs)
local Monsters = require(script.Parent.Monsters)

local P = Style.Part
local W = {}

W.RootName = "MonsterEggEscape"
W.Treadmills = {
	{ Tier = 1, Center = Vector3.new(-20, 0, -14) },
	{ Tier = 2, Center = Vector3.new(0, 0, -14) },
	{ Tier = 3, Center = Vector3.new(20, 0, -14) },
}
W.TreadmillSize = Vector3.new(10, 1.2, 16)
W.Boards = {
	Speed = Vector3.new(-27, 0, -44),
	Storage = Vector3.new(-9, 0, -44),
	Power = Vector3.new(9, 0, -44),
	Info = Vector3.new(27, 0, -44),
}
W.ShopPosition = Vector3.new(-24, 0, 34)
W.IndexPosition = Vector3.new(24, 0, 34)
W.PlotColumns = 6

local WOOD = Color3.fromRGB(158, 104, 60)
local WOOD_LIGHT = Color3.fromRGB(196, 140, 84)
local NAVY = Color3.fromRGB(34, 30, 70)
local SAFE = Color3.fromRGB(80, 255, 170)

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function noCollide(part: BasePart): BasePart
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- Plot geometry ---------------------------------------------------------------

function W.PlotLayout(index: number)
	local side = if index % 2 == 1 then -1 else 1
	local row = math.floor((index - 1) / 2)
	return side, Vector3.new(side * 52, 0, -52 + row * 32)
end

function W.SlotPosition(index: number, slot: number): Vector3
	local _, center = W.PlotLayout(index)
	local col = (slot - 1) % W.PlotColumns
	local row = math.floor((slot - 1) / W.PlotColumns)
	return center + Vector3.new((col - 2.5) * 4.4, 2.2, (row - 2.5) * 3.9)
end

-- Reusable props ----------------------------------------------------------------

local function board(parent: Instance, name: string, position: Vector3, color: Color3, title: string, subtitle: string?): Part
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local face = P(model, "Board", Vector3.new(11, 7, 0.8), CFrame.new(position + Vector3.new(0, 6.5, 0)), color)
	Style.Studs(face)
	for _, x in { -5.9, 5.9 } do
		P(model, "Post", Vector3.new(0.9, 10, 0.9), CFrame.new(position + Vector3.new(x, 5, 0)), Style.Darken(color, 0.45))
	end
	P(model, "Trim", Vector3.new(11.6, 0.4, 1), CFrame.new(position + Vector3.new(0, 10.1, 0)), Style.Lighten(color, 0.5), Enum.Material.Neon)
	P(model, "Trim", Vector3.new(11.6, 0.4, 1), CFrame.new(position + Vector3.new(0, 2.9, 0)), Style.Lighten(color, 0.5), Enum.Material.Neon)
	local titleLabel, sub = Style.Sign(face, title, subtitle or " ", Color3.new(1, 1, 1), Enum.NormalId.Front, 36)
	titleLabel.Name = "Title"
	if sub then
		sub.Name = "Price"
	end
	model.PrimaryPart = face
	return face
end

local function fenceLine(parent: Instance, from: Vector3, to: Vector3, height: number)
	local delta = to - from
	local length = delta.Magnitude
	local posts = math.max(2, math.floor(length / 4.5) + 1)
	for n = 0, posts - 1 do
		local at = from + delta * (n / (posts - 1))
		local post = P(parent, "FencePost", Vector3.new(0.9, height + 0.6, 0.9), CFrame.new(at + Vector3.new(0, (height + 0.6) / 2, 0)), WOOD)
		Style.Studs(post)
	end
	local mid = (from + to) / 2
	local cf = CFrame.lookAt(mid, mid + delta)
	for _, y in { height * 0.38, height * 0.85 } do
		P(parent, "FenceRail", Vector3.new(0.45, 0.6, length), cf + Vector3.new(0, y, 0), WOOD_LIGHT)
	end
end

-- Sanctuary -------------------------------------------------------------------------

local function buildPlot(parent: Instance, index: number)
	local side, center = W.PlotLayout(index)
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	plot:SetAttribute("Owner", 0)
	plot:SetAttribute("Index", index)
	plot.Parent = parent

	local floor = P(plot, "Floor", Vector3.new(30, 0.6, 26), CFrame.new(center + Vector3.new(0, 0.3, 0)), Color3.fromRGB(118, 204, 92))
	Style.Studs(floor)
	local path = P(plot, "Entry", Vector3.new(4, 0.62, 8), CFrame.new(center + Vector3.new(-side * 13, 0.31, 0)), Color3.fromRGB(214, 186, 132))
	Style.Studs(path)

	local outer, inner = center.X + side * 15, center.X - side * 15
	local back, front = center.Z - 13, center.Z + 13
	fenceLine(plot, Vector3.new(outer, 0.6, back), Vector3.new(outer, 0.6, front), 3.2)
	fenceLine(plot, Vector3.new(inner, 0.6, back), Vector3.new(outer, 0.6, back), 3.2)
	fenceLine(plot, Vector3.new(inner, 0.6, front), Vector3.new(outer, 0.6, front), 3.2)
	fenceLine(plot, Vector3.new(inner, 0.6, back), Vector3.new(inner, 0.6, center.Z - 4), 3.2)
	fenceLine(plot, Vector3.new(inner, 0.6, center.Z + 4), Vector3.new(inner, 0.6, front), 3.2)

	-- Arch over the open entrance with the owner's name.
	for _, dz in { -4.6, 4.6 } do
		local pillar = P(plot, "GatePost", Vector3.new(1.4, 9, 1.4), CFrame.new(inner, 4.8, center.Z + dz), WOOD)
		Style.Studs(pillar)
	end
	local sign = P(plot, "OwnerSign", Vector3.new(0.8, 2.6, 11), CFrame.new(inner, 9.6, center.Z), WOOD_LIGHT)
	Style.Studs(sign)
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local title = Style.Sign(sign, "EMPTY PLOT", nil, Color3.fromRGB(255, 240, 200), face, 30)
		title.Name = "Owner"
	end
	local label = Style.Label(floor, "Free plot", Color3.fromRGB(220, 255, 220), 14, 2.2, 12)
	label.Name = "Income"
	label.MaxDistance = 90

	-- Hay nests mark every possible slot.
	for slot = 1, Config.MaxCapacity do
		local at = W.SlotPosition(index, slot)
		local pad = Style.Cylinder(plot, "Pad", 0.3, 3.2, CFrame.new(at.X, 0.72, at.Z), Color3.fromRGB(226, 196, 120))
		noCollide(pad)
	end
	plot.PrimaryPart = floor
	return plot
end

local function buildTreadmill(parent: Instance, info)
	local tier = Config.Treadmills[info.Tier]
	local model = Instance.new("Model")
	model.Name = "Treadmill" .. info.Tier
	model:SetAttribute("Tier", info.Tier)
	model.Parent = parent
	local c = info.Center
	local base = P(model, "Base", Vector3.new(11, 1, 17), CFrame.new(c + Vector3.new(0, 0.5, 0)), Color3.fromRGB(44, 48, 70))
	Style.Studs(base)
	local belt = P(model, "Belt", Vector3.new(8.4, 0.3, 15), CFrame.new(c + Vector3.new(0, 1.12, 0)), Color3.fromRGB(26, 26, 34))
	for _, face in { Enum.NormalId.Top } do
		local t = Instance.new("Texture")
		t.Name = "Stripes"
		t.Texture = Style.CheckerTexture
		t.Face = face
		t.StudsPerTileU = 8.4
		t.StudsPerTileV = 3
		t.Color3 = tier.Color
		t.Transparency = 0.55
		t.Parent = belt
	end
	for _, x in { -4.9, 4.9 } do
		P(model, "Rail", Vector3.new(0.7, 0.6, 17), CFrame.new(c + Vector3.new(x, 1.3, 0)), tier.Color, Enum.Material.Neon)
		P(model, "Handle", Vector3.new(0.5, 3.6, 0.5), CFrame.new(c + Vector3.new(x, 3, 7.4)), Color3.fromRGB(70, 76, 100), Enum.Material.Metal)
	end
	P(model, "HandleBar", Vector3.new(10.3, 0.5, 0.5), CFrame.new(c + Vector3.new(0, 4.8, 7.4)), Color3.fromRGB(70, 76, 100), Enum.Material.Metal)
	local screen = P(model, "Console", Vector3.new(7, 3, 0.6), CFrame.new(c + Vector3.new(0, 6.6, 8.2)) * CFrame.Angles(-0.35, 0, 0), Color3.fromRGB(26, 28, 44))
	Style.Sign(screen, tier.Name:upper(), "x" .. tier.Power .. " TRAINING", tier.Color, Enum.NormalId.Front, 40)
	local lock = P(model, "Lock", Vector3.new(9, 6, 15), CFrame.new(c + Vector3.new(0, 4.3, 0)), tier.Color, Enum.Material.ForceField)
	lock.Transparency = if info.Tier == 1 then 1 else 0.55
	lock.CanCollide = false
	lock.CanQuery = false
	if info.Tier > 1 then
		local lockLabel = Style.Label(lock, "LOCKED\n$" .. Config.Format(tier.Cost), tier.Color, 8, 3, 1)
		lockLabel.Name = "LockLabel"
	end
	model.PrimaryPart = base
	return model
end

local function buildShop(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "TrailShop"
	model.Parent = parent
	local c = W.ShopPosition
	local counter = P(model, "Counter", Vector3.new(14, 3.4, 4), CFrame.new(c + Vector3.new(0, 1.7, -2)), Color3.fromRGB(255, 120, 190))
	Style.Studs(counter)
	P(model, "CounterTop", Vector3.new(14.6, 0.5, 4.6), CFrame.new(c + Vector3.new(0, 3.65, -2)), Color3.fromRGB(255, 240, 250))
	for _, x in { -6.8, 6.8 } do
		for _, z in { -3.8, 3.8 } do
			P(model, "Pole", Vector3.new(0.8, 11, 0.8), CFrame.new(c + Vector3.new(x, 5.5, z)), Color3.new(1, 1, 1))
		end
	end
	for n = 0, 7 do
		local stripe = P(model, "Awning", Vector3.new(2, 0.8, 10), CFrame.new(c + Vector3.new(-7 + n * 2, 11.4, 0)) * CFrame.Angles(0.12, 0, 0),
			if n % 2 == 0 then Color3.fromRGB(255, 90, 170) else Color3.new(1, 1, 1))
		Style.Studs(stripe)
	end
	local sign = P(model, "Sign", Vector3.new(15, 3.4, 0.8), CFrame.new(c + Vector3.new(0, 14, -4.2)), NAVY)
	Style.Sign(sign, "TRAIL SHOP", nil, Color3.fromRGB(255, 160, 220), Enum.NormalId.Front, 30)
	for i, trail in Config.Trails do
		local orb = P(model, "TrailOrb", Vector3.new(1.4, 1.4, 1.4), CFrame.new(c + Vector3.new(-6.2 + (i - 1) * 2.5, 5, -2)), trail.Colors[1], Enum.Material.Neon, Enum.PartType.Ball)
		noCollide(orb)
	end
	local promptPart = P(model, "PromptPart", Vector3.new(2, 2, 2), CFrame.new(c + Vector3.new(0, 3, -4.6)), Color3.new(1, 1, 1))
	promptPart.Transparency = 1
	noCollide(promptPart)
	model.PrimaryPart = counter
	return model
end

local function buildIndex(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "EggIndex"
	model.Parent = parent
	local c = W.IndexPosition
	local face = P(model, "Board", Vector3.new(14, 12, 0.8), CFrame.new(c + Vector3.new(0, 8, 0)), NAVY)
	for _, x in { -7.4, 7.4 } do
		P(model, "Post", Vector3.new(1, 14, 1), CFrame.new(c + Vector3.new(x, 7, 0)), Color3.fromRGB(80, 70, 140))
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = face
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = gui
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.Font = Style.Font
	header.TextScaled = true
	header.Text = "EGG RARITIES"
	header.TextColor3 = Color3.fromRGB(255, 220, 100)
	header.Parent = gui
	for _, rarity in Config.Rarities do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(0.92, 0, 0, 40)
		row.BackgroundTransparency = 1
		row.Font = Style.Font
		row.TextScaled = true
		row.Text = string.format("%s  •  x%d income", rarity.Name, rarity.Multiplier)
		row.TextColor3 = rarity.Color
		row.Parent = gui
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = Style.Ink
		s.Parent = row
	end
	local footer = header:Clone()
	footer.Size = UDim2.new(0.92, 0, 0, 34)
	footer.Text = "Deeper zones = rarer eggs!"
	footer.TextColor3 = Color3.fromRGB(150, 255, 200)
	footer.Parent = gui
	return model
end

local function buildSanctuary(root: Instance)
	local hub = folder(root, "Sanctuary")
	local length = Config.SafeZ - Config.SanctuaryStart
	local midZ = (Config.SafeZ + Config.SanctuaryStart) / 2
	local floor = P(hub, "Floor", Vector3.new(156, 4, length), CFrame.new(0, -2, midZ), Color3.fromRGB(120, 214, 196))
	Style.Checker(floor, 8, { Enum.NormalId.Top }, 0.86)
	local path = P(hub, "Path", Vector3.new(22, 0.2, length), CFrame.new(0, 0.1, midZ), Color3.fromRGB(236, 250, 244))
	Style.Checker(path, 5.5, { Enum.NormalId.Top }, 0.9)

	for _, x in { -1, 1 } do
		local wall = P(hub, "Wall", Vector3.new(6, Config.WallHeight, length + 6), CFrame.new(x * (Config.HalfWidth + 3), Config.WallHeight / 2, midZ - 3), Color3.fromRGB(110, 196, 236))
		Style.Checker(wall, 8, nil, 0.82)
		local trim = P(hub, "WallTrim", Vector3.new(8, 3, length + 6), CFrame.new(x * (Config.HalfWidth + 3), Config.WallHeight + 1.5, midZ - 3), Color3.fromRGB(96, 214, 96))
		Style.Studs(trim)
		P(hub, "Glow", Vector3.new(0.4, 0.8, length), CFrame.new(x * (Config.HalfWidth - 0.1), 3, midZ), SAFE, Enum.Material.Neon)
	end
	local rear = P(hub, "RearWall", Vector3.new(Config.HalfWidth * 2 + 12, Config.WallHeight, 6), CFrame.new(0, Config.WallHeight / 2, Config.SanctuaryStart - 3), Color3.fromRGB(110, 196, 236))
	Style.Checker(rear, 8, nil, 0.82)
	local rearTrim = P(hub, "RearTrim", Vector3.new(Config.HalfWidth * 2 + 12, 3, 8), CFrame.new(0, Config.WallHeight + 1.5, Config.SanctuaryStart - 3), Color3.fromRGB(96, 214, 96))
	Style.Studs(rearTrim)

	-- Title board with giant eggs.
	local title = P(hub, "TitleBoard", Vector3.new(78, 20, 2), CFrame.new(0, 36, Config.SanctuaryStart + 0.6), NAVY)
	Style.Sign(title, "MONSTER EGG ESCAPE", "STEAL  •  RUN  •  GROW", Color3.fromRGB(255, 214, 80), Enum.NormalId.Front, 12)
	for _, edge in { { 0, 10.4, 79, 1 }, { 0, -10.4, 79, 1 }, { -39.6, 0, 1, 21.8 }, { 39.6, 0, 1, 21.8 } } do
		P(hub, "TitleGlow", Vector3.new(edge[3], edge[4], 1.4), CFrame.new(edge[1], 36 + edge[2], Config.SanctuaryStart + 1.2), Color3.fromRGB(255, 120, 200), Enum.Material.Neon)
	end
	for n, rarity in { 5, 7, 4 } do
		local egg = Eggs.Build(1 + n, rarity, CFrame.new((n - 2) * 34, 52, Config.SanctuaryStart + 2), { Scale = 2.6, Parent = hub })
		egg.Name = "GiantEgg"
		for _, part in egg:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SanctuarySpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(Config.SpawnPosition) * CFrame.Angles(0, math.pi, 0) -- face the zones
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(255, 214, 80)
	spawn.Material = Enum.Material.Plastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Parent = hub
	local ring = Style.Cylinder(hub, "SpawnRing", 0.3, 17, CFrame.new(Config.SpawnPosition - Vector3.new(0, 0.4, 0)), Color3.fromRGB(255, 120, 200), Enum.Material.Neon)
	noCollide(ring)

	-- Safe zone gate.
	local line = P(hub, "SafeLine", Vector3.new(Config.HalfWidth * 2, 0.3, 1.6), CFrame.new(0, 0.15, Config.SafeZ), SAFE, Enum.Material.Neon)
	noCollide(line)
	local barrier = P(hub, "SafeBarrier", Vector3.new(Config.HalfWidth * 2, 40, 0.4), CFrame.new(0, 20, Config.SafeZ), SAFE, Enum.Material.ForceField)
	barrier.Transparency = 0.5
	noCollide(barrier)
	for _, x in { -22, 22 } do
		local pillar = P(hub, "GatePillar", Vector3.new(6, 28, 6), CFrame.new(x, 14, Config.SafeZ), Color3.fromRGB(255, 255, 255))
		Style.Studs(pillar, true)
		P(hub, "GateCap", Vector3.new(7, 2, 7), CFrame.new(x, 29, Config.SafeZ), SAFE, Enum.Material.Neon)
	end
	local beam = P(hub, "GateBeam", Vector3.new(50, 7, 5), CFrame.new(0, 32, Config.SafeZ), Color3.fromRGB(40, 150, 110))
	Style.Studs(beam)
	Style.Sign(beam, "SAFE ZONE", "Monsters can't enter • Eggs are banked", Color3.fromRGB(180, 255, 220), Enum.NormalId.Front, 20)
	Style.Sign(beam, "SAFE ZONE", "Run back here with your egg!", Color3.fromRGB(180, 255, 220), Enum.NormalId.Back, 20)

	local plots = folder(hub, "Plots")
	for index = 1, Config.MaxPlayers do
		buildPlot(plots, index)
	end
	local treadmills = folder(hub, "Treadmills")
	for _, info in W.Treadmills do
		buildTreadmill(treadmills, info)
		if info.Tier > 1 then
			local tier = Config.Treadmills[info.Tier]
			board(treadmills, "UnlockBoard" .. info.Tier, info.Center + Vector3.new(0, 0, -12.5), tier.Color, "UNLOCK " .. tier.Name:upper(), "$" .. Config.Format(tier.Cost))
		end
	end
	local boards = folder(hub, "Boards")
	board(boards, "SpeedBoard", W.Boards.Speed, Color3.fromRGB(46, 160, 230), "SPEED +", "Loading...")
	board(boards, "StorageBoard", W.Boards.Storage, Color3.fromRGB(140, 90, 220), "STORAGE +4", "Loading...")
	board(boards, "PowerBoard", W.Boards.Power, Color3.fromRGB(255, 150, 40), "TREADMILL POWER", "Loading...")
	board(boards, "InfoBoard", W.Boards.Info, Color3.fromRGB(60, 190, 120), "HOW TO PLAY", "Steal eggs • Run back here")
	buildShop(hub)
	buildIndex(hub)

	-- Lamps and planters for life.
	for _, x in { -13, 13 } do
		for n = 0, 3 do
			local z = -30 + n * 30
			P(hub, "LampPost", Vector3.new(0.8, 9, 0.8), CFrame.new(x, 4.5, z), Color3.fromRGB(50, 52, 80))
			local lamp = P(hub, "Lamp", Vector3.new(1.8, 1.8, 1.8), CFrame.new(x, 9.6, z), Color3.fromRGB(255, 240, 180), Enum.Material.Neon, Enum.PartType.Ball)
			Style.Light(lamp, Color3.fromRGB(255, 230, 170), 1.2, 16)
		end
	end
	return hub
end

-- Zone decor ---------------------------------------------------------------------------

local function scatter(rng: Random, start: number, count: number, minX: number?, maxX: number?)
	local out = {}
	for n = 1, count do
		local side = if n % 2 == 0 then 1 else -1
		local x = side * rng:NextNumber(minX or 22, maxX or 68)
		local z = start + 10 + (n - 0.5) / count * (Config.ZoneLength - 20) + rng:NextNumber(-5, 5)
		table.insert(out, Vector3.new(x, 0, z))
	end
	return out
end

local function forest(f: Instance, rng: Random, start: number)
	local greens = { Color3.fromRGB(70, 190, 70), Color3.fromRGB(96, 214, 80), Color3.fromRGB(56, 160, 64) }
	for _, at in scatter(rng, start, 14, 30, 66) do
		local h = rng:NextNumber(8, 12)
		Style.Studs(P(f, "Trunk", Vector3.new(3, h, 3), CFrame.new(at + Vector3.new(0, h / 2, 0)), Color3.fromRGB(126, 82, 50)))
		for k, s in { 11, 8, 5 } do
			local leaf = P(f, "Canopy", Vector3.new(s, 3.4, s), CFrame.new(at + Vector3.new(0, h + (k - 1) * 3.2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1), 0), greens[k])
			Style.Studs(leaf)
		end
		for _ = 1, 2 do
			noCollide(P(f, "Apple", Vector3.new(1, 1, 1), CFrame.new(at + Vector3.new(rng:NextNumber(-4, 4), h - 0.4, rng:NextNumber(-4, 4))), Color3.fromRGB(230, 50, 50), nil, Enum.PartType.Ball))
		end
	end
	for _, at in scatter(rng, start, 18, 18, 70) do
		local s = rng:NextNumber(3, 5)
		Style.Studs(P(f, "Bush", Vector3.new(s * 1.4, s, s), CFrame.new(at + Vector3.new(0, s / 2, 0)), greens[2]))
		Style.Studs(P(f, "Bush", Vector3.new(s, s * 0.8, s), CFrame.new(at + Vector3.new(s * 0.6, s * 1.1, 0.4)), greens[1]))
	end
	for _, at in scatter(rng, start, 10, 16, 60) do
		P(f, "MushroomStem", Vector3.new(1.2, 2.4, 1.2), CFrame.new(at + Vector3.new(0, 1.2, 0)), Color3.fromRGB(250, 240, 220))
		Style.Studs(P(f, "MushroomCap", Vector3.new(4, 1.4, 4), CFrame.new(at + Vector3.new(0, 2.9, 0)), Color3.fromRGB(230, 60, 60)))
		for d = -1, 1, 2 do
			P(f, "Dot", Vector3.new(0.8, 0.2, 0.8), CFrame.new(at + Vector3.new(d * 1, 3.65, d * 0.6)), Color3.new(1, 1, 1))
		end
	end
	local flowerColors = { Color3.fromRGB(255, 120, 190), Color3.fromRGB(255, 230, 80), Color3.fromRGB(150, 120, 255), Color3.new(1, 1, 1) }
	for _, at in scatter(rng, start, 26, 14, 72) do
		for k = 1, 3 do
			local p = at + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
			noCollide(P(f, "Stem", Vector3.new(0.2, 1.2, 0.2), CFrame.new(p + Vector3.new(0, 0.6, 0)), Color3.fromRGB(60, 150, 60)))
			noCollide(P(f, "Bloom", Vector3.new(0.9, 0.5, 0.9), CFrame.new(p + Vector3.new(0, 1.3, 0)), flowerColors[(k + math.floor(p.Z)) % 4 + 1]))
		end
	end
end

local function desert(f: Instance, rng: Random, start: number)
	local cactus = Color3.fromRGB(86, 176, 82)
	for _, at in scatter(rng, start, 14, 20, 68) do
		local h = rng:NextNumber(6, 10)
		Style.Studs(P(f, "Cactus", Vector3.new(2.4, h, 2.4), CFrame.new(at + Vector3.new(0, h / 2, 0)), cactus))
		for _, s in { -1, 1 } do
			local y = rng:NextNumber(h * 0.35, h * 0.6)
			Style.Studs(P(f, "CactusArm", Vector3.new(2, 1.8, 1.8), CFrame.new(at + Vector3.new(s * 2, y, 0)), cactus))
			Style.Studs(P(f, "CactusArm", Vector3.new(1.8, 3.4, 1.8), CFrame.new(at + Vector3.new(s * 2.9, y + 2.4, 0)), Style.Lighten(cactus, 0.1)))
		end
		noCollide(P(f, "CactusFlower", Vector3.new(1.2, 0.8, 1.2), CFrame.new(at + Vector3.new(0, h + 0.4, 0)), Color3.fromRGB(255, 110, 170)))
	end
	for _, s in { -1, 1 } do
		for _, dz in { 45, 135 } do
			local at = Vector3.new(s * 54, 0, start + dz + s * 10)
			for k = 0, 5 do
				local size = 26 - k * 4.4
				Style.Studs(P(f, "Pyramid", Vector3.new(size, 3, size), CFrame.new(at + Vector3.new(0, 1.5 + k * 3, 0)), if k % 2 == 0 then Color3.fromRGB(236, 196, 120) else Color3.fromRGB(220, 176, 100)))
			end
			P(f, "PyramidDoor", Vector3.new(4, 5, 0.4), CFrame.new(at + Vector3.new(0, 2.5, -13.1)), Color3.fromRGB(60, 40, 30))
		end
	end
	for _, at in scatter(rng, start, 10, 24, 66) do
		Style.Wedge(f, "Dune", Vector3.new(12, 3.5, 7), CFrame.new(at + Vector3.new(0, 1.75, -3.5)), Color3.fromRGB(246, 214, 140))
		Style.Wedge(f, "Dune", Vector3.new(12, 3.5, 7), CFrame.new(at + Vector3.new(0, 1.75, 3.5)) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(240, 204, 128))
	end
	for _, at in scatter(rng, start, 5, 18, 40) do
		Style.Studs(P(f, "Skull", Vector3.new(3.4, 2.8, 3.4), CFrame.new(at + Vector3.new(0, 1.4, 0)), Color3.fromRGB(250, 244, 226)))
		for _, s in { -1, 1 } do
			P(f, "EyeSocket", Vector3.new(0.9, 0.9, 0.2), CFrame.new(at + Vector3.new(s * 0.8, 1.8, -1.71)), Color3.fromRGB(40, 30, 30))
			P(f, "Horn", Vector3.new(0.6, 2, 0.6), CFrame.new(at + Vector3.new(s * 2, 3, 0)) * CFrame.Angles(0, 0, -s * 0.6), Color3.fromRGB(250, 244, 226))
		end
	end
	for _, at in scatter(rng, start, 6, 56, 70) do
		for k = 0, 4 do
			P(f, "PalmTrunk", Vector3.new(1.6, 2.4, 1.6), CFrame.new(at + Vector3.new(k * 0.4, 1.2 + k * 2.3, 0)) * CFrame.Angles(0, 0, -0.15), Color3.fromRGB(150, 104, 60))
		end
		for n = 0, 4 do
			local angle = n * math.pi * 2 / 5
			local leaf = P(f, "PalmLeaf", Vector3.new(1.6, 0.5, 6), CFrame.new(at + Vector3.new(2, 12.2, 0)) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -2.8) * CFrame.Angles(-0.35, 0, 0), Color3.fromRGB(70, 180, 70))
			Style.Studs(leaf)
		end
	end
end

local function ice(f: Instance, rng: Random, start: number)
	local snow = Color3.fromRGB(246, 252, 255)
	for _, at in scatter(rng, start, 14, 26, 68) do
		P(f, "PineTrunk", Vector3.new(1.6, 3, 1.6), CFrame.new(at + Vector3.new(0, 1.5, 0)), Color3.fromRGB(110, 76, 50))
		for k, s in { 9, 7, 5, 3 } do
			local y = 3 + (k - 1) * 2.6
			Style.Studs(P(f, "PineLayer", Vector3.new(s, 2.4, s), CFrame.new(at + Vector3.new(0, y + 1.2, 0)) * CFrame.Angles(0, k * 0.4, 0), Color3.fromRGB(40, 120, 90)))
			noCollide(P(f, "SnowCap", Vector3.new(s * 0.8, 0.4, s * 0.8), CFrame.new(at + Vector3.new(0, y + 2.6, 0)) * CFrame.Angles(0, k * 0.4, 0), snow))
		end
	end
	for _, at in scatter(rng, start, 16, 18, 70) do
		for k = 1, 3 do
			local spike = P(f, "IceSpike", Vector3.new(1.6, rng:NextNumber(4, 9), 1.6), CFrame.new(at + Vector3.new(k - 2, 2.5, rng:NextNumber(-1, 1))) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)), Color3.fromRGB(140, 220, 255), Enum.Material.Glass)
			spike.Transparency = 0.25
		end
	end
	for _, at in scatter(rng, start, 4, 26, 44) do
		for k, s in { 4, 3, 2.2 } do
			P(f, "Snowball", Vector3.new(s, s, s), CFrame.new(at + Vector3.new(0, ({ 2, 5.2, 7.6 })[k], 0)), snow, Enum.Material.Snow, Enum.PartType.Ball)
		end
		P(f, "Hat", Vector3.new(1.4, 1.4, 1.4), CFrame.new(at + Vector3.new(0, 9.2, 0)), Color3.fromRGB(30, 30, 40))
		P(f, "Carrot", Vector3.new(0.4, 0.4, 1.4), CFrame.new(at + Vector3.new(0, 7.6, -1.5)), Color3.fromRGB(255, 140, 40))
	end
	for _, s in { -1, 1 } do
		local at = Vector3.new(s * 56, 0, start + 90)
		P(f, "Igloo", Vector3.new(16, 16, 16), CFrame.new(at), snow, Enum.Material.Snow, Enum.PartType.Ball)
		P(f, "IglooDoor", Vector3.new(4, 5, 4), CFrame.new(at + Vector3.new(-s * 7, 2.5, 0)), Color3.fromRGB(70, 110, 160))
	end
	for _, at in scatter(rng, start, 12, 16, 72) do
		noCollide(P(f, "SnowPile", Vector3.new(6, 1.6, 4), CFrame.new(at + Vector3.new(0, 0.3, 0)), snow, Enum.Material.Snow, Enum.PartType.Ball))
	end
end

local function lava(f: Instance, rng: Random, start: number)
	local basalt = Color3.fromRGB(58, 42, 46)
	local molten = Color3.fromRGB(255, 110, 30)
	for _, s in { -1, 1 } do
		local river = P(f, "LavaRiver", Vector3.new(14, 0.3, Config.ZoneLength - 10), CFrame.new(s * 44, 0.12, start + Config.ZoneLength / 2), molten, Enum.Material.Neon)
		river.CanCollide = false
		Style.Particles(river, "Embers", {
			Texture = "rbxasset://textures/particles/fire_sparks_main.dds", Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), molten),
			Rate = 25, Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(2, 6), EmissionDirection = Enum.NormalId.Top,
			Size = NumberSequence.new(0.4), LightEmission = 1,
		})
		for _, dz in { 50, 135 } do
			local at = Vector3.new(s * 60, 0, start + dz)
			for k, d in { 26, 20, 14, 9 } do
				Style.Studs(P(f, "Volcano", Vector3.new(d, 4, d), CFrame.new(at + Vector3.new(0, 2 + (k - 1) * 4, 0)) * CFrame.Angles(0, k * 0.3, 0), if k % 2 == 0 then basalt else Style.Lighten(basalt, 0.1)))
			end
			local crater = P(f, "Crater", Vector3.new(6, 1, 6), CFrame.new(at + Vector3.new(0, 16.4, 0)), molten, Enum.Material.Neon)
			Style.Light(crater, molten, 3, 30)
			Style.Particles(crater, "Smoke", {
				Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(Color3.fromRGB(90, 70, 70)),
				Rate = 6, Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(6, 9), EmissionDirection = Enum.NormalId.Top,
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 12) }),
				Transparency = NumberSequence.new(0.3, 1), LightEmission = 0.1,
			})
		end
	end
	for _, at in scatter(rng, start, 14, 20, 34) do
		local h = rng:NextNumber(5, 14)
		Style.Studs(P(f, "BasaltPillar", Vector3.new(4, h, 4), CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0), basalt))
		P(f, "PillarGlow", Vector3.new(4.2, 0.4, 4.2), CFrame.new(at + Vector3.new(0, h * 0.6, 0)), molten, Enum.Material.Neon)
	end
	for _, at in scatter(rng, start, 12, 16, 70) do
		local rock = P(f, "LavaRock", Vector3.new(3, 2, 3), CFrame.new(at + Vector3.new(0, 1, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), basalt)
		Style.Studs(rock)
		noCollide(P(f, "RockCrack", Vector3.new(3.1, 0.3, 0.4), rock.CFrame * CFrame.new(0, 0.2, 0), molten, Enum.Material.Neon))
	end
end

local function toxic(f: Instance, rng: Random, start: number)
	local purple = Color3.fromRGB(110, 60, 170)
	local lime = Color3.fromRGB(90, 220, 30)
	local hazard = Color3.fromRGB(252, 204, 40)
	for _, s in { -1, 1 } do
		for _, dz in { 40, 130 } do
			local at = Vector3.new(s * 54, 0, start + dz)
			local building = P(f, "Factory", Vector3.new(24, 16, 20), CFrame.new(at + Vector3.new(0, 8, 0)), purple)
			Style.Studs(building, true)
			for k = 0, 5 do
				P(f, "RoofStripe", Vector3.new(24.4, 1, 3.3), CFrame.new(at + Vector3.new(0, 16.5, -8.3 + k * 3.3)), if k % 2 == 0 then lime else Color3.fromRGB(70, 150, 40))
			end
			local doorX = -s * 12.05
			for k = 0, 4 do
				P(f, "Door", Vector3.new(0.3, 1.6, 8), CFrame.new(at + Vector3.new(doorX, 0.8 + k * 1.6, 0)), if k % 2 == 0 then hazard else Color3.fromRGB(30, 30, 36))
			end
			for _, dz2 in { -6.5, 6.5 } do
				P(f, "Window", Vector3.new(0.3, 3, 3.4), CFrame.new(at + Vector3.new(doorX, 11, dz2)), lime, Enum.Material.Neon)
			end
			local signPart = P(f, "RadSign", Vector3.new(0.4, 4, 4), CFrame.new(at + Vector3.new(doorX * 1.02, 11, 0)), hazard)
			Style.Sign(signPart, "☢", nil, Color3.fromRGB(30, 30, 36), if s > 0 then Enum.NormalId.Left else Enum.NormalId.Right, 30)
			local chimney = Style.Cylinder(f, "Chimney", 10, 3, CFrame.new(at + Vector3.new(s * 6, 21, 5)), Color3.fromRGB(70, 70, 82), Enum.Material.Metal)
			Style.Particles(chimney, "Smog", {
				Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(Color3.fromRGB(140, 220, 90)),
				Rate = 5, Lifetime = NumberRange.new(3, 4), Speed = NumberRange.new(5, 8), EmissionDirection = Enum.NormalId.Right,
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) }), Transparency = NumberSequence.new(0.4, 1),
			})
		end
	end
	for _, at in scatter(rng, start, 10, 18, 36) do
		for k = 0, 2 do
			local p = at + Vector3.new((k - 1) * 3.2, 0, (k % 2) * 2)
			local barrel = Style.Cylinder(f, "Barrel", 3.6, 3, CFrame.new(p + Vector3.new(0, 1.8, 0)), if k == 1 then hazard else Color3.fromRGB(60, 140, 50))
			Style.Studs(barrel)
			noCollide(Style.Cylinder(f, "Goo", 0.3, 2.4, CFrame.new(p + Vector3.new(0, 3.65, 0)), lime, Enum.Material.Neon))
		end
	end
	for _, at in scatter(rng, start, 12, 20, 70) do
		local h = rng:NextNumber(4, 8)
		P(f, "ShroomStem", Vector3.new(1, h, 1), CFrame.new(at + Vector3.new(0, h / 2, 0)), Color3.fromRGB(230, 240, 200))
		local cap = P(f, "ShroomCap", Vector3.new(5, 1.4, 5), CFrame.new(at + Vector3.new(0, h + 0.4, 0)), Color3.fromRGB(120, 230, 40), Enum.Material.Neon)
		Style.Light(cap, lime, 1.2, 14)
	end
	for _, at in scatter(rng, start, 6, 24, 40) do
		local pool = Style.Cylinder(f, "SludgePool", 0.3, 10, CFrame.new(at + Vector3.new(0, 0.12, 0)), lime, Enum.Material.Neon)
		pool.CanCollide = false
		Style.Particles(pool, "Bubbles", {
			Color = ColorSequence.new(lime), Rate = 6, Speed = NumberRange.new(1, 3), EmissionDirection = Enum.NormalId.Right,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(0.6, 1.2),
		})
	end
	for _, s in { -1, 1 } do
		local pipe = P(f, "Pipe", Vector3.new(Config.ZoneLength, 3, 3), CFrame.new(s * 72.6, 10, start + Config.ZoneLength / 2) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(90, 90, 104), Enum.Material.Metal, Enum.PartType.Cylinder)
		pipe.CanCollide = false
	end
end

local function shadow(f: Instance, rng: Random, start: number)
	local obsidian = Color3.fromRGB(60, 30, 100)
	local glow = Color3.fromRGB(180, 96, 255)
	for _, at in scatter(rng, start, 16, 20, 70) do
		for k = 1, 3 do
			local h = rng:NextNumber(5, 13)
			local crystal = P(f, "Crystal", Vector3.new(2.2, h, 2.2), CFrame.new(at + Vector3.new((k - 2) * 1.6, h / 2 - 0.5, rng:NextNumber(-1, 1))) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)),
				if k == 2 then glow else obsidian, if k == 2 then Enum.Material.Neon else Enum.Material.Glass)
			crystal.Transparency = if k == 2 then 0.1 else 0.2
		end
	end
	for _, at in scatter(rng, start, 8, 30, 66) do
		Style.Studs(P(f, "DeadTrunk", Vector3.new(2.2, 12, 2.2), CFrame.new(at + Vector3.new(0, 6, 0)), Color3.fromRGB(40, 30, 44)))
		for k = 1, 3 do
			P(f, "DeadBranch", Vector3.new(1, 5, 1), CFrame.new(at + Vector3.new(0, 7 + k * 1.6, 0)) * CFrame.Angles(0, k * 2.1, 0) * CFrame.new(0, 0, -2) * CFrame.Angles(-0.8, 0, 0), Color3.fromRGB(40, 30, 44))
		end
	end
	for _, at in scatter(rng, start, 12, 18, 40) do
		local stone = P(f, "Gravestone", Vector3.new(3, 4, 1), CFrame.new(at + Vector3.new(0, 2, 0)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.1, 0.1)), Color3.fromRGB(110, 104, 130))
		Style.Studs(stone)
		P(f, "GraveTop", Vector3.new(1, 3, 3), stone.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(0, math.pi / 2, math.pi / 2), Color3.fromRGB(110, 104, 130), nil, Enum.PartType.Cylinder)
	end
	for _, s in { -1, 1 } do
		local at = Vector3.new(s * 58, 0, start + 70)
		for n = 0, 15 do
			local angle = n * math.pi * 2 / 16
			P(f, "PortalRing", Vector3.new(2, 2, 2), CFrame.new(at + Vector3.new(0, 10 + math.sin(angle) * 8, math.cos(angle) * 8)), if n % 2 == 0 then glow else obsidian, Enum.Material.Neon)
		end
		local disc = P(f, "PortalVoid", Vector3.new(0.4, 15, 15), CFrame.new(at + Vector3.new(0, 10, 0)), Color3.fromRGB(120, 40, 220), Enum.Material.ForceField, Enum.PartType.Cylinder)
		disc.CanCollide = false
		Style.Light(disc, glow, 3, 30)
		Style.Particles(disc, "Swirl", {
			Color = ColorSequence.new(glow, Color3.fromRGB(70, 230, 255)), Rate = 20, Speed = NumberRange.new(2, 5),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }), SpreadAngle = Vector2.new(180, 180),
		})
	end
	for n = 1, 10 do
		local side = if n % 2 == 0 then 1 else -1
		local orb = P(f, "FloatingOrb", Vector3.new(2, 2, 2), CFrame.new(side * rng:NextNumber(20, 66), rng:NextNumber(10, 26), start + rng:NextNumber(10, 170)), if n % 3 == 0 then Color3.fromRGB(70, 230, 255) else glow, Enum.Material.Neon, Enum.PartType.Ball)
		noCollide(orb)
		Style.Light(orb, orb.Color, 1.5, 18)
	end
end

local DECOR = { forest, desert, ice, lava, toxic, shadow }

local function buildNest(f: Instance, index: number)
	local zone = Config.Zones[index]
	local center = Config.NestCenter(index)
	local nest = folder(f, "Nest")
	local straw = Style.Cylinder(nest, "Straw", 0.7, 20, CFrame.new(center + Vector3.new(0, 0.35, 0)), Color3.fromRGB(226, 192, 110))
	Style.Studs(straw)
	for n = 0, 17 do
		local angle = n * math.pi * 2 / 18
		local twig = P(nest, "Twig", Vector3.new(3.6, 1.6, 1.2), CFrame.new(center + Vector3.new(math.cos(angle) * 10, 1, math.sin(angle) * 10)) * CFrame.Angles(0, -angle + math.pi / 2, (n % 2) * 0.25), if n % 2 == 0 then Color3.fromRGB(140, 92, 50) else Color3.fromRGB(170, 116, 64))
		Style.Studs(twig)
	end
	local glowRing = Style.Cylinder(nest, "NestGlow", 0.2, 23, CFrame.new(center + Vector3.new(0, 0.1, 0)), zone.Color, Enum.Material.Neon)
	glowRing.Transparency = 0.4
	noCollide(glowRing)
	for slot = 1, Config.NestSlots do
		local at = Config.NestSlot(index, slot)
		local pedestal = Style.Cylinder(nest, "Pedestal", 0.8, 4, CFrame.new(at.X, 0.9, at.Z), zone.Accent)
		Style.Studs(pedestal)
	end
	local home = Config.GuardianHome(index)
	local bed = P(nest, "GuardianBed", Vector3.new(18, 0.5, 22), home * CFrame.new(0, 0.25, 0), Style.Darken(zone.Color, 0.35))
	Style.Studs(bed)
	noCollide(bed)
end

local function buildZone(root: Instance, index: number)
	local zone = Config.Zones[index]
	local start = Config.ZoneStart(index)
	local mid = Config.ZoneCenter(index)
	local f = folder(root, zone.Name)
	f:SetAttribute("Zone", index)

	local ground = P(f, "Ground", Vector3.new(Config.HalfWidth * 2 + 6, 4, Config.ZoneLength), CFrame.new(0, -2, mid), zone.Ground)
	Style.Checker(ground, 8, { Enum.NormalId.Top }, 0.86)
	local path = P(f, "Path", Vector3.new(22, 0.2, Config.ZoneLength), CFrame.new(0, 0.1, mid), Style.Lighten(zone.Ground, 0.3))
	Style.Checker(path, 5.5, { Enum.NormalId.Top }, 0.88)

	for _, x in { -1, 1 } do
		local wall = P(f, "Wall", Vector3.new(6, Config.WallHeight, Config.ZoneLength), CFrame.new(x * (Config.HalfWidth + 3), Config.WallHeight / 2, mid), zone.Wall)
		Style.Checker(wall, 8, nil, 0.8)
		local trim = P(f, "WallTrim", Vector3.new(8, 3, Config.ZoneLength), CFrame.new(x * (Config.HalfWidth + 3), Config.WallHeight + 1.5, mid), zone.Trim)
		Style.Studs(trim)
		P(f, "Glow", Vector3.new(0.4, 0.8, Config.ZoneLength), CFrame.new(x * (Config.HalfWidth - 0.1), 3, mid), zone.Color, Enum.Material.Neon)
		local plaque = P(f, "Plaque", Vector3.new(0.8, 12, 44), CFrame.new(x * (Config.HalfWidth - 0.4), 24, mid), Style.Darken(zone.Color, 0.55))
		Style.Studs(plaque, true)
		Style.Sign(plaque, zone.Name:upper(), nil, Style.Lighten(zone.Color, 0.2), if x < 0 then Enum.NormalId.Right else Enum.NormalId.Left, 10)
	end

	-- Entry arch (the first zone shares the safe zone gate).
	for _, x in (if index == 1 then {} else { -30, 30 }) do
		local pillar = P(f, "ArchPillar", Vector3.new(6, 34, 6), CFrame.new(x, 17, start), zone.Wall)
		Style.Studs(pillar, true)
		P(f, "ArchCap", Vector3.new(7, 2, 7), CFrame.new(x, 35, start), zone.Color, Enum.Material.Neon)
	end
	local beam = P(f, "ArchBeam", Vector3.new(66, 9, 5), CFrame.new(0, if index == 1 then 46 else 39, start), Style.Darken(zone.Color, 0.55))
	Style.Studs(beam)
	local subtitle = string.format("Guardian: %s  •  Eggs from $%s/s", zone.Monster, Config.Format(zone.Income))
	Style.Sign(beam, zone.Name:upper() .. " ZONE", subtitle, Style.Lighten(zone.Color, 0.15), Enum.NormalId.Front, 14)
	Style.Sign(beam, "SAFE ZONE ←", "Bank your egg behind you!", Color3.fromRGB(180, 255, 220), Enum.NormalId.Back, 14)

	local decor = folder(f, "Decor")
	DECOR[index](decor, Random.new(index * 97), start)
	buildNest(f, index)
	task.wait()
	return f
end

local function setupLighting()
	Lighting.ClockTime = 14.2
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(110, 110, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true
	local function effect(class: string, name: string): Instance
		local existing = Lighting:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local e = Instance.new(class)
		e.Name = name
		e.Parent = Lighting
		return e
	end
	local cc = effect("ColorCorrectionEffect", "EggColor") :: ColorCorrectionEffect
	cc.Saturation = 0.18
	cc.Contrast = 0.06
	cc.Brightness = 0.02
	local bloom = effect("BloomEffect", "EggBloom") :: BloomEffect
	bloom.Intensity = 0.25
	bloom.Size = 20
	bloom.Threshold = 1.5
	local rays = effect("SunRaysEffect", "EggSunRays") :: SunRaysEffect
	rays.Intensity = 0.06
	rays.Spread = 0.6
	local atmosphere = effect("Atmosphere", "EggAtmosphere") :: Atmosphere
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.1
	atmosphere.Haze = 0.8
	atmosphere.Glare = 0.2
	atmosphere.Color = Color3.fromRGB(200, 230, 255)
	atmosphere.Decay = Color3.fromRGB(120, 140, 200)
end

function W.Build(): Folder
	local existing = workspace:FindFirstChild(W.RootName)
	if existing then
		return existing :: Folder
	end
	local root = Instance.new("Folder")
	root.Name = W.RootName
	-- Hide the template baseplate/spawn so they don't fight with the map.
	for _, child in workspace:GetChildren() do
		if child.Name == "Baseplate" and child:IsA("BasePart") then
			child.Transparency = 1
			child.CanCollide = false
			child.CanQuery = false
			for _, d in child:GetChildren() do
				if d:IsA("Texture") then
					d.Transparency = 1
				end
			end
		elseif child:IsA("SpawnLocation") then
			child.Enabled = false
			child.Transparency = 1
			child.CanCollide = false
			for _, d in child:GetChildren() do
				if d:IsA("Decal") then
					d.Transparency = 1
				end
			end
		end
	end
	buildSanctuary(root)
	root.Parent = workspace
	local zones = folder(root, "Zones")
	for index = 1, #Config.Zones do
		buildZone(zones, index)
	end
	local endWall = P(root, "EndWall", Vector3.new(Config.HalfWidth * 2 + 12, Config.WallHeight, 6), CFrame.new(0, Config.WallHeight / 2, Config.ZoneStart(#Config.Zones + 1) + 3), Config.Zones[#Config.Zones].Wall)
	Style.Checker(endWall, 8, nil, 0.8)
	setupLighting()
	return root
end

-- Edit-time preview: sleeping guardians and nest eggs so the place looks complete in Studio.
function W.Preview(root: Instance)
	local old = root:FindFirstChild("Preview")
	if old then
		old:Destroy()
	end
	local preview = folder(root, "Preview")
	local rng = Random.new(7)
	for index = 1, #Config.Zones do
		local home = Config.GuardianHome(index)
		local guardian = Monsters.Build(index, home, preview)
		guardian:PivotTo(Monsters.SleepCFrame(guardian, home))
		Monsters.Animate(Monsters.Collect(guardian), 0, 1, 0, 0)
		for slot = 1, Config.NestSlots do
			local rarity = Config.RollRarity(index, rng)
			Eggs.Build(index, rarity, CFrame.new(Config.NestSlot(index, slot)), { Parent = preview, Label = Eggs.LabelText(index, rarity) })
		end
		task.wait()
	end
	return preview
end

return W
