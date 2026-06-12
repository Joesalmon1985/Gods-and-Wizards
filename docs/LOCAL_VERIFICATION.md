# Local Verification Guide (Windows PowerShell)

Use this on your milestone branch before opening or merging a PR.

**Local Godot executable:** `C:\Tools\Godot\godot.exe.exe`  
(The path `C:\Tools\Godot\godot.exe` is documented elsewhere but may not exist on your machine.)

**Preferred invocation:** `scripts/Invoke-GodotHeadless.ps1` — waits for Godot to exit and propagates the exit code. Direct `& $Godot ...` can leave stale processes or return unreliable exit codes in some shells.

---

## Setup

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$GodotProject = Join-Path $ProjectRoot "godot_game"
$Godot = "C:\Tools\Godot\godot.exe.exe"
$Logs = Join-Path $ProjectRoot "logs"
$InvokeGodot = Join-Path $ProjectRoot "scripts\Invoke-GodotHeadless.ps1"
$GetGodotCount = Join-Path $ProjectRoot "scripts\Get-ProjectGodotProcessCount.ps1"
$StopStaleGodot = Join-Path $ProjectRoot "scripts\Stop-StaleGodotProcesses.ps1"

Set-Location $ProjectRoot
```

**Success:** both checks return `True`.

```powershell
Test-Path $Godot
Test-Path (Join-Path $GodotProject "project.godot")
```

---

## 1. Confirm Git state

```powershell
Set-Location $ProjectRoot

git status --short --branch
git branch --show-current
git log -8 --oneline
git rev-parse HEAD
git rev-parse origin/milestone/macro-product-autonomous-run

git fetch origin
git status --short --branch
```

**Success:**

- Branch is your intended milestone branch (not `main` unless explicitly merging)
- After `git fetch`, local HEAD matches its upstream (no unexpected ahead/behind)
- Working tree is clean or only contains intentional milestone edits

**List untracked / generated (review only):**

```powershell
git status --short
git ls-files --others --exclude-standard
```

**Typical safe-to-ignore untracked:** `*.gd.uid`, `test_m14_result.txt`, `.cursor/plans/`  
**Do not commit:** anything under `logs/`, `.godot/`

---

## 2. Clean only safe generated/untracked files

Review first:

```powershell
Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.gd.uid" -File -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty FullName

if (Test-Path (Join-Path $ProjectRoot "test_m14_result.txt")) {
  Get-Item (Join-Path $ProjectRoot "test_m14_result.txt")
}

if (Test-Path (Join-Path $ProjectRoot ".cursor\plans")) {
  Get-ChildItem (Join-Path $ProjectRoot ".cursor\plans") -File
}
```

Remove only these safe items:

```powershell
Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.gd.uid" -File -ErrorAction SilentlyContinue |
  Remove-Item -Force

Remove-Item -Force (Join-Path $ProjectRoot "test_m14_result.txt") -ErrorAction SilentlyContinue

Remove-Item -Recurse -Force (Join-Path $ProjectRoot ".cursor\plans") -ErrorAction SilentlyContinue
```

Verify (source and `logs/` should remain):

```powershell
git status --short
```

**Success:** no `*.gd.uid`, no `test_m14_result.txt`, no `.cursor/plans/`; source files and `logs/` still present.

---

## 2b. Stale Godot process check and cleanup

**Count project-scoped Godot processes (expect 0 before and after headless runs):**

```powershell
& $GetGodotCount
```

**If count > 0, list and clean (review with `-WhatIf` first):**

```powershell
Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -like "*$GodotProject*" } |
  Select-Object ProcessId, CommandLine

& $StopStaleGodot -WhatIf
& $StopStaleGodot
& $GetGodotCount
```

**Success:** count returns `0` after cleanup. Only processes whose command line references this repo’s `godot_game` path are stopped.

---

## 3. Full Godot test suite

**Preferred — wrapper (waits for completion):**

```powershell
& $InvokeGodot -ArgumentList @("--headless", "--path", $GodotProject, "-s", "res://tests/test_runner.gd")
```

**Fallback — direct Start-Process:**

```powershell
$testProc = Start-Process `
  -FilePath $Godot `
  -ArgumentList @("--headless", "--path", $GodotProject, "-s", "res://tests/test_runner.gd") `
  -Wait -PassThru -NoNewWindow

$testProc.ExitCode
& $GetGodotCount
```

