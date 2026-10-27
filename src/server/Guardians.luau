-- Guardian AI: sleeps beside its nest, wakes when one of its eggs is stolen, chases the carrier
-- (faster and angrier for rare eggs), stops at the safe zone and returns to sleep.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("MonsterEgg")
local Config = require(Shared.Config)
local Monsters = require(Shared.Monsters)

export type Carrier = { Zone: number, Rarity: number }

local Guardian = {}
Guardian.__index = Guardian

local STATUS = {
	Sleeping = { "Zzz", Color3.fromRGB(170, 220, 255) },
	Waking = { "!", Color3.fromRGB(255, 220, 80) },
	Chasing = { "!!", Color3.fromRGB(255, 140, 60) },
	Raging = { "RAGE!", Color3.fromRGB(255, 60, 60) },
	Returning = { "...", Color3.fromRGB(230, 230, 240) },
}

function Guardian.new(zone: number, parent: Instance)
	local home = Config.GuardianHome(zone)
	local model = Monsters.Build(zone, home, parent)
	local self = setmetatable({
		Zone = zone,
		Model = model,
		Root = model.PrimaryPart :: BasePart,
		Home = home,
		State = "",
		StateStart = 0,
		Target = nil :: Player?,
		TargetRarity = 1,
		ChaseStart = 0,
		NextCharge = 0,
		ChargeUntil = 0,
		Rage = 0,
		Status = "",
	}, Guardian)
	self:SetState("Sleeping", os.clock())
	return self
end

function Guardian:SetStatus(key: string)
	if self.Status ~= key then
		self.Status = key
		Monsters.SetStatus(self.Model, STATUS[key][1], STATUS[key][2])
	end
end

function Guardian:SetRage(value: number)
	value = math.floor(value * 20 + 0.5) / 20
	if self.Rage ~= value then
		local wasOn, isOn = self.Rage > 0, value > 0
		self.Rage = value
		self.Model:SetAttribute("Rage", value)
		if wasOn ~= isOn then
			Monsters.SetRage(self.Model, isOn)
		end
	end
end

function Guardian:SetState(state: string, now: number)
	self.State = state
	self.StateStart = now
	self.Model:SetAttribute("State", state)
	self.Model:SetAttribute("Sleeping", state == "Sleeping")
	if state == "Sleeping" then
		self.Root.CFrame = Monsters.SleepCFrame(self.Model, self.Home)
		self:SetRage(0)
		self:SetStatus("Sleeping")
	elseif state == "Waking" then
		self.WakeFrom = self.Root.CFrame
		self:SetStatus("Waking")
	elseif state == "Returning" then
		self:SetRage(0)
		self:SetStatus("Returning")
	end
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Picks the closest living carrier of one of this guardian's eggs outside the safe zone.
function Guardian:FindTarget(carriers: { [Player]: Carrier }, rootOf: (Player) -> BasePart?): (Player?, number)
	local best, bestDistance, rarity = nil, math.huge, 1
	local here = self.Root.Position
	for player, item in carriers do
		if item.Zone == self.Zone then
			local root = rootOf(player)
			if root and root.Position.Z > Config.SafeZ then
				local d = (flat(root.Position) - flat(here)).Magnitude
				if d < bestDistance then
					best, bestDistance, rarity = player, d, item.Rarity
				end
			end
		end
	end
	return best, rarity
end

-- Moves toward `goal` and returns the remaining flat distance.
function Guardian:Step(goal: Vector3, speed: number, dt: number): number
	local hip = self.Model:GetAttribute("Hip") :: number
	local pos = self.Root.Position
	local delta = flat(goal) - flat(pos)
	local distance = delta.Magnitude
	if distance < 0.05 then
		return 0
	end
	local move = math.min(distance, speed * dt)
	local nextPos = flat(pos) + delta.Unit * move
	nextPos = Vector3.new(
		math.clamp(nextPos.X, -Config.HalfWidth + 7, Config.HalfWidth - 7),
		self.Home.Position.Y + hip,
		math.clamp(nextPos.Z, Config.SafeZ + 8, Config.ZoneStart(#Config.Zones + 1) - 6)
	)
	self.Root.CFrame = CFrame.lookAt(nextPos, nextPos + delta.Unit)
	return distance - move
end

-- Returns the player that was caught this frame, if any.
function Guardian:Update(dt: number, now: number, carriers: { [Player]: Carrier }, rootOf: (Player) -> BasePart?, onRoar: (Guardian, boolean) -> ()): Player?
	local target, rarity = self:FindTarget(carriers, rootOf)
	self.Target, self.TargetRarity = target, rarity

	if self.State == "Sleeping" then
		if target then
			self:SetState("Waking", now)
		end
		return nil
	end

	if self.State == "Waking" then
		local alpha = math.clamp((now - self.StateStart) / Config.WakeTime, 0, 1)
		local stand = Monsters.StandCFrame(self.Model, self.Home)
		self.Root.CFrame = self.WakeFrom:Lerp(stand, alpha * alpha * (3 - 2 * alpha))
		if alpha >= 1 then
			if target then
				self:SetState("Chasing", now)
				self.ChaseStart = now
				self.NextCharge = now + 2.5
				onRoar(self, rarity >= Config.RageRarity)
			else
				self:SetState("Returning", now)
			end
		end
		return nil
	end

	if self.State == "Returning" and target then
		self:SetState("Chasing", now)
		self.ChaseStart = now
	end

	if self.State == "Chasing" then
		if not target then
			self:SetState("Returning", now)
			return nil
		end
		local zone = Config.Zones[self.Zone]
		local chaseTime = now - self.ChaseStart
		local raging = rarity >= Config.RageRarity
		local rage = if raging then math.clamp(0.45 + (rarity - Config.RageRarity) * 0.18 + chaseTime * 0.02, 0, 1) else 0
		self:SetRage(rage)
		self:SetStatus(if raging then "Raging" else "Chasing")
		local multiplier = 1 + math.max(0, rarity - 3) * 0.1 + math.min(chaseTime * 0.012, 0.2)
		local root = rootOf(target) :: BasePart
		local distance = (flat(root.Position) - flat(self.Root.Position)).Magnitude
		if rarity >= Config.ChargeRarity and now >= self.NextCharge and distance < 70 then
			self.ChargeUntil = now + 0.8
			self.NextCharge = now + 5
			onRoar(self, true)
		end
		if now < self.ChargeUntil then
			multiplier *= 1.75
		end
		self:Step(root.Position, zone.Speed * multiplier, dt)
		local reach = zone.Reach
		if (flat(root.Position) - flat(self.Root.Position)).Magnitude <= reach then
			return target
		end
		return nil
	end

	if self.State == "Returning" then
		local remaining = self:Step(self.Home.Position, Config.ReturnSpeed, dt)
		if remaining <= 0.5 then
			self:SetState("Sleeping", now)
		end
	end
	return nil
end

return Guardian
