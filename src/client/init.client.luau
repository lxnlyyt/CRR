-- MONSTER EGG ESCAPE client: wires remotes, HUD, world effects and per-player world labels.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("MonsterEgg")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = Shared:WaitForChild("Remotes")
local Hud = require(script:WaitForChild("Hud"))
local Fx = require(script:WaitForChild("Fx"))

local player = Players.LocalPlayer
local world = Workspace:WaitForChild("MonsterEggEscape")
local sanctuary = world:WaitForChild("Sanctuary")
local runtime = world:WaitForChild("Runtime")

local ShopFunction = Remotes:WaitForChild("Shop") :: RemoteFunction
local NoticeEvent = Remotes:WaitForChild("Notice") :: RemoteEvent
local EffectEvent = Remotes:WaitForChild("Effect") :: RemoteEvent

Hud.Build(function(action, index)
	local ok, result, message = pcall(ShopFunction.InvokeServer, ShopFunction, action, index)
	if not ok then
		return false, "Shop is busy — try again"
	end
	return result, message
end)
Fx.Init(world)

-- Remotes ---------------------------------------------------------------------------

NoticeEvent.OnClientEvent:Connect(function(text: string, kind: string)
	Hud.Toast(text, kind)
end)

local effects = {}

function effects.Pickup(rarity: number)
	local info = Config.Rarities[rarity]
	Fx.Sound("Pickup")
	Fx.Burst(info.Color, 20 + rarity * 6, 0.8)
	if rarity >= Config.RageRarity then
		Hud.Splash(info.Name:upper() .. " EGG!", "The guardian is enraged — RUN!", info.Color)
	end
end

function effects.Banked(rarity: number, bonus: number)
	local info = Config.Rarities[rarity]
	Fx.Sound("Bank")
	Fx.Burst(info.Color, 60, 1.4)
	Hud.Splash("SAFE!", "+$" .. Config.Format(bonus) .. "  •  " .. info.Name .. " egg banked", info.Color)
end

function effects.Caught(from: Vector3)
	Fx.Sound("Caught")
	Fx.Shake(2.2, 0.6)
	Fx.Knockback(from)
	Hud.Splash("CAUGHT!", "The egg returned to the guardian", Color3.fromRGB(255, 80, 90))
end

function effects.Stolen()
	Fx.Sound("Steal")
	Fx.Shake(1, 0.3)
end

function effects.Purchase()
	Fx.Sound("Buy")
	Fx.Burst(Color3.fromRGB(255, 214, 80), 24, 0.8)
end

function effects.Cash(amount: number)
	Fx.Float("+$" .. Config.Format(amount), Color3.fromRGB(255, 214, 80))
end

function effects.Treadmill(earned: number, power: number)
	Fx.Float(string.format("+$%s  ⚡+%s", Config.Format(earned), tostring(math.floor(power * 10 + 0.5) / 10)), Color3.fromRGB(120, 230, 255))
end

function effects.Roar(model: Model, raging: boolean)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not model or not model.PrimaryPart or not root then
		return
	end
	local distance = (model.PrimaryPart.Position - root.Position).Magnitude
	if distance < 160 then
		Fx.Sound("Roar", model.PrimaryPart)
		Fx.Shake(if raging then 1.6 else 0.8, if raging then 0.8 else 0.4)
	end
end

function effects.OpenShop()
	Hud.ToggleShop(true)
end

EffectEvent.OnClientEvent:Connect(function(name: string, ...)
	local handler = effects[name]
	if handler then
		handler(...)
	end
end)

-- Personal world labels: board prices, treadmill locks, own egg prompts ------------

local boards = sanctuary:WaitForChild("Boards")
local treadmills = sanctuary:WaitForChild("Treadmills")

local function setPrice(model: Instance, text: string)
	local face = model:FindFirstChild("Board")
	local sign = face and face:FindFirstChild("Sign")
	local price = sign and sign:FindFirstChild("Price") :: TextLabel?
	if price then
		price.Text = text
	end
end

