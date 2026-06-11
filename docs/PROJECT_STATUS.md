# Project Status — Gods and Wizards

**Last updated:** 2026-06-11 (post Run A merge)  
**Purpose:** Human-readable handoff for reviewers and Cursor agents before the next milestone.

---

## Git snapshot

| Item | Value |
|---|---|
| **Production branch** | `main` @ `a0dda56` |
| **Latest merge** | PR #1 — `milestone/run-a-telemetry-and-spells` |
| **Prior tip** | `352c5c8` — local verification guide + macro product run |
| **Remote** | `origin` → https://github.com/Joesalmon1985/Gods-and-Wizards.git |

Run `git pull origin main` if local `main` is still at `352c5c8`.

### Recent commits on `main` (newest first)

| Commit | Summary |
|---|---|
| `a0dda56` | Merge PR #1 — Run A (M26.5–M29) |
| `f8308fb` | M29: spell combat session + micro combat telemetry |
| `722d62e` | M28: spell catalogue + combatant loadouts |
| `6f2f298` | M27: macro training telemetry export |
| `4259d66` | M26.5: Godot verification hardening |
| `352c5c8` | Local verification guide (Windows PowerShell) |

---

## Test status

### Command (preferred)

```powershell
& "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\scripts\Invoke-GodotHeadless.ps1" -ArgumentList @(
  "--headless",
  "--path", "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game",
  "-s", "res://tests/test_runner.gd"
)
```

**Local Godot executable:** `C:\Tools\Godot\godot.exe.exe`

### Result (verified at Run A completion, 2026-06-11)

| Metric | Value |
|---|---|
| Modules run | **54** |
| Assertions | **81,563** |
| Passed | **81,563** |
| Failed | **0** |

Optional suite filter: `--suite=architecture`, `--suite=integration`, etc. (see `tests/test_registry.gd`).

**Note:** First run after adding new global classes may require `--import`. Full suite typically takes ~90 seconds. Use [LOCAL_VERIFICATION.md](LOCAL_VERIFICATION.md) for orphan-process checks after headless runs.

---

## Active Godot project

**Path:** `godot_game/project.godot`  
**Name:** GodsAndWizards  
**Main scene (F5):** `res://run_modes/wizard_world_mode.tscn`

Donor folders under `donor_projects/` are **reference-only** (`project.godot.donor.txt`).

---

## Architecture constraints (mandatory)

1. **One authoritative macro `GameState`** — no second macro state machine, no donor merges into active paths.
2. **One authoritative micro `SpellCombatSession`** — separate from macro `GameState`; timeline for future replay.
3. **Core is headless** — `godot_game/core/` has no UI, Node3D, or input dependencies.
4. **Presentation submits, does not mutate** — `ui/`, `run_modes/`, `integration/`, and `embodied/` must not directly patch game rules; use session/rule APIs or consume snapshots/timelines only.
5. **Generic combatants** — heroes, demons, and wizards share `CombatantSpellLoadout`; spells are not wizard-only APIs.
6. **Donor projects are reference-only** — active project is `godot_game/project.godot` only.
7. **Tests are sacred** — do not weaken, skip, or delete tests to force progress.

---

## Run modes

See [run_modes.md](run_modes.md) and [LOCAL_VERIFICATION.md](LOCAL_VERIFICATION.md) for full commands. Summary:

| Mode | Entry | Purpose |
|---|---|---|
| Headless CSV playthrough | `run_headless_bot_game.gd` | One 4-player bot game → event CSV |
| Headless batch sim | `run_batch_sim.gd` | N games → one summary row per game |
| Macro training telemetry | `run_macro_training_export.gd` | Step-level macro training CSV |
| Micro combat telemetry | `run_micro_combat_export.gd` | Step-level spell combat CSV |
| Headless micro-duel (card) | `run_headless_duel.gd` | Legacy card combat smoke → CSV |
| Underworld pressure telemetry | `run_underworld_pressure.gd` | N pressure-scenario games → CSV |
| 3D wizard-world (F5) | `wizard_world_mode.tscn` | Read-only 3D + overlay; bot advance |
| 2D strategic (read-only) | `strategic_2d_mode.tscn` | Read-only 2D hex board; bot advance |

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
| Build city / build road | Costs, legality, events; `TestBuildRuleLegality` |
| Human player turn shell (M14) | `start_one_human_three_bots`, `submit_human_action` |
| Macro training env (M15) | `MacroTrainingEnv`: reset, observe, step |
| Macro training telemetry (M27) | `MacroTrainingTelemetryExporter`, schema v1 |
| Batch balance runner (M16) | `BatchSimRunner`, `run_batch_sim.gd` |
| Balance config skeleton (M17) | `BalanceConfig`, `default_balance.json` |
| 2D strategic board read-only (M18/M25) | Developments, breaches, demons overlay |
| Hero move | `MoveRules`, occupancy rules |
| Demon spread / breach loss / VP win | Full macro loop |
| Development build (stub) | Catalog foundation; no drafting |
| Headless card combat | `CombatResolver` — legacy smoke regression |
| Spell catalogue (M28) | `SpellCatalog`, `SpellDefinition`, 35 spells, 18 loadouts |
| Spell combat session (M29) | `SpellCombatSession`, alternating-turn v1 |
| Micro combat telemetry (M29) | `MicroCombatTrainingEnv`, schema v1 |
| Bot policies | Random + heuristic; `BotTurnResolver` |
| Event log + replay | Deterministic replay; CSV `road_count` replay fixed |
| Bot game session | 4-player scenario, shared by run modes |
| CSV export | Playthrough, duel, batch, pressure, training telemetry |
| Godot verification scripts (M26.5) | `Invoke-GodotHeadless.ps1`, stale process cleanup |
| Architecture enforcement | Core headless, no parallel GameState |

