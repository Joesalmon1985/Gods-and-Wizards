# Run G — Game Completion Gate + Training Suites

**Branch:** `milestone/run-g-game-completion-training-suites`  
**Purpose:** Two-part gated run — Part 1 completes macro/micro games; Part 2 builds NN training suites if the gate passes.

## Milestones

| ID | Name | Part |
|---|---|---|
| G0 | Pre-flight baseline | Setup |
| G1 | Macro economic game completion audit | 1 |
| G2 | Development-card economy completion audit | 1 |
| G3 | Micro SpellCombatSession completion audit | 1 |
| G4 | Training-readiness gate | 1 |
| G5 | Macro training environment contract | 2 |
| G6 | Micro spell-combat training environment contract | 2 |
| G7 | Donor training code review | 2 |
| G8 | Baseline agents and evaluation harness | 2 |
| G9 | Neural training suite design | 2 |
| G10 | Macro neural training suite | 2 |
| G11 | Micro neural training suite | 2 |
| G12 | Training data/export schema upgrade | 2 |
| G13 | Training run scripts and local workflow | 2 |
| G14 | Documentation and final handoff | 2 |

## Gate policy

Part 2 (G5+) requires `GO_FOR_TRAINING` or `GO_FOR_BASELINES_ONLY` from [`TRAINING_READINESS_GATE.md`](TRAINING_READINESS_GATE.md).  
G10–G11 require `GO_FOR_TRAINING`.

## Hard stops

Macro rule failures, incomplete card economy, non-deterministic micro combat, unreliable legal masks, UI-dependent training, Godot pile-ups, unstaged generated artifacts.

## Verification

```powershell
& "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\scripts\Invoke-GodotHeadless.ps1" -ArgumentList @("--headless", "--path", "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game", "-s", "res://tests/test_runner.gd")
```

See milestone deliverables in Run G session log [`AUTONOMOUS_SESSION_LOG.md`](AUTONOMOUS_SESSION_LOG.md).
