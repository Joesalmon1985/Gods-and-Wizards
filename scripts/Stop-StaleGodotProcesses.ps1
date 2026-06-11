# Stop stale Godot processes scoped to this repo's godot_game project path.
param(
    [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,

    [switch] $WhatIf
)

$ErrorActionPreference = "Stop"
$GodotProject = Join-Path $ProjectRoot "godot_game"
$normalized = $GodotProject.Replace("\", "/")

$candidates = Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue |
    Where-Object {
        $cmd = $_.CommandLine
        if ($null -eq $cmd) { return $false }
        return ($cmd -like "*$GodotProject*") -or ($cmd -like "*$normalized*")
    }

if ($null -eq $candidates -or @($candidates).Count -eq 0) {
    Write-Host "No stale Godot processes found for: $GodotProject"
    return
}

foreach ($proc in $candidates) {
    $line = "PID $($proc.ProcessId): $($proc.CommandLine)"
    if ($WhatIf) {
        Write-Host "[WhatIf] Would stop $line"
    }
    else {
        Write-Host "Stopping $line"
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    }
}
