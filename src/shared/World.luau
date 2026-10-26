local C = require(script.Parent.Config)
local W = {}
function W.Part(parent,name,size,cf,color,material,shape)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic; p.Anchored=true
 if shape then p.Shape=shape end
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent; return p
end
local P=W.Part
function W.Label(part,text,color)
 local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromScale(13,3.2); gui.StudsOffset=Vector3.new(0,4,0); gui.AlwaysOnTop=false; gui.MaxDistance=110; gui.Parent=part
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.Text=text; t.TextColor3=color or Color3.new(1,1,1); t.TextStrokeTransparency=0.35; t.Parent=gui; return t
end
function W.Sign(part,text,color)
 for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
  local gui=Instance.new("SurfaceGui"); gui.Face=face; gui.CanvasSize=Vector2.new(800,300); gui.Parent=part
  local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(0.92,0.86); t.Position=UDim2.fromScale(0.04,0.07); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.TextWrapped=true; t.Text=text; t.TextColor3=color or Color3.new(1,1,1); t.Parent=gui
 end
end
function W.Prompt(part,action,object,callback)
 local pr=Instance.new("ProximityPrompt"); pr.ActionText=action; pr.ObjectText=object; pr.HoldDuration=0.45; pr.MaxActivationDistance=10; pr.RequiresLineOfSight=false; pr.Parent=part
 if callback then pr.Triggered:Connect(callback) end
 return pr
end
function W.Egg(parent,zone,rarity,position)
 local model=Instance.new("Model"); model.Name=C.Rarities[rarity].Name.."Egg"
 local color=C.Rarities[rarity].Color
 local core=P(model,"Shell",Vector3.new(2.8,3.7,2.8),CFrame.new(position),color,Enum.Material.SmoothPlastic,Enum.PartType.Ball); core.CanCollide=false
 for n=1,7 do
  local a=n*math.pi*2/7
  local spot=P(model,"Gem",Vector3.new(0.48,0.65,0.24),CFrame.new(position+Vector3.new(math.sin(a)*1.3,0,math.cos(a)*1.3))*CFrame.Angles(0,a,0),C.Zones[zone].Color,Enum.Material.Neon,Enum.PartType.Ball); spot.CanCollide=false
 end
 local ring=P(model,"Halo",Vector3.new(0.12,3.5,3.5),CFrame.new(position+Vector3.new(0,2.4,0))*CFrame.Angles(0,0,math.pi/2),color,Enum.Material.Neon,Enum.PartType.Cylinder); ring.CanCollide=false
 if rarity>=4 then local light=Instance.new("PointLight"); light.Color=color; light.Brightness=1.5; light.Range=12; light.Parent=core end
 if rarity>=3 then
  local fx=Instance.new("ParticleEmitter"); fx.Name="RaritySparkles"; fx.Texture="rbxasset://textures/particles/sparkles_main.dds"; fx.Color=ColorSequence.new(color); fx.LightEmission=0.8; fx.Rate=rarity*2; fx.Lifetime=NumberRange.new(0.5,1.2); fx.Speed=NumberRange.new(0.3,1.5); fx.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,0)}); fx.Parent=core
 end
 model.PrimaryPart=core; model.Parent=parent; return model
