param([string]$OutputPath = "build/Install.luau")
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$sources = @(
    @{ Path='src/shared/Config.luau'; Service='ReplicatedStorage'; Folder='MonsterEgg'; Name='Config'; Class='ModuleScript' },
    @{ Path='src/shared/World.luau'; Service='ReplicatedStorage'; Folder='MonsterEgg'; Name='World'; Class='ModuleScript' },
    @{ Path='src/server/init.server.luau'; Service='ServerScriptService'; Folder=''; Name='MonsterEggServer'; Class='Script' },
    @{ Path='src/client/init.client.luau'; Service='StarterPlayer'; Folder='StarterPlayerScripts'; Name='MonsterEggClient'; Class='LocalScript' }
)
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('-- Generated from src. Run in Studio Edit mode only.')
$lines.Add('assert(not game:GetService("RunService"):IsRunning(), "Stop Play before installing")')
$lines.Add('local function install(service,folder,name,class,source)')
$lines.Add(' local parent=game:GetService(service)')
$lines.Add(' if folder~="" then local f=parent:FindFirstChild(folder); if not f then f=Instance.new("Folder"); f.Name=folder; f.Parent=parent end; parent=f end')
$lines.Add(' local s=parent:FindFirstChild(name); if s then assert(s.ClassName==class,"Conflicting instance: "..name) else s=Instance.new(class); s.Name=name; s.Parent=parent end; s.Source=source')
$lines.Add('end')
foreach ($entry in $sources) {
    $source = [IO.File]::ReadAllText((Join-Path $projectRoot $entry.Path))
    if ($source.Contains(']========]')) { throw 'Source delimiter conflict' }
    $lines.Add(('install("{0}","{1}","{2}","{3}",[========[{4}]========])' -f $entry.Service,$entry.Folder,$entry.Name,$entry.Class,$source))
}
$lines.Add('local world=require(game.ReplicatedStorage.MonsterEgg.World).Build()')
$lines.Add('for _,v in workspace:GetChildren() do if v:IsA("SpawnLocation") then v.Enabled=false end end')
$lines.Add('workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(130,145,-180),Vector3.new(0,0,180))')
$lines.Add('return {installed=true,objects=#world:GetDescendants()}')
$target = Join-Path $projectRoot $OutputPath
[IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
[IO.File]::WriteAllText($target,($lines -join "`n"),[Text.UTF8Encoding]::new($false))
Write-Output "Installer written: $target"
