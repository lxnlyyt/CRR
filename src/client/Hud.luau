-- Binds behaviour to the HUD built by HudBuilder: stats, menu, Slow Mode, windows (Shop with
-- Robux packs and upgrades, Trail Shop, Index, Rewards, Settings), toasts, chase warning and carry card.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("MonsterEgg")
local Config = require(Shared:WaitForChild("Config"))
local Builder = require(script.Parent:WaitForChild("HudBuilder"))

local player = Players.LocalPlayer
local Hud = {}

export type Handlers = {
	Shop: (action: string, index: any) -> (boolean, string),
	Robux: (kind: string, index: number) -> (), -- kind: "Trail", "Cash", "Speed" or "Tread"
	Claim: () -> (boolean, string),
	Setting: (name: string, enabled: boolean) -> (),
}

local GREEN = Color3.fromRGB(120, 255, 170)
local RED = Color3.fromRGB(255, 90, 110)
local GOLD = Color3.fromRGB(255, 220, 90)

local gui: ScreenGui
local refs: { [string]: any } = {}
local handlers: Handlers
local openWindow: GuiObject? = nil
local settings = { Music = true, Sounds = true, Shake = true, Particles = true }

local function setPair(object: Instance, pair: { Color3 })
	local gloss = object:FindFirstChild("Gloss") :: UIGradient?
	if gloss then
		gloss.Color = ColorSequence.new(pair[1], pair[2])
	end
end

local function setLabel(button: Instance, value: string)
	local label = button:FindFirstChild("Label") :: TextLabel?
	if label then
		label.Text = value
	end
end

local function pop(object: GuiObject, from: number?)
	local scale = (object:FindFirstChild("Pop") or object:FindFirstChild("Press") or object:FindFirstChildOfClass("UIScale")) :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = object
	end
	local s = scale :: UIScale
	s.Scale = from or 0.85
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Hover/press bounce on every glossy button.
local function juice(button: GuiButton)
	local scale = button:FindFirstChild("Press") :: UIScale?
	if not scale then
		return
	end
	local function to(value: number)
		TweenService:Create(scale :: UIScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.06)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.9)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.06)
	end)
end

-- Windows ------------------------------------------------------------------------------

function Hud.Open(name: string?)
	local target = name and gui:FindFirstChild(name) :: GuiObject?
	if openWindow and openWindow ~= target then
		openWindow.Visible = false
	end
	if not target or target == openWindow then
		if openWindow then
			openWindow.Visible = false
		end
		openWindow = nil
		return
	end
	openWindow = target
	target.Visible = true
	pop(target, 0.7)
	Hud.Update()
end

function Hud.ToggleShop(open: boolean)
	if open then
		if openWindow ~= gui:FindFirstChild("TrailsWindow") then
			Hud.Open("TrailsWindow")
		end
	elseif openWindow and openWindow.Name == "TrailsWindow" then
		Hud.Open(nil)
	end
end

local function setStatus(message: string, ok: boolean)
	local status = refs.TrailStatus :: TextLabel
	status.Text = message
	status.TextColor3 = if ok then GREEN else RED
end

-- Construction / binding ---------------------------------------------------------------

