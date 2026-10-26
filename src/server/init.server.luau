-- MONSTER EGG ESCAPE server: eggs, theft, banking, plots, treadmills, upgrades, trails and saving.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("MonsterEgg")
local Config = require(Shared.Config)
local Style = require(Shared.Style)
local Eggs = require(Shared.Eggs)
local World = require(Shared.World)
local Data = require(script.Data)
local Guardian = require(script.Guardians)

local world = World.Build()
local preview = world:FindFirstChild("Preview")
if preview then
	preview:Destroy()
end
local sanctuary = world:WaitForChild("Sanctuary")

local function folder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name) or Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f :: Folder
end

local runtime = folder(world, "Runtime")
local monsterFolder = folder(runtime, "Monsters")
local nestFolder = folder(runtime, "NestEggs")
local carriedFolder = folder(runtime, "CarriedEggs")

local remotes = folder(Shared, "Remotes")
local function remote(class: string, name: string)
	local r = remotes:FindFirstChild(name) or Instance.new(class)
	r.Name = name
	r.Parent = remotes
	return r
end
local NoticeEvent = remote("RemoteEvent", "Notice") :: RemoteEvent
local EffectEvent = remote("RemoteEvent", "Effect") :: RemoteEvent
local ShopFunction = remote("RemoteFunction", "Shop") :: RemoteFunction

type Carried = { Zone: number, Rarity: number, Model: Model, Since: number }

local profiles: { [Player]: Data.Profile } = {}
local carried: { [Player]: Carried } = {}
local plots: { [Player]: Model } = {}
local guardians = {}
local rng = Random.new()

-- Helpers ----------------------------------------------------------------------

local function notice(player: Player, text: string, kind: string?)
	NoticeEvent:FireClient(player, text, kind or "info")
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function near(player: Player, position: Vector3, range: number): boolean
	local root = rootOf(player)
	return root ~= nil and (root.Position - position).Magnitude <= range
end

local function incomeOf(profile: Data.Profile): number
	local total = 0
	for _, egg in profile.Eggs do
		total += Config.EggIncome(egg.Z, egg.R)
	end
	return total
end

local function ownsTrail(profile: Data.Profile, index: number): boolean
	return table.find(profile.Trails, index) ~= nil
end

