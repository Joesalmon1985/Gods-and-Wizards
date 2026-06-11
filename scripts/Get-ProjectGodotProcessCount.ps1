# Count Godot processes whose command line references this repo's godot_game project.
param(
    [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$GodotProject = Join-Path $ProjectRoot "godot_game"
$normalized = $GodotProject.Replace("\", "/")

$processes = Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue |
    Where-Object {
        $cmd = $_.CommandLine
        if ($null -eq $cmd) { return $false }
        return ($cmd -like "*$GodotProject*") -or ($cmd -like "*$normalized*")
    }

return @($processes).Count