function Hud.Build(callbacks: Handlers)
	handlers = callbacks
	local playerGui = player:WaitForChild("PlayerGui")
	gui = (playerGui:FindFirstChild(Builder.Name) or playerGui:WaitForChild(Builder.Name, 3) or Builder.Build(playerGui)) :: ScreenGui

	local uiScale = gui:WaitForChild("Scale") :: UIScale
	local function rescale()
		local size = Workspace.CurrentCamera.ViewportSize
		uiScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.15)
	end
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	local stats = gui:WaitForChild("Stats")
	refs.Cash = stats.Cash
	refs.Speed = stats.Speed
	refs.Eggs = stats.Eggs
	refs.GiftTimer = gui:WaitForChild("GiftTimer").Text
	refs.Slow = gui:WaitForChild("Menu").SlowMode.Switch
	refs.Vignette = gui:WaitForChild("Vignette"):GetChildren()
	refs.Save = gui:WaitForChild("SaveStatus")
	refs.Banner = gui:WaitForChild("ZoneBanner")
	refs.Chase = gui:WaitForChild("Chase")
	refs.Carry = gui:WaitForChild("Carry")
	refs.Toasts = gui:WaitForChild("Toasts")
	refs.Splash = gui:WaitForChild("Splash")
	refs.SplashSub = gui:WaitForChild("SplashSub")
	refs.Trails = gui:WaitForChild("TrailsWindow")
	refs.TrailStatus = refs.Trails.Body.Status
	refs.Shop = gui:WaitForChild("ShopWindow")
	refs.Rewards = gui:WaitForChild("RewardsWindow")
	refs.RewardBadge = gui.SideButtons.Rewards.Badge

	for _, item in gui:GetDescendants() do
		if item:IsA("TextButton") then
			juice(item)
		end
	end

	-- Side buttons and close buttons.
	local windows = { Shop = "ShopWindow", Index = "IndexWindow", Trails = "TrailsWindow", Rewards = "RewardsWindow", Settings = "SettingsWindow" }
	for buttonName, windowName in windows do
		local holder = if buttonName == "Rewards" or buttonName == "Settings" then gui.SideButtons else gui.Menu
		local sideButton = holder:WaitForChild(buttonName) :: TextButton
		sideButton.Activated:Connect(function()
			Hud.Open(windowName)
		end)
		local closeButton = gui:WaitForChild(windowName):WaitForChild("Close") :: TextButton
		closeButton.Activated:Connect(function()
			Hud.Open(nil)
		end)
	end

	-- Trail cards.
	for index = 1, #Config.Trails do
		local card = refs.Trails.Body.Cards:WaitForChild("Trail" .. index)
		card.BuyCash.Activated:Connect(function()
			local ok, message = handlers.Shop("Buy", index)
			setStatus(message, ok)
			pop(card, 0.92)
		end)
		card.BuyRobux.Activated:Connect(function()
			handlers.Robux("Trail", index)
		end)
		card.Equip.Activated:Connect(function()
			local ok, message = handlers.Shop("Equip", index)
			setStatus(message, ok)
			pop(card, 0.92)
		end)
	end

	-- Shop tabs and Robux packs.
	local pages = refs.Shop.Body.Pages
	refs.Upgrades = pages.Upgrades
	for _, tab in refs.Shop.Body.Tabs:GetChildren() do
		if tab:IsA("TextButton") then
			tab.Activated:Connect(function()
				for _, pageFrame in pages:GetChildren() do
					pageFrame.Visible = pageFrame.Name == tab.Name
				end
				Hud.Update()
			end)
		end
	end
	for kind, packs in { Cash = Config.CashPacks, Speed = Config.SpeedPacks } do
		for index = 1, #packs do
			pages[kind]:WaitForChild("Pack" .. index).Buy.Activated:Connect(function()
				handlers.Robux(kind, index)
			end)
		end
	end

	-- Slow Mode (server keeps the real walk speed so upgrades still count).
	refs.Slow.Activated:Connect(function()
		handlers.Shop("SlowMode", not player:GetAttribute("SlowMode"))
	end)

	-- Upgrades.
	for _, name in { "Speed", "Storage", "Treadmill" } do
		local card = refs.Upgrades:WaitForChild(name)
		card.Buy.Activated:Connect(function()
			-- The server sends its own notice toast for upgrades.
			handlers.Shop("Upgrade", name)
			pop(card, 0.94)
		end)
	end

	-- Rewards.
	refs.Rewards.Body.Claim.Activated:Connect(function()
		local ok, message = handlers.Claim()
		Hud.Toast(message, if ok then "rare" else "bad")
		if ok then
			Hud.Splash("FREE GIFT!", message, GOLD)
		end
	end)

	-- Settings toggles.
	for name in settings do
		local row = gui.SettingsWindow.Body:WaitForChild(name)
		local toggle = row.Toggle
		toggle.Activated:Connect(function()
			settings[name] = not settings[name]
			setLabel(toggle, if settings[name] then "ON" else "OFF")
			setPair(toggle, if settings[name] then Builder.Colors.Green else Builder.Colors.Grey)
			handlers.Setting(name, settings[name])
		end)
	end
	return gui
end

-- Updates ------------------------------------------------------------------------------

local function refreshTrails()
	local owned = string.split(player:GetAttribute("OwnedTrails") or "", ",")
	local equipped = player:GetAttribute("Trail") or 0
	local cash = player:GetAttribute("Cash") or 0
	for index, trail in Config.Trails do
		local card = refs.Trails.Body.Cards:FindFirstChild("Trail" .. index)
		if not card then
			continue
		end
		local isOwned = table.find(owned, tostring(index)) ~= nil
		card.BuyCash.Visible = not isOwned
		card.BuyRobux.Visible = not isOwned
		card.Equip.Visible = isOwned
		if isOwned then
			local isEquipped = index == equipped
			setLabel(card.Equip, if isEquipped then "EQUIPPED ✓" else "EQUIP")
			setPair(card.Equip, if isEquipped then Builder.Colors.Green else Builder.Colors.Blue)
			card.State.Text = if isEquipped then "IN USE" else "OWNED"
			card.State.TextColor3 = if isEquipped then GREEN else Color3.fromRGB(220, 215, 245)
		else
			setPair(card.BuyCash, if cash >= trail.Cost then Builder.Colors.Gold else Builder.Colors.Grey)
			card.State.Text = if cash >= trail.Cost then "CAN AFFORD!" else "NOT OWNED"
			card.State.TextColor3 = if cash >= trail.Cost then GOLD else Color3.fromRGB(220, 215, 245)
		end
	end