local function refreshWorldLabels()
	local speed = player:GetAttribute("SpeedLevel") or 0
	local capacity = player:GetAttribute("Capacity") or Config.StartCapacity
	local power = player:GetAttribute("TreadLevel") or 0
	setPrice(boards:WaitForChild("SpeedBoard"), if speed >= Config.MaxSpeedLevel then "MAXED" else string.format("Lv %d → %d  •  $%s", speed, speed + 1, Config.Format(Config.SpeedCost(speed))))
	setPrice(boards:WaitForChild("StorageBoard"), if capacity >= Config.MaxCapacity then "MAXED" else string.format("%d → %d eggs  •  $%s", capacity, capacity + Config.CapacityStep, Config.Format(Config.StorageCost(capacity))))
	setPrice(boards:WaitForChild("PowerBoard"), if power >= Config.MaxTreadLevel then "MAXED" else string.format("Lv %d → %d  •  $%s", power, power + 1, Config.Format(Config.TreadCost(power))))
	local owned = player:GetAttribute("Treads") or "100"
	for tier = 1, #Config.Treadmills do
		local unlocked = owned:sub(tier, tier) == "1"
		local model = treadmills:FindFirstChild("Treadmill" .. tier)
		local lock = model and model:FindFirstChild("Lock") :: BasePart?
		if lock then
			lock.Transparency = if unlocked then 1 else 0.55
			local lockLabel = lock:FindFirstChild("LockLabel") :: BillboardGui?
			if lockLabel then
				lockLabel.Enabled = not unlocked
			end
		end
		local unlockBoard = treadmills:FindFirstChild("UnlockBoard" .. tier)
		if unlockBoard then
			setPrice(unlockBoard, if unlocked then "UNLOCKED ✓" else "$" .. Config.Format(Config.Treadmills[tier].Cost))
		end
	end
end

-- Hide the steal prompt on our own carried egg; enable sell prompts only in our own plot.
local function configurePrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	if prompt.Name == "StealPrompt" then
		local model = prompt:FindFirstAncestorOfClass("Model")
		prompt.Enabled = model == nil or model:GetAttribute("Carrier") ~= player.UserId
	elseif prompt.Name == "SellPrompt" then
		local plot = prompt:FindFirstAncestor("Plot" .. tostring(player:GetAttribute("Plot") or 0))
		prompt.Enabled = plot ~= nil
	end
end

for _, container in { runtime:WaitForChild("CarriedEggs"), sanctuary:WaitForChild("Plots") } do
	for _, item in container:GetDescendants() do
		configurePrompt(item)
	end
	container.DescendantAdded:Connect(function(item)
		if item:IsA("ProximityPrompt") then
			task.defer(configurePrompt, item)
		end
	end)
end

-- Attributes and frame loop -----------------------------------------------------------

player.AttributeChanged:Connect(function(name)
	Hud.Update()
	if name == "SpeedLevel" or name == "Capacity" or name == "TreadLevel" or name == "Treads" then
		refreshWorldLabels()
	elseif name == "Plot" then
		for _, item in sanctuary.Plots:GetDescendants() do
			configurePrompt(item)
		end
	end
end)
Hud.Update()
refreshWorldLabels()

local currentZone = -1
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	Fx.Step(t, dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local safeDistance = nil
	if root then
		local zone = Config.ZoneAt(root.Position.Z)
		if zone ~= currentZone then
			currentZone = zone
			Fx.SetZone(zone)
			if zone == 0 then
				Hud.ZoneBanner("SAFE ZONE", "Monsters can't follow you here", Color3.fromRGB(110, 255, 170))
			else
				local info = Config.Zones[zone]
				Hud.ZoneBanner(info.Name:upper() .. " ZONE", "Guardian: " .. info.Monster .. "  •  Eggs from $" .. Config.Format(info.Income) .. "/s", info.Color)
			end
		end
		if (player:GetAttribute("Carrying") or "") ~= "" then
			safeDistance = math.max(0, root.Position.Z - Config.SafeZ)
		end
	end
	local danger = if (player:GetAttribute("Chaser") or "") ~= "" then 0.5 + 0.5 * (player:GetAttribute("Rage") or 0) else 0
	Hud.Frame(t, safeDistance, danger)
end)