### Partial / stub / prototype

| System | Notes |
|---|---|
| Development cards | Catalog (watchtower, granary, shrine); no drafting |
| Embodied wizard | Placeholder scripts; wizard marker does not affect `GameState` |
| Combat UI | `ui/combat/combat_presenter.gd` — not wired to spell session |
| Spell combat fidelity | v1 instant resolution + pass/mana regen; projectiles/counterspells deferred |
| Human player UI | M14 session API complete; no clickable 2D/3D macro play (M22 deferred) |
| Balance config wiring | JSON skeleton; gameplay constants not yet driven from config |
| 3D combat replay / playable micro | Not started |

### Planned / not yet implemented

| System | Notes |
|---|---|
| **M22 2D human click-to-build** | Wire M14 to 2D view — **deferred** |
| **M26 divine instruction offers** | Future headless bridge |
| Bank trade / 2D audit / 3D spectator | Not started |
| Drafting (Seven Wonders-style) | Out of scope until requested |
| Full embodied encounter gameplay | 3D combat loop not connected to main scene |
| Neural network / training | Telemetry runners exist; training loop not started |
| Multiplayer networking | Not started |

---

## Architecture (current layout)

```
godot_game/
├── core/           Headless rules engine (GameState, rules, combat, spells, export, sim, bots)
├── data/spells/    Encoded spell catalogue + combatant loadouts (v1 JSON)
├── ui/             Debug overlay, 2D strategic board, combat presenter
├── integration/    Board ↔ world mapping, 3D visualizer, encounter bridges
├── embodied/       Placeholder wizard/encounter scripts
├── run_modes/      Headless runners, wizard-world, 2D strategic mode
├── data/balance/   Balance config JSON (skeleton)
└── tests/          54 test modules, architecture scanner, test runner

scripts/            Invoke-GodotHeadless.ps1, spell catalogue export (Python)
data/design/        Local workbook placement (xlsx gitignored)
docs/               Handoff, verification, spell balance source notes
```

---

## Milestones completed (summary)

| Range | Delivered |
|---|---|
| M0–M9 | Headless engine, roads, heroes, demons, card combat stub, integration placeholders |
| M14–M18 | Human session shell, macro training env, batch sim, balance config, 2D read-only board |
| M21–M25 | Duel runner, dev catalog, underworld pressure, 2D lens, CSV fixes |
| M26.5–M29 | Verification hardening, macro/micro telemetry, spell catalogue, spell combat session |

See [NEXT_MILESTONES.md](NEXT_MILESTONES.md) and [AUTONOMOUS_SESSION_LOG.md](AUTONOMOUS_SESSION_LOG.md).

---

## Known limitations and risks

1. **No human playable macro layer** — 2D/3D modes advance bots only; M22 deferred.
2. **Wizard marker is cosmetic** — WASD does not represent hero position in `GameState`.
3. **Batch sim turn-limit stalls** — many games hit turn cap without VP finish.
4. **Spell combat v1** — simplified timing; card `CombatResolver` kept for regression only.
5. **Workbook local only** — regenerate `godot_game/data/spells/*.json` after workbook changes.
6. **Test suite runtime** — ~90s; architecture scan dominates assertion count.

---

## Next recommended task

1. **`git checkout main && git pull origin main`** — sync with merged Run A.
2. **Local verification** — [LOCAL_VERIFICATION.md](LOCAL_VERIFICATION.md) (tests + telemetry smokes + orphan check).
3. **Choose next milestone** — after human review; M22 remains oldest deferred playable macro work.

**Resume from:** `main` @ `a0dda56`

---

## Quick links

- [Local verification](LOCAL_VERIFICATION.md)
- [Autonomous session log](AUTONOMOUS_SESSION_LOG.md)
- [Spell balance source](SPELL_BALANCE_SOURCE.md)
- [Run modes](run_modes.md)
- [Next milestones](NEXT_MILESTONES.md)
- [Testing and Git workflow](TESTING_AND_GIT_WORKFLOW.md)
- GitHub: https://github.com/Joesalmon1985/Gods-and-Wizards
