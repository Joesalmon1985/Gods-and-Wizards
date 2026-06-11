# Invoke Godot headless and wait for completion. Propagates process exit code.
param(
    [Parameter(Mandatory = $true)]
    [string[]] $ArgumentList,

    [string] $GodotExe = "C:\Tools\Godot\godot.exe.exe",

    [switch] $NoNewWindow
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot executable not found: $GodotExe"
}

$startParams = @{
    FilePath     = $GodotExe
    ArgumentList = $ArgumentList
    Wait         = $true
    PassThru     = $true
}

if ($NoNewWindow) {
    $startParams["NoNewWindow"] = $true
}

$proc = Start-Process @startParams
Write-Host "Godot exit code: $($proc.ExitCode)"
exit $proc.ExitCode
