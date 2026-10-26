local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local p=Players.LocalPlayer
local gui=Instance.new("ScreenGui"); gui.Name="MonsterEggHUD"; gui.ResetOnSpawn=false; gui.Parent=p:WaitForChild("PlayerGui")
local function label(name,size,pos,text,color)
 local t=Instance.new("TextLabel"); t.Name=name; t.Size=size; t.Position=pos; t.BackgroundColor3=Color3.fromRGB(21,27,46); t.BackgroundTransparency=0.12; t.TextColor3=color or Color3.fromRGB(238,246,255); t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.TextWrapped=true; t.Text=text; t.Parent=gui
 local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,12); c.Parent=t
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,12); pad.PaddingRight=UDim.new(0,12); pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8); pad.Parent=t
 local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(72,99,139); stroke.Transparency=0.4; stroke.Parent=t
 return t
end
label("Title",UDim2.fromScale(0.38,0.055),UDim2.fromScale(0.31,0.018),"MONSTER EGG ESCAPE",Color3.fromRGB(255,214,94))
local money=label("Cash",UDim2.fromScale(0.23,0.09),UDim2.fromScale(0.02,0.12),"$0",Color3.fromRGB(105,255,188))
local stats=label("Stats",UDim2.fromScale(0.23,0.13),UDim2.fromScale(0.02,0.22),"Loading...")
local objective=label("Objective",UDim2.fromScale(0.5,0.08),UDim2.fromScale(0.25,0.83),"Take an egg • escape to the green sanctuary")
local toast=label("Notice",UDim2.fromScale(0.6,0.07),UDim2.fromScale(0.2,0.73),""); toast.Visible=false
local save=label("SaveStatus",UDim2.fromScale(0.4,0.035),UDim2.fromScale(0.3,0.94),""); save.BackgroundTransparency=1
local rage=label("Rage",UDim2.fromScale(0.26,0.08),UDim2.fromScale(0.72,0.12),"",Color3.fromRGB(255,103,117)); rage.Visible=false
local C=require(RS:WaitForChild("MonsterEgg"):WaitForChild("Config"))
local function update()
 local speed=p:GetAttribute("Speed") or 0
 money.Text=string.format("$%s  •  +$%s / sec",math.floor(p:GetAttribute("Cash") or 0),p:GetAttribute("Income") or 0)
 stats.Text=string.format("SPEED LV %d\nTRAINING %.1f / 100\nEGGS %d / %d",speed,p:GetAttribute("Training") or 0,p:GetAttribute("EggCount") or 0,p:GetAttribute("Capacity") or 8)
 local egg=p:GetAttribute("Carrying") or ""; local r=p:GetAttribute("Rage") or 0
 objective.Text=egg~="" and ("CARRYING: "..egg.."\nRUN TO SANCTUARY!") or "Take an egg • escape to the green sanctuary"
 rage.Visible=r>0; rage.Text=r>=4 and "MONSTER RAGE!\nGuardian speed increased" or "GUARDIAN CHASING!"
 save.Text=p:GetAttribute("SaveStatus") or "Connecting progress..."
end
p.AttributeChanged:Connect(update); update()
local serial=0
RS.MonsterEgg:WaitForChild("Notice").OnClientEvent:Connect(function(text)
 serial+=1; local current=serial; toast.Text=text; toast.Visible=true
 task.delay(5,function() if serial==current then toast.Visible=false end end)
end)
local Run=game:GetService("RunService")
Run.RenderStepped:Connect(function()
 local char=p.Character; local r=char and char:FindFirstChild("HumanoidRootPart"); if not r then return end
 local zone=math.clamp(math.floor((r.Position.Z-80)/180)+1,1,6)
 objective.TextColor3=r.Position.Z<=80 and Color3.fromRGB(113,255,202) or C.Zones[zone].Color
end)
