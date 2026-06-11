# Integration Plan for gods-and-wizards

This document describes how the workspace combines two donor Godot projects into one coherent hybrid game.

## Workspace layout

```
gods-and-wizards/
├── godot_game/                     Authoritative Godot project
├── donor_projects/
│   ├── board_game_M13/             Headless board-game prototype (reference)
│   └── KF_wizard_game/             Wizard/combat prototype (reference)
└── docs/
    └── integration_plan.md         This file
```

## Game identity

Strategic board game (source of truth) plus optional embodied wizard layer.

- Hexes produce resources; corners are **BoardNodes**; edges connect nodes.
- Roads on edges; cities on nodes; heroes and demons on nodes.
- Demon spread is node-to-node along edges.
- Embodied wizard gameplay is presentation/interaction only.

## Architecture

| Folder | Role |
|---|---|
| `godot_game/core/` | Headless deterministic rules engine |
| `godot_game/embodied/` | 3D wizard/hero gameplay (optional) |
| `godot_game/integration/` | Board state ↔ embodied scene bridge |
| `godot_game/ui/` | Debug, board, and combat presentation |
| `godot_game/tests/` | Headless tests |

Rules mutate `GameState` and return `GameEvent`s. Same seed plus same action sequence must produce the same result.

## Donor audit summary

**board_game_M13:** GameState, hex board, production, actions, legal masks, bots, events, tests — migrate selectively into `godot_game/core/`.

**KF_wizard_game:** Card combat rules, deck runtime, combat profiles, 3D movement — extract combat into core; defer scene orchestration to embodied/ui.

## Milestones

| # | Goal |
|---|---|
| M0 | Workspace restructure |
| M1 | Baseline headless engine in `godot_game/` |
| M2 | BoardNode + EdgeCoord topology |
| M3 | Roads on edges |
| M4 | Heroes on nodes, MOVE_HERO |
| M5 | Demon spread + breach loss |
| M6 | Development card stub |
| M7 | Headless card combat contract |
| M8 | Integration bridge |
| M9 | Embodied wizard layer (presentation) |

## Test command

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://tests/test_runner.gd
```

See [run_modes.md](run_modes.md) for headless CSV simulation and 3D wizard-world mode.
