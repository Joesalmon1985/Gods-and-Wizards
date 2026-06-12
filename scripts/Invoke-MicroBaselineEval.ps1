$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotProject = Join-Path $ProjectRoot "godot_game"
$InvokeGodot = Join-Path $ProjectRoot "scripts\Invoke-GodotHeadless.ps1"
$Logs = Join-Path $ProjectRoot "logs"
New-Item -ItemType Directory -Force $Logs | Out-Null
$Out = Join-Path $Logs "micro_baseline_eval.csv"
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_micro_baseline_eval.gd",
  "--", "--seed", "42", "--episodes", "4", "--output", $Out
)
exit $LASTEXITCODE
