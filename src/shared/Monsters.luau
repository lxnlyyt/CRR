-- Guardian models: one AI-generated slime mesh per zone (ids in Config), animated on each client
-- with squash & stretch, leaning and a red rage glow. Every guardian has an anchored invisible
-- Root that the server moves; the body hangs off it on a Motor6D that clients animate.
local AssetService = game:GetService("AssetService")

local Config = require(script.Parent.Config)
local Style = require(script.Parent.Style)

local Monsters = {}

local meshCache: { [number]: MeshPart | false } = {}

local function soften(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
end

-- Loads (once) the zone's generated mesh. Returns nil if the asset can't be loaded.
local function meshTemplate(zone: number): MeshPart?
	local cached = meshCache[zone]
	if cached ~= nil then
		return cached or nil
	end
	local info = Config.Zones[zone]
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(info.MeshId)
	end)
	if not ok or not result then
		warn(string.format("[MonsterEgg] Mesh for %s could not load (%s); using fallback blob", info.Monster, tostring(result)))
		meshCache[zone] = false
		return nil
	end
	local part = result :: MeshPart
	part.TextureID = info.TextureId
	meshCache[zone] = part
	return part
end

-- Simple glossy blob with eyes, used when a mesh asset is unavailable.
local function fallbackBody(zone: number, height: number): Part
	local info = Config.Zones[zone]
	local body = Style.Part(nil, "Body", Vector3.new(height * 1.15, height, height * 0.9), CFrame.identity, info.Color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	body.Reflectance = 0.1
	for _, s in { -1, 1 } do
		local eye = Style.Part(body, "Eye", Vector3.new(1.6, 1.6, 0.8) * height / 12, CFrame.new(s * height * 0.17, height * 0.15, -height * 0.42), Color3.fromRGB(255, 230, 80), Enum.Material.Neon, Enum.PartType.Ball)
		soften(eye)
		Style.Weld(body, eye)
	end
	local mouth = Style.Part(body, "Mouth", Vector3.new(height * 0.35, height * 0.1, 0.6), CFrame.new(0, -height * 0.08, -height * 0.44), Color3.fromRGB(30, 10, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	soften(mouth)
	Style.Weld(body, mouth)
	return body
end

function Monsters.Build(zone: number, home: CFrame, parent: Instance?): Model
	local info = Config.Zones[zone]
	local height = info.Height
	local hip = height / 2
	local model = Instance.new("Model")
	model.Name = info.Monster
	model:SetAttribute("Zone", zone)
	model:SetAttribute("Hip", hip)
	model:SetAttribute("SleepDrop", 0)
	model:SetAttribute("Sleeping", true)
	model:SetAttribute("Rage", 0)

	local root = Style.Part(model, "Root", Vector3.new(2, 2, 2), CFrame.new(0, hip, 0), Color3.new(1, 1, 1))
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	model.PrimaryPart = root

	local facing = CFrame.Angles(0, info.MeshYaw, 0)
	local template = meshTemplate(zone)
	local body: BasePart
	if template then
		local mesh = template:Clone()
		mesh.Name = "Body"
		mesh.Size = template.Size * (height / template.Size.Y)
		body = mesh
	else
		body = fallbackBody(zone, height)
		facing = CFrame.identity
	end
	body.CFrame = root.CFrame * facing
	soften(body)
	body.CastShadow = true
	body.Parent = model
	for _, extra in body:GetChildren() do
		if extra:IsA("BasePart") then
			extra.Parent = model
		end
	end

	local motor = Instance.new("Motor6D")
	motor.Name = "Body"
	motor.Part0 = root
	motor.Part1 = body
	motor.C0 = facing
	motor:SetAttribute("Rest", facing)
	motor:SetAttribute("Kind", "Blob")
	motor:SetAttribute("BaseSize", body.Size)
	motor.Parent = root

	Style.Particles(body, "Drips", {
		Color = ColorSequence.new(info.Color),
		Rate = 6,
		Speed = NumberRange.new(0),
		Acceleration = Vector3.new(0, -30, 0),
		Lifetime = NumberRange.new(0.6, 0.9),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2) }),
		LightEmission = 0.3,
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
	})

	local glow = Instance.new("Highlight")
	glow.Name = "RageGlow"
	glow.Adornee = body
	glow.FillColor = Color3.fromRGB(255, 40, 40)
	glow.FillTransparency = 0.7
	glow.OutlineColor = Color3.fromRGB(255, 120, 80)
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Enabled = false
	glow.Parent = model

	local fire = Style.Particles(root, "RageFire", {
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(255, 70, 50), info.Color),
		Rate = 40,
		Lifetime = NumberRange.new(0.4, 0.9),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0.5) }),
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, 8, 0),
		LightEmission = 1,
		Enabled = false,
	})
	fire:SetAttribute("Rage", true)
	local light = Style.Light(root, Color3.fromRGB(255, 60, 60), 3, 26)
	light.Name = "RageLight"
	light.Enabled = false
	Style.Light(root, info.Color, 1.2, height * 1.4).Name = "ZoneGlow"

	local status = Style.Label(root, "Zzz", Color3.fromRGB(170, 220, 255), 7, 2.6, hip + 2.4)
	status.Name = "Status"
	status.MaxDistance = 220
	local nameplate = Style.Label(root, info.Monster, info.Color, 14, 1.8, hip + 5.4)
	nameplate.Name = "Nameplate"
	nameplate.MaxDistance = 160

	model:PivotTo(home * CFrame.new(0, hip, 0))
	model.Parent = parent
	return model
