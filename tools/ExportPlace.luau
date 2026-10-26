-- Run through Studio MCP in Edit mode. Returns XML; the MCP caller saves it locally.
-- Exports this game's owned hierarchy only. Dynamic runtime objects are regenerated on Play.
assert(not game:GetService("RunService"):IsRunning(),"Stop Play before export")
local roots={workspace.MonsterEggEscape,game.ReplicatedStorage.MonsterEgg,game.ServerScriptService.MonsterEggServer,game.StarterPlayer.StarterPlayerScripts.MonsterEggClient}
local ids={}; local nextId=0
local function identify(i)
 nextId+=1; ids[i]="RBX"..nextId
 for _,child in i:GetChildren() do identify(child) end
end
for _,i in roots do identify(i) end
local function escape(s)
 return tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub('"',"&quot;")
end
local out={'<roblox version="4">'}
local function add(s) table.insert(out,s) end
local function element(tag,name,value) add('<'..tag..' name="'..name..'">'..value..'</'..tag..'>') end
local function serialize(name,value)
 local t=typeof(value)
 if t=="string" then element(name=="Source" and "ProtectedString" or "string",name,escape(value))
 elseif t=="boolean" then element("bool",name,tostring(value))
 elseif t=="number" then element("float",name,tostring(value))
 elseif t=="EnumItem" then element("token",name,tostring(value.Value))
 elseif t=="Vector3" then element("Vector3",name,string.format('<X>%.9g</X><Y>%.9g</Y><Z>%.9g</Z>',value.X,value.Y,value.Z))
 elseif t=="Vector2" then element("Vector2",name,string.format('<X>%.9g</X><Y>%.9g</Y>',value.X,value.Y))
 elseif t=="Color3" then element("Color3",name,string.format('<R>%.9g</R><G>%.9g</G><B>%.9g</B>',value.R,value.G,value.B))
 elseif t=="CFrame" then
  local v={value:GetComponents()}; local tags={"X","Y","Z","R00","R01","R02","R10","R11","R12","R20","R21","R22"}; local b={}
  for n,tag in tags do table.insert(b,'<'..tag..'>'..string.format('%.9g',v[n])..'</'..tag..'>') end
  element("CoordinateFrame",name,table.concat(b))
 elseif t=="UDim2" then element("UDim2",name,string.format('<XS>%.9g</XS><XO>%d</XO><YS>%.9g</YS><YO>%d</YO>',value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset))
 elseif t=="UDim" then element("UDim",name,string.format('<S>%.9g</S><O>%d</O>',value.Scale,value.Offset))
 elseif t=="NumberRange" then element("NumberRange",name,value.Min..' '..value.Max)
 elseif t=="NumberSequence" then
  local b={}; for _,key in value.Keypoints do table.insert(b,key.Time..' '..key.Value..' '..key.Envelope) end; element("NumberSequence",name,table.concat(b,' ')..' ')
 elseif t=="ColorSequence" then
  local b={}; for _,key in value.Keypoints do table.insert(b,key.Time..' '..key.Value.R..' '..key.Value.G..' '..key.Value.B..' 0') end; element("ColorSequence",name,table.concat(b,' ')..' ')
 elseif t=="Instance" then element("Ref",name,ids[value] or "null") end
end
local groups={
 {"BasePart",{"Anchored","CanCollide","CanTouch","CanQuery","CastShadow","Transparency","Reflectance","Material","Color","Size","CFrame","TopSurface","BottomSurface"}},
 {"Part",{"Shape"}}, {"SpawnLocation",{"Enabled","Neutral","Duration","AllowTeamChangeOnTouch"}},
 {"Model",{"PrimaryPart"}}, {"LuaSourceContainer",{"Source"}},
 {"BillboardGui",{"Size","StudsOffset","StudsOffsetWorldSpace","AlwaysOnTop","MaxDistance","LightInfluence"}},
 {"SurfaceGui",{"Face","CanvasSize","LightInfluence"}},
 {"GuiObject",{"Size","Position","BackgroundColor3","BackgroundTransparency","BorderSizePixel"}},
 {"TextLabel",{"Text","TextColor3","TextStrokeTransparency","Font","TextScaled","TextWrapped"}},
 {"UICorner",{"CornerRadius"}}, {"UIStroke",{"Color","Thickness","Transparency"}},
 {"UIPadding",{"PaddingLeft","PaddingRight","PaddingTop","PaddingBottom"}},
 {"PointLight",{"Brightness","Color","Range","Enabled"}},
 {"ParticleEmitter",{"Texture","Enabled","Color","LightEmission","Rate","Lifetime","Speed","Size","Transparency"}},
 {"BloomEffect",{"Intensity","Size","Threshold","Enabled"}},
}
local function instance(i)
 add('<Item class="'..i.ClassName..'" referent="'..ids[i]..'"><Properties>')
 serialize("Name",i.Name)
 for _,group in groups do
  if i:IsA(group[1]) then
   for _,name in group[2] do
    local ok,value=pcall(function() return i[name] end)
    if ok and value~=nil then serialize(name=="Shape" and "shape" or name,value) end
   end
  end
 end
 add('</Properties>')
 for _,child in i:GetChildren() do instance(child) end
 add('</Item>')
end
local function service(class,name,children)
 add('<Item class="'..class..'"><Properties><string name="Name">'..name..'</string></Properties>')
 for _,child in children do instance(child) end
 add('</Item>')
end
service("Workspace","Workspace",{roots[1]})
service("ReplicatedStorage","ReplicatedStorage",{roots[2]})
service("ServerScriptService","ServerScriptService",{roots[3]})
add('<Item class="StarterPlayer"><Properties><string name="Name">StarterPlayer</string></Properties>')
service("StarterPlayerScripts","StarterPlayerScripts",{roots[4]}); add('</Item>')
add('<Item class="Lighting"><Properties><string name="Name">Lighting</string><float name="ClockTime">14</float><float name="Brightness">2.5</float></Properties></Item>')
add('</roblox>')
_G.MonsterEggPlaceXML=table.concat(out,'\n')
return {bytes=#_G.MonsterEggPlaceXML,instances=nextId,read="_G.MonsterEggPlaceXML"}
