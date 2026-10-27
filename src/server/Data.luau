-- Player progress with DataStore session locking. Unpublished Studio sessions fall back to
-- clearly-labelled temporary progress; live servers refuse to play on a failed load.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("MonsterEgg"):WaitForChild("Config"))

local Data = {}

local LOCK_EXPIRY = 180
local session = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
local store: DataStore? = nil
local storeError: string? = nil

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		storeError = tostring(result)
		warn("[MonsterEgg] DataStore unavailable: " .. storeError)
	end
end

export type Egg = { Z: number, R: number }
export type Profile = {
	Cash: number,
	SpeedLevel: number,
	Training: number,
	Capacity: number,
	TreadLevel: number,
	Trails: { number },
	Trail: number,
	Eggs: { Egg },
	Stats: { Banked: number, Stolen: number, Caught: number },
	LastSeen: number,
	LastReward: number, -- os.time() of the last free gift claim
	BonusSpeed: number, -- permanent walk speed from Robux speed packs
	Receipts: { string }, -- recent developer product PurchaseIds, so a receipt is never granted twice
	-- Runtime only
	Persistent: boolean?,
	Saving: boolean?,
}

function Data.Default(): Profile
	return {
		Cash = 0,
		SpeedLevel = 0,
		Training = 0,
		Capacity = Config.StartCapacity,
		TreadLevel = 1,
		Trails = {},
		Trail = 0,
		Eggs = {},
		Stats = { Banked = 0, Stolen = 0, Caught = 0 },
		LastSeen = 0,
		LastReward = 0,
		BonusSpeed = 0,
		Receipts = {},
	}
end

-- Fill fields missing from older saves and clamp anything out of range.
local function reconcile(saved: any): Profile
	local profile = Data.Default()
	if type(saved) ~= "table" then
		return profile
	end
	for key, value in saved do
		if key ~= "Lock" and profile[key] ~= nil and type(profile[key]) == type(value) then
			profile[key] = value
		end
	end
	profile.Capacity = math.clamp(profile.Capacity, Config.StartCapacity, Config.MaxCapacity)
	profile.SpeedLevel = math.clamp(profile.SpeedLevel, 0, Config.MaxSpeedLevel)
	profile.TreadLevel = math.clamp(math.floor(profile.TreadLevel), 1, Config.MaxTreadLevel)
	local eggs = {}
	for _, egg in profile.Eggs do
		if type(egg) == "table" and Config.Zones[egg.Z] and Config.Rarities[egg.R] and #eggs < profile.Capacity then
			table.insert(eggs, { Z = egg.Z, R = egg.R })
		end
	end
	profile.Eggs = eggs
	if not Config.Trails[profile.Trail] then
		profile.Trail = 0
	end
	return profile
end

local function payload(profile: Profile)
	return {
		Cash = profile.Cash,
		SpeedLevel = profile.SpeedLevel,
		Training = profile.Training,
		Capacity = profile.Capacity,
		TreadLevel = profile.TreadLevel,
		Trails = table.clone(profile.Trails),
		Trail = profile.Trail,
		Eggs = table.clone(profile.Eggs),
		Stats = table.clone(profile.Stats),
		LastSeen = os.time(),
		LastReward = profile.LastReward,
		BonusSpeed = profile.BonusSpeed,
		Receipts = table.clone(profile.Receipts),
	}
end

-- Returns profile, persistent, kickMessage.
function Data.Load(player: Player): (Profile?, boolean, string?)
	local loaded
	local ok, err = pcall(function()
		assert(store, storeError or "DataStore unavailable")
		loaded = store:UpdateAsync("p" .. player.UserId, function(old)
			if old and old.Lock and old.Lock.Id ~= session and os.time() - old.Lock.Time < LOCK_EXPIRY then
				return nil
			end
			old = old or {}
			old.Lock = { Id = session, Time = os.time() }
			return old
		end)
	end)
	if not ok then
		if RunService:IsStudio() then
			warn("[MonsterEgg] Studio temporary session: " .. tostring(err))
			return Data.Default(), false, nil
		end
		return nil, false, "Progress could not load. Please rejoin; your saved data is safe."
	end
	if not loaded then
		return nil, false, "Your progress is open on another server. Please rejoin in a moment."
	end
	return reconcile(loaded), true, nil
end

-- Writes progress if this server still owns the lock. Returns "ok", "failed" or "lost".
function Data.Save(player: Player, profile: Profile, release: boolean): string
	if not profile.Persistent or not store then
		return "ok"
	end
	while profile.Saving do
		task.wait(0.1)
	end
	profile.Saving = true
	local body = payload(profile)
	local written
	local ok, err = pcall(function()
		written = (store :: DataStore):UpdateAsync("p" .. player.UserId, function(old)
			if not old or not old.Lock or old.Lock.Id ~= session then
				return nil
			end
			body.Lock = if release then nil else { Id = session, Time = os.time() }
			return body
		end)
	end)
	profile.Saving = false
	if not ok then
		warn("[MonsterEgg] Save failed for " .. player.Name .. ": " .. tostring(err))
		return "failed"
	end
	if not written then
		profile.Persistent = false
		return "lost"
	end
	return "ok"
end

function Data.OfflineEarnings(profile: Profile, incomePerSecond: number): number
	if profile.LastSeen <= 0 then
		return 0
	end
	local away = math.clamp(os.time() - profile.LastSeen, 0, Config.OfflineCapSeconds)
	return math.floor(away * incomePerSecond * Config.OfflineRate)
end

return Data
