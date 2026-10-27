-- MONSTER EGG ESCAPE client: wires remotes, HUD, world effects and per-player world labels.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")

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

local function invokeShop(action: string, index: any): (boolean, string)
	local ok, result, message = pcall(ShopFunction.InvokeServer, ShopFunction, action, index)
	if not ok then
		return false, "Shop is busy — try again"
	end
	return result, message
end

Hud.Build({
	Shop = invokeShop,
	Robux = function(index: number)
		local trail = Config.Trails[index]
		if trail and trail.ProductId > 0 then
			MarketplaceService:PromptProductPurchase(player, trail.ProductId)
		else
			Hud.Toast("Robux purchases are not set up yet", "info")
		end
	end,
	Claim = function()
		return invokeShop("Claim", 0)
	end,
	Setting = function(name: string, enabled: boolean)
		if name == "Music" then
			Fx.SetMusicEnabled(enabled)
		else
			Fx.SetOption(name, enabled)
		end
	end,
})
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

function effects.Treadmill(earned: number, level: number)
	local design = Config.TreadmillDesigns[level]
	Fx.Float(string.format("+$%s  ⚡+%d", Config.Format(earned), level), design.Accent)
	Fx.RunBoost(design.Accent, level)
end

function effects.TreadUp(level: number)
	local design = Config.TreadmillDesigns[level]
	Fx.Sound("LevelUp")
	Fx.Burst(design.Accent, 80, 1.6)
	Fx.Shake(0.6, 0.3)
	Hud.Splash("TREADMILL LV " .. level .. "!", design.Name .. " design  •  +" .. Config.TreadSpeedPerLevel .. " walk speed", design.Accent)
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

-- Personal world labels: board prices and prompts that only the base owner sees -----

local boards = sanctuary:WaitForChild("Boards")

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
	setPrice(boards:WaitForChild("SpeedBoard"), if speed >= Config.MaxSpeedLevel then "MAXED" else string.format("Lv %d → %d  •  $%s", speed, speed + 1, Config.Format(Config.SpeedCost(speed))))
	setPrice(boards:WaitForChild("StorageBoard"), if capacity >= Config.MaxCapacity then "MAXED" else string.format("%d → %d eggs  •  $%s", capacity, capacity + Config.CapacityStep, Config.Format(Config.StorageCost(capacity))))
end

-- Hide the steal prompt on our own carried egg; sell and upgrade prompts only work in our own base.
local function configurePrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	if prompt.Name == "StealPrompt" then
		local model = prompt:FindFirstAncestorOfClass("Model")
		prompt.Enabled = model == nil or model:GetAttribute("Carrier") ~= player.UserId
	elseif prompt.Name == "SellPrompt" or prompt.Name == "UpgradePrompt" then
		local base = prompt:FindFirstAncestor("Base" .. tostring(player:GetAttribute("Base") or 0))
		prompt.Enabled = base ~= nil
	end
end

for _, container in { runtime:WaitForChild("CarriedEggs"), sanctuary:WaitForChild("Bases") } do
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
	if name == "SpeedLevel" or name == "Capacity" then
		refreshWorldLabels()
	elseif name == "Base" then
		for _, item in sanctuary.Bases:GetDescendants() do
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
