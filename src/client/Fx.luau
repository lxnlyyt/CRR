-- Client-side world effects: monster animation, treadmill belts, sounds, camera shake,
-- knockback, particle bursts and per-zone lighting.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("MonsterEgg")
local Config = require(Shared:WaitForChild("Config"))
local Monsters = require(Shared:WaitForChild("Monsters"))

local player = Players.LocalPlayer
local Fx = {}

type Tracked = { Pose: Monsters.Pose, Root: BasePart, Last: Vector3, Speed: number, Sleep: number }
local tracked: { [Model]: Tracked } = {}
local belts: { Texture } = {}
local shake = { Strength = 0, Until = 0 }
local boostUntil, boostLevel = 0, 0

local function track(model: Instance)
	if not model:IsA("Model") or tracked[model] then
		return
	end
	local root = model:WaitForChild("Root", 5) :: BasePart?
	if not root then
		return
	end
	tracked[model] = {
		Pose = Monsters.Collect(model),
		Root = root,
		Last = root.Position,
		Speed = 0,
		Sleep = if model:GetAttribute("Sleeping") then 1 else 0,
	}
end

function Fx.Init(world: Instance)
	local monsterFolder = world:WaitForChild("Runtime"):WaitForChild("Monsters")
	for _, model in monsterFolder:GetChildren() do
		task.spawn(track, model)
	end
	monsterFolder.ChildAdded:Connect(function(model)
		task.wait(0.2)
		track(model)
	end)
	monsterFolder.ChildRemoved:Connect(function(model)
		tracked[model :: Model] = nil
	end)
	-- Treadmills are rebuilt on every upgrade, so keep collecting their belt textures.
	local bases = world:WaitForChild("Sanctuary"):WaitForChild("Bases")
	local function addBelt(item: Instance)
		if item:IsA("Texture") and item.Name == "Stripes" then
			table.insert(belts, item)
		end
	end
	for _, item in bases:GetDescendants() do
		addBelt(item)
	end
	bases.DescendantAdded:Connect(addBelt)
	RunService:BindToRenderStep("MonsterEggShake", Enum.RenderPriority.Camera.Value + 1, function()
		local now = os.clock()
		if now < shake.Until then
			local fade = (shake.Until - now)
			local s = shake.Strength * math.min(fade * 2, 1)
			local camera = Workspace.CurrentCamera
			camera.CFrame *= CFrame.Angles(math.noise(now * 25, 1) * s * 0.05, math.noise(now * 25, 2) * s * 0.05, 0)
		end
	end)
end

function Fx.Step(t: number, dt: number)
	local camera = Workspace.CurrentCamera.CFrame.Position
	for model, info in tracked do
		if not model.Parent then
			tracked[model] = nil
			continue
		end
		local position = info.Root.Position
		local velocity = (Vector3.new(position.X, 0, position.Z) - Vector3.new(info.Last.X, 0, info.Last.Z)).Magnitude / math.max(dt, 1e-3)
		info.Last = position
		info.Speed += (velocity - info.Speed) * math.min(dt * 8, 1)
		local target = if model:GetAttribute("Sleeping") then 1 else 0
		info.Sleep += (target - info.Sleep) * math.min(dt * 2.5, 1)
		if (position - camera).Magnitude < 420 then
			Monsters.Animate(info.Pose, t, info.Sleep, math.clamp(info.Speed / 22, 0, 1), (model:GetAttribute("Rage") or 0) :: number)
		end
	end
	for i = #belts, 1, -1 do
		local texture = belts[i]
		if texture.Parent then
			texture.OffsetStudsV = (texture.OffsetStudsV - dt * 9) % 3
		else
			table.remove(belts, i)
		end
	end
	local camera = Workspace.CurrentCamera
	local targetFov = if os.clock() < boostUntil then 70 + boostLevel * 0.8 else 70
	camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(dt * 4, 1)
end

-- Sounds ---------------------------------------------------------------------------