**If new global classes fail to resolve ("Identifier X not declared"):**

```powershell
& $InvokeGodot -ArgumentList @("--headless", "--path", $GodotProject, "--import")
```

Then re-run the test suite.

**Success:**

- Exit code `0`
- Output ends with: `Ran 50 modules, ... assertions` and `Failed: 0`
- CanvasItem RID leak warnings at exit are known and acceptable if tests passed

---

## 4. Generate fresh CSVs under `logs/`

```powershell
New-Item -ItemType Directory -Force -Path $Logs | Out-Null

$PlaythroughCsv = Join-Path $Logs "playthrough_seed_42.csv"
$BatchCsv       = Join-Path $Logs "batch_balance.csv"
$DuelCsv        = Join-Path $Logs "duel_seed_123.csv"
$PressureCsv    = Join-Path $Logs "underworld_pressure.csv"
```

**Macro playthrough (seed 42):**

```powershell
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_headless_bot_game.gd",
  "--", "--seed", "42", "--max-turns", "300", "--output", $PlaythroughCsv
)
```

**100-game batch (seeds 42–141):**

```powershell
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_batch_sim.gd",
  "--", "--games", "100", "--seed", "42", "--max-turns", "300", "--output", $BatchCsv
)
```

**Micro duel (seed 123):**

```powershell
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_headless_duel.gd",
  "--", "--seed", "123", "--output", $DuelCsv
)
```

**Underworld pressure (20 games, seeds 42–61):**

```powershell
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_underworld_pressure.gd",
  "--", "--games", "20", "--seed", "42", "--max-turns", "120", "--output", $PressureCsv
)
```

**Macro training telemetry (seed 42, after M27):**

```powershell
$MacroTrainingCsv = Join-Path $Logs "macro_training_seed_42.csv"
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_macro_training_export.gd",
  "--", "--seed", "42", "--max-steps", "50", "--output", $MacroTrainingCsv
)
```

**Micro combat telemetry (seed 123, after M29):**

```powershell
$MicroCombatCsv = Join-Path $Logs "micro_combat_seed_123.csv"
& $InvokeGodot -ArgumentList @(
  "--headless", "--path", $GodotProject,
  "-s", "res://run_modes/run_micro_combat_export.gd",
  "--", "--seed", "123", "--output", $MicroCombatCsv
)
```

After each smoke batch:

```powershell
& $GetGodotCount   # expect 0
```

**Success:**

- Each command exit code `0`
- Godot prints paths like `Playthrough CSV written to: ...`
- All four files exist and are non-empty:

```powershell
@($PlaythroughCsv, $BatchCsv, $DuelCsv, $PressureCsv) | ForEach-Object {
  [PSCustomObject]@{ Path = $_; Exists = (Test-Path $_); Bytes = (Get-Item $_ -ErrorAction SilentlyContinue).Length }
} | Format-Table -AutoSize
```

---

## 5. Run G training/evaluation (headless)

```powershell
& (Join-Path $ProjectRoot "scripts\Invoke-MacroBaselineEval.ps1")
& (Join-Path $ProjectRoot "scripts\Invoke-MicroBaselineEval.ps1")
& (Join-Path $ProjectRoot "scripts\Invoke-MacroNeuralTrain.ps1")
& (Join-Path $ProjectRoot "scripts\Invoke-MicroNeuralTrain.ps1")
```

Outputs under `logs/` (gitignored): `macro_baseline_eval.csv`, `micro_baseline_eval.csv`, `macro_neural_train_metrics.csv`, `micro_neural_train_metrics.csv`.

**Success:** each script exit code `0`; CSV files non-empty.

---

## 6. Inspect CSVs in PowerShell

