# Autonomous Session Log — Macro Foundation

**Last updated:** 2026-06-11  
**Purpose:** Resume point for Cursor agents after context reset. Do not treat as user-facing release notes.

---

## Current branch state

| Item | Value |
|------|--------|
| **Branch** | `milestone/macro-foundation-autonomous` |
| **Latest commit** | `8cfa8d9` — *Docs: finalize autonomous session log* |
| **Push status** | **In sync** with `origin/milestone/macro-foundation-autonomous` (after handoff commit below) |
| **Baseline tag** | `checkpoint/macro-foundation-baseline` @ `3242cff` |
| **Not merged to `main`** | `origin/main` remains @ `e1b94c7` |

---

## Latest full test result

Verified 2026-06-11:

```
Ran 46 modules, 62491 assertions
Passed: 62491
Failed: 0
```

### Command

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://tests/test_runner.gd
```

After adding new global classes:

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" --import
```

---

## Phases completed (autonomous macro-foundation session)

| Phase | Commit | Summary |
|-------|--------|---------|
| M14 human turn shell | `3242cff` | `BotGameSession` human APIs; `TestHumanPlayerSession` |
| Baseline tag | `3242cff` | `checkpoint/macro-foundation-baseline` |
| Design docs | `d25ba1a`, `954cec4`, `8cfa8d9` | Brief, status, session log |
| M15 macro training env | `5c3ab90` | `MacroTrainingEnv`; `TestMacroTrainingEnv` |
| M16 batch balance runner | `8d9c353` | `BatchSimRunner`, `run_batch_sim.gd`; `TestBatchSim` |
| M17 balance config skeleton | `d9a8e73` | `BalanceConfig`, `default_balance.json`; `TestBalanceConfig` |
| M18 read-only 2D board | `772a1c9` | `StrategicBoardView`, `strategic_2d_mode`; `TestStrategicBoardView` |

**Build legality** (pre-M14 on branch): `8f54090` … `c421ec5` — `BuildRules.can_build_city`, CSV duplicate-log fix.

## Phases skipped / blocked

**None.** All planned autonomous phases completed.

---

## Files changed by phase

### M14 (`3242cff`)

- `godot_game/core/sim/bot_game_session.gd`
- `godot_game/tests/test_human_player_session.gd`
- `godot_game/tests/test_registry.gd`

### M15 (`5c3ab90`)

- `godot_game/core/sim/macro_training_env.gd`
- `godot_game/tests/test_macro_training_env.gd`

### M16 (`8d9c353`)

- `godot_game/core/sim/batch_sim_runner.gd`
- `godot_game/run_modes/run_batch_sim.gd`
- `godot_game/tests/test_batch_sim.gd`
- `docs/run_modes.md`

### M17 (`d9a8e73`)

- `godot_game/core/config/balance_config.gd`
- `godot_game/data/balance/default_balance.json`
- `godot_game/tests/test_balance_config.gd`

### M18 (`772a1c9`)

- `godot_game/ui/board/strategic_board_view.gd`
- `godot_game/run_modes/strategic_2d_mode.gd`
- `godot_game/run_modes/strategic_2d_mode.tscn`
- `godot_game/tests/test_strategic_board_view.gd`

---

## Run commands (copy/paste)

### Full test suite

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://tests/test_runner.gd
```

### Macro playthrough CSV (one game, event log)

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\playthrough_seed_42.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_headless_bot_game.gd -- --seed 42 --max-turns 300 --output $Out
```

### Batch simulation CSV (one row per game)

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\batch_balance.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_batch_sim.gd -- --games 100 --seed 42 --max-turns 300 --output $Out
```

**Do not commit** files under `logs/` (gitignored).

---

## Headless micro / mini duel runner

**Does not exist.** No `run_headless_duel.gd`, `run_encounter_sim.gd`, or similar under `run_modes/`.

**Existing headless combat (tests only, no CLI export):**

- `core/combat/` — `CombatResolver`, `CombatRules`, deck runtime
- `core/rules/encounter_rules.gd` — hero vs demon on board
- `integration/encounter_bridge.gd` — bridge into `GameState`
- Tests: `TestCombatRules`, `TestDeckRuntime`, `TestEncounterResolver`, `TestIntegrationBridge`

---

## Proposed M21 — Headless micro-duel smoke runner (not implemented)

Smallest next step for micro encounters:

1. **`run_modes/run_headless_duel.gd`** — `--seed`, `--output`; calls `CombatResolver.resolve_encounter()` only (no `GameState`, no 3D).
2. **`core/export/duel_log_exporter.gd`** (optional) — CSV: `seed`, `winner_id`, `attacker_health_final`, `defender_health_final`, `rounds_played`; per-round: `round`, `att_move`, `def_move`, `att_damage`, `def_damage`.
3. **`tests/test_headless_duel_runner.gd`** — same seed → identical CSV; no scene dependency.
4. Doc section in `run_modes.md`.

Out of scope: embodied combat, board-linked encounters, NN training.

---

## CSV review findings (2026-06-11, seed 42)

**Playthrough** (`review_macro_playthrough_seed_42.csv`): 3,152 rows; 38 player turns; VP win (player 1); 37 cities/roads built; 0 actor mismatches; 0 negative resources.

**Batch** (100 games, seeds 42–141): 49 VP finishes, 51 turn-limit stalls; deterministic on re-run; 0 breach endings in range.

---

## Known issues

1. **`origin/main` lags milestone branch** — merge via PR after human review.
2. **Playthrough CSV `road_count`** — uses final session state on all rows; `city_count` is replayed per step.
3. **`production_check` rows** — empty `event_summary` (1,670 rows in typical playthrough).
4. **`BalanceConfig`** — skeleton only; rules still read `GameConstants` / `BuildCosts` directly.
5. **Batch sim** — 51/100 games hit 300-turn cap without VP finish (seeds 42–141); tune balance or cap separately.
6. **Untracked Godot `.uid` files** — safe to commit or gitignore; not required for resume.
7. **Old git stash** — `stash@{0}`: *WIP M14 human turn shell before build-rule legality tests* — redundant; do not pop without diff review.
8. **Headless `StrategicBoardView` test** — may warn about CanvasItem RID leaks; tests pass.

---

## Architecture constraints (mandatory)

- **One authoritative `GameState`** — no second state, no donor merges into active paths.
- **Core is headless** — `godot_game/core/` has no UI, Node3D, or input dependencies.
- **Presentation submits, does not mutate** — `ui/`, `run_modes/`, `integration/`, `embodied/` must not directly patch cities, roads, resources, demons, heroes, or scores; use session/rule APIs.
- **Donor projects reference-only** — `donor_projects/`; active project is `godot_game/project.godot` only.
- **Tests are sacred** — do not weaken, skip, or delete tests to force progress.

---

## Next recommended task

1. **Human review + PR** — `milestone/macro-foundation-autonomous` → `main`.
2. **M21** — headless micro-duel smoke runner (see above).
3. **M22 (playable 2D)** — wire M14 human shell to 2D view (click-to-build); read-only 2D already exists (`strategic_2d_mode.tscn`).

**Resume branch:** `milestone/macro-foundation-autonomous`  
**First implementation task for next autonomous run:** M21 headless duel runner (tests first).

---

## Blockers / stashes

None active. Session complete; handoff docs updated in commit after this file.
