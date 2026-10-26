-- Six unique guardian rigs. Every rig has an anchored invisible Root (moved by the server)
-- and Motor6D joints that clients animate locally from the attributes stored on each motor.
local Config = require(script.Parent.Config)
local Style = require(script.Parent.Style)

local Monsters = {}

type Rig = { Model: Model, Root: Part }

local WHITE = Color3.new(1, 1, 1)
local BONE = Color3.fromRGB(246, 238, 220)
local BLACK = Color3.fromRGB(26, 22, 30)

local function soften(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
end

local function newRig(zone: number, hip: number, sleepDrop: number): Rig
	local model = Instance.new("Model")
	model.Name = Config.Zones[zone].Monster
	local root = Style.Part(model, "Root", Vector3.new(2, 2, 2), CFrame.new(0, hip, 0), WHITE)
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	model.PrimaryPart = root
	model:SetAttribute("Zone", zone)
	model:SetAttribute("Hip", hip)
	model:SetAttribute("SleepDrop", sleepDrop)
	model:SetAttribute("Sleeping", true)
	model:SetAttribute("Rage", 0)
	return { Model = model, Root = root }
end

-- Visual block welded to `attach` at a local offset.
local function add(rig: Rig, attach: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Style.Part(rig.Model, name, size, attach.CFrame * offset, color, material, shape)
	soften(p)
	Style.Weld(attach, p)
	return p
end

local function addStud(rig: Rig, attach: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3): Part
	return Style.Studs(add(rig, attach, name, size, offset, color)) :: Part
end

local function addWedge(rig: Rig, attach: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local w = Style.Wedge(rig.Model, name, size, attach.CFrame * offset, color, material)
	soften(w)
	Style.Weld(attach, w)
	return w
end

local function addCylinder(rig: Rig, attach: BasePart, name: string, length: number, diameter: number, offset: CFrame, color: Color3, material: Enum.Material?): Part
	-- Cylinder axis along the offset's X axis.
	return add(rig, attach, name, Vector3.new(length, diameter, diameter), offset, color, material, Enum.PartType.Cylinder)
end

-- Invisible pivot connected with a Motor6D; the client animates C0 from these attributes.
local function joint(rig: Rig, parent: BasePart, name: string, offset: CFrame, kind: string, props: { [string]: any }?): Part
	local pivot = Style.Part(rig.Model, name, Vector3.new(0.4, 0.4, 0.4), parent.CFrame * offset, WHITE)
	pivot.Transparency = 1
	soften(pivot)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = parent
	motor.Part1 = pivot
	motor.C0 = offset
	motor:SetAttribute("Rest", offset)
	motor:SetAttribute("Kind", kind)
	for key, value in props or {} do
		motor:SetAttribute(key, value)
	end
	motor.Parent = parent
	return pivot
end

local function eye(rig: Rig, attach: BasePart, size: Vector3, offset: CFrame, color: Color3, lidColor: Color3)
	local e = add(rig, attach, "Eye", size, offset, color, Enum.Material.Neon)
	e:SetAttribute("Base", color)
	local lid = add(rig, attach, "Lid", size + Vector3.new(0.2, 0.2, 0.08), offset, lidColor)
	lid.Transparency = 1
	return e
end

local function finish(rig: Rig, zone: number, statusAttach: BasePart, statusHeight: number)
	local info = Config.Zones[zone]
	local fire = Style.Particles(rig.Root, "RageFire", {
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
	local light = Style.Light(rig.Root, Color3.fromRGB(255, 60, 60), 3, 26)
	light.Name = "RageLight"
	light.Enabled = false

	local gui = Style.Label(statusAttach, "Zzz", Color3.fromRGB(170, 220, 255), 7, 2.6, statusHeight)
	gui.Name = "Status"
	gui.MaxDistance = 220
	local nameGui = Style.Label(rig.Root, info.Monster, info.Color, 14, 1.8, statusHeight + 3.4)
	nameGui.Name = "Nameplate"
	nameGui.MaxDistance = 160
	nameGui.Adornee = statusAttach
	nameGui.Parent = statusAttach
	return rig.Model
end

local function sleepCF(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
end

-- 1. FOREST — Bramble Beast: mossy antlered bear-stag.
local function brambleBeast(): Model
	local rig = newRig(1, 6.2, 3.4)
	local root = rig.Root
	local fur = Color3.fromRGB(58, 132, 62)
	local moss = Color3.fromRGB(110, 206, 80)
	local bark = Color3.fromRGB(122, 80, 50)
	local belly = Color3.fromRGB(176, 214, 120)
	local dark = Color3.fromRGB(38, 92, 46)

	addStud(rig, root, "Torso", Vector3.new(9, 7, 13), CFrame.new(0, 1.5, 0), fur)
	add(rig, root, "Belly", Vector3.new(7.6, 1, 11), CFrame.new(0, -2.1, 0), belly)
	addStud(rig, root, "Hump", Vector3.new(8, 3, 5), CFrame.new(0, 4.6, -3.5), dark)
	local rng = Random.new(11)
	for n = 1, 6 do
		local x, z = rng:NextNumber(-3, 3), rng:NextNumber(-2, 5.5)
		addStud(rig, root, "Moss", Vector3.new(rng:NextNumber(2.4, 3.6), 1, rng:NextNumber(2.4, 3.6)), CFrame.new(x, 5.4, z), moss)
		if n % 2 == 0 then
			add(rig, root, "Flower", Vector3.new(0.9, 0.9, 0.9), CFrame.new(x, 6.2, z), if n == 4 then Color3.fromRGB(255, 120, 180) else Color3.fromRGB(255, 226, 90), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
	end
	for _, z in { -1.5, 3.5 } do
		add(rig, root, "MushroomStem", Vector3.new(0.6, 1.4, 0.6), CFrame.new(-2.6, 6.2, z), BONE)
		add(rig, root, "MushroomCap", Vector3.new(2, 1, 2), CFrame.new(-2.6, 7, z), Color3.fromRGB(230, 60, 60), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
	for n = 0, 7 do
		local angle = n * math.pi / 4
		addStud(rig, root, "LeafMane", Vector3.new(2.6, 2.6, 1.4), CFrame.new(0, 3, -6.6) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 4.2, 0), if n % 2 == 0 then moss else Color3.fromRGB(80, 176, 70))
	end

	local head = joint(rig, root, "Head", CFrame.new(0, 4, -7.5), "Head", { Sleep = sleepCF(0, -2.6, -0.6, 0.35) })
	addStud(rig, head, "Skull", Vector3.new(6, 5, 6), CFrame.new(0, 0.8, -2.6), fur)
	add(rig, head, "Brow", Vector3.new(6.4, 1.2, 2), CFrame.new(0, 2.7, -4.8), dark)
	add(rig, head, "Snout", Vector3.new(4, 2.4, 3.2), CFrame.new(0, -0.6, -6.2), belly)
	add(rig, head, "Nose", Vector3.new(1.6, 1, 1), CFrame.new(0, 0.3, -7.85), BLACK)
	for _, s in { -1, 1 } do
		eye(rig, head, Vector3.new(1.2, 1.2, 0.4), CFrame.new(s * 1.6, 1.6, -5.65), Color3.fromRGB(255, 220, 60), fur)
		addWedge(rig, head, "Ear", Vector3.new(1.2, 2, 1.6), CFrame.new(s * 2.8, 3.6, -1.8), dark)
		addStud(rig, head, "Antler", Vector3.new(0.9, 4, 0.9), CFrame.new(s * 2.2, 4.8, -1.4) * CFrame.Angles(0, 0, -s * 0.35), bark)
		addStud(rig, head, "Antler", Vector3.new(0.8, 2.8, 0.8), CFrame.new(s * 3.7, 6.3, -1.6) * CFrame.Angles(0, 0, -s * 0.95), bark)
		addStud(rig, head, "Antler", Vector3.new(0.8, 2.4, 0.8), CFrame.new(s * 2.5, 7.3, -1.2) * CFrame.Angles(-0.35, 0, 0), bark)
		addStud(rig, head, "Antler", Vector3.new(0.8, 2, 0.8), CFrame.new(s * 4.6, 7.8, -1.5) * CFrame.Angles(0, 0, -s * 0.2), bark)
		add(rig, head, "AntlerLeaf", Vector3.new(1.4, 1.4, 1.4), CFrame.new(s * 4.8, 8.9, -1.5), moss)
	end
	for n = -1, 1, 2 do
		add(rig, head, "Fang", Vector3.new(0.5, 0.9, 0.5), CFrame.new(n * 1.1, -2.1, -7.2), BONE)
	end
	local jaw = joint(rig, head, "Jaw", CFrame.new(0, -1.8, -3.5), "Jaw", { Amp = 0.45 })
	add(rig, jaw, "LowerJaw", Vector3.new(3.8, 1, 4), CFrame.new(0, -0.4, -2.6), fur)
	for n = -1.2, 1.2, 0.8 do
		add(rig, jaw, "Tooth", Vector3.new(0.4, 0.6, 0.4), CFrame.new(n, 0.3, -4.2), BONE)
	end

	for _, leg in { { -1, -1, 0 }, { 1, -1, math.pi }, { -1, 1, math.pi }, { 1, 1, 0 } } do
		local s, front, phase = leg[1], leg[2], leg[3]
		local pivot = joint(rig, root, "Leg", CFrame.new(s * 3.4, -0.6, front * 4.2), "Leg", {
			Amp = 0.6, Phase = phase, Sleep = CFrame.Angles(-front * 1.35, 0, 0),
		})
		add(rig, pivot, "Thigh", Vector3.new(2.8, 3.2, 3), CFrame.new(0, -1.4, 0), fur)
		add(rig, pivot, "Shin", Vector3.new(2.4, 2.4, 2.4), CFrame.new(0, -3.6, 0), dark)
		addStud(rig, pivot, "Paw", Vector3.new(3, 1.2, 3.6), CFrame.new(0, -5, -0.4), bark)
		for c = -1, 1 do
			add(rig, pivot, "Claw", Vector3.new(0.5, 0.6, 0.8), CFrame.new(c * 0.9, -5.2, -2.5), BONE)
		end
	end

	local tail = joint(rig, root, "Tail", CFrame.new(0, 2.5, 6.5), "Tail", { Amp = 0.35, Sleep = CFrame.Angles(0.5, 0.6, 0) })
	add(rig, tail, "TailBase", Vector3.new(2, 2, 2.5), CFrame.new(0, 0.5, 1.2), fur)
	addStud(rig, tail, "TailLeaf", Vector3.new(1.8, 1.8, 2.2), CFrame.new(0, 1.3, 3.2), Color3.fromRGB(80, 176, 70))
	addStud(rig, tail, "TailTuft", Vector3.new(2.6, 2.6, 2.6), CFrame.new(0, 2.2, 4.8), moss)

	return finish(rig, 1, head, 9)
end

-- 2. DESERT — Dune Scorpion: armoured, six legs, pincers and a curled stinger.
local function duneScorpion(): Model
	local rig = newRig(2, 3.6, 1.6)
	local root = rig.Root
	local shell = Color3.fromRGB(214, 140, 60)
	local dark = Color3.fromRGB(150, 86, 40)
	local sand = Color3.fromRGB(244, 204, 128)
	local venom = Color3.fromRGB(170, 70, 230)

	addStud(rig, root, "Thorax", Vector3.new(8, 3, 8), CFrame.new(0, 0.6, 0), shell)
	for n, z in { -2.6, 0, 2.6 } do
		addStud(rig, root, "Plate", Vector3.new(7, 0.8, 2.4), CFrame.new(0, 2.5, z), if n % 2 == 0 then sand else dark)
	end
	for n, w in { 6.4, 5.6, 4.8 } do
		addStud(rig, root, "Abdomen", Vector3.new(w, 2.8 - n * 0.2, 3), CFrame.new(0, 0.6, 2.4 + n * 2.8), if n % 2 == 0 then dark else shell)
	end
	local head = add(rig, root, "Head", Vector3.new(6, 2.4, 3), CFrame.new(0, 0.8, -5.4), dark)
	for _, s in { -1, 1 } do
		eye(rig, head, Vector3.new(0.7, 0.7, 0.3), CFrame.new(s * 0.9, 0.8, -1.55), Color3.fromRGB(255, 50, 70), dark)
		eye(rig, head, Vector3.new(0.5, 0.5, 0.3), CFrame.new(s * 2.1, 0.5, -1.55), Color3.fromRGB(255, 50, 70), dark)
		addWedge(rig, head, "Mandible", Vector3.new(0.6, 1, 1.6), CFrame.new(s * 1.2, -1, -2.2) * CFrame.Angles(math.pi, 0, 0), sand)
	end

	for _, s in { -1, 1 } do
		local claw = joint(rig, root, "Claw", CFrame.new(s * 3.6, 0.6, -5), "Arm", {
			Amp = 0.25, Axis = "Y", Phase = if s > 0 then math.pi else 0, Sleep = CFrame.Angles(0, s * 0.45, 0),
		})
		add(rig, claw, "UpperArm", Vector3.new(1.6, 1.6, 4), CFrame.new(s * 1.2, 0, -1.8) * CFrame.Angles(0, -s * 0.3, 0), shell)
		add(rig, claw, "Forearm", Vector3.new(1.4, 1.4, 3.5), CFrame.new(s * 1.7, 0, -4.8), dark)
		addStud(rig, claw, "Pincer", Vector3.new(2.6, 2, 2.8), CFrame.new(s * 1.8, 0.2, -7.6), shell)
		local snap = joint(rig, claw, "Pincers", CFrame.new(s * 1.8, 0.2, -8.8), "Jaw", { Amp = 0.35, Axis = "Y", Side = s })
		add(rig, snap, "Finger", Vector3.new(0.9, 0.9, 2.8), CFrame.new(-s * 0.7, 0, -1.3), sand)
		add(rig, claw, "Finger", Vector3.new(0.9, 0.9, 2.8), CFrame.new(s * 2.6, 0.2, -10.1), sand)
	end

	for s = -1, 1, 2 do
		for n, z in { -2.5, 0.5, 3.5 } do
			local leg = joint(rig, root, "Leg", CFrame.new(s * 4, 0, z), "Leg", {
				Amp = 0.45, Axis = "Y", Phase = (n + (if s > 0 then 1 else 0)) % 2 * math.pi, Sleep = CFrame.Angles(0, 0, s * 0.3),
			})
			add(rig, leg, "LegUpper", Vector3.new(5, 1, 1), CFrame.new(s * 2.4, 0.9, 0) * CFrame.Angles(0, 0, s * 0.45), shell)
			add(rig, leg, "LegLower", Vector3.new(1, 4.4, 1), CFrame.new(s * 5, -1.3, 0) * CFrame.Angles(0, 0, -s * 0.25), dark)
		end
	end

	local tail = joint(rig, root, "Tail", CFrame.new(0, 1.2, 10.6), "Tail", { Amp = 0.12, Axis = "X", Sleep = CFrame.Angles(0.9, 0, 0) })
	local segments = {
		{ Vector3.new(3.4, 2.4, 2.8), CFrame.new(0, 1.2, 1.2) },
		{ Vector3.new(3, 2.2, 2.6), CFrame.new(0, 3.6, 2.4) },
		{ Vector3.new(2.6, 2.1, 2.4), CFrame.new(0, 6.2, 2.6) },
		{ Vector3.new(2.3, 2, 2.2), CFrame.new(0, 8.6, 1.6) },
		{ Vector3.new(2, 1.8, 2), CFrame.new(0, 10.4, -0.2) },
	}
	for n, seg in segments do
		addStud(rig, tail, "TailSegment", seg[1], seg[2], if n % 2 == 0 then dark else shell)
	end
	add(rig, tail, "Bulb", Vector3.new(2.2, 2.2, 2.6), CFrame.new(0, 11.2, -2.2), venom, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local stinger = add(rig, tail, "Stinger", Vector3.new(0.7, 0.7, 2.6), CFrame.new(0, 10.5, -4.1) * CFrame.Angles(0.5, 0, 0), venom, Enum.Material.Neon)
	Style.Particles(stinger, "Drip", {
		Color = ColorSequence.new(venom), Rate = 3, Acceleration = Vector3.new(0, -12, 0), Speed = NumberRange.new(0),
		Size = NumberSequence.new(0.3),
	})

	return finish(rig, 2, head, 13)
end

-- 3. ICE — Frost Yeti: towering biped with horns, tusks and icicle fists.
local function frostYeti(): Model
	local rig = newRig(3, 7, 4)
	local root = rig.Root
	local fur = Color3.fromRGB(236, 246, 255)
	local shade = Color3.fromRGB(186, 214, 238)
	local face = Color3.fromRGB(104, 178, 232)
	local horn = Color3.fromRGB(70, 104, 156)
	local crystal = Color3.fromRGB(120, 224, 255)

	addStud(rig, root, "Chest", Vector3.new(9, 8, 6), CFrame.new(0, 4.5, 0), fur)
	add(rig, root, "Belly", Vector3.new(6.5, 5, 0.8), CFrame.new(0, 3.6, -3.1), face)
	add(rig, root, "Hips", Vector3.new(7.6, 2.4, 5.4), CFrame.new(0, 0.6, 0), shade)
	for _, s in { -1, 1 } do
		for _, z in { -1.2, 1.2 } do
			addStud(rig, root, "Tuft", Vector3.new(2.4, 2.4, 2.4), CFrame.new(s * 4.6, 7.8, z), fur)
		end
	end
	for n = 0, 2 do
		local c = add(rig, root, "IceCrystal", Vector3.new(1.2, 2.6 - n * 0.4, 1.2), CFrame.new((n - 1) * 1.8, 7.4 - math.abs(n - 1) * 0.6, 3.2) * CFrame.Angles(-0.4, 0, (n - 1) * 0.4), crystal, Enum.Material.Neon)
		c.Transparency = 0.15
	end

	local head = joint(rig, root, "Head", CFrame.new(0, 9, -0.5), "Head", { Sleep = sleepCF(0, -0.8, -0.8, 0.5) })
	addStud(rig, head, "Skull", Vector3.new(6, 5, 5.6), CFrame.new(0, 2, -0.6), fur)
	add(rig, head, "Face", Vector3.new(4.6, 3.2, 0.6), CFrame.new(0, 1.6, -3.4), face)
	add(rig, head, "Brow", Vector3.new(5, 0.9, 1), CFrame.new(0, 3.4, -3.4), shade)
	for _, s in { -1, 1 } do
		eye(rig, head, Vector3.new(0.9, 0.9, 0.3), CFrame.new(s * 1.1, 2.4, -3.75), Color3.fromRGB(255, 70, 100), face)
		addStud(rig, head, "Horn", Vector3.new(1.3, 2.6, 1.3), CFrame.new(s * 3.3, 4, 0) * CFrame.Angles(0, 0, -s * 0.55), horn)
		addStud(rig, head, "Horn", Vector3.new(1, 2.2, 1), CFrame.new(s * 4.6, 5.7, -0.4) * CFrame.Angles(0, 0, -s * 0.2), horn)
		add(rig, head, "Tusk", Vector3.new(0.6, 1.5, 0.6), CFrame.new(s * 1.4, -0.2, -3.6) * CFrame.Angles(0.2, 0, s * 0.15), BONE)
	end
	local jaw = joint(rig, head, "Jaw", CFrame.new(0, 0.2, -2.6), "Jaw", { Amp = 0.4 })
	add(rig, jaw, "LowerJaw", Vector3.new(4, 1.2, 2.6), CFrame.new(0, -0.6, -0.8), shade)
	for n = -1, 1 do
		add(rig, jaw, "Tooth", Vector3.new(0.4, 0.5, 0.4), CFrame.new(n * 0.9, 0.1, -1.9), BONE)
	end

	for _, s in { -1, 1 } do
		local arm = joint(rig, root, "Arm", CFrame.new(s * 5.6, 7.6, 0), "Arm", {
			Amp = 0.7, Phase = if s > 0 then math.pi else 0, Sleep = CFrame.Angles(0.35, 0, s * 0.25),
		})
		addStud(rig, arm, "UpperArm", Vector3.new(3.2, 5, 3.2), CFrame.new(0, -2.2, 0), fur)
		add(rig, arm, "Forearm", Vector3.new(3, 3.6, 3), CFrame.new(0, -5.8, -0.3), shade)
		addStud(rig, arm, "Fist", Vector3.new(3.6, 2.8, 3.6), CFrame.new(0, -8.4, -0.5), face)
		for c = -1, 1 do
			local icicle = add(rig, arm, "Icicle", Vector3.new(0.5, 1.4, 0.5), CFrame.new(c * 1, -10.2, -1.3), crystal, Enum.Material.Neon)
			icicle.Transparency = 0.1
		end
		local leg = joint(rig, root, "Leg", CFrame.new(s * 2.4, 0.4, 0), "Leg", {
			Amp = 0.55, Phase = if s > 0 then 0 else math.pi, Sleep = CFrame.Angles(1.45, 0, s * 0.2),
		})
		addStud(rig, leg, "Thigh", Vector3.new(3.6, 3.8, 3.6), CFrame.new(0, -1.6, 0), fur)
		add(rig, leg, "Shin", Vector3.new(3.2, 2.6, 3.2), CFrame.new(0, -4.4, 0), shade)
		addStud(rig, leg, "Foot", Vector3.new(4, 1.4, 5), CFrame.new(0, -6.7, -0.8), face)
	end
	Style.Particles(head, "FrostBreath", {
		Color = ColorSequence.new(Color3.fromRGB(220, 250, 255)), Rate = 4, Speed = NumberRange.new(2, 4),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) }),
		Transparency = NumberSequence.new(0.3, 1), Texture = "rbxasset://textures/particles/smoke_main.dds",
		EmissionDirection = Enum.NormalId.Front,
	})

	return finish(rig, 3, head, 8)
end

-- 4. LAVA — Magma Drake: winged dragon with molten cracks and a flame tail.
local function magmaDrake(): Model
	local rig = newRig(4, 6.4, 3.6)
	local root = rig.Root
	local scale = Color3.fromRGB(76, 46, 50)
	local dark = Color3.fromRGB(46, 28, 34)
	local lava = Color3.fromRGB(255, 120, 40)
	local belly = Color3.fromRGB(214, 96, 52)
	local horn = Color3.fromRGB(255, 220, 150)
	local membrane = Color3.fromRGB(180, 52, 40)

	addStud(rig, root, "Body", Vector3.new(8, 6, 14), CFrame.new(0, 1.6, 0), scale)
	add(rig, root, "Belly", Vector3.new(7, 1, 12), CFrame.new(0, -1.5, 0), belly)
	for _, s in { -1, 1 } do
		for n = -1, 1 do
			add(rig, root, "Crack", Vector3.new(0.2, 3.6, 0.4), CFrame.new(s * 4.02, 1.6, n * 3.6) * CFrame.Angles(n * 0.4, 0, 0), lava, Enum.Material.Neon)
		end
	end
	for n = 0, 5 do
		addWedge(rig, root, "SpineFin", Vector3.new(0.6, 1.8 + (n % 2) * 0.6, 2), CFrame.new(0, 5.4, -5 + n * 2.1), if n % 2 == 0 then lava else horn, Enum.Material.Neon)
	end
	addStud(rig, root, "Neck", Vector3.new(3.6, 3.6, 5.6), CFrame.new(0, 4.2, -8.2) * CFrame.Angles(0.55, 0, 0), scale)

	local head = joint(rig, root, "Head", CFrame.new(0, 6.2, -10.6), "Head", { Sleep = sleepCF(0, -4.4, 1.2, 0.35) })
	addStud(rig, head, "Skull", Vector3.new(4.6, 4, 5.4), CFrame.new(0, 0.8, -1.8), scale)
	add(rig, head, "Snout", Vector3.new(3.6, 2.4, 4), CFrame.new(0, 0, -5.6), scale)
	for _, s in { -1, 1 } do
		add(rig, head, "Nostril", Vector3.new(0.6, 0.6, 0.3), CFrame.new(s * 0.9, 0.6, -7.62), lava, Enum.Material.Neon)
		eye(rig, head, Vector3.new(1, 0.8, 0.3), CFrame.new(s * 1.5, 1.8, -4.55), Color3.fromRGB(255, 226, 60), scale)
		addStud(rig, head, "Horn", Vector3.new(0.9, 3.6, 0.9), CFrame.new(s * 1.6, 3.6, 0.2) * CFrame.Angles(0.85, 0, s * 0.2), horn)
		add(rig, head, "Horn", Vector3.new(0.7, 2, 0.7), CFrame.new(s * 2.5, 2.4, 0.4) * CFrame.Angles(1.1, 0, s * 0.5), horn)
		add(rig, head, "Fang", Vector3.new(0.45, 1, 0.45), CFrame.new(s * 1.1, -1.5, -6.9), BONE)
	end
	local jaw = joint(rig, head, "Jaw", CFrame.new(0, -1.2, -2.6), "Jaw", { Amp = 0.5 })
	add(rig, jaw, "LowerJaw", Vector3.new(3.4, 1, 5.2), CFrame.new(0, -0.4, -2.8), dark)
	add(rig, jaw, "Tongue", Vector3.new(1.6, 0.3, 3), CFrame.new(0, 0.2, -2.4), lava, Enum.Material.Neon)
	local breathAt = add(rig, head, "Mouth", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, -0.8, -7.8), lava)
	breathAt.Transparency = 1
	local breath = Style.Particles(breathAt, "RageBreath", {
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(255, 230, 90), Color3.fromRGB(255, 70, 30)),
		Rate = 60, Speed = NumberRange.new(14, 20), Lifetime = NumberRange.new(0.3, 0.5), SpreadAngle = Vector2.new(12, 12),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3.5) }),
		EmissionDirection = Enum.NormalId.Front, LightEmission = 1, Enabled = false,
	})
	breath:SetAttribute("Rage", true)

	for _, s in { -1, 1 } do
		local wing = joint(rig, root, "Wing", CFrame.new(s * 3.8, 4.4, -1.5) * CFrame.Angles(0, 0, s * 0.25), "Wing", {
			Amp = 0.45, Side = s, Sleep = CFrame.Angles(0, 0, -s * 0.85),
		})
		addStud(rig, wing, "WingBone", Vector3.new(8, 0.8, 0.8), CFrame.new(s * 4, 1.2, 0) * CFrame.Angles(0, 0, s * 0.25), dark)
		add(rig, wing, "WingBone", Vector3.new(0.6, 0.6, 6.4), CFrame.new(s * 7.6, 2.1, 2.8) * CFrame.Angles(0, -s * 0.25, 0), dark)
		add(rig, wing, "Membrane", Vector3.new(6.6, 0.3, 5.2), CFrame.new(s * 3.8, 0.9, 2.6) * CFrame.Angles(0, 0, s * 0.25), membrane)
		add(rig, wing, "Membrane", Vector3.new(4.4, 0.3, 4.4), CFrame.new(s * 7.6, 1.9, 3.2) * CFrame.Angles(0, 0, s * 0.25), Style.Lighten(membrane, 0.12))
		add(rig, wing, "WingClaw", Vector3.new(0.5, 1.2, 0.5), CFrame.new(s * 8.1, 2.8, -0.4), horn)
	end

	for _, leg in { { -1, -1, 0 }, { 1, -1, math.pi }, { -1, 1, math.pi }, { 1, 1, 0 } } do
		local s, front, phase = leg[1], leg[2], leg[3]
		local pivot = joint(rig, root, "Leg", CFrame.new(s * 3.4, -0.8, front * 4.6), "Leg", {
			Amp = 0.6, Phase = phase, Sleep = CFrame.Angles(-front * 1.35, 0, 0),
		})
		addStud(rig, pivot, "Thigh", Vector3.new(2.8, 3, 3.2), CFrame.new(0, -1.2, 0), scale)
		add(rig, pivot, "Shin", Vector3.new(2.2, 2.4, 2.4), CFrame.new(0, -3.4, 0), dark)
		add(rig, pivot, "Foot", Vector3.new(3, 1.2, 3.8), CFrame.new(0, -4.9, -0.6), dark)
		for c = -1, 1 do
			add(rig, pivot, "Claw", Vector3.new(0.5, 0.6, 0.8), CFrame.new(c * 0.9, -5.1, -2.8), horn)
		end
	end

	local tail = joint(rig, root, "Tail", CFrame.new(0, 1.6, 7), "Tail", { Amp = 0.4, Sleep = CFrame.Angles(0, 0.9, 0) })
	for k = 0, 5 do
		addStud(rig, tail, "TailSegment", Vector3.new(3.4 - k * 0.45, 2.8 - k * 0.35, 3), CFrame.new(0, -k * 0.25, 1.6 + k * 2.7), if k % 2 == 0 then scale else dark)
		addWedge(rig, tail, "TailFin", Vector3.new(0.4, 1.2, 1.8), CFrame.new(0, 1.6 - k * 0.4, 1.6 + k * 2.7), lava, Enum.Material.Neon)
	end
	local tip = add(rig, tail, "TailFlame", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, -1.4, 18.4), lava, Enum.Material.Neon)
	Style.Particles(tip, "TailFire", {
		Texture = "rbxasset://textures/particles/fire_main.dds", Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), lava),
		Rate = 18, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(1, 3), Acceleration = Vector3.new(0, 6, 0), LightEmission = 1,
	})
	Style.Light(tip, lava, 2, 14)

	return finish(rig, 4, head, 7)
