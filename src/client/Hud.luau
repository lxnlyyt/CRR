-- Builds and updates the on-screen HUD, toasts, chase warning and the Trail Shop window.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("MonsterEgg")
local Config = require(Shared:WaitForChild("Config"))

local player = Players.LocalPlayer
local Hud = {}

local FONT = Enum.Font.FredokaOne
local PANEL = Color3.fromRGB(28, 22, 56)
local INK = Color3.fromRGB(20, 14, 40)
local GREEN = Color3.fromRGB(110, 255, 160)
local GOLD = Color3.fromRGB(255, 214, 80)
local PINK = Color3.fromRGB(255, 110, 200)
local RED = Color3.fromRGB(255, 70, 90)

local function make(class: string, props: { [string]: any }, children: { Instance }?): Instance
	local item = Instance.new(class)
	for key, value in props do
		if key ~= "Parent" then
			(item :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = item
	end
	item.Parent = props.Parent
	return item
end

local function corner(radius: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, radius) }) :: UICorner
end

local function stroke(color: Color3, thickness: number, transparency: number?): UIStroke
	return make("UIStroke", { Color = color, Thickness = thickness, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) :: UIStroke
end

local function textStroke(thickness: number?): UIStroke
	return make("UIStroke", { Color = INK, Thickness = thickness or 2 }) :: UIStroke
end

local function gradient(a: Color3, b: Color3, rotation: number?): UIGradient
	return make("UIGradient", { Color = ColorSequence.new(a, b), Rotation = rotation or 90 }) :: UIGradient
end

local function label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT
	props.TextScaled = if props.TextScaled == nil then true else props.TextScaled
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	local thickness = props.StrokeThickness
	props.StrokeThickness = nil
	local l = make("TextLabel", props, { textStroke(thickness) }) :: TextLabel
	return l
end

-- A ForgeGUI icon, or the given text if the icon id isn't configured.
local function icon(parent: Instance, id: string, size: number, position: UDim2, fallback: string): GuiObject
	if id:match("^rbxassetid://%d+$") then
		return make("ImageLabel", {
			Size = UDim2.fromOffset(size, size), Position = position, BackgroundTransparency = 1,
			Image = id, ScaleType = Enum.ScaleType.Fit, Parent = parent,
		}) :: ImageLabel
	end
	return label({ Size = UDim2.fromOffset(size, size), Position = position, Text = fallback, Parent = parent })
end

local function panel(props: { [string]: any }, accent: Color3): Frame
	props.BackgroundColor3 = props.BackgroundColor3 or PANEL
	props.BackgroundTransparency = props.BackgroundTransparency or 0.08
	local f = make("Frame", props, { corner(16), stroke(accent, 3, 0.1), gradient(Color3.new(1, 1, 1), Color3.fromRGB(190, 180, 230)) }) :: Frame
	return f
end

local function pop(object: GuiObject)
	local scale = object:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = object })
	scale.Scale = 0.85
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Construction ---------------------------------------------------------------------

local gui: ScreenGui
local refs = {}

