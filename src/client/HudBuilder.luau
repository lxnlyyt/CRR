-- Builds the MONSTER EGG ESCAPE interface as real GUI objects with stable names.
-- Run once in Studio (Edit mode) to place it in StarterGui, where it can be inspected and tweaked;
-- the Hud module binds behaviour to these objects at runtime and rebuilds them only if missing.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("MonsterEgg"):WaitForChild("Config"))

local Builder = {}

Builder.Name = "MonsterEggHUD"
Builder.TitleFont = Enum.Font.LuckiestGuy
Builder.Font = Enum.Font.FredokaOne
Builder.Ink = Color3.fromRGB(25, 18, 48)

local INK = Builder.Ink
local WHITE = Color3.new(1, 1, 1)

-- Two-stop gradients per accent: light top, rich bottom.
Builder.Colors = {
	Gold = { Color3.fromRGB(255, 236, 120), Color3.fromRGB(255, 166, 30) },
	Blue = { Color3.fromRGB(130, 230, 255), Color3.fromRGB(40, 120, 255) },
	Pink = { Color3.fromRGB(255, 170, 230), Color3.fromRGB(225, 70, 185) },
	Green = { Color3.fromRGB(150, 245, 110), Color3.fromRGB(40, 170, 60) },
	Purple = { Color3.fromRGB(200, 160, 255), Color3.fromRGB(115, 60, 220) },
	Orange = { Color3.fromRGB(255, 190, 90), Color3.fromRGB(240, 90, 50) },
	Steel = { Color3.fromRGB(190, 205, 235), Color3.fromRGB(85, 105, 155) },
	Red = { Color3.fromRGB(255, 130, 130), Color3.fromRGB(215, 35, 60) },
	Teal = { Color3.fromRGB(120, 255, 220), Color3.fromRGB(20, 160, 150) },
	Grey = { Color3.fromRGB(170, 170, 185), Color3.fromRGB(95, 95, 115) },
	Window = { Color3.fromRGB(70, 55, 130), Color3.fromRGB(30, 22, 64) },
}

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
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
Builder.Make = make

local function corner(radius: number)
	return make("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function outline(thickness: number, color: Color3?)
	return make("UIStroke", { Thickness = thickness, Color = color or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round })
end

-- Vertical glossy gradient for a colour pair.
function Builder.Gradient(pair: { Color3 }, rotation: number?)
	return make("UIGradient", { Name = "Gloss", Color = ColorSequence.new(pair[1], pair[2]), Rotation = rotation or 90 })
end

-- White highlight across the top half, the classic "glossy button" look.
local function shine(parent: Instance, radius: number)
	return make("Frame", {
		Name = "Shine", BackgroundColor3 = WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0,
		Position = UDim2.new(0, 5, 0, 4), Size = UDim2.new(1, -10, 0.42, 0), ZIndex = 2, Parent = parent,
	}, {
		corner(radius),
		make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) }),
	})
end

-- Big cartoon text with a thick dark outline.
function Builder.Text(props: { [string]: any }): TextLabel
	local thickness = props.Outline or 3
	props.Outline = nil
	props.BackgroundTransparency = 1
	props.Font = props.Font or Builder.TitleFont
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	props.ZIndex = props.ZIndex or 3
	return make("TextLabel", props, { make("UIStroke", { Thickness = thickness, Color = INK, LineJoinMode = Enum.LineJoinMode.Round }) })
end
local text = Builder.Text

local function icon(parent: Instance, name: string, id: string, size: UDim2, position: UDim2, fallback: string): GuiObject
	if id:match("^rbxassetid://%d+$") then
		return make("ImageLabel", {
			Name = name, Image = id, ScaleType = Enum.ScaleType.Fit, BackgroundTransparency = 1,
			Size = size, Position = position, ZIndex = 4, Parent = parent,
		})
	end
	return text({ Name = name, Text = fallback, Size = size, Position = position, ZIndex = 4, Parent = parent })
end