end

-- 5. TOXIC — Sludge Mech: rusty mechanical hound with a glowing sludge tank.
local function sludgeMech(): Model
	local rig = newRig(5, 6.4, 3.2)
	local root = rig.Root
	local rust = Color3.fromRGB(198, 106, 42)
	local darkRust = Color3.fromRGB(128, 64, 30)
	local metal = Color3.fromRGB(74, 74, 86)
	local hazard = Color3.fromRGB(252, 204, 40)
	local toxic = Color3.fromRGB(160, 255, 60)

	addStud(rig, root, "Hull", Vector3.new(8, 5.6, 12), CFrame.new(0, 1.4, 0), rust)
	for _, s in { -1, 1 } do
		add(rig, root, "SidePlate", Vector3.new(0.6, 4, 10), CFrame.new(s * 4.3, 1.4, 0), darkRust)
		for n = -1, 1 do
			add(rig, root, "Bolt", Vector3.new(0.5, 0.5, 0.5), CFrame.new(s * 4.65, 2.8, n * 4), metal, Enum.Material.Metal, Enum.PartType.Ball)
		end
		local stack = addCylinder(rig, root, "Exhaust", 3.2, 1.1, CFrame.new(s * 2.6, 5.8, 4.6) * CFrame.Angles(0, 0, math.pi / 2), metal, Enum.Material.Metal)
		Style.Particles(stack, "Smoke", {
			Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(Color3.fromRGB(120, 200, 90)),
			Rate = 5, Speed = NumberRange.new(3, 5), EmissionDirection = Enum.NormalId.Right, LightEmission = 0.2,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.4) }),
			Transparency = NumberSequence.new(0.4, 1),
		})
	end
	for n = 0, 7 do
		add(rig, root, "Hazard", Vector3.new(1, 1, 0.6), CFrame.new(-3.5 + n, 0.1, -6.2), if n % 2 == 0 then hazard else Color3.fromRGB(30, 30, 36))
	end
	local glass = addCylinder(rig, root, "Tank", 7, 3.8, CFrame.new(0, 5.6, 0.6) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(200, 255, 200), Enum.Material.Glass)
	glass.Transparency = 0.45
	local sludge = addCylinder(rig, root, "Sludge", 6.6, 3, CFrame.new(0, 5.4, 0.6) * CFrame.Angles(0, math.pi / 2, 0), toxic, Enum.Material.Neon)
	Style.Light(sludge, toxic, 2, 16)
	for _, z in { -3, 4.2 } do
		addCylinder(rig, root, "TankCap", 0.6, 4.2, CFrame.new(0, 5.6, z + 0.6) * CFrame.Angles(0, math.pi / 2, 0), metal, Enum.Material.Metal)
	end
	add(rig, root, "Antenna", Vector3.new(0.3, 4, 0.3), CFrame.new(2.6, 6, -3.6), metal, Enum.Material.Metal)
	local beacon = add(rig, root, "Beacon", Vector3.new(0.8, 0.8, 0.8), CFrame.new(2.6, 8.2, -3.6), Color3.fromRGB(255, 50, 50), Enum.Material.Neon, Enum.PartType.Ball)
	Style.Light(beacon, Color3.fromRGB(255, 50, 50), 1, 8)

	local head = joint(rig, root, "Head", CFrame.new(0, 4.2, -6.8), "Head", { Sleep = sleepCF(0, -2.2, 0, 0.3) })
	addStud(rig, head, "HeadBox", Vector3.new(5.6, 4.2, 5.2), CFrame.new(0, 0.4, -2.2), rust)
	eye(rig, head, Vector3.new(4.6, 1.1, 0.4), CFrame.new(0, 1.2, -4.85), toxic, darkRust)
	for _, s in { -1, 1 } do
		addWedge(rig, head, "Fin", Vector3.new(0.6, 2, 3), CFrame.new(s * 3, 2.6, -1.4), darkRust)
	end
	local jaw = joint(rig, head, "Jaw", CFrame.new(0, -1.4, -0.6), "Jaw", { Amp = 0.5 })
	add(rig, jaw, "JawPlate", Vector3.new(5, 1.2, 4.6), CFrame.new(0, -0.6, -2.2), darkRust)
	for n = -2, 2 do
		add(rig, jaw, "Grill", Vector3.new(0.5, 0.9, 0.5), CFrame.new(n * 0.9, 0.3, -4.2), metal, Enum.Material.Metal)
	end
	Style.Particles(jaw, "Drool", {
		Color = ColorSequence.new(toxic), Rate = 6, Speed = NumberRange.new(0), Acceleration = Vector3.new(0, -14, 0),
		Size = NumberSequence.new(0.35), LightEmission = 1,
	})

	for _, leg in { { -1, -1, 0 }, { 1, -1, math.pi }, { -1, 1, math.pi }, { 1, 1, 0 } } do
		local s, front, phase = leg[1], leg[2], leg[3]
		local pivot = joint(rig, root, "Leg", CFrame.new(s * 3.6, -0.4, front * 4), "Leg", {
			Amp = 0.55, Phase = phase, Sleep = CFrame.Angles(-front * 1.3, 0, 0),
		})
		addStud(rig, pivot, "Housing", Vector3.new(2.6, 3, 2.8), CFrame.new(0, -1.2, 0), darkRust)
		addCylinder(rig, pivot, "Piston", 2.8, 1.2, CFrame.new(0, -3.6, 0) * CFrame.Angles(0, 0, math.pi / 2), metal, Enum.Material.Metal)
		add(rig, pivot, "Foot", Vector3.new(3.2, 1.2, 3.8), CFrame.new(0, -5.4, -0.4), Color3.fromRGB(34, 34, 40))
		add(rig, pivot, "ToeStripe", Vector3.new(3.24, 0.4, 0.6), CFrame.new(0, -5.2, -2.1), hazard)
	end

	local tail = joint(rig, root, "Tail", CFrame.new(0, 2.4, 6.2), "Tail", { Amp = 0.45, Sleep = CFrame.Angles(0.6, 0.5, 0) })
	for k = 0, 3 do
		add(rig, tail, "Hose", Vector3.new(1, 1, 2), CFrame.new(0, k * 0.5, 1 + k * 1.9) * CFrame.Angles(-0.25, 0, 0), Color3.fromRGB(34, 34, 40))
	end
	local nozzle = add(rig, tail, "Nozzle", Vector3.new(1.4, 1.4, 1), CFrame.new(0, 2.2, 8.4), toxic, Enum.Material.Neon)
	Style.Particles(nozzle, "Drip", { Color = ColorSequence.new(toxic), Rate = 4, Speed = NumberRange.new(0), Acceleration = Vector3.new(0, -14, 0), Size = NumberSequence.new(0.4) })

	return finish(rig, 5, head, 7)