function Hud.Build(onShopAction: (string, number) -> (boolean, string))
	gui = make("ScreenGui", {
		Name = "MonsterEggHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	}) :: ScreenGui
	local uiScale = make("UIScale", { Parent = gui }) :: UIScale
	local function rescale()
		local size = Workspace.CurrentCamera.ViewportSize
		uiScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 760), 0.55, 1.15)
	end
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	-- Danger vignette (four soft red edges).
	local vignette = make("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui, ZIndex = 0 }) :: Frame
	refs.Vignette = {}
	for _, edge in { { 0, 0, 1, 0.22, 90 }, { 0, 0.78, 1, 0.22, -90 }, { 0, 0, 0.16, 1, 0 }, { 0.84, 0, 0.16, 1, 180 } } do
		local f = make("Frame", {
			Position = UDim2.fromScale(edge[1], edge[2]), Size = UDim2.fromScale(edge[3], edge[4]),
			BackgroundColor3 = RED, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = vignette,
		}, {
			make("UIGradient", { Rotation = edge[5], Transparency = NumberSequence.new(0, 1) }),
		}) :: Frame
		table.insert(refs.Vignette, f)
	end

	-- Left stat column.
	local column = make("Frame", {
		Name = "Stats", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.46, 0), Size = UDim2.fromOffset(250, 380),
		BackgroundTransparency = 1, Parent = gui,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	}) :: Frame

	local cash = panel({ Name = "Cash", Size = UDim2.fromOffset(250, 84), LayoutOrder = 1, Parent = column }, GOLD)
	icon(cash, Config.Icons.Coin, 64, UDim2.fromOffset(8, 10), "$")
	refs.Cash = label({ Size = UDim2.new(1, -84, 0, 44), Position = UDim2.fromOffset(78, 8), Text = "$0", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, StrokeThickness = 3, Parent = cash })
	refs.Income = label({ Size = UDim2.new(1, -84, 0, 24), Position = UDim2.fromOffset(78, 52), Text = "+$0/s", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GREEN, Parent = cash })

	local eggs = panel({ Name = "Eggs", Size = UDim2.fromOffset(250, 58), LayoutOrder = 2, Parent = column }, Color3.fromRGB(150, 220, 255))
	icon(eggs, Config.Icons.Egg, 48, UDim2.fromOffset(8, 5), "🥚")
	refs.Eggs = label({ Size = UDim2.new(1, -72, 0, 36), Position = UDim2.fromOffset(62, 11), Text = "0 / 8 eggs", TextXAlignment = Enum.TextXAlignment.Left, Parent = eggs })

	local speed = panel({ Name = "Speed", Size = UDim2.fromOffset(250, 76), LayoutOrder = 3, Parent = column }, Color3.fromRGB(110, 210, 255))
	icon(speed, Config.Icons.Speed, 46, UDim2.fromOffset(8, 3), "⚡")
	refs.Speed = label({ Size = UDim2.new(1, -72, 0, 32), Position = UDim2.fromOffset(62, 8), Text = "Speed 20", TextXAlignment = Enum.TextXAlignment.Left, Parent = speed })
	local bar = make("Frame", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 52), BackgroundColor3 = Color3.fromRGB(14, 10, 30), Parent = speed }, { corner(7) }) :: Frame
	refs.TrainingFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(110, 210, 255), Parent = bar }, { corner(7), gradient(Color3.fromRGB(120, 240, 255), Color3.fromRGB(60, 140, 255), 0) })
	refs.TrainingText = label({ Size = UDim2.fromScale(1, 1), Text = "Training 0", Parent = bar, StrokeThickness = 1.5 })

	local trailsButton = make("TextButton", {
		Name = "TrailsButton", Size = UDim2.fromOffset(250, 58), LayoutOrder = 4, BackgroundColor3 = PINK, Text = "", AutoButtonColor = true, Parent = column,
	}, { corner(16), stroke(Color3.new(1, 1, 1), 3, 0.2), gradient(Color3.fromRGB(255, 150, 220), Color3.fromRGB(220, 70, 180)) }) :: TextButton
	icon(trailsButton, Config.Icons.Trail, 48, UDim2.fromOffset(10, 5), "✨")
	label({ Size = UDim2.new(1, -76, 1, -14), Position = UDim2.fromOffset(64, 7), Text = "TRAIL SHOP", Parent = trailsButton, StrokeThickness = 2.5 })

	local musicButton = make("TextButton", {
		Name = "MusicButton", Size = UDim2.fromOffset(250, 40), LayoutOrder = 5, BackgroundColor3 = Color3.fromRGB(70, 60, 130), Text = "", AutoButtonColor = true, Parent = column,
	}, { corner(14), stroke(Color3.new(1, 1, 1), 2, 0.4) }) :: TextButton
	refs.MusicText = label({ Size = UDim2.new(1, -20, 1, -12), Position = UDim2.fromOffset(10, 6), Text = "♪ MUSIC: ON", Parent = musicButton, StrokeThickness = 2 })
	Hud.MusicButton = musicButton

	refs.Save = label({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.fromOffset(330, 20), TextXAlignment = Enum.TextXAlignment.Left, Text = "", TextColor3 = Color3.fromRGB(200, 200, 230), Parent = gui, StrokeThickness = 1.5 })

	-- Zone banner and chase warning (top centre).
	refs.Banner = panel({ Name = "ZoneBanner", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -120), Size = UDim2.fromOffset(420, 82), Parent = gui }, GREEN)
	refs.BannerTitle = label({ Size = UDim2.new(1, -24, 0, 48), Position = UDim2.fromOffset(12, 6), Text = "SAFE ZONE", Parent = refs.Banner, StrokeThickness = 3 })
	refs.BannerSub = label({ Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 54), Text = "", TextColor3 = Color3.fromRGB(220, 220, 240), Parent = refs.Banner })

	refs.Chase = panel({ Name = "Chase", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(460, 74), Visible = false, BackgroundColor3 = Color3.fromRGB(70, 10, 24), Parent = gui }, RED)
	refs.ChaseText = label({ Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 6), Text = "", TextColor3 = Color3.fromRGB(255, 220, 220), Parent = refs.Chase, StrokeThickness = 3 })
	local rageIcon = icon(refs.Chase, Config.Icons.Rage, 76, UDim2.new(0, -38, 0.5, -38), "")
	rageIcon.ZIndex = 2
	local rageBar = make("Frame", { Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(12, 46), BackgroundColor3 = Color3.fromRGB(20, 6, 12), Parent = refs.Chase }, { corner(8) }) :: Frame
	refs.RageFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = RED, Parent = rageBar }, { corner(8), gradient(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 40, 60), 0) })
	refs.RageText = label({ Size = UDim2.fromScale(1, 1), Text = "", Parent = rageBar, StrokeThickness = 1.5 })

	-- Carried egg card (bottom centre).
	refs.Carry = panel({ Name = "Carry", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.fromOffset(440, 92), Visible = false, Parent = gui }, GOLD)
	label({ Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 6), Text = "CARRYING", TextColor3 = Color3.fromRGB(200, 200, 230), Parent = refs.Carry })
	refs.CarryTitle = label({ Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 26), Text = "", Parent = refs.Carry, StrokeThickness = 3 })
	refs.CarryHint = label({ Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 62), Text = "", TextColor3 = GREEN, Parent = refs.Carry })

	-- Toast stack.
	refs.Toasts = make("Frame", {
		Name = "Toasts", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 180), Size = UDim2.fromOffset(520, 260), BackgroundTransparency = 1, Parent = gui,
	}, { make("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })

	-- Big centre splash for banking.
	refs.Splash = label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(520, 90), Text = "", Visible = false, Parent = gui, StrokeThickness = 4 })
	refs.SplashSub = label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromOffset(420, 40), Text = "", Visible = false, TextColor3 = GOLD, Parent = gui, StrokeThickness = 3 })

	Hud.BuildShop(onShopAction)
	trailsButton.Activated:Connect(function()
		Hud.ToggleShop(true)
	end)
	return gui
