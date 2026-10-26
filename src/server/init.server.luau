local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local C=require(RS.MonsterEgg.Config)
local W=require(RS.MonsterEgg.World)
local world=W.Build()
local preview=world:FindFirstChild("Preview"); if preview then preview:Destroy() end
local event=Instance.new("RemoteEvent"); event.Name="Notice"; event.Parent=RS.MonsterEgg
local profiles,carried,plots,eggs,monsters={},{},{},{},{}
local session=game.JobId~="" and game.JobId or Http:GenerateGUID(false)
local store
local storeReady,storeError=pcall(function() store=DSS:GetDataStore("MonsterEggEscape_v1") end)
if not storeReady then warn("[MonsterEgg] DataStore unavailable: "..tostring(storeError)) end
local function notice(p,s) event:FireClient(p,s) end
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function alive(p) local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); return h and h.Health>0 end
local function near(p,part,d) local r=root(p); return r and alive(p) and (r.Position-part.Position).Magnitude<=d end
local function sync(p)
 local d=profiles[p]; if not d then return end
 for _,key in {"Cash","Speed","Training","Trail","Capacity"} do p:SetAttribute(key,d[key]) end
 local income=0; for _,e in d.Eggs do income+=C.Zones[e.Zone].Income*C.Rarities[e.Rarity].Multiplier end
 p:SetAttribute("Income",income); p:SetAttribute("EggCount",#d.Eggs)
 p.leaderstats.Cash.Value=math.floor(d.Cash)
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if h then h.WalkSpeed=(20+d.Speed*2+math.min(d.Training,100)*0.15)*(d.Trail>0 and C.Trails[d.Trail].Multiplier or 1) end
end
local function trail(p)
 local r=root(p); local d=profiles[p]; if not r or not d then return end
 for _,v in r:GetChildren() do if v.Name=="EggTrail" then v:Destroy() end end
 if d.Trail==0 then return end
 local a=Instance.new("Attachment"); a.Name="EggTrail"; a.Position=Vector3.new(-0.8,0.1,0); a.Parent=r
 local b=a:Clone(); b.Position=Vector3.new(0.8,0.1,0); b.Parent=r
 local t=Instance.new("Trail"); t.Name="EggTrail"; t.Attachment0=a; t.Attachment1=b; t.Lifetime=0.6; t.LightEmission=1; t.Color=ColorSequence.new(C.Trails[d.Trail].Color); t.Parent=r
end
local function redraw(p)
 local plot=plots[p]; local d=profiles[p]; if not plot or not d then return end
 local old=plot:FindFirstChild("BankedEggs"); if old then old:Destroy() end
 local folder=Instance.new("Folder"); folder.Name="BankedEggs"; folder.Parent=plot
 for n,e in d.Eggs do
  local pos=plot.Floor.Position+Vector3.new(((n-1)%4-1.5)*6,2.5,math.floor((n-1)/4)*6-8)
  local m=W.Egg(folder,e.Zone,e.Rarity,pos)
  W.Label(m.PrimaryPart,C.Rarities[e.Rarity].Name.." • $"..C.Zones[e.Zone].Income*C.Rarities[e.Rarity].Multiplier.."/s",C.Rarities[e.Rarity].Color)
 end
end
local function drop(p)
 local item=carried[p]; if not item then return end
 carried[p]=nil; if item.Model then item.Model:Destroy() end
 p:SetAttribute("Carrying",""); p:SetAttribute("Rage",0)
end
local function carry(p,data)
 if carried[p] or not profiles[p] or #profiles[p].Eggs>=profiles[p].Capacity then notice(p,"Your sanctuary is full — upgrade storage!"); return false end
 local r=root(p); if not r then return false end
 local model=W.Egg(world,data.Zone,data.Rarity,r.Position+Vector3.new(0,3.8,0))
 local pr=W.Prompt(model.PrimaryPart,"Steal egg",p.DisplayName.."'s egg")
 carried[p]={Zone=data.Zone,Rarity=data.Rarity,Model=model,Prompt=pr,Since=os.clock()}
 p:SetAttribute("Carrying",C.Rarities[data.Rarity].Name.." "..C.Zones[data.Zone].Name.." Egg"); p:SetAttribute("Rage",data.Rarity)
 pr.Triggered:Connect(function(thief)
  local item=carried[p]; local a=root(p); local b=root(thief)
  if thief==p or not item or item.Model~=model or not a or not b or not near(thief,model.PrimaryPart,12) then return end
  if a.Position.Z<=C.SafeZ or b.Position.Z<=C.SafeZ or os.clock()-item.Since<2 then return end
  if carried[thief] or not profiles[thief] or #profiles[thief].Eggs>=profiles[thief].Capacity then return end
  local payload={Zone=item.Zone,Rarity=item.Rarity}; drop(p)
  carry(thief,payload); notice(p,"Your egg was stolen!"); notice(thief,"Stolen! Run to the sanctuary!")
 end)
 notice(p,"EGG TAKEN! Run back to the green sanctuary!"); return true
end
local function spawnEgg(zone,slot)
 local rarity=1; local roll=Random.new():NextNumber(0,100); local total=0
 for i,r in C.Rarities do total+=r.Weight; if roll<=total then rarity=i; break end end
 local z=80+(zone-1)*180+45+slot*28
 local pos=Vector3.new(slot%2==0 and -24 or 24,2.8,z)
 local model=W.Egg(world,zone,rarity,pos)
 local pedestal=W.Part(model,"Nest",Vector3.new(6,0.6,6),CFrame.new(pos.X,0.4,pos.Z),C.Zones[zone].Color:Lerp(Color3.new(0,0,0),0.4),Enum.Material.Slate,Enum.PartType.Cylinder)
 pedestal.CFrame=CFrame.new(pos.X,0.4,pos.Z)*CFrame.Angles(0,0,math.pi/2); pedestal.Size=Vector3.new(0.6,6,6)
 W.Label(model.PrimaryPart,C.Rarities[rarity].Name.."\n$"..C.Zones[zone].Income*C.Rarities[rarity].Multiplier.."/s",C.Rarities[rarity].Color)
 local taken=false
 W.Prompt(model.PrimaryPart,"Take egg",C.Zones[zone].Name.." nest",function(p)
  if taken or not near(p,model.PrimaryPart,12) or carried[p] then return end
  if carry(p,{Zone=zone,Rarity=rarity}) then taken=true; eggs[model]=nil; model:Destroy(); task.delay(12,function() spawnEgg(zone,slot) end) end
 end)
 eggs[model]=pos
end
local function save(p,release)
 local d=profiles[p]; if not d or not d.Persistent or d.Saving then return end
 d.Saving=true
 local payload={Cash=d.Cash,Speed=d.Speed,Training=d.Training,Trail=d.Trail,Capacity=d.Capacity,Eggs=table.clone(d.Eggs)}
 local written
 local ok,err=pcall(function() written=store:UpdateAsync("p"..p.UserId,function(old)
  if not old or not old.Lock or old.Lock.Id~=session then return nil end
  if release then payload.Lock=nil else payload.Lock={Id=session,Time=os.time()} end; return payload
 end) end)
 d.Saving=false
 if not ok then
  p:SetAttribute("SaveStatus","Save delayed - retrying next autosave")
  warn("[MonsterEgg] Save failed: "..tostring(err))
 elseif not written then
  d.Persistent=false; p:SetAttribute("SaveStatus","Save session lost")
  if p.Parent==Players then p:Kick("Your save session changed. Please rejoin to protect progress.") end
 else p:SetAttribute("SaveStatus","Cloud save connected") end
end
local function load(p)
 local loaded
 local ok,err=pcall(function()
  assert(store,storeError or "DataStore unavailable")
  loaded=store:UpdateAsync("p"..p.UserId,function(old)
   old=old or {Cash=0,Speed=0,Training=0,Trail=0,Capacity=8,Eggs={}}
   if old.Lock and old.Lock.Id~=session and os.time()-old.Lock.Time<180 then return nil end
   old.Lock={Id=session,Time=os.time()}; return old
  end)
 end)
 if not ok and not Run:IsStudio() then p:Kick("Progress could not load. Please rejoin; your saved data is safe."); return end
 if ok and not loaded then p:Kick("Your progress is open on another server. Please rejoin shortly."); return end
 local d=loaded or {Cash=0,Speed=0,Training=0,Trail=0,Capacity=8,Eggs={}}
 d.Persistent=ok; profiles[p]=d
 if p.Parent~=Players then save(p,true); profiles[p]=nil; return end
 p:SetAttribute("SaveStatus",ok and "Cloud save connected" or "STUDIO: temporary progress (API unavailable)")
 if not ok then warn("[MonsterEgg] Studio temporary session: "..tostring(err)) end
 local stats=Instance.new("Folder"); stats.Name="leaderstats"; stats.Parent=p
 local cash=Instance.new("IntValue"); cash.Name="Cash"; cash.Parent=stats
 for i=1,8 do local plot=world.Sanctuary:FindFirstChild("Plot"..i); if (plot:GetAttribute("Owner") or 0)==0 then plots[p]=plot; plot:SetAttribute("Owner",p.UserId); plot.Floor.BillboardGui.TextLabel.Text=p.DisplayName.."'S SANCTUARY"; break end end
 if not plots[p] then save(p,true); profiles[p]=nil; p:Kick("Sanctuaries full. Please join another server."); return end
 local function character(char)
  local h=char:WaitForChild("Humanoid"); char:WaitForChild("HumanoidRootPart"); sync(p); trail(p)
  char:PivotTo(CFrame.lookAt(Vector3.new(0,4,-43),Vector3.new(0,4,80)))
  h.Died:Connect(function() drop(p) end)
 end
 p.CharacterAdded:Connect(character); if p.Character then task.spawn(character,p.Character) end
 redraw(p); sync(p)
end
for i=1,6 do
 local z=80+(i-0.5)*180
 local model=W.Monster(world,i,Vector3.new(0,0,z+35)); monsters[i]={Model=model,Home=model:GetPivot(),Phase=0}
 for s=1,3 do spawnEgg(i,s) end
end
local function board(name,pos,color,action,callback)
 local p=W.Part(world.Sanctuary,name,Vector3.new(10,6,1),CFrame.new(pos),color)
 W.Sign(p,name.."\n"..action,Color3.new(1,1,1)); W.Prompt(p,action,name,function(player) if near(player,p,12) and profiles[player] then callback(player,profiles[player]) end end); return p
end
board("SPEED UPGRADE",Vector3.new(-20,4,-53),Color3.fromRGB(44,158,212),"Cost: $100 x (level+1)^2",function(p,d)
 local cost=100*(d.Speed+1)^2; if d.Speed>=50 then notice(p,"Speed maxed!"); elseif d.Cash>=cost then d.Cash-=cost; d.Speed+=1; sync(p); notice(p,"Speed upgraded!"); else notice(p,"Need $"..cost) end
end)
board("STORAGE UPGRADE",Vector3.new(20,4,-53),Color3.fromRGB(125,89,196),"Buy 4 slots",function(p,d)
 local cost=500*2^((d.Capacity-8)/4); if d.Capacity>=16 then notice(p,"Storage maxed: 16 eggs"); elseif d.Cash>=cost then d.Cash-=cost; d.Capacity+=4; sync(p); else notice(p,"Need $"..cost) end
end)
for i,t in C.Trails do
 board(t.Name.." TRAIL",Vector3.new(-22+(i-1)*14,4,60),t.Color,t.Multiplier.."× • $"..t.Cost,function(p,d)
  if d.Trail>=i then notice(p,"You already own an equal or faster trail"); elseif d.Cash>=t.Cost then d.Cash-=t.Cost; d.Trail=i; trail(p); sync(p); notice(p,t.Name.." trail equipped!"); else notice(p,"Need $"..t.Cost) end
 end)
end
for i=1,3 do
 local x=-18+(i-1)*18
 local belt=W.Part(world.Sanctuary,"Treadmill"..i,Vector3.new(12,0.8,16),CFrame.new(x,0.5,14),Color3.fromRGB(28,32,49),Enum.Material.Metal)
 for n=1,8 do W.Part(world.Sanctuary,"BeltStripe",Vector3.new(10,0.1,0.25),CFrame.new(x,0.96,6+n*1.8),Color3.fromRGB(79,213,237),Enum.Material.Neon) end
 for _,dx in {-6,6} do W.Part(world.Sanctuary,"Handrail",Vector3.new(0.5,4,16),CFrame.new(x+dx,2,14),Color3.fromRGB(79,92,121),Enum.Material.Metal) end
 W.Label(belt,"TREADMILL\nStand here: +speed +cash",Color3.fromRGB(108,226,255))
end
Players.PlayerAdded:Connect(load); for _,p in Players:GetPlayers() do task.spawn(load,p) end
Players.PlayerRemoving:Connect(function(p)
 drop(p); while profiles[p] and profiles[p].Saving do task.wait(0.1) end; save(p,true)
 local plot=plots[p]; if plot then plot:SetAttribute("Owner",0); plot.Floor.BillboardGui.TextLabel.Text="AVAILABLE SANCTUARY"; local f=plot:FindFirstChild("BankedEggs"); if f then f:Destroy() end end
 profiles[p]=nil; plots[p]=nil
end)
local tickCount=0; local accumulated=0
Run.Heartbeat:Connect(function(dt)
 accumulated+=dt; dt=math.min(dt,0.1)
 for p,item in carried do
  local r=root(p)
  if r and alive(p) then
   item.Model:PivotTo(CFrame.new(r.Position+Vector3.new(0,3.8,0))*CFrame.Angles(0,os.clock(),0))
   if r.Position.Z<=C.SafeZ and math.abs(r.Position.X)<=73 and r.Position.Y<20 then
    local d=profiles[p]; if d and #d.Eggs<d.Capacity then table.insert(d.Eggs,{Zone=item.Zone,Rarity=item.Rarity}); drop(p); redraw(p); sync(p); notice(p,"SAFE! Egg banked — passive income increased!") end
   end
  else drop(p) end
 end
 for index,m in monsters do
  local target,dist,rarity=nil,math.huge,1
  for p,item in carried do
   local r=root(p)
   if r and alive(p) and r.Position.Z>C.SafeZ and item.Zone==index then
    local d=(r.Position-m.Model:GetPivot().Position).Magnitude; if d<dist then target=p; dist=d; rarity=item.Rarity end
   end
  end
  local pivot=m.Model:GetPivot(); local pos=pivot.Position
  local destination=target and root(target).Position or m.Home.Position
  local delta=Vector3.new(destination.X-pos.X,0,destination.Z-pos.Z)
  if delta.Magnitude>0.5 then
   local speed=target and C.Zones[index].Speed*(1+(rarity-1)*0.13) or 13
   local nextPos=pos+delta.Unit*math.min(delta.Magnitude,speed*dt); nextPos=Vector3.new(math.clamp(nextPos.X,-66,66),m.Home.Position.Y,math.max(C.SafeZ+8,nextPos.Z))
   m.Model:PivotTo(CFrame.lookAt(nextPos,nextPos+delta.Unit))
  end
  m.Model:SetAttribute("Raging",target~=nil and rarity>=4)
  m.Model.PrimaryPart.RageAura.Enabled=target~=nil and rarity>=4
  m.Model.PrimaryPart.BillboardGui.TextLabel.Text=C.Zones[index].Monster..(target and (rarity>=4 and "\nMONSTER RAGE!" or "\nCHASING!") or "\nGUARDIAN")
  if target and dist<8 then local h=target.Character and target.Character:FindFirstChildOfClass("Humanoid"); drop(target); if h then h.Health=0 end; notice(target,"The guardian caught you! Train speed and try again.") end
 end
 if accumulated>=1 then
  accumulated-=1; tickCount+=1
  for p,d in profiles do
   local income=0; for _,e in d.Eggs do income+=C.Zones[e.Zone].Income*C.Rarities[e.Rarity].Multiplier end
   d.Cash+=income
   local r=root(p)
   if r and alive(p) and r.Position.Z>=6 and r.Position.Z<=22 and r.Position.Y<6 then
    for i=1,3 do if math.abs(r.Position.X-(-18+(i-1)*18))<5.5 then d.Training=math.min(100,d.Training+0.15); d.Cash+=2+d.Speed; break end end
   end
   sync(p)
  end
  if tickCount%60==0 then for p in profiles do task.spawn(save,p,false) end end
 end
end)
-- Server-only test seam. Never created on published servers.
if Run:IsStudio() then
 local qa=Instance.new("BindableFunction"); qa.Name="MonsterEggStudioQA"; qa.Parent=game:GetService("ServerStorage")
 qa.OnInvoke=function(action,p,arg)
  assert(p and profiles[p],"Player profile not ready")
  if action=="GrantCash" then profiles[p].Cash+=arg; sync(p); return profiles[p].Cash
  elseif action=="Carry" then drop(p); return carry(p,arg)
  elseif action=="Snapshot" then return {Profile=profiles[p],Carried=carried[p],Plot=plots[p]} end
  error("Unknown QA action")
 end
end
game:BindToClose(function()
 local pending=0
 for p in profiles do pending+=1; task.spawn(function() while profiles[p] and profiles[p].Saving do task.wait(0.1) end; save(p,true); pending-=1 end) end
 local deadline=os.clock()+25
 while pending>0 and os.clock()<deadline do task.wait(0.1) end
end)
print("[MonsterEgg] Ready: 6 zones, 18 nests, 8 sanctuaries")