-- Glossy, outlined button with a centred label.
function Builder.Button(parent: Instance, name: string, pair: { Color3 }, size: UDim2, position: UDim2, label: string, radius: number?): TextButton
	local r = radius or 14
	local button = make("TextButton", {
		Name = name, Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, Size = size, Position = position, Parent = parent,
	}, { corner(r), outline(3.5), Builder.Gradient(pair), make("UIScale", { Name = "Press" }) })
	shine(button, r - 4)
	text({ Name = "Label", Text = label, Size = UDim2.new(1, -14, 1, -10), Position = UDim2.fromOffset(7, 5), Font = Builder.TitleFont, Parent = button })
	return button
end
local button = Builder.Button

-- Rounded panel with gloss and a thick outline.
local function panel(parent: Instance, name: string, pair: { Color3 }, size: UDim2, position: UDim2, radius: number?): Frame
	local r = radius or 18
	local frame = make("Frame", {
		Name = name, BackgroundColor3 = WHITE, Size = size, Position = position, Parent = parent,
	}, { corner(r), outline(4), Builder.Gradient(pair) })
	shine(frame, r - 4)
	return frame
end
Builder.Panel = panel

-- HUD -------------------------------------------------------------------------------

local function counter(parent: Instance, name: string, pair: { Color3 }, iconId: string, fallback: string, order: number)
	local holder = make("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.fromOffset(250, 66), LayoutOrder = order, Parent = parent })
	local bar = panel(holder, "Bar", pair, UDim2.new(1, -30, 0, 52), UDim2.fromOffset(30, 7), 26)
	icon(holder, "Icon", iconId, UDim2.fromOffset(66, 66), UDim2.fromOffset(0, 0), fallback)
	text({ Name = "Value", Text = "0", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(46, 3), Parent = bar })
	text({ Name = "Sub", Text = "", Font = Builder.Font, Outline = 2, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(46, 32), Parent = bar })
	return holder, bar
end

local function sideButton(parent: Instance, name: string, label: string, pair: { Color3 }, iconId: string, fallback: string, order: number)
	local b = button(parent, name, pair, UDim2.fromOffset(92, 92), UDim2.new(), "", 22)
	b.LayoutOrder = order
	b.Label:Destroy()
	icon(b, "Icon", iconId, UDim2.fromOffset(62, 62), UDim2.fromOffset(15, 4), fallback)
	text({ Name = "Label", Text = label, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 1, -26), Parent = b })
	return b
end

-- Window ------------------------------------------------------------------------------

local function window(parent: Instance, name: string, title: string, pair: { Color3 }, size: Vector2): (Frame, Frame)
	local w = panel(parent, name, Builder.Colors.Window, UDim2.fromOffset(size.X, size.Y), UDim2.fromScale(0.5, 0.52), 24)
	w.AnchorPoint = Vector2.new(0.5, 0.5)
	w.Visible = false
	w.ZIndex = 10
	make("UIScale", { Name = "Pop", Parent = w })
	local header = panel(w, "Header", pair, UDim2.new(1, -40, 0, 70), UDim2.fromOffset(20, -30), 22)
	text({ Name = "Title", Text = title, Size = UDim2.new(1, -40, 1, -14), Position = UDim2.fromOffset(20, 7), Outline = 4, Parent = header })
	local close = button(w, "Close", Builder.Colors.Red, UDim2.fromOffset(58, 58), UDim2.new(1, -38, 0, -24), "X", 29)
	close.ZIndex = 12
	local body = make("Frame", {
		Name = "Body", BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, -70), Position = UDim2.fromOffset(20, 52), Parent = w,
	})
	return w, body
end