end

-- Root CFrame for a standing (awake) guardian at a ground-level CFrame.
function Monsters.StandCFrame(model: Model, ground: CFrame): CFrame
	return ground * CFrame.new(0, model:GetAttribute("Hip") :: number, 0)
end

function Monsters.SleepCFrame(model: Model, ground: CFrame): CFrame
	local hip = model:GetAttribute("Hip") :: number
	local drop = model:GetAttribute("SleepDrop") :: number
	return ground * CFrame.new(0, hip - drop, 0)
end

function Monsters.SetStatus(model: Model, text: string, color: Color3)
	local root = model.PrimaryPart
	local gui = root and root:FindFirstChild("Status") :: BillboardGui?
	local label = gui and gui:FindFirstChild("Text") :: TextLabel?
	if label then
		label.Text = text
		label.TextColor3 = color
	end
end

function Monsters.SetRage(model: Model, on: boolean)
	for _, item in model:GetDescendants() do
		if item:IsA("ParticleEmitter") and item:GetAttribute("Rage") then
			item.Enabled = on
		elseif item:IsA("PointLight") and item.Name == "RageLight" then
			item.Enabled = on
		elseif item:IsA("Highlight") and item.Name == "RageGlow" then
			item.Enabled = on
		end
	end
end

-- Animation ----------------------------------------------------------------

export type Pose = {
	Motors: { Motor6D },
}

function Monsters.Collect(model: Model): Pose
	local pose: Pose = { Motors = {} }
	for _, item in model:GetDescendants() do
		if item:IsA("Motor6D") and item:GetAttribute("Rest") then
			table.insert(pose.Motors, item)
		end
	end
	return pose
end

-- sleep: 0 awake .. 1 asleep; move: 0 idle .. 1 full speed; rage: 0 .. 1.
function Monsters.Animate(pose: Pose, t: number, sleep: number, move: number, rage: number)
	for _, motor in pose.Motors do
		local body = motor.Part1
		local base = motor:GetAttribute("BaseSize") :: Vector3?
		if not body or not base then
			continue
		end
		local rest = motor:GetAttribute("Rest") :: CFrame
		local breath = math.sin(t * 1.4) * 0.035
		local wobble = math.sin(t * (4 + move * 9 + rage * 6)) * (0.035 + 0.07 * move + 0.05 * rage)
		local awakeY, awakeX = 1 + wobble + breath * 0.5, 1 - wobble * 0.6
		local sleepY, sleepX = 0.8 + breath, 1.12 - breath * 0.5
		local sy = awakeY + (sleepY - awakeY) * sleep
		local sx = awakeX + (sleepX - awakeX) * sleep
		body.Size = base * Vector3.new(sx, sy, sx)
		local lean = (move * 0.2 + rage * 0.08) * (1 - sleep)
		local sway = math.sin(t * 2.1) * 0.05 * (1 + move) * (1 - sleep)
		local drop = (1 - sy) * base.Y / 2
		motor.C0 = CFrame.new(0, -drop, 0) * CFrame.Angles(-lean, 0, sway) * rest
	end
end

return Monsters
