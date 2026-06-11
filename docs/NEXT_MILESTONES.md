# Next Milestones (Proposed)

**Last updated:** 2026-06-11

**Strategic direction:** Macro-first, trainable mythic civilisation simulation. One authoritative `GameState`. Headless core and `BotGameSession` are source of truth. **2D strategic mode** supports debug/training/balancing; **3D wizard mode** is a deferred presentation layer. See [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md).

**Architecture constraints (all milestones):**

- One authoritative `GameState`; no second state machine.
- Core is headless; no UI in `godot_game/core/`.
- UI, `run_modes/`, `integration/`, and `embodied/` submit legal actions only — they do not directly mutate `GameState`.
- Donor projects under `donor_projects/` are reference-only.

---

## Completed on `milestone/macro-foundation-autonomous`

| ID | Title | Commit | Tests |
|---|---|---|---|
| **M14** | Human player turn shell (1 human + 3 bots) | `3242cff` | `TestHumanPlayerSession` |
| **M15** | Macro training environment skeleton | `5c3ab90` | `TestMacroTrainingEnv` |
| **M16** | Headless batch balance runner | `8d9c353` | `TestBatchSim` |
| **M17** | Balance configuration skeleton | `d9a8e73` | `TestBalanceConfig` |
| **M18** | 2D board state view (read-only) | `772a1c9` | `TestStrategicBoardView` |

**Note:** Original doc numbering had M15 = 2D read-only and M19/M20 = macro env + batch. Autonomous session used M15–M18 for macro env, batch, balance config, and 2D board respectively. This file reflects **what was built**, not the original draft order.

---

## M21 — Headless micro-duel smoke runner (proposed, **not implemented**)

### Goal

Smallest CLI runner for headless card combat: one seeded `CombatResolver.resolve_encounter()` call, CSV or JSON export, no `GameState`, no 3D.

### Why it matters

Proves micro-encounter layer is exportable and deterministic before wiring board encounters or embodied combat.

### Existing foundation

- `core/combat/` — `CombatResolver`, `CombatRules`, deck runtime
- `core/rules/encounter_rules.gd`, `integration/encounter_bridge.gd`
- Tests: `TestCombatRules`, `TestDeckRuntime`, `TestEncounterResolver`, `TestIntegrationBridge`

### Files likely to change

- `godot_game/run_modes/run_headless_duel.gd` (new)
- `godot_game/core/export/duel_log_exporter.gd` (optional)
- `godot_game/tests/test_headless_duel_runner.gd` (new)
- `docs/run_modes.md`

### Tests first

- Same seed → identical CSV/JSON output on two runs
- No scene or `GameState` dependency
- Architecture scan passes

### Acceptance criteria

- One headless command: `--seed`, `--output`
- Full test suite passes
- Documented in `run_modes.md`

### Out of scope

- Embodied combat, board-linked encounters, NN training

---

## M22 — 2D human action selection (was M16 in original doc)

### Goal

Wire M14 human turn shell to M18 2D view: highlight legal build/move targets from `LegalActionQuery`, submit chosen `GameAction` through session API.

### Why it matters

First **playable** strategic experience: one human can actually play against bots on the board.

### Files likely to change

- `godot_game/ui/board/strategic_board_view.gd` (input, highlights)
- `godot_game/run_modes/strategic_2d_mode.gd`
- `godot_game/tests/` (UI boundary tests)

### Tests first

- Selection maps to correct `GameAction` payload
- UI never calls rule functions except via session submit
- Human build road/city/end turn identical to headless path
- Illegal targets not submit-able

### Acceptance criteria

- Play 1 human + 3 bots to completion or turn limit from 2D mode
- Full test suite passes

### Out of scope

- Drafting UI, 3D wizard embodiment

---

## M23 — Unified run mode entry (2D primary, 3D observatory)

### Goal

Single entry point defaulting to **2D playable mode** with **3D wizard-world as observatory** (same `BotGameSession`, switch views without duplicate state).

### Files likely to change

- `godot_game/project.godot` (main scene)
- `godot_game/run_modes/`
- `docs/run_modes.md`

### Acceptance criteria

- F5 launches 2D human+bot experience (after M22)
- Optional key/menu opens 3D observatory of same session
- Headless CSV/batch modes unchanged
- Full test suite passes

---

## M24 — Balance config wiring (optional)

### Goal

Drive selected `GameConstants` / `BuildCosts` values from `BalanceConfig` JSON so batch runner can sweep parameters without code edits.

### Acceptance criteria

- Default config produces identical gameplay to current constants
- Batch runner can load alternate config path
- Full test suite passes

---

## Priority recommendation

| Order | Milestone | Status |
|---|---|---|
| 1 | M14 Human turn shell | **Done** |
| 2 | M15 Macro training env | **Done** |
| 3 | M16 Batch balance runner | **Done** |
| 4 | M17 Balance config skeleton | **Done** |
| 5 | M18 2D read-only board | **Done** |
| 6 | **M21 Headless micro-duel runner** | **Next (headless, small scope)** |
| 7 | M22 2D human click-to-build | First playable loop |
| 8 | M23 Unified entry | UX coherence |
| 9 | M24 Balance config wiring | Optional |

---

## Explicitly not next

- Full drafting system
- Wizard marker → hero position binding
- Combat UI in main loop
- Donor project merges
- Second parallel `GameState`
- Weakening architecture tests
- Merge to `main` without human PR review

See [PROJECT_STATUS.md](PROJECT_STATUS.md) and [AUTONOMOUS_SESSION_LOG.md](AUTONOMOUS_SESSION_LOG.md) for current state.