end
Hud.RefreshShop = refreshTrails

local function refreshUpgrades()
	local speed = player:GetAttribute("SpeedLevel") or 0
	local capacity = player:GetAttribute("Capacity") or Config.StartCapacity
	local cash = player:GetAttribute("Cash") or 0
	local speedCard, storageCard = refs.Upgrades.Speed, refs.Upgrades.Storage
	local speedMax = speed >= Config.MaxSpeedLevel
	speedCard.Level.Text = if speedMax then "MAX LEVEL" else string.format("LEVEL %d → %d", speed, speed + 1)
	speedCard.Progress.Fill.Size = UDim2.fromScale(speed / Config.MaxSpeedLevel, 1)
	setLabel(speedCard.Buy, if speedMax then "MAXED" else "$" .. Config.Format(Config.SpeedCost(speed)))
	setPair(speedCard.Buy, if not speedMax and cash >= Config.SpeedCost(speed) then Builder.Colors.Green else Builder.Colors.Grey)
	local storageMax = capacity >= Config.MaxCapacity
	storageCard.Level.Text = if storageMax then "MAX " .. capacity .. " EGGS" else string.format("%d → %d EGGS", capacity, capacity + Config.CapacityStep)
	storageCard.Progress.Fill.Size = UDim2.fromScale((capacity - Config.StartCapacity) / (Config.MaxCapacity - Config.StartCapacity), 1)
	setLabel(storageCard.Buy, if storageMax then "MAXED" else "$" .. Config.Format(Config.StorageCost(capacity)))
	setPair(storageCard.Buy, if not storageMax and cash >= Config.StorageCost(capacity) then Builder.Colors.Green else Builder.Colors.Grey)
	local tread = player:GetAttribute("TreadLevel") or 1
	local treadCard = refs.Upgrades.Treadmill
	local treadMax = tread >= Config.MaxTreadLevel
	treadCard.Level.Text = if treadMax then "MAX LEVEL" else string.format("LEVEL %d → %d", tread, tread + 1)
	treadCard.Progress.Fill.Size = UDim2.fromScale(tread / Config.MaxTreadLevel, 1)
	setLabel(treadCard.Buy, if treadMax then "MAXED" else "$" .. Config.Format(Config.TreadCost(tread)))
	setPair(treadCard.Buy, if not treadMax and cash >= Config.TreadCost(tread) then Builder.Colors.Green else Builder.Colors.Grey)
end

function Hud.Update()
	if not gui then
		return
	end
	local cash = player:GetAttribute("Cash") or 0
	refs.Cash.Value.Text = "$" .. Config.Format(cash)
	refs.Cash.Sub.Text = "+$" .. Config.Format(player:GetAttribute("Income") or 0) .. " per second"
	local trail = Config.Trails[player:GetAttribute("Trail") or 0]
	local walk = player:GetAttribute("WalkSpeed") or Config.BaseWalkSpeed
	refs.Speed.Value.Text = if trail then string.format("%.1f (x%s)", walk, tostring(trail.Multiplier)) else string.format("%.1f", walk)
	local training = player:GetAttribute("Training") or 0
	refs.Speed.Sub.Text = if player:GetAttribute("SlowMode")
		then "SLOW MODE ON"
		else string.format("Treadmill Lv %d  •  Training %d/%d", player:GetAttribute("TreadLevel") or 1, math.min(training, Config.TrainingCap), Config.TrainingCap)
	refs.Speed.Progress.Fill.Size = UDim2.fromScale(math.clamp(training / Config.TrainingCap, 0, 1), 1)
	refs.Eggs.Value.Text = string.format("%d/%d", player:GetAttribute("EggCount") or 0, player:GetAttribute("Capacity") or Config.StartCapacity)
	refs.Eggs.Sub.Text = "eggs in your base"
	local slow = player:GetAttribute("SlowMode") == true
	local knob = refs.Slow.Knob
	knob.Position = UDim2.fromOffset(if slow then 41 else 3, 3)
	knob.BackgroundColor3 = if slow then Color3.fromRGB(110, 240, 90) else Color3.fromRGB(190, 190, 205)
	refs.Slow.BackgroundColor3 = if slow then Color3.fromRGB(40, 120, 50) else Color3.fromRGB(70, 74, 90)
	refs.Save.Text = player:GetAttribute("SaveStatus") or ""

	local carrying = player:GetAttribute("Carrying") or ""
	refs.Carry.Visible = carrying ~= ""
	if carrying ~= "" then
		local rarity = Config.Rarities[player:GetAttribute("CarryRarity") or 1]
		refs.Carry.Title.Text = carrying:upper()
		refs.Carry.Title.TextColor3 = rarity.Color
		setPair(refs.Carry, { rarity.Shade:Lerp(Color3.new(0, 0, 0), 0.3), Color3.fromRGB(30, 22, 64) })
	end

	local chaser = player:GetAttribute("Chaser") or ""
	local rage = player:GetAttribute("Rage") or 0
	refs.Chase.Visible = chaser ~= ""
	if chaser ~= "" then
		refs.Chase.Title.Text = chaser:upper() .. " IS CHASING YOU!"
		refs.Chase.Bar.Fill.Size = UDim2.fromScale(math.max(rage, 0.08), 1)
		refs.Chase.Bar.Text.Text = if rage > 0 then string.format("MONSTER RAGE %d%%", math.floor(rage * 100)) else "RUN!"
	end
	if refs.Trails.Visible then
		refreshTrails()
	end
	if refs.Shop.Visible then
		refreshUpgrades()
	end
	refs.Rewards.Body.Amount.Text = "+$" .. Config.Format(Config.RewardCash(player:GetAttribute("Income") or 0))