local function trailCard(parent: Instance, index: number)
	local trail = Config.Trails[index]
	local rarity = Config.RarityInfo(trail.Rarity)
	local card = panel(parent, "Trail" .. index, { rarity.Color:Lerp(Color3.new(0, 0, 0), 0.35), rarity.Shade:Lerp(Color3.new(0, 0, 0), 0.65) }, UDim2.new(), UDim2.new(), 18)
	card.LayoutOrder = index
	local ribbon = panel(card, "Rarity", { rarity.Color, rarity.Shade }, UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 8), 12)
	text({ Name = "Text", Text = trail.Rarity:upper(), Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), Parent = ribbon })
	local preview = panel(card, "Preview", { trail.Colors[1], trail.Colors[2] }, UDim2.new(1, -24, 0, 58), UDim2.fromOffset(12, 44), 29)
	preview.Gloss.Rotation = 0
	icon(preview, "Icon", Config.Icons.Trail, UDim2.fromOffset(54, 54), UDim2.fromOffset(4, 2), "✨")
	text({ Name = "Name", Text = trail.Name:upper(), Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, 106), Parent = card })
	local badge = panel(card, "Multiplier", Builder.Colors.Green, UDim2.new(1, -60, 0, 26), UDim2.fromOffset(30, 138), 13)
	text({ Name = "Text", Text = string.format("x%.2f SPEED", trail.Multiplier), Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), Parent = badge })
	button(card, "BuyCash", Builder.Colors.Gold, UDim2.new(0.5, -16, 0, 40), UDim2.new(0, 12, 0, 172), "$" .. Config.Format(trail.Cost), 12)
	button(card, "BuyRobux", Builder.Colors.Teal, UDim2.new(0.5, -16, 0, 40), UDim2.new(0.5, 4, 0, 172), "R$ " .. trail.Robux, 12)
	local equip = button(card, "Equip", Builder.Colors.Blue, UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 172), "EQUIP", 12)
	equip.Visible = false
	text({ Name = "State", Text = "NOT OWNED", Font = Builder.Font, Outline = 2, TextColor3 = Color3.fromRGB(220, 215, 245), Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(12, 218), Parent = card })
	return card
end

local function upgradeCard(parent: Instance, name: string, title: string, desc: string, pair: { Color3 }, iconId: string, fallback: string, order: number)
	local card = panel(parent, name, pair, UDim2.new(0.5, -10, 1, -10), UDim2.new(), 20)
	card.LayoutOrder = order
	icon(card, "Icon", iconId, UDim2.fromOffset(88, 88), UDim2.new(0.5, -44, 0, 12), fallback)
	text({ Name = "Title", Text = title, Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 104), Parent = card })
	text({ Name = "Level", Text = "LEVEL 0", Font = Builder.Font, Outline = 2, Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 140), Parent = card })
	local track = make("Frame", { Name = "Progress", BackgroundColor3 = INK, Size = UDim2.new(1, -40, 0, 16), Position = UDim2.fromOffset(20, 170), ZIndex = 3, Parent = card }, { corner(8) })
	make("Frame", { Name = "Fill", BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = track }, { corner(8), Builder.Gradient(Builder.Colors.Green, 0) })
	text({ Name = "Desc", Text = desc, Font = Builder.Font, Outline = 2, TextColor3 = Color3.fromRGB(255, 250, 230), Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 192), Parent = card })
	button(card, "Buy", Builder.Colors.Green, UDim2.new(1, -40, 0, 46), UDim2.new(0, 20, 1, -58), "BUY", 14)
	return card
end

local function toggleRow(parent: Instance, name: string, label: string, order: number)
	local row = panel(parent, name, Builder.Colors.Window, UDim2.new(1, -8, 0, 58), UDim2.new(), 16)
	row.LayoutOrder = order
	text({ Name = "Label", Text = label, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -150, 0, 34), Position = UDim2.fromOffset(18, 12), Parent = row })
	local toggle = button(row, "Toggle", Builder.Colors.Green, UDim2.fromOffset(110, 42), UDim2.new(1, -124, 0, 8), "ON", 21)
	return row, toggle
end

-- Build everything ---------------------------------------------------------------------