end

-- Trail shop -------------------------------------------------------------------------

local shopCards = {}

function Hud.BuildShop(onShopAction: (string, number) -> (boolean, string))
	local window = panel({
		Name = "TrailShop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 440),
		Visible = false, BackgroundColor3 = Color3.fromRGB(36, 24, 70), Parent = gui, ZIndex = 5,
	}, PINK)
	refs.Shop = window
	local header = make("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = PINK, Parent = window }, {
		corner(16), gradient(Color3.fromRGB(255, 150, 220), Color3.fromRGB(200, 60, 170)),
	})
	label({ Size = UDim2.new(1, -120, 0, 48), Position = UDim2.fromOffset(20, 9), Text = "✨ TRAIL SHOP", TextXAlignment = Enum.TextXAlignment.Left, Parent = header, StrokeThickness = 3 })
	local close = make("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = RED, Text = "", Parent = header }, {
		corner(12), stroke(Color3.new(1, 1, 1), 2),
	}) :: TextButton
	label({ Size = UDim2.fromScale(1, 1), Text = "X", Parent = close })
	close.Activated:Connect(function()
		Hud.ToggleShop(false)
	end)
	refs.ShopStatus = label({ Size = UDim2.new(1, -40, 0, 24), Position = UDim2.new(0, 20, 1, -34), Text = "Trails multiply your running speed!", TextColor3 = Color3.fromRGB(220, 210, 255), Parent = window })

	local grid = make("Frame", { Position = UDim2.fromOffset(20, 80), Size = UDim2.new(1, -40, 1, -124), BackgroundTransparency = 1, Parent = window }, {
		make("UIGridLayout", { CellSize = UDim2.new(0.32, 0, 0.48, 0), CellPadding = UDim2.new(0.02, 0, 0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for index, trail in Config.Trails do
		local card = make("Frame", { LayoutOrder = index, BackgroundColor3 = Color3.fromRGB(22, 16, 44), Parent = grid }, { corner(14), stroke(trail.Colors[1], 2.5, 0.2) }) :: Frame
		make("Frame", { Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.new(1, 1, 1), Parent = card }, {
			corner(11), gradient(trail.Colors[1], trail.Colors[2], 0),
		})
		label({ Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 34), Text = trail.Name:upper(), TextColor3 = trail.Colors[1], Parent = card, StrokeThickness = 2.5 })
		label({ Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 64), Text = string.format("+%d%% speed", math.floor((trail.Multiplier - 1) * 100 + 0.5)), TextColor3 = GREEN, Parent = card })
		local button = make("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -16, 0, 36), BackgroundColor3 = GOLD, Text = "", Parent = card }, {
			corner(10), stroke(Color3.new(1, 1, 1), 2, 0.3),
		}) :: TextButton
		local buttonText = label({ Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), Text = "$" .. Config.Format(trail.Cost), Parent = button })
		button.Activated:Connect(function()
			local owned = table.find(string.split(player:GetAttribute("OwnedTrails") or "", ","), tostring(index)) ~= nil
			local ok, message = onShopAction(if owned then "Equip" else "Buy", index)
			refs.ShopStatus.Text = message
			refs.ShopStatus.TextColor3 = if ok then GREEN else RED
			pop(card)
		end)
		shopCards[index] = { Button = button, Text = buttonText, Card = card }
	end
end

function Hud.SetMusicLabel(on: boolean)
	refs.MusicText.Text = if on then "♪ MUSIC: ON" else "♪ MUSIC: OFF"
end

function Hud.ToggleShop(open: boolean)
	refs.Shop.Visible = open
	if open then
		pop(refs.Shop)
		Hud.RefreshShop()
	end
end

function Hud.RefreshShop()
	local owned = string.split(player:GetAttribute("OwnedTrails") or "", ",")
	local equipped = player:GetAttribute("Trail") or 0
	local cash = player:GetAttribute("Cash") or 0
	for index, card in shopCards do
		local trail = Config.Trails[index]
		if index == equipped then
			card.Text.Text = "EQUIPPED"
			card.Button.BackgroundColor3 = GREEN
		elseif table.find(owned, tostring(index)) then
			card.Text.Text = "EQUIP"
			card.Button.BackgroundColor3 = Color3.fromRGB(110, 170, 255)
		else
			card.Text.Text = "$" .. Config.Format(trail.Cost)
			card.Button.BackgroundColor3 = if cash >= trail.Cost then GOLD else Color3.fromRGB(110, 100, 130)
		end
	end
end

-- Updates ----------------------------------------------------------------------------

function Hud.Update()
	local cash = player:GetAttribute("Cash") or 0
	refs.Cash.Text = "$" .. Config.Format(cash)
	refs.Income.Text = "+$" .. Config.Format(player:GetAttribute("Income") or 0) .. "/s"
	refs.Eggs.Text = string.format("%d / %d eggs", player:GetAttribute("EggCount") or 0, player:GetAttribute("Capacity") or Config.StartCapacity)
	refs.Speed.Text = string.format("Speed %.1f", player:GetAttribute("WalkSpeed") or Config.BaseWalkSpeed)
	local training = player:GetAttribute("Training") or 0
	refs.TrainingFill.Size = UDim2.fromScale(math.clamp(training / Config.TrainingCap, 0, 1), 1)
	local treadLevel = player:GetAttribute("TreadLevel") or 1
	refs.TrainingText.Text = if training >= Config.TrainingCap
		then string.format("Treadmill Lv %d  •  Training MAX", treadLevel)
		else string.format("Treadmill Lv %d  •  Training %d/%d", treadLevel, training, Config.TrainingCap)
	refs.Save.Text = player:GetAttribute("SaveStatus") or ""

	local carrying = player:GetAttribute("Carrying") or ""
	refs.Carry.Visible = carrying ~= ""
	if carrying ~= "" then
		local rarity = Config.Rarities[player:GetAttribute("CarryRarity") or 1]
		refs.CarryTitle.Text = carrying
		refs.CarryTitle.TextColor3 = rarity.Color
		;(refs.Carry:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = rarity.Color
	end

	local chaser = player:GetAttribute("Chaser") or ""
	local rage = player:GetAttribute("Rage") or 0
	refs.Chase.Visible = chaser ~= ""
	if chaser ~= "" then
		refs.ChaseText.Text = "⚠ " .. chaser:upper() .. " IS CHASING YOU!"
		refs.RageFill.Size = UDim2.fromScale(math.max(rage, 0.08), 1)
		refs.RageText.Text = if rage > 0 then string.format("MONSTER RAGE %d%%", math.floor(rage * 100)) else "RUN!"
	end
	if refs.Shop.Visible then
		Hud.RefreshShop()
	end
end

-- Called every frame with the distance to safety (or nil when not carrying).
function Hud.Frame(t: number, safeDistance: number?, danger: number)
	if safeDistance then
		refs.CarryHint.Text = if safeDistance > 0 then string.format("↓ SAFE ZONE in %d studs ↓", math.ceil(safeDistance)) else "SAFE!"
	end
	local pulse = 0.5 + 0.5 * math.sin(t * 8)
	for _, edge in refs.Vignette do
		edge.BackgroundTransparency = 1 - danger * (0.35 + 0.25 * pulse)
	end
	if refs.Chase.Visible then
		refs.Chase.Rotation = math.sin(t * 30) * (player:GetAttribute("Rage") or 0) * 1.5
	end
end

function Hud.ZoneBanner(title: string, subtitle: string, color: Color3)
	refs.BannerTitle.Text = title
	refs.BannerTitle.TextColor3 = color
	refs.BannerSub.Text = subtitle
	;(refs.Banner:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = color
	local banner = refs.Banner
	TweenService:Create(banner, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 10) }):Play()
	local token = {}
	refs.BannerToken = token
	task.delay(2.6, function()
		if refs.BannerToken == token then
			TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -120) }):Play()
		end
	end)
end

local TOAST_COLORS = {
	good = GREEN,
	bad = RED,
	info = Color3.fromRGB(150, 210, 255),
	rare = GOLD,
}
local toastOrder = 0

function Hud.Toast(text: string, kind: string?)
	toastOrder += 1
	local color = TOAST_COLORS[kind or "info"] or TOAST_COLORS.info
	local toast = panel({ Size = UDim2.fromOffset(500, 48), LayoutOrder = -toastOrder, BackgroundTransparency = 0.12, Parent = refs.Toasts }, color)
	local l = label({ Size = UDim2.new(1, -24, 1, -12), Position = UDim2.fromOffset(12, 6), Text = text, TextColor3 = color, Parent = toast })
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
			TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			task.wait(0.4)
			toast:Destroy()
		end
	end)
end

function Hud.Splash(text: string, sub: string, color: Color3)
	refs.Splash.Text = text
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