end

-- Called every frame with the distance to safety (or nil when not carrying).
function Hud.Frame(t: number, safeDistance: number?, danger: number)
	if not gui then
		return
	end
	if safeDistance then
		refs.Carry.Hint.Text = if safeDistance > 0 then string.format("↓ SAFE ZONE IN %d STUDS ↓", math.ceil(safeDistance)) else "SAFE!"
	end
	local pulse = 0.5 + 0.5 * math.sin(t * 8)
	for _, edge in refs.Vignette do
		edge.BackgroundTransparency = 1 - danger * (0.35 + 0.25 * pulse)
	end
	if refs.Chase.Visible then
		refs.Chase.Rotation = math.sin(t * 30) * (player:GetAttribute("Rage") or 0) * 1.5
	end
	local remaining = math.max(0, (player:GetAttribute("NextReward") or 0) - Workspace:GetServerTimeNow())
	local ready = remaining <= 0
	refs.RewardBadge.Visible = ready
	if ready then
		refs.RewardBadge.Rotation = math.sin(t * 6) * 12
	end
	refs.GiftTimer.Text = if ready then "GIFT READY!" else string.format("in %dm %02ds", remaining // 60, math.floor(remaining % 60))
	refs.GiftTimer.TextColor3 = if ready then GOLD else Color3.new(1, 1, 1)
	local claim = refs.Rewards.Body.Claim
	setLabel(claim, if ready then "CLAIM!" else string.format("%d:%02d", remaining // 60, math.floor(remaining % 60)))
	setPair(claim, if ready then Builder.Colors.Green else Builder.Colors.Grey)
end

function Hud.ZoneBanner(title: string, subtitle: string, color: Color3)
	local banner = refs.Banner
	banner.Title.Text = title
	banner.Sub.Text = subtitle
	setPair(banner, { color:Lerp(Color3.new(1, 1, 1), 0.25), color:Lerp(Color3.new(0, 0, 0), 0.35) })
	TweenService:Create(banner, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 12) }):Play()
	local token = {}
	refs.BannerToken = token
	task.delay(2.6, function()
		if refs.BannerToken == token then
			TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -200) }):Play()
		end
	end)
end

local TOAST_COLORS = {
	good = Builder.Colors.Green,
	bad = Builder.Colors.Red,
	info = Builder.Colors.Blue,
	rare = Builder.Colors.Gold,
}
local toastOrder = 0

function Hud.Toast(message: string, kind: string?)
	if not gui then
		return
	end
	toastOrder += 1
	local toast = Builder.Panel(refs.Toasts, "Toast", TOAST_COLORS[kind or "info"] or TOAST_COLORS.info, UDim2.fromOffset(500, 48), UDim2.new(), 16)
	toast.LayoutOrder = -toastOrder
	local label = Builder.Text({ Name = "Text", Text = message, Font = Builder.Font, Size = UDim2.new(1, -24, 1, -12), Position = UDim2.fromOffset(12, 6), Parent = toast })
	pop(toast)
	local items = {}
	for _, child in refs.Toasts:GetChildren() do
		if child:IsA("Frame") then
			table.insert(items, child)
		end
	end
	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for n = 5, #items do
		items[n]:Destroy()
	end
	task.delay(4, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			task.wait(0.4)
			toast:Destroy()
		end
	end)
end

function Hud.Splash(title: string, sub: string, color: Color3)
	refs.Splash.Text = title
	refs.Splash.TextColor3 = color
	refs.SplashSub.Text = sub
	refs.Splash.Visible = true
	refs.SplashSub.Visible = true
	pop(refs.Splash)
	local token = {}
	refs.SplashToken = token
	task.delay(1.8, function()
		if refs.SplashToken == token then
			refs.Splash.Visible = false
			refs.SplashSub.Visible = false
		end
	end)
end

return Hud
