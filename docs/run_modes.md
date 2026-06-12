# Run Modes

This workspace has **exactly one active Godot project**: [`godot_game/project.godot`](../godot_game/project.godot).

Donor folders under `donor_projects/` are **reference-only**. Their former `project.godot` files were renamed to `project.godot.donor.txt` so Godot does not treat them as openable projects.

---

## Architecture constraints

- **One authoritative `GameState`** — no second state machine.
- **Core is headless** — `godot_game/core/` has no UI or input dependencies.
- **Run modes submit, do not mutate** — `run_modes/`, `ui/`, `integration/`, and `embodied/` must not directly patch cities, roads, resources, demons, heroes, or scores; use `BotGameSession` and rule APIs.
- **Donor projects are reference-only** — do not import active code from `donor_projects/`.

Macro run modes (A, A2) and visual modes (B, C) use the same authoritative core types where applicable:

- `GameState`
- rule functions (`ActionRules`, `ProductionRules`, etc.)
- `BotGameSession` (shared 4-player bot simulation wrapper)

There is **one** game state machine in `godot_game/core/`. The 3D wizard-world mode does not create a parallel board or wizard GameState.

---

## A. Headless bot simulation (CSV playthrough)

**Script:** `res://run_modes/run_headless_bot_game.gd`

Runs a deterministic **4-player** bot game from a seed until game over or a turn limit, then writes a CSV playthrough log.

### Command

```powershell
& "C:\Tools\Godot\godot.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://run_modes/run_headless_bot_game.gd -- --seed 42 --max-turns 300
```

### Command (write CSV under repo `logs/`)

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\playthrough_seed_42.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_headless_bot_game.gd -- --seed 42 --max-turns 300 --output $Out
```

Do not commit files under `logs/` (gitignored).

### Optional arguments

| Flag | Default | Meaning |
|---|---|---|
| `--seed` | `42` | Game RNG seed |
| `--max-turns` | `200` | Max completed player turns if game-over rules do not finish first |
| `--output` | (auto) | Override CSV output path (`user://` or absolute) |

### CSV output path

Default:

```
user://playthrough_seed_<seed>.csv
```

On Windows this resolves under the Godot user data folder for the project, typically:

```
C:\Users\<you>\AppData\Roaming\Godot\app_userdata\GodsAndWizards\playthrough_seed_42.csv
```

The headless script prints the **globalized absolute path** when finished.

### CSV columns

`seed`, `turn_number`, `round_number`, `active_player_id`, `active_player_name`, `action_type`, `action_details`, `event_type`, `event_details`, `event_summary`, `player_resources`, `city_count`, `road_count`, `demon_breach_info`, `score`

`event_summary` is a human-readable one-line description of each event. `event_details` still contains the full JSON payload.

Columns are always present; unimplemented fields use blank or default values.

---

## A2. Headless batch balance simulation (CSV summary)

**Script:** `res://run_modes/run_batch_sim.gd`

Runs **N** independent 4-player bot games (seeds `seed`, `seed+1`, …) and writes **one CSV row per game** with aggregate outcome stats.

### Command

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\batch_balance.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_batch_sim.gd -- --games 100 --seed 42 --max-turns 300 --output $Out
```

### Optional arguments

| Flag | Default | Meaning |
|---|---|---|
| `--games` | `10` | Number of games to simulate |
| `--seed` | `42` | First game seed (increments by 1 per game) |
| `--max-turns` | `200` | Max completed player turns per game |
| `--policy` | `heuristic` | Bot policy name |
| `--output` | (auto) | CSV output path |

### CSV columns (one row per game)

`seed`, `turns_played`, `game_over`, `winner_id`, `outcome_reason`, `vp_p0`, `vp_p1`, `vp_p2`, `vp_p3`, `city_count`, `road_count`, `breach_count`, `demon_count`, `policy_name`

---

## B. 3D wizard-world mode

**Main scene:** `res://run_modes/wizard_world_mode.tscn` (also `macro_spectator_3d_mode.tscn` for Run B spectator)

Launch from the editor (F5) or:

```powershell
& "C:\Tools\Godot\godot.exe" --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game"
```

**Product direction:** Long-term default player experience is 3D wizard spectator/RPG. Near-term development default remains 2D strategic playable/debug until macro rules are stable.

### What it shows

- Initialises the same `BotGameSession` / `GameState` as headless mode
- Renders a **read-only** 3D board from `BoardWorldMapper` / `BoardStateVisualizer`
- Human-readable overlay via `GameStateSummary`, `TurnReport`, and `EventSummary` (no raw JSON spam)
- Scoreboard with victory points, cities, roads, hero status, and resource totals per player
- Recent-turn log with aggregated production summaries

**The 3D layer does not own or directly mutate `GameState`.** WASD wizard movement is presentation-only.

### Controls (Run J — 2026-06-12)

| Input | Action |
|---|---|
| **Space** / **Enter** / **N** | Advance one bot player turn (explicit handler; not `ui_accept`) |
| **P** | Toggle autoplay |
| **+** / **-** | Adjust autoplay speed |
| **C** / camera button | Toggle board overview / wizard camera |
| **R** | Reset with the same seed |
| **H** | Hide/show help overlay |
| **WASD** | Move wizard marker relative to Q/E facing (presentation only) |
| **Q** / **E** | Turn wizard marker yaw |

**Scale:** `WorldPresentationScale.HEX_SIZE = 16`; walk speed calibrated for ~5 hex centre-spacings in 180 s.

