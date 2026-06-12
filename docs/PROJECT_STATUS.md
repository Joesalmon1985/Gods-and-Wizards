# Project Status — Gods and Wizards

**Last updated:** 2026-06-12 (Run G game completion + training suites)  
**Purpose:** Human-readable handoff for reviewers and Cursor agents before the next milestone.

**Design docs (authoritative intent):** [RULEBOOK.md](RULEBOOK.md), [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md), [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md).  
**Run G:** [RUN_G_PLAN.md](RUN_G_PLAN.md), [TRAINING_READINESS_GATE.md](TRAINING_READINESS_GATE.md) — gate `GO_FOR_TRAINING`.

---

## Git snapshot

Run locally for current values:

```powershell
git status --short --branch
git log -1 --oneline
```

| Item | How to check |
|---|---|
| Current branch | `git branch --show-current` |
| Latest commit | `git log -1 --oneline` |
| Remote tracking | `git status --short --branch` |
| Remote URL | `git remote get-url origin` |

Do not treat stale branch names or SHAs in this doc as authoritative.

---

## Test status

### Command

```powershell
& "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\scripts\Invoke-GodotHeadless.ps1" -ArgumentList @("--headless", "--path", "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game", "-s", "res://tests/test_runner.gd")
```

### Result (verified 2026-06-12, Run G)

| Metric | Value |
|---|---|
| Exit code | **0** |
| Modules run | **104** |
| Assertions | **141,726** |
| Passed | **All** |
| Failed | **0** |
| Stale Godot processes after run | Check locally with `Get-Process -Name "Godot*"` |

Optional suite filter: `--suite=architecture`, `--suite=integration`, etc. (see `tests/test_registry.gd`).

**Note:** First run after adding new scripts may require `--import` so Godot registers global classes. Full suite typically takes ~80–100 seconds.

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
| Headless micro-duel | `run_headless_duel.gd` | One seeded combat encounter → CSV |
| Underworld pressure telemetry | `run_underworld_pressure.gd` | N pressure-scenario games → CSV |
| 2D strategic (read-only) | `strategic_2d_mode.tscn` | Read-only 2D hex board; bot advance |

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

## Product mode defaults

| Horizon | Default | Notes |
|---|---|---|
| **Long-term product** | 3D wizard spectator/RPG | Human experiences game as god avatar |
| **Near-term development** | 2D strategic playable/debug | Macro rules stabilisation first |
| **Developer-only** | Headless CSV, batch sim, telemetry export | Not player-facing |

---

## Design decisions recorded (Run C — docs only)

- Macro hero/demon = **instant contact resolution** (not `SpellCombatSession`).
- Tactical combat = **`SpellCombatSession`** only; isolated from macro loop.
- Legacy **`CombatResolver` card duel** = debug/reference.
- Multi-step macro turns with **`END_TURN`**; step-level legal masks for RL.
- VP win at **21**; collective breach loss at **10** (`GameConstants.BREACH_LIMIT`).
- No **ports**; offer/accept trading is intended (current 1:1 trade is provisional).
- Neural training export is **partial/prototyping**; dataset v2 required before serious RL.

See [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md) for full decision log.

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
| Breach loss | `BreachEndCondition`, `GameConstants.BREACH_LIMIT` (**10**) |
| Victory points win | `VictoryPointsEndCondition`, `GameConstants.VP_TO_WIN` |
| Development build (stub) | Single stub card path, not full drafting |
| Headless card combat | `CombatResolver` card duel — **legacy/debug**; not macro resolution |
| Spell combat (tactical) | `SpellCombatSession` — canonical tactical model; isolated sim/replay/export |
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
| Development cards | Catalog foundation (watchtower, granary, shrine); no drafting; action space still one BUILD_DEVELOPMENT per vertex |
| Embodied wizard | Placeholder scripts only; wizard marker in 3D mode does not affect `GameState` |
| Combat UI | `ui/combat/combat_presenter.gd` — presentation layer, not wired into main run mode |
| Integration bridge | `encounter_bridge.gd`, `sync_controller.gd` — contract exists; not full embodied loop |
| Drafting human pick UI | Auto-pick skeleton at round end; no `DRAFT_PICK` action for humans yet |
| M22 hex click-to-build | Keyboard `strategic_play_2d_mode` works; no hex picking |
| Neural training data | v1 telemetry export only — **not production RL-ready** |
| Human player UI | M14 session API complete; no clickable 2D/3D action selection yet |
| Balance config wiring | JSON skeleton loaded; gameplay constants not yet driven from config |
| Headless micro-duel runner | `run_headless_duel.gd`, `DuelLogExporter`, `TestHeadlessDuelRunner` |
| Underworld pressure runner | `run_underworld_pressure.gd`, `UnderworldPressureRunner` |
| Playthrough CSV telemetry | Replay `road_count`; `production_check` summaries |

### Planned / not yet implemented

| System | Notes |
|---|---|
| **M22 2D human click-to-build** | Wire M14 to hex/click selection — **next** |
| **M26 divine instruction offers** | Future headless bridge — documented only |
| Dataset v2 / board featurizer | Before serious macro RL |
| Drafting human pick + full card library | Skeleton only in Run D |
| Age-weighted infection reshuffle | Deferred |
| Dataset v2 / board featurizer | Before serious macro RL |
| Full drafting (Seven Wonders-style) | Explicitly out of scope until requested |
| Full development card system | Beyond current stub |
| Full embodied encounter gameplay | 3D combat loop not connected to main scene |
| Neural network / training in Godot | Not started — export telemetry only |
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
└── tests/          100 test modules (+ rule contract suite), architecture scanner, test runner
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

1. **Human play is keyboard-only** — `strategic_play_2d_mode` lists legal actions; no hex click-to-build yet.
2. **Wizard marker is cosmetic** — WASD movement does not represent hero position in `GameState`.
3. **Playthrough CSV `road_count`** — column uses final session state on all rows; `city_count` is replayed per step.
4. **`production_check` rows** — empty `event_summary` in playthrough CSV.
5. **Batch sim turn-limit stalls** — ~51/100 games hit 300-turn cap without VP finish (seeds 42–141).
6. **`origin/main` lags milestone branch** — merge via PR after human review.
7. **Test suite runtime** — ~50–80s; architecture scan dominates assertion count.
8. **Old git stash** — `stash@{0}` WIP M14 shell may be redundant; review before popping.

---

## Next recommended task

1. **Human review** — commit Run C documentation; open PR if needed (`git status --short --branch` for current branch).
2. **Human review** — Run D complete; open PR from milestone branch.
3. **Next implementation:** M22 hex click-to-build or dataset v2 — see [NEXT_MILESTONES.md](NEXT_MILESTONES.md).

**Current branch / commit:** run `git branch --show-current` and `git log -1 --oneline`.

---

## Quick links

- [Rulebook (design intent)](RULEBOOK.md)
- [Turn timing and phase model](TURN_TIMING_AND_PHASE_MODEL.md)
- [Rules engine audit](RULES_ENGINE_AUDIT.md)
- [Rules gap / decision log](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md)
- [Autonomous session log](AUTONOMOUS_SESSION_LOG.md)
- [Run modes](run_modes.md)
- [Next milestones](NEXT_MILESTONES.md)
- [Testing and Git workflow](TESTING_AND_GIT_WORKFLOW.md)
- GitHub: https://github.com/Joesalmon1985/Gods-and-Wizards
