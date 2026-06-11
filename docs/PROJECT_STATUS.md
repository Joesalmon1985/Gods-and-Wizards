# Project Status — Gods and Wizards

**Last updated:** 2026-06-11  
**Purpose:** Human-readable handoff for reviewers and Cursor agents before the next milestone.

---

## Git snapshot

| Item | Value |
|---|---|
| Active development branch | `milestone/macro-foundation-autonomous` |
| Latest commit | See `git log -1` on branch (handoff docs commit after this update) |
| Baseline tag | `checkpoint/macro-foundation-baseline` @ `3242cff` |
| `origin/main` | `e1b94c7` — **not merged**; milestone branch ahead |
| Remote | `origin` → https://github.com/Joesalmon1985/Gods-and-Wizards.git |
| Push status | Check `git status --short --branch` after handoff commit |

### Recent commits (newest first)

| Commit | Summary |
|---|---|
| `8cfa8d9` | Docs: finalize autonomous session log |
| `772a1c9` | M18: read-only 2D strategic board mode |
| `d9a8e73` | M17: balance configuration skeleton |
| `8d9c353` | M16: headless batch balance runner |
| `5c3ab90` | M15: training-ready macro environment skeleton |
| `3242cff` | M14: human player turn shell |

Build legality (`BuildRules.can_build_city`, CSV duplicate-log fix) is on this branch from earlier work.

---

## Test status

### Command

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://tests/test_runner.gd
```

### Result (verified 2026-06-11)

| Metric | Value |
|---|---|
| Modules run | **46** |
| Assertions | **62,491** |
| Passed | **62,491** |
| Failed | **0** |

Optional suite filter: `--suite=architecture`, `--suite=integration`, etc. (see `tests/test_registry.gd`).

**Note:** First run after adding new scripts may require `--import` so Godot registers global classes. Full suite typically takes ~50–80 seconds.

---

## Active Godot project

**Path:** `godot_game/project.godot`  
**Name:** GodsAndWizards  
**Main scene (F5):** `res://run_modes/wizard_world_mode.tscn`

Donor folders under `donor_projects/` are **reference-only** (`project.godot.donor.txt`).

---

## Architecture constraints (mandatory)

1. **One authoritative `GameState`** — no second state machine, no donor merges into active paths.
2. **Core is headless** — `godot_game/core/` has no UI, Node3D, or input dependencies.
3. **Presentation submits, does not mutate** — `ui/`, `run_modes/`, `integration/`, and `embodied/` must not directly patch cities, roads, resources, demons, heroes, or scores; use session/rule APIs only.
4. **Donor projects are reference-only** — `donor_projects/`; active project is `godot_game/project.godot` only.
5. **Tests are sacred** — do not weaken, skip, or delete tests to force progress.

---

## Run modes

See [run_modes.md](run_modes.md) for full commands. Summary:

| Mode | Entry | Purpose |
|---|---|---|
| Headless CSV playthrough | `run_headless_bot_game.gd` | One 4-player bot game → event CSV |
| Headless batch sim | `run_batch_sim.gd` | N games → one summary row per game |
| 3D wizard-world (F5) | `wizard_world_mode.tscn` | Read-only 3D + overlay; bot advance |
| 2D strategic (read-only) | `strategic_2d_mode.tscn` | Read-only 2D hex board; bot advance |
| **Headless micro-duel** | **Does not exist** | Proposed M21 — see [NEXT_MILESTONES.md](NEXT_MILESTONES.md) |

### Macro playthrough CSV (repo `logs/` path)

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\playthrough_seed_42.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_headless_bot_game.gd -- --seed 42 --max-turns 300 --output $Out
```

### Batch simulation CSV

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\batch_balance.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_batch_sim.gd -- --games 100 --seed 42 --max-turns 300 --output $Out
```

Do not commit files under `logs/` (gitignored).

---

## Gameplay systems

### Fully implemented and test-covered

| System | Notes |
|---|---|
| Seeded hex board (radius 3) | `BoardGenerator`, topology tests |
| Production | Start-of-turn rolls, `ProductionCheckEvent`, `ResourceGainedEvent` |
| Players, resources, cities | Setup, build rules, scoring hooks |
| Turn order and rounds | `TurnRules`, `GameStartRules` |
| Legal action masks | `LegalActionQuery`, `ActionSpace` |
| Build city / build road | Costs, legality (distance + road network), events; `TestBuildRuleLegality` |
| Human player turn shell (M14) | `start_one_human_three_bots`, `submit_human_action`, `TestHumanPlayerSession` |
| Macro training env (M15) | `MacroTrainingEnv`: reset, observe, legal_actions, step |
| Batch balance runner (M16) | `BatchSimRunner`, `run_batch_sim.gd`, `TestBatchSim` |
| Balance config skeleton (M17) | `BalanceConfig`, `default_balance.json`; rules still use `GameConstants` |
| 2D strategic board read-only (M18) | `StrategicBoardView`, `strategic_2d_mode.tscn`, `TestStrategicBoardView` |
| Hero move | `MoveRules`, occupancy rules |
| Demon spread | Node-to-node along edges |
| Breach loss | `BreachEndCondition`, `GameConstants.BREACH_LIMIT` |
| Victory points win | `VictoryPointsEndCondition`, `GameConstants.VP_TO_WIN` |
| Development build (stub) | Single stub card path, not full drafting |
| Headless card combat | `CombatRules`, `CombatResolver`, deck runtime |
| Encounter resolver bridge | Headless contract for embodied encounters |
| Bot policies | Random + heuristic; `BotTurnResolver` |
| Event log + replay | Deterministic replay at any step |
| Bot game session | 4-player scenario, shared by run modes |
| CSV export | `PlaythroughCsvExporter` with `event_summary` column |
| Reporting helpers | Game state summary, event summarisation, turn report |
| 3D board snapshot | `BoardWorldMapper`, `BoardStateVisualizer` (read-only) |
| Architecture enforcement | Core headless, no UI in core, no parallel GameState |

