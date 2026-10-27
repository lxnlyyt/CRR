# Builds a place file containing every game script. Open it in Roblox Studio and press Play:
# the server builds the full map, guardians and nests on startup.
param([string]$OutputPath = 'dist/MonsterEggEscape.rbxlx')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'Sources.ps1')

# Build a tree: service -> nested folders/scripts.
$root = [ordered]@{}
function Get-Node($path) {
    $node = $root
    foreach ($part in $path.Split('.')) {
        if (-not $node.Contains($part)) { $node[$part] = [ordered]@{ '__children' = [ordered]@{} } }
        $node = $node[$part]['__children']
    }
    return $node
}
foreach ($entry in $GameSources) {
    $parent = Get-Node $entry.Parent
    $parent[$entry.Name] = [ordered]@{ '__entry' = $entry; '__children' = [ordered]@{} }
}

$serviceClasses = @{ ReplicatedStorage = 'ReplicatedStorage'; ServerScriptService = 'ServerScriptService'; StarterPlayer = 'StarterPlayer'; StarterPlayerScripts = 'StarterPlayerScripts' }
$target = Join-Path $projectRoot $OutputPath
[IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
$settings = [Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [Text.UTF8Encoding]::new($false)
$writer = [Xml.XmlWriter]::Create($target, $settings)

function Write-Item($name, $node, $isService) {
    $entry = $node['__entry']
    $class = if ($entry) { $entry.Class } elseif ($isService -and $serviceClasses.ContainsKey($name)) { $serviceClasses[$name] } else { 'Folder' }
    $writer.WriteStartElement('Item')
    $writer.WriteAttributeString('class', $class)
    $writer.WriteStartElement('Properties')
    $writer.WriteStartElement('string'); $writer.WriteAttributeString('name', 'Name'); $writer.WriteString($name); $writer.WriteEndElement()
    if ($entry) {
        $writer.WriteStartElement('ProtectedString'); $writer.WriteAttributeString('name', 'Source')
        $writer.WriteString([IO.File]::ReadAllText((Join-Path $projectRoot $entry.Path)).Replace("`r`n", "`n"))
        $writer.WriteEndElement()
    }
    $writer.WriteEndElement()
    foreach ($childName in $node['__children'].Keys) {
        Write-Item $childName $node['__children'][$childName] ($class -eq 'StarterPlayer')
    }
    $writer.WriteEndElement()
}

try {
    $writer.WriteStartElement('roblox'); $writer.WriteAttributeString('version', '4')
    # Workspace with streaming off: client labels and monster animation expect the whole map.
    $writer.WriteStartElement('Item'); $writer.WriteAttributeString('class', 'Workspace')
    $writer.WriteStartElement('Properties')
    $writer.WriteStartElement('string'); $writer.WriteAttributeString('name', 'Name'); $writer.WriteString('Workspace'); $writer.WriteEndElement()
    $writer.WriteStartElement('bool'); $writer.WriteAttributeString('name', 'StreamingEnabled'); $writer.WriteString('false'); $writer.WriteEndElement()
    $writer.WriteEndElement(); $writer.WriteEndElement()
    foreach ($service in $root.Keys) {
        Write-Item $service $root[$service] $true
    }
    $writer.WriteEndElement()
} finally { $writer.Dispose() }

$xml = [xml][IO.File]::ReadAllText($target)
$count = $xml.SelectNodes('//ProtectedString').Count
if ($count -ne $GameSources.Count) { throw "Place source validation failed: $count of $($GameSources.Count) scripts" }
Write-Output "Place written and XML validated ($count scripts): $target"