### Row counts

```powershell
function Get-CsvLineCount([string]$Path) {
  if (-not (Test-Path $Path)) { return 0 }
  (Get-Content $Path | Measure-Object -Line).Lines
}

[PSCustomObject]@{
  playthrough_lines = Get-CsvLineCount $PlaythroughCsv
  batch_lines       = Get-CsvLineCount $BatchCsv
  duel_lines        = Get-CsvLineCount $DuelCsv
  pressure_lines    = Get-CsvLineCount $PressureCsv
}
```

**Expected (approximate):**

| File | Lines |
|------|-------|
| Playthrough | thousands (e.g. ~3,000+ with header) |
| Batch | **101** (header + 100 games) |
| Duel | small (summary + round rows) |
| Pressure | **21** (header + 20 games) |

### Macro playthrough — `city_count` / `road_count` replay

```powershell
$pt = Import-Csv $PlaythroughCsv

"First data row:"
$pt | Select-Object -First 1 turn_number, action_type, event_type, city_count, road_count, event_summary

"Last data row:"
$pt | Select-Object -Last 1 turn_number, action_type, event_type, city_count, road_count, event_summary

"First road_built row:"
$pt | Where-Object { $_.action_type -eq "build_road" } | Select-Object -First 1 turn_number, city_count, road_count, action_details

"Final road_count vs max seen:"
[PSCustomObject]@{
  final_row_road_count = ($pt | Select-Object -Last 1).road_count
  max_road_count_seen  = ($pt.road_count | ForEach-Object { [int]$_ } | Measure-Object -Maximum).Maximum
}
```

**Success:**

- `city_count` and `road_count` change over time
- On first `build_road` row, `road_count` is less than final max (replay fix)
- `production_check` rows have readable summaries (below)

### First 10 `production_check` summaries

```powershell
$pt |
  Where-Object { $_.event_type -eq "production_check" -and $_.event_summary -ne "" } |
  Select-Object -First 10 turn_number, round_number, event_summary
```

**Success:** lines like `Production check: Wood on hex 0,0 — roll 4, produced.` or `... no production.`

### Batch `outcome_reason` distribution

```powershell
$batch = Import-Csv $BatchCsv
$batch | Group-Object outcome_reason | Sort-Object Name |
  Select-Object Name, Count | Format-Table -AutoSize

"Sample VP finishes:"
$batch | Where-Object { $_.outcome_reason -eq "victory_points" } | Select-Object -First 3 seed, turns_played, winner_id, vp_p0, vp_p1, vp_p2, vp_p3

"Sample turn-limit stalls:"
$batch | Where-Object { $_.outcome_reason -eq "turn_limit" } | Select-Object -First 3 seed, turns_played, winner_id
```

**Success:**

- ~100 data rows
- Mix of `victory_points` and `turn_limit` (turn-limit stalls are a known balance issue, not a PR blocker)
- Re-running with same args produces the same CSV

### Duel summary

```powershell
Get-Content $DuelCsv -TotalCount 6
```

**Success:**

- Line 1: header (`seed,winner_id,attacker_id,...`)
- Line 2: one summary row with `winner_id`, `rounds_played`, final health
- Blank line, then round detail header and round rows

### Underworld breach / spread telemetry

```powershell
$pressure = Import-Csv $PressureCsv
$pressure | Select-Object -First 5 seed, turns_played, breach_count, peak_demon_count, spread_event_count, outcome_reason

[PSCustomObject]@{
  games             = $pressure.Count
  breach_outcomes   = ($pressure | Where-Object outcome_reason -eq "breach").Count
  avg_peak_demons   = [math]::Round(($pressure.peak_demon_count | ForEach-Object { [double]$_ } | Measure-Object -Average).Average, 1)
  avg_spread_events = [math]::Round(($pressure.spread_event_count | ForEach-Object { [double]$_ } | Measure-Object -Average).Average, 1)
  max_breach_count  = ($pressure.breach_count | ForEach-Object { [int]$_ } | Measure-Object -Maximum).Maximum
}
```