end
function W.Monster(parent,index,position)
 local z=C.Zones[index]; local m=Instance.new("Model"); m.Name=z.Monster
 local dark=z.Color:Lerp(Color3.new(0,0,0),0.5)
 local body=P(m,"Body",Vector3.new(8,9,6),CFrame.new(position+Vector3.new(0,6,0)),dark,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 P(m,"Head",Vector3.new(7,6,6),CFrame.new(position+Vector3.new(0,12,-1)),z.Color,nil,Enum.PartType.Ball)
 for _,s in {-1,1} do
  P(m,"Arm",Vector3.new(3,7,3),CFrame.new(position+Vector3.new(s*5,6,0))*CFrame.Angles(0,0,s*0.25),dark,nil,Enum.PartType.Ball)
  P(m,"Foot",Vector3.new(3,3,5),CFrame.new(position+Vector3.new(s*2.4,1.7,-1)),z.Color,nil,Enum.PartType.Ball)
  P(m,"Eye",Vector3.new(1.6,1.3,0.7),CFrame.new(position+Vector3.new(s*1.7,12.5,-3.7)),Color3.fromRGB(255,69,92),Enum.Material.Neon,Enum.PartType.Ball)
  P(m,"Pupil",Vector3.new(0.45,1,0.3),CFrame.new(position+Vector3.new(s*1.7,12.5,-4.1)),Color3.new(0.03,0.02,0.06),nil,Enum.PartType.Ball)
  for n=1,3 do P(m,"Claw",Vector3.new(0.5,1.8,0.6),CFrame.new(position+Vector3.new(s*(4+n*0.5),2.5,-1)),Color3.fromRGB(255,238,205),nil,Enum.PartType.Ball) end
  local horn=P(m,"Horn",Vector3.new(1.3,4,1.3),CFrame.new(position+Vector3.new(s*2.6,16,0))*CFrame.Angles(0,0,-s*0.4),Color3.fromRGB(255,225,163),nil,Enum.PartType.Ball)
 end
 P(m,"Mouth",Vector3.new(3.5,1.1,0.6),CFrame.new(position+Vector3.new(0,10.3,-3.6)),Color3.fromRGB(33,16,38),nil,Enum.PartType.Ball)
 for n=1,5 do P(m,"Tooth",Vector3.new(0.38,0.8,0.4),CFrame.new(position+Vector3.new(n*0.58-1.74,10.5,-4)),Color3.new(1,1,0.9),nil,Enum.PartType.Ball) end
 for n=1,5 do P(m,"BackSpine",Vector3.new(1.5,2+n%2,2),CFrame.new(position+Vector3.new(0,5+n*1.7,3)),z.Color,Enum.Material.Neon,Enum.PartType.Ball) end
 if index==2 or index==5 then
  for _,s in {-1,1} do for n=1,4 do P(m,"CrawlerLeg",Vector3.new(6,0.8,1),CFrame.new(position+Vector3.new(s*5,2,n*2-5))*CFrame.Angles(0,s*0.4,s*0.3),z.Color,nil,Enum.PartType.Ball) end end
 elseif index==4 then
  for _,s in {-1,1} do P(m,"Wing",Vector3.new(9,1,7),CFrame.new(position+Vector3.new(s*6,10,3))*CFrame.Angles(0,0,s*0.5),dark,nil,Enum.PartType.Ball) end
 elseif index==6 then
  P(m,"VoidCrown",Vector3.new(0.3,9,9),CFrame.new(position+Vector3.new(0,18,0))*CFrame.Angles(0,0,math.pi/2),z.Color,Enum.Material.Neon,Enum.PartType.Cylinder)
 end
 if index==1 then
  for _,s in {-1,1} do
   for n=1,4 do P(m,"AntlerBranch",Vector3.new(0.7,3.8,0.7),CFrame.new(position+Vector3.new(s*(2.5+n*0.7),15+n*0.65,0))*CFrame.Angles(0,0,-s*(0.3+n*0.15)),Color3.fromRGB(139,95,53),Enum.Material.Wood,Enum.PartType.Ball) end
   for n=1,3 do P(m,"LeafMane",Vector3.new(3,2,3),CFrame.new(position+Vector3.new(s*3.6,8+n*1.2,1)),Color3.fromRGB(102,210,90),Enum.Material.Grass,Enum.PartType.Ball) end
  end
 elseif index==2 then
  for n=1,6 do P(m,"ArmoredTail",Vector3.new(2.7,2.7,2.7),CFrame.new(position+Vector3.new(0,2+n*1.5,3+n)),z.Color,Enum.Material.Sandstone,Enum.PartType.Ball) end
  P(m,"VenomStinger",Vector3.new(1.5,4,1.5),CFrame.new(position+Vector3.new(0,12,8))*CFrame.Angles(0.7,0,0),Color3.fromRGB(72,30,91),Enum.Material.Neon,Enum.PartType.Ball)
 elseif index==3 then
  for _,s in {-1,1} do
   for n=1,5 do P(m,"FrostFur",Vector3.new(2.2,3,2.2),CFrame.new(position+Vector3.new(s*(2+n*0.55),10-n*0.55,0)),Color3.fromRGB(231,251,255),Enum.Material.Snow,Enum.PartType.Ball) end
   P(m,"IceTusk",Vector3.new(0.8,3,0.8),CFrame.new(position+Vector3.new(s*1.5,9.6,-4)),Color3.fromRGB(190,243,255),Enum.Material.Ice,Enum.PartType.Ball)
  end
 elseif index==4 then
  for n=1,7 do P(m,"DrakeTail",Vector3.new(3-n*0.3,2.4-n*0.2,3),CFrame.new(position+Vector3.new(math.sin(n*0.5)*2,3,3+n*1.8)),dark,Enum.Material.Basalt,Enum.PartType.Ball) end
  for _,s in {-1,1} do P(m,"Nostril",Vector3.new(0.7,0.7,0.7),CFrame.new(position+Vector3.new(s*0.7,11.8,-4)),Color3.fromRGB(255,210,65),Enum.Material.Neon,Enum.PartType.Ball) end
 elseif index==5 then
  for n=1,8 do P(m,"ToxinBlister",Vector3.new(1.5,1.5,1.5),CFrame.new(position+Vector3.new(math.sin(n)*3.7,5+n*0.75,math.cos(n)*3)),Color3.fromRGB(220,255,53),Enum.Material.Neon,Enum.PartType.Ball) end
  for _,s in {-1,1} do P(m,"Antenna",Vector3.new(0.5,5,0.5),CFrame.new(position+Vector3.new(s*2,17,-1))*CFrame.Angles(0,0,-s*0.35),dark,nil,Enum.PartType.Ball) end
 else
  for n=1,7 do P(m,"ShadowWisp",Vector3.new(1.3,6,1.3),CFrame.new(position+Vector3.new(math.sin(n)*4,3,math.cos(n)*3))*CFrame.Angles(0,0,math.sin(n)*0.3),z.Color,Enum.Material.Neon,Enum.PartType.Ball) end
 end
 local aura=Instance.new("ParticleEmitter"); aura.Name="RageAura"; aura.Texture="rbxasset://textures/particles/sparkles_main.dds"; aura.Color=ColorSequence.new(z.Color); aura.Rate=18; aura.Enabled=false; aura.Speed=NumberRange.new(2,5); aura.Lifetime=NumberRange.new(0.4,1); aura.LightEmission=1; aura.Parent=body
 for _,p in m:GetChildren() do if p:IsA("BasePart") then p.CanCollide=false; p.CanTouch=false end end
 m.PrimaryPart=body; W.Label(body,z.Monster.."\nGUARDIAN",z.Color); m.Parent=parent; return m
end
function W.Build()
 local existing=workspace:FindFirstChild("MonsterEggEscape"); if existing then return existing end
 local root=Instance.new("Folder"); root.Name="MonsterEggEscape"; root.Parent=workspace
 local baseplate=workspace:FindFirstChild("Baseplate"); if baseplate and baseplate:IsA("BasePart") then baseplate.Transparency=1; baseplate.CanCollide=false end
 local hub=Instance.new("Folder"); hub.Name="Sanctuary"; hub.Parent=root
 P(hub,"SafeFloor",Vector3.new(150,3,155),CFrame.new(0,-1.5,2.5),Color3.fromRGB(39,51,79))
 for _,x in {-74,74} do P(hub,"NeonEdge",Vector3.new(1,0.3,155),CFrame.new(x,0.2,2.5),Color3.fromRGB(67,255,204),Enum.Material.Neon) end
 local spawn=Instance.new("SpawnLocation"); spawn.Name="SanctuarySpawn"; spawn.Size=Vector3.new(12,1,12); spawn.Position=Vector3.new(0,0.5,-48); spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0; spawn.Color=Color3.fromRGB(65,209,179); spawn.Parent=hub
 local gate=P(hub,"SafeGate",Vector3.new(146,0.4,2),CFrame.new(0,0.3,80),Color3.fromRGB(72,255,197),Enum.Material.Neon)
 W.Label(gate,"SANCTUARY • BANK YOUR EGGS",Color3.fromRGB(109,255,206))
 local sign=P(hub,"Title",Vector3.new(50,10,2),CFrame.new(0,19,-69),Color3.fromRGB(22,28,48)); W.Sign(sign,"MONSTER EGG ESCAPE\nSTEAL • RUN • GROW",Color3.fromRGB(255,217,103))
 for _,x in {-27,27} do P(hub,"TitleSupport",Vector3.new(1,22,1),CFrame.new(x,10,-69),Color3.fromRGB(76,237,198),Enum.Material.Neon) end
 for n=1,12 do P(hub,"CenterPaving",Vector3.new(20,0.1,8),CFrame.new(0,0.08,-58+n*11),n%2==0 and Color3.fromRGB(55,70,99) or Color3.fromRGB(48,62,89)) end
 for _,x in {-77,77} do P(hub,"SanctuaryBoundary",Vector3.new(4,8,155),CFrame.new(x,3,2.5),Color3.fromRGB(34,45,66),Enum.Material.Slate) end
 P(hub,"SanctuaryRear",Vector3.new(154,8,4),CFrame.new(0,3,-77),Color3.fromRGB(34,45,66),Enum.Material.Slate)
 for i=1,6 do
  local z=C.Zones[i]; local section=Instance.new("Folder"); section.Name=z.Name; section.Parent=root
  local center=80+(i-0.5)*C.ZoneLength
  local materials={Enum.Material.Grass,Enum.Material.Sand,Enum.Material.Snow,Enum.Material.Basalt,Enum.Material.Mud,Enum.Material.Slate}
  P(section,"Ground",Vector3.new(150,3,C.ZoneLength),CFrame.new(0,-1.5,center),z.Color,materials[i])
  P(section,"Runway",Vector3.new(28,0.16,C.ZoneLength),CFrame.new(0,0.1,center),z.Color:Lerp(Color3.new(1,1,1),0.3))
  for _,x in {-77,77} do
   P(section,"HighWall",Vector3.new(6,42,C.ZoneLength),CFrame.new(x,20,center),z.Color:Lerp(Color3.fromRGB(31,34,54),0.65),Enum.Material.Slate)
   P(section,"WallGlow",Vector3.new(0.3,0.4,C.ZoneLength),CFrame.new(x>0 and 73.8 or -73.8,11,center),z.Color,Enum.Material.Neon)
  end
  local arch=P(section,"ZoneSign",Vector3.new(46,6,2),CFrame.new(0,24,center-83),z.Color:Lerp(Color3.new(0,0,0),0.6)); W.Sign(arch,string.upper(z.Name).."\n"..z.Monster,z.Color)
  for _,x in {-24,24} do P(section,"ArchColumn",Vector3.new(2,26,3),CFrame.new(x,12,center-83),z.Color,Enum.Material.Neon) end
  local rng=Random.new(120+i)
  for n=1,18 do
   local x=(n%2==0 and 1 or -1)*rng:NextNumber(36,65); local zz=center+rng:NextNumber(-75,75)
   if i==1 then
    P(section,"Trunk",Vector3.new(12,3,3),CFrame.new(x,6,zz)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(112,77,52),Enum.Material.Wood,Enum.PartType.Cylinder)
    for k=1,3 do P(section,"Canopy",Vector3.new(13-k*2,10,13-k*2),CFrame.new(x,11+k*3,zz),z.Color:Lerp(Color3.fromRGB(20,80,56),k/5),Enum.Material.Grass,Enum.PartType.Ball) end
   else
    local crystal=P(section,"Crystal",Vector3.new(rng:NextNumber(3,7),rng:NextNumber(5,17),4),CFrame.new(x,4,zz)*CFrame.Angles(0,rng:NextNumber(0,6),0.2),z.Color, i>=4 and Enum.Material.Neon or Enum.Material.Glass); crystal.Transparency=i==3 and 0.2 or 0
    P(section,"Stone",Vector3.new(8,3,8),CFrame.new(x,1,zz),z.Color:Lerp(Color3.new(0,0,0),0.45),Enum.Material.Slate,Enum.PartType.Ball)
   end
  end
  if i>=3 then
   for n=1,6 do
    local x=n%2==0 and 52 or -52; local zz=center-80+n*24
    local pool=P(section,"EnergyPool",Vector3.new(0.15,17,23),CFrame.new(x,0.15,zz)*CFrame.Angles(0,0,math.pi/2),z.Color, i==3 and Enum.Material.Ice or Enum.Material.Neon,Enum.PartType.Cylinder)
    pool.CanCollide=false
   end
  end
  for n=1,8 do P(section,"PathLight",Vector3.new(1,0.2,4),CFrame.new(n%2==0 and 16 or -16,0.25,center-85+n*20),Color3.fromRGB(255,245,198),Enum.Material.Neon) end
  task.wait()
 end
 P(root,"EndWall",Vector3.new(150,42,5),CFrame.new(0,20,1163),C.Zones[6].Color,Enum.Material.Slate)
 for i=1,8 do
  local x=i%2==0 and 51 or -51; local z=-48+math.floor((i-1)/2)*32
  local plot=Instance.new("Model"); plot.Name="Plot"..i; plot:SetAttribute("Owner",0); plot.Parent=hub
  local floor=P(plot,"Floor",Vector3.new(32,0.5,27),CFrame.new(x,0.3,z),Color3.fromRGB(95,148,112),Enum.Material.Grass); W.Label(floor,"AVAILABLE SANCTUARY",Color3.fromRGB(206,255,221))
  for _,dx in {-16,16} do
   for n=0,4 do P(plot,"FencePost",Vector3.new(0.7,4,0.7),CFrame.new(x+dx,2,z-13+n*6.5),Color3.fromRGB(151,106,64),Enum.Material.Wood) end
   for _,y in {1.4,3} do P(plot,"FenceRail",Vector3.new(0.5,0.5,26),CFrame.new(x+dx,y,z),Color3.fromRGB(185,135,81),Enum.Material.Wood) end
  end
  for _,y in {1.4,3} do P(plot,"BackRail",Vector3.new(32,0.5,0.5),CFrame.new(x,y,z+13),Color3.fromRGB(185,135,81),Enum.Material.Wood) end
 end
 local light=game:GetService("Lighting"); light.ClockTime=14; light.Brightness=2.5; light.Ambient=Color3.fromRGB(145,154,184)
 if not light:FindFirstChild("EggBloom") then local b=Instance.new("BloomEffect"); b.Name="EggBloom"; b.Intensity=0.3; b.Size=24; b.Threshold=1.3; b.Parent=light end
 return root
end
function W.Preview(root)
 local old=root:FindFirstChild("Preview"); if old then old:Destroy() end
 local preview=Instance.new("Folder"); preview.Name="Preview"; preview.Parent=root
 for i=1,6 do
  W.Monster(preview,i,Vector3.new(0,0,80+(i-0.5)*180+35))
  for slot=1,3 do
   local e=W.Egg(preview,i,math.min(i,6),Vector3.new(slot%2==0 and -24 or 24,2.8,80+(i-1)*180+45+slot*28))
   W.Label(e.PrimaryPart,C.Rarities[math.min(i,6)].Name,C.Rarities[math.min(i,6)].Color)
  end
  task.wait()
 end
 for i=1,3 do
  local x=-18+(i-1)*18
  local belt=P(preview,"Treadmill",Vector3.new(12,0.8,16),CFrame.new(x,0.5,14),Color3.fromRGB(28,32,49),Enum.Material.Metal)
  for n=1,8 do P(preview,"BeltStripe",Vector3.new(10,0.1,0.25),CFrame.new(x,0.96,6+n*1.8),Color3.fromRGB(79,213,237),Enum.Material.Neon) end
  for _,dx in {-6,6} do P(preview,"Handrail",Vector3.new(0.5,4,16),CFrame.new(x+dx,2,14),Color3.fromRGB(79,92,121),Enum.Material.Metal) end
  W.Label(belt,"TREADMILL",Color3.fromRGB(108,226,255))
 end
 for i,t in C.Trails do local board=P(preview,t.Name.."TrailBoard",Vector3.new(10,6,1),CFrame.new(-22+(i-1)*14,4,60),t.Color); W.Sign(board,t.Name.." TRAIL\n"..t.Multiplier.."x - $"..t.Cost) end
 for _,v in {{"SPEED UPGRADE",-20,Color3.fromRGB(44,158,212)},{"STORAGE UPGRADE",20,Color3.fromRGB(125,89,196)}} do local board=P(preview,v[1],Vector3.new(10,6,1),CFrame.new(v[2],4,-53),v[3]); W.Sign(board,v[1]) end
end
return W
