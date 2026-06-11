# Next Milestones (Proposed)

**Last updated:** 2026-06-11

**Strategic direction:** Macro-first, trainable mythic civilisation simulation. One authoritative `GameState`. Headless core and `BotGameSession` are source of truth. **2D strategic mode** supports debug/training/balancing; **3D wizard mode** is a deferred presentation layer. See [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md).

**Architecture constraints (all milestones):**

- One authoritative `GameState`; no second state machine.
- Core is headless; no UI in `godot_game/core/`.
- UI, `run_modes/`, `integration/`, and `embodied/` submit legal actions only — they do not directly mutate `GameState`.
- Donor projects under `donor_projects/` are reference-only.

---

## Roadmap reconciliation note (2026-06-11)

Completed milestone history (M14–M18) is **not renumbered**.

During the `milestone/macro-product-autonomous-run` session, these IDs were used for new headless/tooling work:

| ID used this run | Delivered | Earlier draft meaning (unchanged / deferred) |
|---|---|---|
| **M21** | Headless micro-duel smoke runner | Same intent — now **done** |
| **M23** | Small development-card catalog foundation | Draft M23 was unified run-mode entry → see **future M27** below |
| **M24** | Underworld pressure smoke scenario + telemetry | Draft M24 was balance-config wiring → remains optional future work |
| **M25** | Read-only 2D strategic board improvements | Extends M18 read-only lens — **done** |

**M22 remains:** 2D human click-to-build (deferred to next run).

**M26 added:** divine instruction offer system (future core/headless bridge — docs only this run).

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
- M22 playable 2D loop (recommended)
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

Single entry defaulting to 2D playable mode with 3D observatory — **after M22**.

### Balance config wiring (draft M24)

Drive selected `GameConstants` / `BuildCosts` from `BalanceConfig` JSON for batch sweeps.

---

## Priority recommendation

| Order | Milestone | Status |
|---|---|---|
| 1 | M14–M18 Macro foundation | **Done** (`macro-foundation-autonomous`) |
| 2 | M21 Headless micro-duel runner | **Done** |
| 3 | CSV telemetry fix | **Done** |
| 4 | M24 Underworld pressure telemetry | **Done** |
| 5 | M23 Development-card foundation | **Done** |
| 6 | M25 2D read-only improvements | **Done** |
| 7 | **M22 2D human click-to-build** | **Next (playable loop)** |
| 8 | M26 Divine instruction offers | Future headless bridge |
| 9 | Draft M23 unified entry | After M22 |
| 10 | Draft M24 balance wiring | Optional |

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