**Success:**

- Elevated `peak_demon_count` and `spread_event_count` vs default batch (where demons are often 0)
- Many `outcome_reason = breach`
- Same seed range produces identical CSV on re-run

---

## 6. Launch GUI / visual modes

**3D wizard-world (main scene):**

```powershell
& $Godot --path $GodotProject
```

**2D strategic read-only mode:**

```powershell
& $Godot --path $GodotProject res://run_modes/strategic_2d_mode.tscn
```

**Start-Process variant (keeps console free):**

```powershell
Start-Process -FilePath $Godot -ArgumentList @("--path", $GodotProject)
Start-Process -FilePath $Godot -ArgumentList @("--path", $GodotProject, "res://run_modes/strategic_2d_mode.tscn")
```

| Mode | Controls | Success |
|------|----------|---------|
| 3D wizard-world | Enter/N = advance turn; Space = autoplay | Board renders; scoreboard updates; no crash |
| 2D strategic | Enter/N = advance turn | Hex board visible; header shows breaches/demons; **no** click-to-build (M22 deferred) |

---

## 7. Go / no-go checklist before PR

| Check | Go | No-go |
|-------|----|-------|
| Branch | Intended milestone branch | Unintended branch or dirty WIP |
| Remote sync | Matches origin after fetch | Unexpected unpushed/pulled divergence |
| Working tree | Clean or intentional edits only | Staged `logs/`, `.godot/`, or accidental source changes |
| Orphan Godot | `Get-ProjectGodotProcessCount` = 0 after runs | Stale Godot processes remain |
| Tests | All modules, **0** failures | Any failure |
| Playthrough CSV | Generated; production summaries readable; road_count replays | Empty, missing summaries, flat road_count |
| Batch CSV | 100 games + header | Wrong row count or empty |
| Duel CSV | Summary + round rows | Script/parse errors |
| Pressure CSV | Breach/spread telemetry present | Empty or all zeros |
| Visual smoke | 3D + 2D launch without errors | Crashes |
| Merge policy | Open PR for human review | Do not merge to `main` without review |

**Suggested PR:**

- **From:** `milestone/macro-product-autonomous-run`
- **Into:** `main`
- **Title:** Macro product autonomous run — CSV telemetry, duel runner, underworld pressure, dev catalog, 2D lens

---

## Quick one-block smoke (after tests pass)

```powershell
Set-Location $ProjectRoot
New-Item -ItemType Directory -Force -Path $Logs | Out-Null

& $InvokeGodot -ArgumentList @("--headless", "--path", $GodotProject, "-s", "res://run_modes/run_headless_bot_game.gd", "--", "--seed", "42", "--max-turns", "300", "--output", (Join-Path $Logs "playthrough_seed_42.csv"))
& $InvokeGodot -ArgumentList @("--headless", "--path", $GodotProject, "-s", "res://run_modes/run_batch_sim.gd", "--", "--games", "100", "--seed", "42", "--max-turns", "300", "--output", (Join-Path $Logs "batch_balance.csv"))
& $InvokeGodot -ArgumentList @("--headless", "--path", $GodotProject, "-s", "res://run_modes/run_headless_duel.gd", "--", "--seed", "123", "--output", (Join-Path $Logs "duel_seed_123.csv"))
& $InvokeGodot -ArgumentList @("--headless", "--path", $GodotProject, "-s", "res://run_modes/run_underworld_pressure.gd", "--", "--games", "20", "--seed", "42", "--max-turns", "120", "--output", (Join-Path $Logs "underworld_pressure.csv"))

& $GetGodotCount
Get-ChildItem $Logs -Filter "*.csv" | Sort-Object LastWriteTime -Descending | Select-Object Name, Length, LastWriteTime
```

---

## Related docs

- [TESTING_AND_GIT_WORKFLOW.md](TESTING_AND_GIT_WORKFLOW.md)
- [run_modes.md](run_modes.md)
- [PROJECT_STATUS.md](PROJECT_STATUS.md)
