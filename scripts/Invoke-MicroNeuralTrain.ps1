$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GodotProject = Join-Path $ProjectRoot "godot_game"
$InvokeGodot = Join-Path $ProjectRoot "scripts\Invoke-GodotHeadless.ps1"
$Logs = Join-Path $ProjectRoot "logs"
New-Item -ItemType Directory -Force $Logs | Out-Null
$Out = Join-Path $Logs "micro_neural_train_metrics.csv"
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_micro_neural_train.gd",
  "--", "--seed", "42", "--output", $Out
)
exit $LASTEXITCODE