end

-- 6. SHADOW — Void Reaper: floating hooded wraith with a glowing scythe.
local function voidReaper(): Model
	local rig = newRig(6, 8, 2)
	local root = rig.Root
	local robe = Color3.fromRGB(40, 24, 66)
	local robe2 = Color3.fromRGB(64, 38, 100)
	local trim = Color3.fromRGB(180, 96, 255)
	local cyan = Color3.fromRGB(70, 230, 255)
	local void = Color3.fromRGB(8, 4, 14)

	local body = joint(rig, root, "Body", CFrame.identity, "Float", { Amp = 0.7, Sleep = CFrame.new(0, 0, 0) })
	addStud(rig, body, "RobeTop", Vector3.new(6, 3, 5), CFrame.new(0, 3.8, 0), robe)
	addStud(rig, body, "RobeMid", Vector3.new(7, 3, 6), CFrame.new(0, 1, 0), robe2)
	addStud(rig, body, "RobeLow", Vector3.new(8, 3, 7), CFrame.new(0, -1.8, 0.2), robe)
	add(rig, body, "Trim", Vector3.new(8.15, 0.35, 7.15), CFrame.new(0, -0.3, 0.2), trim, Enum.Material.Neon)
	add(rig, body, "Trim", Vector3.new(7.1, 0.3, 6.1), CFrame.new(0, 2.5, 0), trim, Enum.Material.Neon)
	for n = 0, 7 do
		local angle = n * math.pi / 4
		local strip = add(rig, body, "Tatter", Vector3.new(1.8, 3.4 - (n % 2) * 0.8, 1.2), CFrame.Angles(0, angle, 0) * CFrame.new(0, -4.6, 3.1), if n % 2 == 0 then robe else robe2)
		strip.Transparency = 0.15
	end
	addStud(rig, body, "Mantle", Vector3.new(9, 1.6, 6), CFrame.new(0, 5.6, 0.4), robe2)
	for _, s in { -1, 1 } do
		addWedge(rig, body, "ShoulderSpike", Vector3.new(0.8, 2, 1.6), CFrame.new(s * 4, 7.2, 0.4), trim, Enum.Material.Neon)
	end

	local head = joint(rig, body, "Head", CFrame.new(0, 7, -0.3), "Head", { Sleep = sleepCF(0, -1.2, -0.6, 0.55) })
	addStud(rig, head, "Hood", Vector3.new(5.2, 5.4, 5.2), CFrame.new(0, 0.6, 0), robe2)
	addWedge(rig, head, "HoodPeak", Vector3.new(5.2, 2, 2.6), CFrame.new(0, 4.3, 0.9) * CFrame.Angles(0, math.pi, 0), robe2)
	add(rig, head, "Face", Vector3.new(3.8, 3.6, 0.4), CFrame.new(0, 0.2, -2.45), void)
	for _, s in { -1, 1 } do
		eye(rig, head, Vector3.new(0.9, 0.5, 0.2), CFrame.new(s * 0.9, 0.8, -2.72), cyan, void)
	end
	for n = 0, 4 do
		local angle = (n - 2) * 0.45
		add(rig, head, "Crown", Vector3.new(0.5, 1.8, 0.5), CFrame.new(math.sin(angle) * 2.2, 4.2, math.cos(angle) * 0.6 - 0.8) * CFrame.Angles(0, 0, -angle * 0.5), trim, Enum.Material.Neon)
	end

	for _, s in { -1, 1 } do
		local arm = joint(rig, body, "Arm", CFrame.new(s * 4.4, 5, 0), "Arm", {
			Amp = 0.35, Phase = if s > 0 then math.pi else 0, Sleep = CFrame.Angles(0.4, 0, -s * 0.2),
		})
		addStud(rig, arm, "Sleeve", Vector3.new(2.4, 5, 2.4), CFrame.new(0, -2.2, -0.4), robe)
		add(rig, arm, "Cuff", Vector3.new(2.6, 0.4, 2.6), CFrame.new(0, -4.6, -0.4), trim, Enum.Material.Neon)
		add(rig, arm, "Hand", Vector3.new(1.6, 1.6, 1.6), CFrame.new(0, -5.4, -0.8), BONE)
		for f = -1, 1 do
			add(rig, arm, "Finger", Vector3.new(0.35, 1.3, 0.35), CFrame.new(f * 0.5, -6.6, -1.2) * CFrame.Angles(-0.3, 0, 0), BONE)
		end
		if s > 0 then
			add(rig, arm, "ScytheHandle", Vector3.new(0.6, 15, 0.6), CFrame.new(0, -4.4, -1.8) * CFrame.Angles(0.12, 0, 0), Color3.fromRGB(56, 36, 40))
			add(rig, arm, "ScytheBlade", Vector3.new(0.35, 1.8, 5), CFrame.new(0, 2.8, -4.6) * CFrame.Angles(-0.2, 0, 0), Color3.fromRGB(190, 200, 220), Enum.Material.Metal)
			add(rig, arm, "ScytheEdge", Vector3.new(0.4, 0.45, 5.2), CFrame.new(0, 1.8, -4.8) * CFrame.Angles(-0.2, 0, 0), cyan, Enum.Material.Neon)
			addWedge(rig, arm, "ScytheTip", Vector3.new(0.35, 1.8, 2), CFrame.new(0, 1.9, -8.1) * CFrame.Angles(math.pi, 0, 0), Color3.fromRGB(190, 200, 220), Enum.Material.Metal)
		end
	end

	local orbit = joint(rig, body, "Orbit", CFrame.new(0, 2, 0), "Spin", { Amp = 1.4 })
	for n = 0, 3 do
		local angle = n * math.pi / 2
		local orb = add(rig, orbit, "Wisp", Vector3.new(1.1, 1.1, 1.1), CFrame.new(math.cos(angle) * 6.5, math.sin(angle * 2) * 1.2, math.sin(angle) * 6.5), if n % 2 == 0 then trim else cyan, Enum.Material.Neon, Enum.PartType.Ball)
		Style.Light(orb, orb.Color, 1, 8)
	end
	Style.Particles(body, "Shadow", {
		Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(Color3.fromRGB(70, 30, 120)),
		Rate = 10, Speed = NumberRange.new(0.5, 1.5), Acceleration = Vector3.new(0, -2, 0), LightEmission = 0.3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 4) }),
		Transparency = NumberSequence.new(0.5, 1),
	})

	return finish(rig, 6, head, 8)
