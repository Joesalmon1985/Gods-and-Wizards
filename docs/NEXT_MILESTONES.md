# Next Milestones (Proposed)

**Last updated:** 2026-06-11 (post Run A merge to `main`)

**Strategic direction:** Macro-first, trainable mythic civilisation simulation. One authoritative `GameState`. Headless core and `BotGameSession` are source of truth. **2D strategic mode** supports debug/training/balancing; **3D wizard mode** is a deferred presentation layer. See [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md).

**Architecture constraints (all milestones):**

- One authoritative `GameState`; no second state machine for macro play.
- One authoritative `SpellCombatSession` for micro spell combat (separate from macro `GameState`).
- Core is headless; no UI in `godot_game/core/`.
- UI, `run_modes/`, `integration/`, and `embodied/` submit legal actions or consume snapshots/timelines only.
- Donor projects under `donor_projects/` are reference-only.
- Heroes, demons, and wizards are generic combatants with spell loadouts — not wizard-only spell APIs.

---

## Roadmap reconciliation note

Completed milestone history (M14–M18, M21–M25) is **not renumbered**.

| ID | Status | Notes |
|---|---|---|
| **M21** | Done | Headless card micro-duel smoke runner |
| **M22** | Deferred | 2D human click-to-build — not implemented |
| **M23** (product run) | Done | Development-card catalog foundation |
| **M24** (product run) | Done | Underworld pressure telemetry |
| **M25** | Done | Read-only 2D strategic board improvements |
| **M26** | Deferred | Divine instruction offers — docs only |
| **M26.5** | **Done** (Run A) | Local Godot verification hardening |
| **M27** | **Done** (Run A) | Macro training telemetry export |
| **M28** | **Done** (Run A) | Spell catalogue + combatant loadout model |
| **M29** | **Done** (Run A) | Spell combat session + micro combat telemetry |

Run A merged via PR #1 → `main` @ `a0dda56`.

---

## Completed on `milestone/macro-foundation-autonomous`

| ID | Title | Commit | Tests |
|---|---|---|---|
| **M14** | Human player turn shell (1 human + 3 bots) | `3242cff` | `TestHumanPlayerSession` |
| **M15** | Macro training environment skeleton | `5c3ab90` | `TestMacroTrainingEnv` |
| **M16** | Headless batch balance runner | `8d9c353` | `TestBatchSim` |
| **M17** | Balance configuration skeleton | `d9a8e73` | `TestBalanceConfig` |
| **M18** | 2D board state view (read-only) | `772a1c9` | `TestStrategicBoardView` |

---

## Completed on `milestone/macro-product-autonomous-run`

| ID | Title | Commit | Tests |
|---|---|---|---|
| **M21** | Headless micro-duel smoke runner | `1996120` | `TestHeadlessDuelRunner` |
| **M23** | Small development-card catalog foundation | `053b57e` | `TestDevelopmentCatalog` |
| **M24** | Underworld pressure smoke + telemetry | `d0a7667` | `TestUnderworldPressure` |
| **M25** | Read-only 2D strategic board improvements | `9c1df90` | `TestBoardWorldMapper`, `TestStrategicBoardView` |
| **Fix** | Playthrough CSV road replay + production summaries | `9b46681` | `TestPlaythroughCsvExporter` |

---

## Completed on `milestone/run-a-telemetry-and-spells` (merged to `main`)

| ID | Title | Commit | Tests |
|---|---|---|---|
| **M26.5** | Local Godot verification hardening | `4259d66` | Scripts/docs; `Invoke-GodotHeadless.ps1` |
| **M27** | Macro training telemetry runner | `6f2f298` | `TestMacroTrainingTelemetry` |
| **M28** | Spell catalogue and combatant loadout model | `722d62e` | `TestSpellCatalog` |
| **M29** | Spell combat session + micro combat telemetry | `f8308fb` | `TestSpellCombatSession`, `TestMicroCombatTelemetry` |

Spell balance source: workbook `SpellSpecs` sheet → `godot_game/data/spells/`. See [SPELL_BALANCE_SOURCE.md](SPELL_BALANCE_SOURCE.md).

---

## M22 — 2D human action selection (**deferred, not implemented**)

### Goal

Wire M14 human turn shell to M18 2D view: highlight legal build/move targets from `LegalActionQuery`, submit chosen `GameAction` through session API.

### Why it matters

First **playable** strategic experience: one human can actually play against bots on the board.

### Prerequisites (green)

- M14 human turn shell
- M18 read-only 2D board
- Session APIs for legal human actions

### Out of scope

- Drafting UI, 3D wizard embodiment

**Suggested branch:** `milestone/2d-human-click-to-build`

---

## M26 — Divine instruction offer system (proposed, **not implemented**)

### Goal

Headless core bridge between future 3D wizard presentation and legal macro actions: deterministic **offer / accept / decline** flow that submits legal actions through session/rule APIs only.

### Why it matters

Lets embodied wizard UX propose macro choices without becoming a second source of truth.

### Prerequisites

- M21 headless micro-duel runner green
- Playable 2D macro loop (recommended)
- Stable encounter contracts (`EncounterRequest` / `EncounterResult`) before embodied integration

### Scope (initial)

- Seeded offer catalog + events
- Pass/accept through existing action submission paths
- Headless tests only

### Out of scope

- Full embodied wizard loop
- Full drafting
- Neural-network training

**Suggested branch:** `milestone/divine-instruction-offers`

---

## Future optional milestones (draft IDs preserved)

### Unified run mode entry (draft M23)

Single entry defaulting to 2D playable mode with 3D observatory — **after playable 2D macro loop**.

### Balance config wiring (draft M24)

Drive selected `GameConstants` / `BuildCosts` from `BalanceConfig` JSON for batch sweeps.

---

## Priority recommendation

| Order | Milestone | Status |
|---|---|---|
| 1 | M14–M18 Macro foundation | **Done** |
| 2 | M21–M25 Macro product run | **Done** |
| 3 | M26.5–M29 Run A (telemetry + spells) | **Done** — merged PR #1 |
| 4 | **M22 2D human click-to-build** | **Deferred** |
| 5 | M26 Divine instruction offers | Future headless bridge |
| 6 | Draft M23 unified entry | After playable macro loop |
| 7 | Draft M24 balance wiring | Optional |

---

## Explicitly not next (until requested)

- Full drafting system
- Wizard marker → hero position binding
- Full 3D combat presentation loop
- Donor project merges
- Second parallel `GameState`
- Weakening architecture tests
- Neural network training infrastructure

See [PROJECT_STATUS.md](PROJECT_STATUS.md) and [AUTONOMOUS_SESSION_LOG.md](AUTONOMOUS_SESSION_LOG.md) for current state.
