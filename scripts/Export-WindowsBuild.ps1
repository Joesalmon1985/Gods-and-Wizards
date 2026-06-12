# Prototype Windows export wrapper for Gods and Wizards.
param(
    [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string] $PresetName = "Windows Desktop",
    [string] $OutputDir = ""
)

$ErrorActionPreference = "Stop"
$GodotProject = Join-Path $ProjectRoot "godot_game"
if ($OutputDir -eq "") {
    $OutputDir = Join-Path $ProjectRoot "build\windows"
}
$ExportPresets = Join-Path $GodotProject "export_presets.cfg"

if (-not (Test-Path $ExportPresets)) {
    Write-Error "Missing export preset at $ExportPresets. Create it in the Godot editor first."
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$invoke = Join-Path $ProjectRoot "scripts\Invoke-GodotHeadless.ps1"

& $invoke -ArgumentList @(
    "--headless",
    "--path", $GodotProject,
    "--export-release", $PresetName,
    (Join-Path $OutputDir "GodsAndWizards.exe")
)

Write-Host "Export complete: $OutputDir"