end

local builders = { brambleBeast, duneScorpion, frostYeti, magmaDrake, sludgeMech, voidReaper }

function Monsters.Build(zone: number, home: CFrame, parent: Instance?): Model
	local model = builders[zone]()
	local hip = model:GetAttribute("Hip") :: number
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
	for _, gui in model:GetDescendants() do
		if gui:IsA("BillboardGui") and gui.Name == "Status" then
			local label = gui:FindFirstChild("Text") :: TextLabel
			label.Text = text
			label.TextColor3 = color
		end
	end
end

function Monsters.SetRage(model: Model, on: boolean)
	for _, item in model:GetDescendants() do
		if item:IsA("ParticleEmitter") and item:GetAttribute("Rage") then
			item.Enabled = on
		elseif item:IsA("PointLight") and item.Name == "RageLight" then
			item.Enabled = on
		end
	end
end

-- Animation ----------------------------------------------------------------

export type Pose = {
	Motors: { Motor6D },
	Eyes: { BasePart },
	Lids: { BasePart },
	Sleep: number,
	Rage: number,
	LidsClosed: boolean?,
	EyeRage: number?,
}

function Monsters.Collect(model: Model): Pose
	local pose: Pose = { Motors = {}, Eyes = {}, Lids = {}, Sleep = if model:GetAttribute("Sleeping") then 1 else 0, Rage = 0 }
	for _, item in model:GetDescendants() do
		if item:IsA("Motor6D") and item:GetAttribute("Rest") then
			table.insert(pose.Motors, item)
		elseif item:IsA("BasePart") and item.Name == "Eye" then
			table.insert(pose.Eyes, item)
		elseif item:IsA("BasePart") and item.Name == "Lid" then
			table.insert(pose.Lids, item)
		end
	end
	return pose