**Visuals:** Manifest-backed billboards from `godot_game/assets/billboards/` (wizard, heroes, demons, forest props, spell icons). Hybrid built-development indicators on city vertices (read-only; no draft pack/hand UI).

**Deferred:** Combat sim / DTO adapter → Run J2 ([RUN_J2_MICRO_COMBAT_ADAPTER_PLAN.md](RUN_J2_MICRO_COMBAT_ADAPTER_PLAN.md)); AI/training → Run K.

---

## C. 2D strategic mode

**Scenes:** `strategic_2d_mode.tscn` (read-only), `strategic_play_2d_mode.tscn` (playable), `strategic_audit_2d_mode.tscn` (audit)

**Near-term development default** for macro rules testing and human play. Read-only and playable variants driven by `BoardWorldMapper` snapshots and `BotGameSession` / human session API. Does not replace F5 main scene (`wizard_world_mode.tscn`).

```powershell
& "C:\Tools\Godot\godot.exe" --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" res://run_modes/strategic_2d_mode.tscn
```

---

## D. Headless micro-duel runner (legacy card duel)

**Script:** `res://run_modes/run_headless_duel.gd`

Runs a single headless `CombatResolver.resolve_encounter()` from a seed and writes a CSV with one summary row plus per-round detail. No `GameState`, no 3D.

**Classification:** **Legacy / debug only.** Uses the card-duel `CombatResolver` model, not canonical tactical combat (`SpellCombatSession`). Do not use for macro hero/demon resolution or NN training alongside `micro_combat_v1` export.

### Command

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\duel_seed_123.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_headless_duel.gd -- --seed 123 --output $Out
```

### Optional arguments

| Flag | Default | Meaning |
|---|---|---|
| `--seed` | `42` | Duel RNG seed |
| `--output` | `user://duel_seed_<seed>.csv` | CSV output path |

### CSV columns

Summary row: `seed`, `winner_id`, `attacker_id`, `defender_id`, `attacker_health_final`, `defender_health_final`, `rounds_played`

Round rows (below blank line): `seed`, `round`, `att_move`, `def_move`, `att_damage`, `def_damage`

---

## E. Underworld pressure telemetry (CSV summary)

**Script:** `res://run_modes/run_underworld_pressure.gd`

Runs **N** bot games using the underworld pressure scenario (seeded initial demon clusters) and writes one CSV row per game with spread/breach telemetry.

### Command

```powershell
$ProjectRoot = "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
$Out = Join-Path $ProjectRoot "logs\underworld_pressure.csv"
New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
& "C:\Tools\Godot\godot.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_underworld_pressure.gd -- --games 20 --seed 42 --max-turns 120 --output $Out
```

### CSV columns (one row per game)

`seed`, `turns_played`, `rounds_played`, `breach_count`, `peak_demon_count`, `spread_event_count`, `game_over`, `winner_id`, `outcome_reason`, `policy_name`

---

## Known CSV quirks (playthrough mode A)

- **`production_check` rows** — now include human-readable `event_summary` (roll, hex, hit/miss).
- **`road_count` and `city_count`** — both replayed per log step via `EventLogReplay`.
- **Batch sim turn-limit stalls** — many games may hit `--max-turns` without VP finish; see batch CSV `outcome_reason`.

---

## E. Headless macro training telemetry export

**Script:** `res://run_modes/run_macro_training_export.gd`

Exports step-level macro training rows (observations, legal masks, selected actions, rewards) from `MacroTrainingEnv`.

**Classification:** Partial/prototyping telemetry — **not production RL-ready.** Dataset v2 required before serious macro RL. Macro RL design target uses full global state observation; v1 export has aggregate scalars only. See [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md).

```powershell
& "C:\Tools\Godot\godot.exe.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_macro_training_export.gd -- --seed 42 --max-steps 50 --output (Join-Path $ProjectRoot "logs\macro_training_seed_42.csv")
```

---

## F. Headless tactical combat telemetry export

**Script:** `res://run_modes/run_micro_combat_export.gd`

Exports step-level **tactical combat** telemetry from `SpellCombatSession` / `MicroCombatTrainingEnv`. This is the canonical tactical combat export — not macro contact resolution and not the legacy card-duel runner (§D).

```powershell
& "C:\Tools\Godot\godot.exe.exe" --headless --path (Join-Path $ProjectRoot "godot_game") -s res://run_modes/run_micro_combat_export.gd -- --seed 123 --max-steps 80 --output (Join-Path $ProjectRoot "logs\micro_combat_seed_123.csv")
```

---

## Tests

```powershell
& "C:\Tools\Godot\godot.exe.exe" --headless --path "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game" -s res://tests/test_runner.gd
```

Architecture tests verify:

- core remains headless
- core does not reference donor projects
- workspace has only one active `project.godot`
- headless run mode can produce CSV
- wizard-world scripts do not bypass rule/action APIs

---

## Debug overlay (legacy)

The earlier debug replay UI remains at `res://ui/debug/debug_game_overlay.tscn` for event-log inspection. It is not the default main scene.

---

## Product / UI planning (Run I)

Implementation-ready UX and 3D specs live under `docs/` (prefix `PRODUCT_*`, `THREE_D_*`, `HUD_*`, `IMPLEMENTATION_PLAN_3D_UI.md`). No gameplay changes in Run I — future work tracked as Impl I1–I7.