function Builder.Build(parent: Instance): ScreenGui
	local old = parent:FindFirstChild(Builder.Name)
	if old then
		old:Destroy()
	end
	local gui = make("ScreenGui", {
		Name = Builder.Name, ResetOnSpawn = false, IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	})
	make("UIScale", { Name = "Scale", Parent = gui })

	-- Red danger edges while being chased.
	local vignette = make("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, Parent = gui })
	for n, edge in { { 0, 0, 1, 0.22, 90 }, { 0, 0.78, 1, 0.22, -90 }, { 0, 0, 0.16, 1, 0 }, { 0.84, 0, 0.16, 1, 180 } } do
		make("Frame", {
			Name = "Edge" .. n, Position = UDim2.fromScale(edge[1], edge[2]), Size = UDim2.fromScale(edge[3], edge[4]),
			BackgroundColor3 = Color3.fromRGB(255, 50, 70), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = vignette,
		}, { make("UIGradient", { Rotation = edge[5], Transparency = NumberSequence.new(0, 1) }) })
	end

	-- Counters (top left).
	local counters = make("Frame", {
		Name = "Counters", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(250, 230), Parent = gui,
	}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	counter(counters, "Cash", Builder.Colors.Gold, Config.Icons.Coin, "$", 1)
	local _, speedBar = counter(counters, "Speed", Builder.Colors.Blue, Config.Icons.Speed, "⚡", 2)
	local track = make("Frame", { Name = "Progress", BackgroundColor3 = INK, BackgroundTransparency = 0.2, Size = UDim2.new(1, -60, 0, 6), Position = UDim2.new(0, 46, 1, -9), ZIndex = 3, Parent = speedBar }, { corner(3) })
	make("Frame", { Name = "Fill", BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = track }, { corner(3) })
	counter(counters, "Eggs", Builder.Colors.Pink, Config.Icons.Egg, "🥚", 3)

	-- Side buttons (left, 2 columns).
	local side = make("Frame", {
		Name = "SideButtons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 70), Size = UDim2.fromOffset(196, 306), Parent = gui,
	}, { make("UIGridLayout", { CellSize = UDim2.fromOffset(92, 92), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
	sideButton(side, "Shop", "SHOP", Builder.Colors.Green, Config.Icons.Shop, "🛒", 1)
	sideButton(side, "Index", "INDEX", Builder.Colors.Purple, Config.Icons.Index, "📖", 2)
	sideButton(side, "Trails", "TRAILS", Builder.Colors.Pink, Config.Icons.Trail, "✨", 3)
	local rewards = sideButton(side, "Rewards", "REWARDS", Builder.Colors.Orange, Config.Icons.Rewards, "🎁", 4)
	local badge = panel(rewards, "Badge", Builder.Colors.Red, UDim2.fromOffset(30, 30), UDim2.new(1, -22, 0, -8), 15)
	badge.ZIndex = 6
	text({ Name = "Text", Text = "!", Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), ZIndex = 7, Parent = badge })
	sideButton(side, "Settings", "SETTINGS", Builder.Colors.Steel, Config.Icons.Settings, "⚙", 5)

	text({ Name = "SaveStatus", Text = "", Font = Builder.Font, Outline = 1.5, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(210, 210, 235), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -8), Size = UDim2.fromOffset(330, 18), Parent = gui })

	-- Zone banner, chase warning and carried egg.
	local banner = panel(gui, "ZoneBanner", Builder.Colors.Green, UDim2.fromOffset(440, 84), UDim2.new(0.5, 0, 0, -200), 22)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	text({ Name = "Title", Text = "SAFE ZONE", Size = UDim2.new(1, -30, 0, 48), Position = UDim2.fromOffset(15, 6), Outline = 4, Parent = banner })
	text({ Name = "Sub", Text = "", Font = Builder.Font, Outline = 2, Size = UDim2.new(1, -30, 0, 22), Position = UDim2.fromOffset(15, 54), Parent = banner })

	local chase = panel(gui, "Chase", Builder.Colors.Red, UDim2.fromOffset(470, 78), UDim2.new(0.5, 0, 0, 100), 22)
	chase.AnchorPoint = Vector2.new(0.5, 0)
	chase.Visible = false
	text({ Name = "Title", Text = "", Size = UDim2.new(1, -70, 0, 34), Position = UDim2.fromOffset(52, 6), Outline = 3.5, Parent = chase })
	local rageTrack = make("Frame", { Name = "Bar", BackgroundColor3 = INK, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.fromOffset(52, 46), ZIndex = 3, Parent = chase }, { corner(10) })
	make("Frame", { Name = "Fill", BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = rageTrack }, { corner(10), Builder.Gradient({ Color3.fromRGB(255, 220, 70), Color3.fromRGB(255, 40, 60) }, 0) })
	text({ Name = "Text", Text = "", Font = Builder.Font, Outline = 2, Size = UDim2.new(1, -8, 1, -2), Position = UDim2.fromOffset(4, 1), ZIndex = 5, Parent = rageTrack })
	icon(chase, "RageIcon", Config.Icons.Rage, UDim2.fromOffset(84, 84), UDim2.fromOffset(-36, -4), "!")

	local carry = panel(gui, "Carry", Builder.Colors.Window, UDim2.fromOffset(440, 96), UDim2.new(0.5, 0, 1, -100), 22)
	carry.AnchorPoint = Vector2.new(0.5, 1)
	carry.Visible = false
	text({ Name = "Header", Text = "CARRYING", Font = Builder.Font, Outline = 2, TextColor3 = Color3.fromRGB(210, 205, 240), Size = UDim2.new(1, -30, 0, 20), Position = UDim2.fromOffset(15, 6), Parent = carry })
	text({ Name = "Title", Text = "", Size = UDim2.new(1, -30, 0, 36), Position = UDim2.fromOffset(15, 26), Outline = 3.5, Parent = carry })
	text({ Name = "Hint", Text = "", Font = Builder.Font, Outline = 2, TextColor3 = Color3.fromRGB(120, 255, 170), Size = UDim2.new(1, -30, 0, 22), Position = UDim2.fromOffset(15, 64), Parent = carry })

	make("Frame", {
		Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 186), Size = UDim2.fromOffset(520, 260), Parent = gui,
	}, { make("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
	text({ Name = "Splash", Text = "", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(560, 96), Outline = 5, Parent = gui })
	text({ Name = "SplashSub", Text = "", Visible = false, Font = Builder.Font, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(460, 40), Outline = 3, TextColor3 = Color3.fromRGB(255, 220, 90), Parent = gui })

	-- Windows ---------------------------------------------------------------------------
	local _, trailBody = window(gui, "TrailsWindow", "TRAIL SHOP", Builder.Colors.Pink, Vector2.new(720, 540))
	local scroller = make("ScrollingFrame", {
		Name = "Cards", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -36),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 8, ScrollBarImageColor3 = Color3.fromRGB(255, 170, 230), Parent = trailBody,
	}, {
		make("UIGridLayout", { CellSize = UDim2.fromOffset(210, 244), CellPadding = UDim2.fromOffset(14, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
	})
	for index = 1, #Config.Trails do
		trailCard(scroller, index)
	end
	text({ Name = "Status", Text = "Trails multiply your running speed!", Font = Builder.Font, Outline = 2, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 26), Parent = trailBody })

	local _, shopBody = window(gui, "ShopWindow", "UPGRADES", Builder.Colors.Green, Vector2.new(620, 400))
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 20), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = shopBody })
	upgradeCard(shopBody, "Speed", "SPEED", "+" .. Config.SpeedPerLevel .. " walk speed per level", Builder.Colors.Blue, Config.Icons.Speed, "⚡", 1)
	upgradeCard(shopBody, "Storage", "STORAGE", "+" .. Config.CapacityStep .. " egg slots in your base", Builder.Colors.Pink, Config.Icons.Egg, "🥚", 2)

	local _, indexBody = window(gui, "IndexWindow", "EGG INDEX", Builder.Colors.Purple, Vector2.new(640, 520))
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = indexBody })
	local headerRow = make("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 0, Parent = indexBody })
	for n, column in { { "RARITY", 0.06, 0.34 }, { "INCOME", 0.4, 0.18 }, { "FOREST", 0.6, 0.18 }, { "SHADOW", 0.8, 0.18 } } do
		text({ Name = "Col" .. n, Text = column[1], Font = Builder.Font, Outline = 2, TextColor3 = Color3.fromRGB(220, 210, 255), Position = UDim2.fromScale(column[2], 0), Size = UDim2.fromScale(column[3], 1), Parent = headerRow })
	end
	local forest, shadowW = Config.RarityWeights(1), Config.RarityWeights(#Config.Zones)
	local forestTotal, shadowTotal = 0, 0
	for i = 1, #forest do
		forestTotal += forest[i]
		shadowTotal += shadowW[i]
	end
	for i, rarity in Config.Rarities do
		local row = panel(indexBody, rarity.Name, { rarity.Color:Lerp(Color3.new(0, 0, 0), 0.25), rarity.Shade:Lerp(Color3.new(0, 0, 0), 0.6) }, UDim2.new(1, -8, 0, 52), UDim2.new(), 14)
		row.LayoutOrder = i
		icon(row, "Egg", Config.Icons.Egg, UDim2.fromOffset(44, 44), UDim2.fromOffset(6, 4), "🥚")
		text({ Name = "Name", Text = rarity.Name:upper(), TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0.06, 26, 0, 10), Size = UDim2.new(0.34, -26, 0, 32), Parent = row })
		text({ Name = "Income", Text = "x" .. rarity.Multiplier, Position = UDim2.new(0.4, 0, 0, 10), Size = UDim2.new(0.18, 0, 0, 32), Parent = row })
		text({ Name = "Forest", Text = string.format("%.1f%%", forest[i] / forestTotal * 100), Font = Builder.Font, Position = UDim2.new(0.6, 0, 0, 12), Size = UDim2.new(0.18, 0, 0, 28), Parent = row })
		text({ Name = "Shadow", Text = string.format("%.1f%%", shadowW[i] / shadowTotal * 100), Font = Builder.Font, Position = UDim2.new(0.8, 0, 0, 12), Size = UDim2.new(0.18, 0, 0, 28), Parent = row })
	end

	local _, rewardsBody = window(gui, "RewardsWindow", "FREE GIFT", Builder.Colors.Orange, Vector2.new(460, 440))
	icon(rewardsBody, "Gift", Config.Icons.Rewards, UDim2.fromOffset(150, 150), UDim2.new(0.5, -75, 0, 18), "🎁")
	text({ Name = "Info", Text = "Claim a cash gift every 15 minutes!", Font = Builder.Font, Outline = 2, Position = UDim2.fromOffset(10, 176), Size = UDim2.new(1, -20, 0, 26), Parent = rewardsBody })
	text({ Name = "Amount", Text = "+$500", TextColor3 = Color3.fromRGB(255, 225, 90), Position = UDim2.fromOffset(10, 206), Size = UDim2.new(1, -20, 0, 48), Outline = 4, Parent = rewardsBody })
	button(rewardsBody, "Claim", Builder.Colors.Green, UDim2.new(1, -80, 0, 60), UDim2.new(0, 40, 0, 270), "CLAIM", 18)

	local _, settingsBody = window(gui, "SettingsWindow", "SETTINGS", Builder.Colors.Steel, Vector2.new(480, 400))
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = settingsBody })
	make("UIPadding", { PaddingTop = UDim.new(0, 16), Parent = settingsBody })
	toggleRow(settingsBody, "Music", "MUSIC", 1)
	toggleRow(settingsBody, "Sounds", "SOUND EFFECTS", 2)
	toggleRow(settingsBody, "Shake", "CAMERA SHAKE", 3)
	toggleRow(settingsBody, "Particles", "ZONE PARTICLES", 4)

	gui.Parent = parent
	return gui
end

return Builder
