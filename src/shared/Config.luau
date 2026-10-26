local Config = {}
Config.Version = 1
Config.SafeZ = 80
Config.ZoneLength = 180
Config.Zones = {
 {Name="Forest", Color=Color3.fromRGB(62,185,103), Monster="Bramble Beast", Speed=19, Income=3},
 {Name="Desert", Color=Color3.fromRGB(244,185,77), Monster="Dune Scorpion", Speed=23, Income=8},
 {Name="Ice", Color=Color3.fromRGB(99,211,250), Monster="Frost Yeti", Speed=27, Income=18},
 {Name="Lava", Color=Color3.fromRGB(255,94,52), Monster="Magma Drake", Speed=31, Income=40},
 {Name="Toxic", Color=Color3.fromRGB(162,239,55), Monster="Venom Crawler", Speed=35, Income=85},
 {Name="Shadow", Color=Color3.fromRGB(155,91,245), Monster="Void Reaper", Speed=39, Income=180},
}
Config.Rarities = {
 {Name="Common", Color=Color3.fromRGB(229,241,247), Weight=48, Multiplier=1},
 {Name="Uncommon", Color=Color3.fromRGB(94,242,141), Weight=27, Multiplier=2},
 {Name="Rare", Color=Color3.fromRGB(74,170,255), Weight=15, Multiplier=4},
 {Name="Epic", Color=Color3.fromRGB(195,102,255), Weight=7, Multiplier=8},
 {Name="Legendary", Color=Color3.fromRGB(255,193,49), Weight=2.5, Multiplier=18},
 {Name="Divine", Color=Color3.fromRGB(255,113,194), Weight=0.5, Multiplier=45},
}
Config.Trails = {
 {Name="Mint", Cost=300, Multiplier=1.15, Color=Color3.fromRGB(87,255,184)},
 {Name="Prism", Cost=2500, Multiplier=1.35, Color=Color3.fromRGB(93,184,255)},
 {Name="Solar", Cost=15000, Multiplier=1.65, Color=Color3.fromRGB(255,195,68)},
 {Name="Void", Cost=80000, Multiplier=2, Color=Color3.fromRGB(194,112,255)},
}
return Config
