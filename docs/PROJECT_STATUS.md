# Project Status — Gods and Wizards

**Last updated:** 2026-06-11  
**Purpose:** Human-readable handoff for reviewers and Cursor agents before the next milestone.

---

## Git snapshot

| Item | Value |
|---|---|
| Active development branch | `milestone/macro-foundation-autonomous` |
| Baseline tag | `checkpoint/macro-foundation-baseline` |
| Latest M14 commit | `3242cff` — *M14: add human player turn shell to BotGameSession* |
| Build legality | On milestone branch (`BuildRules.can_build_city`, CSV logging fix) |
| Remote | `origin` → https://github.com/Joesalmon1985/Gods-and-Wizards.git |

---

## Test status

### Command

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://tests/test_runner.gd
```

### Result (verified 2026-06-10)

| Metric | Value |
|---|---|
| Modules run | **42** |
| Assertions | **~54,860** |
| Passed | **All** |
| Failed | **0** |
| Warnings | None reported by the test runner (Godot engine startup only) |

Optional suite filter: `--suite=architecture`, `--suite=integration`, etc. (see `tests/test_registry.gd`).

**Note:** First run after adding new scripts may require `--import` so Godot registers global classes. Full suite typically takes ~50–80 seconds.

---

## Active Godot project

**Path:** `godot_game/project.godot`  
**Name:** GodsAndWizards  
**Main scene (F5):** `res://run_modes/wizard_world_mode.tscn`

Donor folders under `donor_projects/` are **reference-only** (`project.godot.donor.txt`).

---

## Run modes

### 1. Headless CSV bot simulation

- **Script:** `godot_game/run_modes/run_headless_bot_game.gd`
- **Purpose:** Deterministic 4-player bot game; exports CSV playthrough log.
- **Shared session:** `BotGameSession` / `GameState`
- **Docs:** [run_modes.md](run_modes.md)

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://run_modes/run_headless_bot_game.gd -- --seed 42 --max-turns 200
```

### 2. 3D wizard-world mode (default F5)

- **Scene:** `godot_game/run_modes/wizard_world_mode.tscn`
- **Purpose:** Read-only 3D board visualisation + human-readable overlay; advances bots via `BotGameSession`.
- **Reporting:** `core/reporting/` (`GameStateSummary`, `EventSummary`, `TurnReport`)
- **Controls:** Enter/N advance turn; Space autoplay; +/- speed; R reset seed; H help; WASD wizard marker (presentation only)
- **Docs:** [run_modes.md](run_modes.md)

### 3. Legacy debug overlay

- **Scene:** `godot_game/ui/debug/debug_game_overlay.tscn`
- **Purpose:** Event-log replay and CSV export for development/debugging.
- **Not** the default main scene. Still covered by `TestDebugController` and `TestDebugRunExport`.

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
| Embodied wizard | Placeholder scripts only (`embodied/player`, `embodied/encounters`); wizard marker in 3D mode does not affect `GameState` |
| Combat UI | `ui/combat/combat_presenter.gd` — presentation layer, not wired into main run mode |
| Integration bridge | `encounter_bridge.gd`, `sync_controller.gd` — contract exists; not full embodied loop |
| Phase model | Overlay shows generic “Player turn”; no fine-grained phase enum in `GameState` |
| Human player UI | M14 session API complete; no clickable 2D/3D action selection yet |
| Macro training env | Skeleton in progress on autonomous branch |

### Planned / not yet implemented

| System | Notes |
|---|---|
| **2D strategic board UI** | Read-only mode planned (M15); see [NEXT_MILESTONES.md](NEXT_MILESTONES.md) |
| **Macro training / batch balance** | Skeleton env + batch runner on autonomous branch |
| **Human click-to-build (2D)** | After read-only 2D (M16) |
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
├── core/           Headless authoritative rules engine (GameState, rules, events, bots, combat, export, reporting)
├── ui/             Debug overlay, combat presenter (presentation only)
├── integration/    Board ↔ world mapping, 3D visualizer, encounter/sync bridges
├── embodied/       Placeholder wizard/encounter scripts (must not mutate GameState directly)
├── run_modes/      Headless CSV runner, wizard-world main scene
└── tests/          40 test modules, architecture scanner, test runner
```

### Core principle (unchanged)

**One authoritative `GameState`.** Rules mutate state only through explicit rule functions and return events. UI, 3D, integration, and embodied layers **read** state and **submit legal actions** via session/rule APIs — they do not patch resources, cities, roads, demons, heroes, or scores directly.

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
| Post-M9 | Single Godot project, two run modes, shared `BotGameSession` |
| Latest | 3D board visualisation + human-readable reporting overlay |

See [integration_plan.md](integration_plan.md) for the original M0–M9 plan (historical).

---

## Known limitations and risks

1. **No human playable layer** — Watching bot autoplay in 3D/CSV is informative but not interactive strategy gameplay.
2. **Wizard marker is cosmetic** — WASD movement does not represent hero position in `GameState`.
3. **Four-player start scenario has no heroes/demons** — Overlay shows placeholders (`—`, `0`) until spread/move rules run in simulation.
4. **Turn log noise** — Game-start batches can list many city/VP events in one turn group.
5. **Test suite runtime** — ~50–80s; architecture scan dominates assertion count.
6. **Git bulk add on Windows** — Large `git add .` may hit permission errors; stage in batches if needed.
7. **Donor projects in repo** — Reference-only but large; do not treat as active code paths.

---

## Stale or misleading documentation

| Location | Issue |
|---|---|
| `.cursor/rules/game-architecture.mdc` | Previously described “first milestone only” and listed heroes/spread as “do not build” — **updated** in this handoff pass |
| `docs/integration_plan.md` | Milestone table stops at M9; does not list run modes, reporting, or next 2D/human-player direction |
| `.cursor/rules/project-architecture.mdc` | “Do not build embodied before…” gates are largely passed; constraints on *direct mutation* still apply |

For agent workflow and next steps, prefer **this file**, [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md), [TESTING_AND_GIT_WORKFLOW.md](TESTING_AND_GIT_WORKFLOW.md), and [NEXT_MILESTONES.md](NEXT_MILESTONES.md).

---

## Quick links

- [Run modes](run_modes.md)
- [Integration plan](integration_plan.md)
- [Testing and Git workflow](TESTING_AND_GIT_WORKFLOW.md)
- [Next milestones](NEXT_MILESTONES.md)
- GitHub: https://github.com/Joesalmon1985/Gods-and-Wizards
