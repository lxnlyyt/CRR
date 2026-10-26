param([string]$OutputPath = 'dist/MonsterEggEscape.rbxlx')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$target = Join-Path $projectRoot $OutputPath
[IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
$settings = [Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [Text.UTF8Encoding]::new($false)
$writer = [Xml.XmlWriter]::Create($target,$settings)
function Start-Instance([string]$Class,[string]$Name,[string]$SourcePath='') {
    $writer.WriteStartElement('Item')
    $writer.WriteAttributeString('class',$Class)
    $writer.WriteStartElement('Properties')
    $writer.WriteStartElement('string'); $writer.WriteAttributeString('name','Name'); $writer.WriteString($Name); $writer.WriteEndElement()
    if ($SourcePath) {
        $writer.WriteStartElement('ProtectedString'); $writer.WriteAttributeString('name','Source')
        $writer.WriteString([IO.File]::ReadAllText((Join-Path $projectRoot $SourcePath)))
        $writer.WriteEndElement()
    }
    $writer.WriteEndElement()
}
try {
    $writer.WriteStartElement('roblox'); $writer.WriteAttributeString('version','4')
    Start-Instance 'Workspace' 'Workspace'; $writer.WriteEndElement()
    Start-Instance 'ReplicatedStorage' 'ReplicatedStorage'
    Start-Instance 'Folder' 'MonsterEgg'
    Start-Instance 'ModuleScript' 'Config' 'src/shared/Config.luau'; $writer.WriteEndElement()
    Start-Instance 'ModuleScript' 'World' 'src/shared/World.luau'; $writer.WriteEndElement()
    $writer.WriteEndElement(); $writer.WriteEndElement()
    Start-Instance 'ServerScriptService' 'ServerScriptService'
    Start-Instance 'Script' 'MonsterEggServer' 'src/server/init.server.luau'; $writer.WriteEndElement()
    $writer.WriteEndElement()
    Start-Instance 'StarterPlayer' 'StarterPlayer'
    Start-Instance 'StarterPlayerScripts' 'StarterPlayerScripts'
    Start-Instance 'LocalScript' 'MonsterEggClient' 'src/client/init.client.luau'; $writer.WriteEndElement()
    $writer.WriteEndElement(); $writer.WriteEndElement()
    $writer.WriteEndElement()
} finally { $writer.Dispose() }
$xml = [xml][IO.File]::ReadAllText($target)
if ($xml.SelectNodes('//ProtectedString').Count -ne 4) { throw 'Place source validation failed' }
Write-Output "Place written and XML validated: $target"