### Partial / stub / prototype

| System | Notes |
|---|---|
| Development cards | Stub build exists; no drafting, deck, or card library |
| Embodied wizard | Placeholder scripts only; wizard marker in 3D mode does not affect `GameState` |
| Combat UI | `ui/combat/combat_presenter.gd` — presentation layer, not wired into main run mode |
| Integration bridge | `encounter_bridge.gd`, `sync_controller.gd` — contract exists; not full embodied loop |
| Phase model | Overlay shows generic “Player turn”; no fine-grained phase enum in `GameState` |
| Human player UI | M14 session API complete; no clickable 2D/3D action selection yet |
| Balance config wiring | JSON skeleton loaded; gameplay constants not yet driven from config |
| Headless micro-duel runner | Combat core tested; no CLI export runner |

### Planned / not yet implemented

| System | Notes |
|---|---|
| **M21 headless micro-duel smoke runner** | Single `CombatResolver.resolve_encounter`, CSV export |
| **M22 2D human click-to-build** | Wire M14 to 2D view |
| Unified run mode entry (2D primary) | After M22 |
| Drafting (Seven Wonders-style) | Explicitly out of scope until requested |
| Full development card system | Beyond current stub |
| Full embodied encounter gameplay | 3D combat loop not connected to main scene |
| Neural network / training | Not started |
| Art, animation, polish | Placeholder visuals only |
| Multiplayer networking | Not started |

---

## Architecture (current layout)

```
godot_game/
├── core/           Headless authoritative rules engine (GameState, rules, events, bots, combat, export, reporting, config)
├── ui/             Debug overlay, 2D strategic board, combat presenter (presentation only)
├── integration/    Board ↔ world mapping, 3D visualizer, encounter/sync bridges
├── embodied/       Placeholder wizard/encounter scripts (must not mutate GameState directly)
├── run_modes/      Headless CSV/batch runners, wizard-world main scene, 2D strategic mode
├── data/balance/   Balance config JSON (skeleton)
└── tests/          46 test modules, architecture scanner, test runner
```

---

## Milestones completed (summary)

| Range | Delivered |
|---|---|
| M0–M1 | Workspace + headless engine in `godot_game/` |
| M2–M5 | BoardNode/EdgeCoord, roads, heroes, demon spread, breach |
| M6 | Development card stub |
| M7 | Headless card combat |
| M8 | Integration bridge |
| M9 | Embodied placeholders |
| Post-M9 | Single Godot project, run modes, shared `BotGameSession` |
| M14 | Human player turn shell |
| M15 | Macro training environment skeleton |
| M16 | Headless batch balance runner |
| M17 | Balance configuration skeleton |
| M18 | Read-only 2D strategic board |

See [integration_plan.md](integration_plan.md) for the original M0–M9 plan (historical).  
See [AUTONOMOUS_SESSION_LOG.md](AUTONOMOUS_SESSION_LOG.md) for agent resume details.

---

## Known limitations and risks

1. **No human playable layer** — 2D/3D modes advance bots only; human session API has no UI wiring yet.
2. **Wizard marker is cosmetic** — WASD movement does not represent hero position in `GameState`.
3. **Playthrough CSV `road_count`** — column uses final session state on all rows; `city_count` is replayed per step.
4. **`production_check` rows** — empty `event_summary` in playthrough CSV.
5. **Batch sim turn-limit stalls** — ~51/100 games hit 300-turn cap without VP finish (seeds 42–141).
6. **`origin/main` lags milestone branch** — merge via PR after human review.
7. **Test suite runtime** — ~50–80s; architecture scan dominates assertion count.
8. **Old git stash** — `stash@{0}` WIP M14 shell may be redundant; review before popping.

---

## Next recommended task

1. **Human review + PR** — `milestone/macro-foundation-autonomous` → `main`.
2. **M21** — headless micro-duel smoke runner (see [NEXT_MILESTONES.md](NEXT_MILESTONES.md)).
3. **M22** — 2D human click-to-build wired to M14 session API.

**Resume branch:** `milestone/macro-foundation-autonomous`

---

## Quick links

- [Autonomous session log](AUTONOMOUS_SESSION_LOG.md)
- [Run modes](run_modes.md)
- [Next milestones](NEXT_MILESTONES.md)
- [Testing and Git workflow](TESTING_AND_GIT_WORKFLOW.md)
- GitHub: https://github.com/Joesalmon1985/Gods-and-Wizards
