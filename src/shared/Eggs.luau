-- Voxel-style eggs: stacked brick rings with rarity colours, glow and extras.
local Config = require(script.Parent.Config)
local Style = require(script.Parent.Style)

local Eggs = {}

local SLICES = 9

export type Options = {
	Scale: number?,
	Anchored: boolean?,
	Label: string?,
	Parent: Instance?,
	Light: boolean?,
}

local function decorate(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
end

function Eggs.Radius(scale: number, t: number): number
	-- t runs -1 (bottom) .. 1 (top); slightly wider at the bottom like a real egg.
	return math.max(0.32 * scale, 1.6 * scale * math.sqrt(math.max(0, 1 - t * t)) * (1 - 0.16 * t))
end

function Eggs.Build(zone: number, rarity: number, cf: CFrame, options: Options?): Model
	local opts = options or {}
	local scale = opts.Scale or 1
	local info = Config.Rarities[rarity]
	local zoneInfo = Config.Zones[zone]
	local model = Instance.new("Model")
	model.Name = info.Name .. "Egg"
	model:SetAttribute("Zone", zone)
	model:SetAttribute("Rarity", rarity)

	local core = Style.Part(model, "Core", Vector3.new(0.6, 0.6, 0.6) * scale, cf, info.Color)
	core.Transparency = 1
	core.CanCollide = false
	core.CanTouch = false
	core.Massless = true
	core.Anchored = opts.Anchored ~= false

	local height = 4.4 * scale
	local sliceHeight = height / SLICES
	local widest = 0
	local function add(part: BasePart)
		decorate(part)
		Style.Weld(core, part)
		return part
	end

	for k = 1, SLICES do
		local y = -height / 2 + (k - 0.5) * sliceHeight
		local t = y / (height / 2)
		local r = Eggs.Radius(scale, t)
		widest = math.max(widest, r)
		local color = info.Shade:Lerp(info.Color, (k - 1) / (SLICES - 1))
		if k % 2 == 0 then
			color = Style.Lighten(color, 0.1)
		end
		add(Style.Cylinder(model, "Slice", sliceHeight * 1.03, r * 2, cf * CFrame.new(0, y, 0), color))
		if k == 3 or k == 6 then
			for n = 0, 5 do
				local angle = n * math.pi / 3 + (if k == 6 then math.pi / 6 else 0)
				local brick = Style.Part(model, "Brick", Vector3.new(0.95, sliceHeight * 0.9, 0.45) * Vector3.new(scale, 1, scale),
					cf * CFrame.new(0, y, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, r - 0.08 * scale),
					if n % 2 == 0 then zoneInfo.Color else Style.Lighten(info.Color, 0.35))
				Style.Studs(brick)
				add(brick)
			end
		end
	end

	add(Style.Part(model, "Cap", Vector3.new(0.75, 0.75, 0.75) * scale, cf * CFrame.new(0, height / 2 - 0.1 * scale, 0),
		Style.Lighten(info.Color, 0.3), Enum.Material.SmoothPlastic, Enum.PartType.Ball))

	if rarity >= 3 then
		local band = add(Style.Cylinder(model, "Band", 0.2 * scale, widest * 2 + 0.16 * scale, cf * CFrame.new(0, -0.35 * scale, 0),
			Style.Lighten(info.Color, 0.25), Enum.Material.Neon))
		band.Transparency = 0.1
		Style.Particles(core, "Sparkles", {
			Color = ColorSequence.new(info.Color, Color3.new(1, 1, 1)),
			Rate = rarity * 2,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 * scale), NumberSequenceKeypoint.new(1, 0) }),
			SpreadAngle = Vector2.new(180, 180),
			Speed = NumberRange.new(0.5, 2),
		})
	end
	if rarity >= 4 and opts.Light ~= false then
		Style.Light(core, info.Color, 0.6 + (rarity - 4) * 0.3, 8 + rarity)
	end
	if rarity == 5 then
		for n = 0, 4 do
			local angle = n * math.pi * 2 / 5
			local spike = Style.Part(model, "CrownSpike", Vector3.new(0.35, 0.9, 0.35) * scale,
				cf * CFrame.new(0, height / 2 - 0.25 * scale, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, 0.45 * scale) * CFrame.Angles(-0.35, 0, 0),
				Color3.fromRGB(255, 220, 70), Enum.Material.Neon)
			add(spike)
		end
	elseif rarity == 6 then
		for n = 0, 2 do
			local angle = n * math.pi * 2 / 3
			add(Style.Part(model, "Shard", Vector3.new(0.4, 1.3, 0.4) * scale,
				cf * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.3 * scale, widest + 0.9 * scale) * CFrame.Angles(0.4, 0, 0.3),
				info.Color, Enum.Material.Neon))
		end
		Style.Particles(core, "Flames", {
			Texture = "rbxasset://textures/particles/fire_main.dds",
			Color = ColorSequence.new(info.Color, Color3.fromRGB(255, 160, 60)),
			Rate = 10,
			Lifetime = NumberRange.new(0.4, 0.8),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9 * scale), NumberSequenceKeypoint.new(1, 0) }),
			Speed = NumberRange.new(1, 2),
			Acceleration = Vector3.new(0, 4, 0),
		})
	elseif rarity == 7 then
		for n = 0, 11 do
			local angle = n * math.pi * 2 / 12
			add(Style.Part(model, "Halo", Vector3.new(0.32, 0.32, 0.32) * scale,
				cf * CFrame.new(math.cos(angle) * 1.1 * scale, height / 2 + 0.9 * scale, math.sin(angle) * 1.1 * scale),
				Color3.fromRGB(255, 240, 150), Enum.Material.Neon, Enum.PartType.Ball))
		end
		for _, side in { -1, 1 } do
			for n = 0, 2 do
				add(Style.Part(model, "Wing", Vector3.new(0.18, 0.55, 1.9 - n * 0.4) * scale,
					cf * CFrame.new(side * (widest + 0.15 * scale), (0.6 - n * 0.55) * scale, 0.5 * scale) * CFrame.Angles(0.5 + n * 0.15, side * 0.5, 0),
					Color3.new(1, 1, 1), Enum.Material.Neon))
			end
		end
		local sparkles = core:FindFirstChild("Sparkles") :: ParticleEmitter
		sparkles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 240, 120)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(120, 255, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 140, 255)),
		})
	end

	if opts.Label then
		Style.Label(core, opts.Label, Style.Lighten(info.Color, 0.15), 7 * scale, 1.9 * scale, height / 2 + 1.6 * scale)
	end

	model.PrimaryPart = core
	model.Parent = opts.Parent
	return model
end

function Eggs.Title(zone: number, rarity: number): string
	return Config.Rarities[rarity].Name .. " " .. Config.Zones[zone].Name .. " Egg"
end

function Eggs.LabelText(zone: number, rarity: number): string
	return string.format("%s\n$%s/s", Config.Rarities[rarity].Name, Config.Format(Config.EggIncome(zone, rarity)))
end

return Eggs