function Fx.Sound(name: string, at: Instance?)
	local info = Config.Sounds[name]
	if not info then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = info.Id
	sound.PlaybackSpeed = info.Pitch or 1
	sound.Volume = info.Volume
	if at then
		sound.RollOffMaxDistance = 260
	end
	sound.Parent = at or Workspace.CurrentCamera
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(8, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function Fx.Shake(strength: number, duration: number)
	local now = os.clock()
	if now + duration > shake.Until or strength > shake.Strength then
		shake.Strength = math.max(strength, if now < shake.Until then shake.Strength else 0)
		shake.Until = now + duration
	end
end

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Fx.Burst(color: Color3, count: number, size: number?)
	local root = rootPart()
	if not root then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 1.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Speed = NumberRange.new(14, 28)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Acceleration = Vector3.new(0, -20, 0)
	emitter.Rate = 0
	emitter.Parent = attachment
	emitter:Emit(count)
	task.delay(2, function()
		attachment:Destroy()
	end)
end

-- Little "+$5" popups above the player's head.
function Fx.Float(text: string, color: Color3)
	local root = rootPart()
	if not root then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(math.random(-15, 15) / 10, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(20, 14, 40)
	stroke.Parent = label
	gui.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(gui, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.1), { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(1.1), { Transparency = 1 }):Play()
	task.delay(1.2, function()
		gui:Destroy()
	end)
end

-- Running on your own treadmill: speed lines at your feet and a slightly wider view.
function Fx.RunBoost(color: Color3, level: number)
	boostUntil = os.clock() + 1.3
	boostLevel = level
	local root = rootPart()
	if not root then
		return
	end
	local emitter = root:FindFirstChild("SpeedLines", true) :: ParticleEmitter?
	if not emitter then
		local attachment = Instance.new("Attachment")
		attachment.Name = "SpeedLinesAt"
		attachment.Position = Vector3.new(0, -2.6, 0.8)
		attachment.Parent = root
		local e = Instance.new("ParticleEmitter")
		e.Name = "SpeedLines"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate = 0
		e.Speed = NumberRange.new(10, 18)
		e.EmissionDirection = Enum.NormalId.Back
		e.SpreadAngle = Vector2.new(15, 15)
		e.Lifetime = NumberRange.new(0.3, 0.5)
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = attachment
		emitter = e
	end
	local e = emitter :: ParticleEmitter
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e:Emit(6 + level * 2)
end

function Fx.Knockback(from: Vector3)
	local root = rootPart()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	local away = Vector3.new(root.Position.X - from.X, 0, root.Position.Z - from.Z)
	if away.Magnitude < 0.1 then
		away = Vector3.new(0, 0, -1)
	end
	humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	root.AssemblyLinearVelocity = away.Unit * 70 + Vector3.new(0, 45, 0)
	task.delay(1.1, function()
		if humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

-- Music: one looping track per zone, cross-faded when you change zone ----------------

local musicTracks: { [string]: Sound } = {}
local currentTrack: Sound? = nil
local musicEnabled = true

local function musicTrack(id: string): Sound?
	if not id:match("^rbxassetid://%d+$") then
		return nil
	end
	local sound = musicTracks[id]
	if not sound then
		local s = Instance.new("Sound")
		s.Name = "ZoneMusic"
		s.SoundId = id
		s.Looped = true
		s.Volume = 0
		s.Parent = game:GetService("SoundService")
		musicTracks[id] = s
		sound = s
	end
	return sound
end

function Fx.PlayMusic(zone: number)
	local id = if zone == 0 then Config.Music.Sanctuary else Config.Music.Zones[zone]
	local nextTrack = id and musicTrack(id)
	if nextTrack == currentTrack then
		return
	end
	local fade = TweenInfo.new(1.5, Enum.EasingStyle.Quad)
	local previous = currentTrack
	if previous then
		local out = TweenService:Create(previous, fade, { Volume = 0 })
		out.Completed:Once(function()
			if currentTrack ~= previous then
				previous:Pause()
			end
		end)
		out:Play()
	end
	currentTrack = nextTrack
	if nextTrack then
		if not nextTrack.IsPlaying then
			nextTrack:Play()
		end
		TweenService:Create(nextTrack, fade, { Volume = if musicEnabled then Config.Music.Volume else 0 }):Play()
	end
end

function Fx.SetMusicEnabled(enabled: boolean)
	musicEnabled = enabled
	if currentTrack then
		TweenService:Create(currentTrack, TweenInfo.new(0.4), { Volume = if enabled then Config.Music.Volume else 0 }):Play()
	end
end

-- Zone ambience ---------------------------------------------------------------------

local SANCTUARY_FOG = Color3.fromRGB(200, 230, 255)

function Fx.SetZone(index: number)
	local atmosphere = Lighting:FindFirstChild("EggAtmosphere") :: Atmosphere?
	local cc = Lighting:FindFirstChild("EggColor") :: ColorCorrectionEffect?
	local zone = Config.Zones[index]
	local fog = if zone then zone.Fog else SANCTUARY_FOG
	local tint = if zone then Color3.new(1, 1, 1):Lerp(zone.Fog, 0.12) else Color3.new(1, 1, 1)
	local info = TweenInfo.new(1.2, Enum.EasingStyle.Quad)
	if atmosphere then
		TweenService:Create(atmosphere, info, { Color = fog, Density = if index >= 4 then 0.32 else 0.22 }):Play()
	end
	if cc then
		TweenService:Create(cc, info, { TintColor = tint }):Play()
	end
	TweenService:Create(Lighting, info, { ClockTime = if index == 6 then 18.6 elseif index >= 4 then 16.5 else 14.2 }):Play()
	Fx.PlayMusic(index)
end

return Fx