end

local function axisAngles(axis: string?, angle: number): CFrame
	if axis == "Y" then
		return CFrame.Angles(0, angle, 0)
	elseif axis == "Z" then
		return CFrame.Angles(0, 0, angle)
	end
	return CFrame.Angles(angle, 0, 0)
end

local RAGE_EYE = Color3.fromRGB(255, 40, 40)

-- sleep: 0 awake .. 1 asleep; move: 0 idle .. 1 full stride; rage: 0 .. 1.
function Monsters.Animate(pose: Pose, t: number, sleep: number, move: number, rage: number)
	for _, motor in pose.Motors do
		local rest = motor:GetAttribute("Rest") :: CFrame
		local kind = motor:GetAttribute("Kind")
		local amp = (motor:GetAttribute("Amp") or 0.5) :: number
		local phase = (motor:GetAttribute("Phase") or 0) :: number
		local axis = motor:GetAttribute("Axis") :: string?
		local target: CFrame
		if kind == "Leg" or kind == "Arm" then
			local stride = math.sin(t * (6 + move * 6) + phase) * amp * move
			local idle = if kind == "Arm" then math.sin(t * 1.5 + phase) * 0.05 else 0
			target = rest * axisAngles(axis, stride + idle)
		elseif kind == "Tail" then
			target = rest * axisAngles(axis or "Y", math.sin(t * (2 + move * 4) + phase) * amp * (0.6 + move * 0.6 + rage * 0.5))
		elseif kind == "Head" then
			local bob = math.sin(t * 1.6) * 0.05 + math.sin(t * 12) * 0.05 * move + math.sin(t * 20) * 0.04 * rage
			target = rest * CFrame.Angles(bob, math.sin(t * 0.7) * 0.08 * (1 - move), 0)
		elseif kind == "Jaw" then
			local open = (0.08 + rage * 0.55 + move * 0.25) * (0.5 + 0.5 * math.sin(t * (5 + rage * 10)))
			local side = (motor:GetAttribute("Side") or 1) :: number
			target = rest * axisAngles(axis, -open * amp * 2 * side)
		elseif kind == "Wing" then
			local side = (motor:GetAttribute("Side") or 1) :: number
			target = rest * CFrame.Angles(0, 0, math.sin(t * (2.5 + move * 6)) * amp * side * (0.4 + move))
		elseif kind == "Float" then
			target = rest * CFrame.new(0, math.sin(t * 1.8) * amp, 0) * CFrame.Angles(move * 0.18, 0, 0)
		elseif kind == "Spin" then
			target = rest * CFrame.Angles(0, t * amp * (1 + rage), 0)
		else
			target = rest
		end
		if sleep > 0 and kind ~= "Spin" then
			local sleepPose = rest * ((motor:GetAttribute("Sleep") or CFrame.identity) :: CFrame)
			if kind == "Head" or kind == "Float" then
				sleepPose *= CFrame.new(0, math.sin(t * 1.3) * 0.12, 0)
			end
			target = target:Lerp(sleepPose, sleep)
		end
		motor.C0 = target
	end
	local closed = sleep > 0.55
	if pose.LidsClosed ~= closed then
		pose.LidsClosed = closed
		for _, lid in pose.Lids do
			lid.Transparency = if closed then 0 else 1
		end
		for _, e in pose.Eyes do
			e.Transparency = if closed then 1 else 0
		end
	end
	local eyeRage = math.floor(rage * 10 + 0.5) / 10
	if pose.EyeRage ~= eyeRage then
		pose.EyeRage = eyeRage
		for _, e in pose.Eyes do
			e.Color = (e:GetAttribute("Base") :: Color3):Lerp(RAGE_EYE, eyeRage)
		end
	end
end

return Monsters