local function sync(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Cash", profile.Cash)
	player:SetAttribute("Income", incomeOf(profile))
	player:SetAttribute("SpeedLevel", profile.SpeedLevel)
	player:SetAttribute("Training", profile.Training)
	player:SetAttribute("Capacity", profile.Capacity)
	player:SetAttribute("EggCount", #profile.Eggs)
	player:SetAttribute("TreadLevel", profile.TreadLevel)
	player:SetAttribute("Trail", profile.Trail)
	player:SetAttribute("OwnedTrails", table.concat(profile.Trails, ","))
	player:SetAttribute("Treads", string.format("%d%d%d", profile.Treads[1] and 1 or 0, profile.Treads[2] and 1 or 0, profile.Treads[3] and 1 or 0))
	local walk = Config.WalkSpeed(profile.SpeedLevel, profile.Training, profile.Trail)
	player:SetAttribute("WalkSpeed", walk)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local cashValue = stats:FindFirstChild("Cash") :: IntValue
		local eggsValue = stats:FindFirstChild("Eggs") :: IntValue
		cashValue.Value = math.floor(profile.Cash)
		eggsValue.Value = #profile.Eggs
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = walk
	end
end

local function applyTrail(player: Player)
	local profile = profiles[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not profile or not root then
		return
	end
	for _, child in root:GetChildren() do
		if child.Name == "EggTrail" then
			child:Destroy()
		end
	end
	if profile.Trail == 0 then
		return
	end
	local info = Config.Trails[profile.Trail]
	local top = Instance.new("Attachment")
	top.Name = "EggTrail"
	top.Position = Vector3.new(0, 0.9, 0.4)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "EggTrail"
	bottom.Position = Vector3.new(0, -1.8, 0.4)
	bottom.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "EggTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.55
	trail.LightEmission = 0.8
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(info.Colors[1], info.Colors[2])
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	trail.Parent = root
end

-- Plots ----------------------------------------------------------------------------

local sellEgg: (Player, number) -> ()

local function redrawPlot(player: Player)
	local plot, profile = plots[player], profiles[player]
	if not plot or not profile then
		return
	end
	local index = plot:GetAttribute("Index") :: number
	local old = plot:FindFirstChild("Eggs")
	if old then
		old:Destroy()
	end
	local eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "Eggs"
	for slot, egg in profile.Eggs do
		local model = Eggs.Build(egg.Z, egg.R, CFrame.new(World.SlotPosition(index, slot)) * CFrame.Angles(0, rng:NextNumber(-0.4, 0.4), 0), {
			Scale = 0.75,
			Light = false, -- many lit eggs side by side overexpose the plot
			Parent = eggsFolder,
		})
		model:SetAttribute("Slot", slot)
		local prompt = Style.Prompt(model.PrimaryPart :: BasePart, "Sell $" .. Config.Format(Config.EggIncome(egg.Z, egg.R) * Config.SellSeconds), Eggs.Title(egg.Z, egg.R), 0.8, 7)
		prompt.Name = "SellPrompt"
		prompt.Enabled = false -- the owner's client enables its own sell prompts
		prompt.Triggered:Connect(function(who)
			if who == player then
				sellEgg(player, slot)
			end
		end)
	end
	eggsFolder.Parent = plot
	local income = incomeOf(profile)
	local label = (plot:FindFirstChild("Floor") :: BasePart):FindFirstChild("Income") :: BillboardGui
	(label:FindFirstChild("Text") :: TextLabel).Text = string.format("$%s/s  •  %d/%d eggs", Config.Format(income), #profile.Eggs, profile.Capacity)
end

local function assignPlot(player: Player): Model?
	for index = 1, Config.MaxPlayers do
		local plot = sanctuary.Plots:FindFirstChild("Plot" .. index) :: Model
		if (plot:GetAttribute("Owner") or 0) == 0 then
			plot:SetAttribute("Owner", player.UserId)
			for _, gui in (plot:FindFirstChild("OwnerSign") :: BasePart):GetChildren() do
				((gui :: SurfaceGui):FindFirstChild("Owner") :: TextLabel).Text = string.upper(player.DisplayName) .. "'S PLOT"
			end
			plots[player] = plot
			player:SetAttribute("Plot", index)
			return plot
		end
	end
	return nil
end

local function releasePlot(player: Player)
	local plot = plots[player]
	if not plot then
		return
	end
	plot:SetAttribute("Owner", 0)
	for _, gui in (plot:FindFirstChild("OwnerSign") :: BasePart):GetChildren() do
		((gui :: SurfaceGui):FindFirstChild("Owner") :: TextLabel).Text = "EMPTY PLOT"
	end
	local eggsFolder = plot:FindFirstChild("Eggs")
	if eggsFolder then
		eggsFolder:Destroy()
	end
	local label = (plot:FindFirstChild("Floor") :: BasePart):FindFirstChild("Income") :: BillboardGui
	(label:FindFirstChild("Text") :: TextLabel).Text = "Free plot"
	plots[player] = nil
end

sellEgg = function(player: Player, slot: number)
	local profile = profiles[player]
	local plot = plots[player]
	local egg = profile and profile.Eggs[slot]
	if not egg or not plot or not near(player, World.SlotPosition(plot:GetAttribute("Index") :: number, slot), 12) then
		return
	end
	local value = Config.EggIncome(egg.Z, egg.R) * Config.SellSeconds
	table.remove(profile.Eggs, slot)
	profile.Cash += value
	redrawPlot(player)
	sync(player)
	notice(player, string.format("Sold %s for $%s", Eggs.Title(egg.Z, egg.R), Config.Format(value)), "good")
	EffectEvent:FireClient(player, "Cash", value)
end

-- Carrying, stealing and banking ---------------------------------------------------

local function dropEgg(player: Player)
	local item = carried[player]
	if not item then
		return
	end
	carried[player] = nil
	item.Model:Destroy()
	player:SetAttribute("Carrying", "")
	player:SetAttribute("CarryRarity", 0)
	player:SetAttribute("Chaser", "")
	player:SetAttribute("Rage", 0)
end

local attachEgg: (Player, number, number) -> boolean

local function steal(thief: Player, victim: Player, model: Model)
	local item = carried[victim]
	local thiefRoot, victimRoot = rootOf(thief), rootOf(victim)
	if thief == victim or not item or item.Model ~= model or not thiefRoot or not victimRoot then
		return
	end
	if carried[thief] or not profiles[thief] then
		return
	end
	if victimRoot.Position.Z <= Config.SafeZ or thiefRoot.Position.Z <= Config.SafeZ then
		notice(thief, "Eggs can't be stolen inside the safe zone!", "bad")
		return
	end
	if os.clock() - item.Since < Config.StealProtection then
		notice(thief, "That egg was just grabbed — try again!", "bad")
		return
	end
	if (thiefRoot.Position - victimRoot.Position).Magnitude > Config.StealRange then
		return
	end
	if #profiles[thief].Eggs >= profiles[thief].Capacity then
		notice(thief, "Your plot is full! Upgrade storage or sell eggs.", "bad")
		return
	end
	local zone, rarity = item.Zone, item.Rarity
	dropEgg(victim)
	if attachEgg(thief, zone, rarity) then
		profiles[thief].Stats.Stolen += 1
		notice(victim, thief.DisplayName .. " stole your " .. Eggs.Title(zone, rarity) .. "!", "bad")
		notice(thief, "STOLEN! Run to the safe zone!", "rare")
		EffectEvent:FireClient(victim, "Stolen")
		EffectEvent:FireClient(thief, "Pickup", rarity)
	end
end

attachEgg = function(player: Player, zone: number, rarity: number): boolean
	local profile = profiles[player]
	local root = rootOf(player)
	if not profile or not root or carried[player] then
		return false
	end
	if #profile.Eggs >= profile.Capacity then
		notice(player, "Your plot is full! Upgrade storage or sell eggs.", "bad")
		return false
	end
	local offset = CFrame.new(0, 4, 0)
	local model = Eggs.Build(zone, rarity, root.CFrame * offset, {
		Scale = 0.7,
		Anchored = false,
		Light = false, -- a light this close to the camera washes out the screen
		Label = Config.Rarities[rarity].Name,
	})
	model:SetAttribute("Carrier", player.UserId)
	local core = model.PrimaryPart :: BasePart
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = core
	weld.C0 = offset
	weld.Parent = core
	local prompt = Style.Prompt(core, "Steal Egg", player.DisplayName .. "'s " .. Config.Rarities[rarity].Name, 0.5, 10)
	prompt.Name = "StealPrompt"
	prompt.Triggered:Connect(function(thief)
		steal(thief, player, model)
	end)
	model.Parent = carriedFolder
	carried[player] = { Zone = zone, Rarity = rarity, Model = model, Since = os.clock() }
	player:SetAttribute("Carrying", Eggs.Title(zone, rarity))
	player:SetAttribute("CarryRarity", rarity)
	player:SetAttribute("CarryZone", zone)
	return true
end

local function bank(player: Player)
	local item = carried[player]
	local profile = profiles[player]
	if not item or not profile then
		return
	end
	if #profile.Eggs >= profile.Capacity then
		return
	end
	table.insert(profile.Eggs, { Z = item.Zone, R = item.Rarity })
	profile.Stats.Banked += 1
	local bonus = Config.EggIncome(item.Zone, item.Rarity) * Config.BankBonusSeconds
	profile.Cash += bonus
	local title = Eggs.Title(item.Zone, item.Rarity)
	local rarity = item.Rarity
	dropEgg(player)
	redrawPlot(player)
	sync(player)
	notice(player, string.format("SAFE! %s banked  +$%s", title, Config.Format(bonus)), if rarity >= 5 then "rare" else "good")
	EffectEvent:FireClient(player, "Banked", rarity, bonus)
end

local function caught(player: Player, guardian)
	local item = carried[player]
	if not item then
		return
	end
	local profile = profiles[player]
	if profile then
		profile.Stats.Caught += 1
	end
	local from = guardian.Root.Position
	dropEgg(player)
	notice(player, Config.Zones[guardian.Zone].Monster .. " caught you! The egg is lost — train speed and try again.", "bad")
	EffectEvent:FireClient(player, "Caught", from)
end

-- Nest eggs --------------------------------------------------------------------------

local function spawnNestEgg(zone: number, slot: number)
	local rarity = Config.RollRarity(zone, rng)
	local model = Eggs.Build(zone, rarity, CFrame.new(Config.NestSlot(zone, slot)), {
		Label = Eggs.LabelText(zone, rarity),
		Parent = nestFolder,
	})
	model.Name = string.format("%s_%d", Config.Zones[zone].Name, slot)
	local prompt = Style.Prompt(model.PrimaryPart :: BasePart, "Steal Egg", Config.Rarities[rarity].Name .. " • " .. Config.Zones[zone].Monster .. "'s nest", 0.4, 10)
	prompt.Name = "TakePrompt"
	local taken = false
	prompt.Triggered:Connect(function(player)
		if taken or carried[player] or not near(player, (model.PrimaryPart :: BasePart).Position, 13) then
			return
		end
		if attachEgg(player, zone, rarity) then
			taken = true
			model:Destroy()
			notice(player, if rarity >= Config.RageRarity then "RARE EGG! The guardian is FURIOUS — RUN!" else "Egg grabbed! Run back to the safe zone!", if rarity >= Config.RageRarity then "rare" else "info")
			EffectEvent:FireClient(player, "Pickup", rarity)
			task.delay(Config.NestRespawn, spawnNestEgg, zone, slot)
		end
	end)
end

-- Purchases --------------------------------------------------------------------------

local function spend(player: Player, profile: Data.Profile, cost: number): boolean
	if profile.Cash < cost then
		notice(player, "You need $" .. Config.Format(cost - profile.Cash) .. " more!", "bad")
		return false
	end
	profile.Cash -= cost
	EffectEvent:FireClient(player, "Purchase")
	return true
end

local purchases = {}

function purchases.Speed(player: Player, profile: Data.Profile)
	if profile.SpeedLevel >= Config.MaxSpeedLevel then
		return notice(player, "Speed is maxed out!", "info")
	end
	if spend(player, profile, Config.SpeedCost(profile.SpeedLevel)) then
		profile.SpeedLevel += 1
		notice(player, "Speed upgraded to level " .. profile.SpeedLevel .. "!", "good")
	end
end

function purchases.Storage(player: Player, profile: Data.Profile)
	if profile.Capacity >= Config.MaxCapacity then
		return notice(player, "Storage is maxed out!", "info")
	end
	if spend(player, profile, Config.StorageCost(profile.Capacity)) then
		profile.Capacity += Config.CapacityStep
		redrawPlot(player)
		notice(player, "Plot expanded to " .. profile.Capacity .. " eggs!", "good")
	end
end

function purchases.Power(player: Player, profile: Data.Profile)
	if profile.TreadLevel >= Config.MaxTreadLevel then
		return notice(player, "Treadmill power is maxed out!", "info")
	end
	if spend(player, profile, Config.TreadCost(profile.TreadLevel)) then
		profile.TreadLevel += 1
		notice(player, "Treadmill power level " .. profile.TreadLevel .. "!", "good")
	end
end

local function unlockTreadmill(player: Player, profile: Data.Profile, tier: number)
	if profile.Treads[tier] then
		return notice(player, "Already unlocked — hop on!", "info")
	end
	if spend(player, profile, Config.Treadmills[tier].Cost) then
		profile.Treads[tier] = true
		notice(player, Config.Treadmills[tier].Name .. " treadmill unlocked!", "good")
	end
end

local function boardPrompt(model: Instance, action: string, callback: (Player, Data.Profile) -> ())
	local face = model:FindFirstChild("Board") :: BasePart
	local prompt = Style.Prompt(face, action, model.Name, 0.25, 12)
	prompt.Triggered:Connect(function(player)
		local profile = profiles[player]
		if profile and near(player, face.Position, 16) then
			callback(player, profile)
			sync(player)
		end
	end)
end

local boards = sanctuary:WaitForChild("Boards")
boardPrompt(boards:WaitForChild("SpeedBoard"), "Buy Speed", purchases.Speed)
boardPrompt(boards:WaitForChild("StorageBoard"), "Buy Storage", purchases.Storage)
boardPrompt(boards:WaitForChild("PowerBoard"), "Buy Power", purchases.Power)
for tier = 2, #Config.Treadmills do
	boardPrompt(sanctuary.Treadmills:WaitForChild("UnlockBoard" .. tier), "Unlock", function(player, profile)
		unlockTreadmill(player, profile, tier)
	end)
end

local shopPart = sanctuary.TrailShop:WaitForChild("PromptPart") :: BasePart
local shopPrompt = Style.Prompt(shopPart, "Open Shop", "Trail Shop", 0, 12)
shopPrompt.Triggered:Connect(function(player)
	EffectEvent:FireClient(player, "OpenShop")
end)

local function handleShop(player: Player, action: any, index: any): (boolean, string)
	local profile = profiles[player]
	if not profile or type(index) ~= "number" or not Config.Trails[index] then
		return false, "Invalid request"
	end
	if action == "Buy" then
		if ownsTrail(profile, index) then
			return false, "Already owned"
		end
		if not spend(player, profile, Config.Trails[index].Cost) then
			return false, "Not enough cash"
		end
		table.insert(profile.Trails, index)
		profile.Trail = index
	elseif action == "Equip" then
		if not ownsTrail(profile, index) then
			return false, "Not owned"
		end
		profile.Trail = if profile.Trail == index then 0 else index
	else
		return false, "Invalid request"
	end
	applyTrail(player)
	sync(player)
	return true, if profile.Trail == index then Config.Trails[index].Name .. " trail equipped!" else "Trail unequipped"
end
ShopFunction.OnServerInvoke = handleShop

-- Players ----------------------------------------------------------------------------

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	character:WaitForChild("HumanoidRootPart")
	dropEgg(player)
	sync(player)
	applyTrail(player)
	humanoid.Died:Connect(function()
		dropEgg(player)
	end)
end

local function onPlayerAdded(player: Player)
	local profile, persistent, kickMessage = Data.Load(player)
	if not profile then
		player:Kick(kickMessage)
		return
	end
	profile.Persistent = persistent
	if player.Parent ~= Players then
		Data.Save(player, profile, true)
		return
	end
	profiles[player] = profile
	if not assignPlot(player) then
		Data.Save(player, profile, true)
		profiles[player] = nil
		player:Kick("This server is full. Please join another server.")
		return
	end
	player:SetAttribute("SaveStatus", if persistent then "Progress saved to cloud" else "STUDIO TEST: progress is temporary")
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local eggsValue = Instance.new("IntValue")
	eggsValue.Name = "Eggs"
	eggsValue.Parent = stats
	stats.Parent = player

	local offline = Data.OfflineEarnings(profile, incomeOf(profile))
	if offline > 0 then
		profile.Cash += offline
		task.delay(3, notice, player, "Welcome back! Your eggs earned $" .. Config.Format(offline) .. " while you were away.", "good")
	end
	redrawPlot(player)
	sync(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	dropEgg(player)
	local profile = profiles[player]
	if profile then
		Data.Save(player, profile, true)
	end
	releasePlot(player)
	profiles[player] = nil
end)

-- World setup ------------------------------------------------------------------------

for zone = 1, #Config.Zones do
	guardians[zone] = Guardian.new(zone, monsterFolder)
	for slot = 1, Config.NestSlots do
		spawnNestEgg(zone, slot)
	end
end

local function onRoar(guardian, raging: boolean)
	EffectEvent:FireAllClients("Roar", guardian.Model, raging)
end

-- Main loop --------------------------------------------------------------------------

local accumulated, ticks = 0, 0
local chaserText: { [Player]: string } = {}

RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 0.1)
	local now = os.clock()

	for player in carried do
		local root = rootOf(player)
		if not root then
			dropEgg(player)
		elseif root.Position.Z <= Config.SafeZ and root.Position.Z > Config.SanctuaryStart and math.abs(root.Position.X) <= Config.HalfWidth then
			bank(player)
		end
	end

	local carriers = {}
	for player, item in carried do
		carriers[player] = { Zone = item.Zone, Rarity = item.Rarity }
	end
	local chased = {}
	for _, guardian in guardians do
		local victim = guardian:Update(dt, now, carriers, rootOf, onRoar)
		if victim then
			caught(victim, guardian)
			carriers[victim] = nil
		elseif guardian.Target and (guardian.State == "Chasing" or guardian.State == "Waking") then
			chased[guardian.Target] = guardian
		end
	end
	for player in profiles do
		local guardian = chased[player]
		local text = if guardian then Config.Zones[guardian.Zone].Monster else ""
		if chaserText[player] ~= text then
			chaserText[player] = text
			player:SetAttribute("Chaser", text)
		end
		local rage = if guardian then guardian.Rage else 0
		if player:GetAttribute("Rage") ~= rage then
			player:SetAttribute("Rage", rage)
		end
	end

	accumulated += dt
	if accumulated < 1 then
		return
	end
	accumulated -= 1
	ticks += 1
	for player, profile in profiles do
		profile.Cash += incomeOf(profile)
		local root = rootOf(player)
		if root and not carried[player] then
			for _, info in World.Treadmills do
				local offset = root.Position - info.Center
				if math.abs(offset.X) < 4.6 and math.abs(offset.Z) < 7.8 and offset.Y < 7 and offset.Y > 0 then
					if profile.Treads[info.Tier] then
						local power = Config.TreadPower(info.Tier, profile.TreadLevel)
						profile.Training = math.min(profile.Training + power, Config.TrainingCap * 10)
						local earned = math.floor(2 * power + profile.SpeedLevel)
						profile.Cash += earned
						EffectEvent:FireClient(player, "Treadmill", earned, power)
					elseif ticks % 3 == 0 then
						notice(player, "Unlock this treadmill at the board in front of it!", "info")
					end
					break
				end
			end
		end
		sync(player)
	end
	if ticks % 60 == 0 then
		for player, profile in profiles do
			task.spawn(function()
				local result = Data.Save(player, profile, false)
				if result == "lost" and player.Parent == Players then
					player:Kick("Your save session moved to another server. Please rejoin to protect your progress.")
				elseif result == "failed" then
					player:SetAttribute("SaveStatus", "Save delayed — retrying")
				elseif profile.Persistent then
					player:SetAttribute("SaveStatus", "Progress saved to cloud")
				end
			end)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player, profile in profiles do
		pending += 1
		task.spawn(function()
			Data.Save(player, profile, true)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

-- Studio-only test seam for tests/StudioSmoke.luau. Never created on live servers.
if RunService:IsStudio() then
	local qa = ServerStorage:FindFirstChild("MonsterEggStudioQA") or Instance.new("BindableFunction")
	qa.Name = "MonsterEggStudioQA"
	qa.Parent = ServerStorage
	qa.OnInvoke = function(action: string, player: Player, arg: any)
		local profile = assert(profiles[player], "Player profile not ready")
		assert(not profile.Persistent, "QA hook refuses cloud-backed profiles")
		if action == "GrantCash" then
			profile.Cash += arg
			sync(player)
			return profile.Cash
		elseif action == "Carry" then
			dropEgg(player)
			return attachEgg(player, arg.Zone, arg.Rarity)
		elseif action == "Steal" then
			local victim = arg :: Player
			local item = carried[victim]
			if item then
				item.Since -= Config.StealProtection
				steal(player, victim, item.Model)
			end
			return carried[player] ~= nil
		elseif action == "Snapshot" then
			return {
				Profile = profile,
				Carrying = carried[player] and { Zone = carried[player].Zone, Rarity = carried[player].Rarity } or nil,
				Plot = plots[player],
			}
		elseif action == "Guardian" then
			local g = guardians[arg]
			return { State = g.State, Rage = g.Rage, Position = g.Root.Position, Target = g.Target }
		elseif action == "Purchase" then
			purchases[arg](player, profile)
			sync(player)
			return true
		elseif action == "Sell" then
			sellEgg(player, arg)
			return #profile.Eggs
		elseif action == "Unlock" then
			unlockTreadmill(player, profile, arg)
			sync(player)
			return profile.Treads[arg]
		elseif action == "Shop" then
			return handleShop(player, arg.Action, arg.Index)
		end
		error("Unknown QA action " .. tostring(action))
	end
end

print(string.format("[MonsterEgg] Ready: %d zones, %d nests, %d plots", #Config.Zones, #Config.Zones * Config.NestSlots, Config.MaxPlayers))
