-- Small builders shared by the world, egg and monster modules.
local Style = {}

Style.CheckerTexture = "rbxassetid://6372755229"
Style.Font = Enum.Font.FredokaOne
Style.FontBold = Enum.Font.GothamBlack
Style.White = Color3.new(1, 1, 1)
Style.Ink = Color3.fromRGB(28, 22, 44)

local ALL_FACES = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top }

function Style.Part(parent: Instance?, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Style.Wedge(parent: Instance?, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Vertical cylinder (Roblox cylinders run along X, so rotate onto Y).
function Style.Cylinder(parent: Instance?, name: string, height: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Style.Part(parent, name, Vector3.new(height, diameter, diameter), cf * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
end

-- Lego-style studs on top (and optionally sides) of a part.
function Style.Studs(part: BasePart, sides: boolean?)
	part.Material = Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Studs
	if sides then
		part.FrontSurface = Enum.SurfaceType.Studs
		part.BackSurface = Enum.SurfaceType.Studs
		part.LeftSurface = Enum.SurfaceType.Studs
		part.RightSurface = Enum.SurfaceType.Studs
	end
	return part
end

-- Two-tone checker tiles, like a classic obby wall.
function Style.Checker(part: BasePart, tile: number?, faces: { Enum.NormalId }?, transparency: number?)
	for _, face in faces or ALL_FACES do
		local t = Instance.new("Texture")
		t.Name = "Checker"
		t.Texture = Style.CheckerTexture
		t.Face = face
		t.StudsPerTileU = tile or 8
		t.StudsPerTileV = tile or 8
		t.Color3 = Color3.new(0, 0, 0)
		t.Transparency = transparency or 0.82
		t.Parent = part
	end
	return part
end

function Style.Weld(part0: BasePart, part1: BasePart): Weld
	local w = Instance.new("Weld")
	w.Name = "Weld"
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = part0.CFrame:Inverse() * part1.CFrame
	w.Parent = part1
	return w
end

function Style.Light(part: BasePart, color: Color3, brightness: number?, range: number?): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness or 1.5
	l.Range = range or 14
	l.Shadows = false
	l.Parent = part
	return l
end

function Style.Particles(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.LightEmission = 0.8
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(1, 3)
	e.Rate = 6
	for key, value in props do
		(e :: any)[key] = value
	end
	e.Parent = parent
	return e
end

-- Floating world label that keeps a fixed size in studs.
function Style.Label(adornee: BasePart, text: string, color: Color3?, width: number?, height: number?, offsetY: number?): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(width or 10, height or 2.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY or 4, 0)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	gui.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Style.Font
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color or Style.White
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Style.Ink
	stroke.Parent = label
	gui.Parent = adornee
	return gui
end

-- Sign text printed on a part face; returns the title and subtitle labels.
function Style.Sign(part: BasePart, title: string, subtitle: string?, color: Color3?, face: Enum.NormalId?, pixelsPerStud: number?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 40
	gui.LightInfluence = 0
	gui.Parent = part
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.fromScale(0.92, if subtitle then 0.58 else 0.84)
	titleLabel.Position = UDim2.fromScale(0.04, 0.08)
	titleLabel.Font = Style.Font
	titleLabel.TextScaled = true
	titleLabel.Text = title
	titleLabel.TextColor3 = color or Style.White
	titleLabel.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Style.Ink
	stroke.Parent = titleLabel
	local sub
	if subtitle then
		sub = Instance.new("TextLabel")
		sub.Name = "Subtitle"
		sub.BackgroundTransparency = 1
		sub.Size = UDim2.fromScale(0.92, 0.28)
		sub.Position = UDim2.fromScale(0.04, 0.66)
		sub.Font = Style.Font
		sub.TextScaled = true
		sub.Text = subtitle
		sub.TextColor3 = Style.White
		sub.Parent = gui
		local s2 = stroke:Clone()
		s2.Thickness = 3
		s2.Parent = sub
	end
	return titleLabel, sub
end

function Style.Prompt(part: Instance, action: string, object: string, hold: number?, distance: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold or 0.35
	prompt.MaxActivationDistance = distance or 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

function Style.Darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function Style.Lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

return Style
