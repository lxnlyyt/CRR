-- Execute through MCP in the Server datamodel during a disposable Studio Play session.
-- This deliberately changes temporary test progress; never runs against cloud-backed profiles.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local p=assert(game.Players:GetPlayers()[1], "Start Play first")
local qa=assert(game.ServerStorage:FindFirstChild("MonsterEggStudioQA"), "Wait for server startup")
assert(not qa:Invoke("Snapshot",p).Profile.Persistent, "Use an API-disabled test session")
local C=require(game.ReplicatedStorage.MonsterEgg.Config)
local checks={}
local function check(name,condition)
 assert(condition,"FAIL: "..name); table.insert(checks,name)
end
local world=workspace.MonsterEggEscape
for i,z in C.Zones do
 check(z.Name.." zone and guardian",world:FindFirstChild(z.Name)~=nil and world:FindFirstChild(z.Monster)~=nil)
end
local char=p.Character
char:PivotTo(CFrame.new(24,4,125))
check("Divine pickup",qa:Invoke("Carry",p,{Zone=1,Rarity=6}))
local guardian=world[C.Zones[1].Monster]
local before=guardian:GetPivot().Position
task.wait(0.35)
check("Guardian pursues carrier",(guardian:GetPivot().Position-before).Magnitude>1)
check("Divine triggers rage and particles",guardian:GetAttribute("Raging") and guardian.PrimaryPart.RageAura.Enabled)
local count=p:GetAttribute("EggCount")
char:PivotTo(CFrame.new(0,4,65)); task.wait(0.2)
check("Sanctuary banks carried egg",p:GetAttribute("EggCount")==count+1 and p:GetAttribute("Carrying")=="")
check("Sanctuary ends rage",not guardian:GetAttribute("Raging"))
check("Guardian stays outside sanctuary",guardian:GetPivot().Position.Z>=C.SafeZ+8)
local cash=p:GetAttribute("Cash"); task.wait(1.2)
check("Banked eggs earn cash",p:GetAttribute("Cash")>cash and p:GetAttribute("Income")>0)
local snap=qa:Invoke("Snapshot",p)
check("Egg is visible in personal plot",#snap.Plot.BankedEggs:GetChildren()==#snap.Profile.Eggs)
local training=p:GetAttribute("Training"); char:PivotTo(CFrame.new(0,4,14)); task.wait(1.2)
check("Treadmill trains speed",p:GetAttribute("Training")>training)
while p:GetAttribute("EggCount")<p:GetAttribute("Capacity") do
 char:PivotTo(CFrame.new(0,4,65)); qa:Invoke("Carry",p,{Zone=1,Rarity=1}); task.wait(0.05)
end
char:PivotTo(CFrame.new(24,4,125))
check("Full storage rejects another egg",not qa:Invoke("Carry",p,{Zone=1,Rarity=1}))
check("Full storage has no carried egg",p:GetAttribute("Carrying")=="")
return {passed=#checks,checks=checks,temporaryProgress=true}
