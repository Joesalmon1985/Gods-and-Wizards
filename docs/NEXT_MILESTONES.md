# Next Milestones (Proposed)

**Last updated:** 2026-06-12 (post–Run D v1 macro implementation)

**Strategic direction:** Macro-first, trainable mythic civilisation simulation. One authoritative `GameState`. Headless core and `BotGameSession` are source of truth. **Near-term dev default:** 2D strategic playable/debug. **Long-term product default:** 3D wizard spectator/RPG. See [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md) and [RULEBOOK.md](RULEBOOK.md).

**Architecture constraints (all milestones):**

- One authoritative `GameState`; no second state machine.
- Core is headless; no UI in `godot_game/core/`.
- UI, `run_modes/`, `integration/`, and `embodied/` submit legal actions only — they do not directly mutate `GameState`.
- **Do not integrate `SpellCombatSession` into the macro economy loop.** Macro contact resolution is instant.
- Donor projects under `donor_projects/` are reference-only.

---

## Run D complete (v1 macro implementation)

Run D implemented and test-covered:

- Breach limit **10**; `TurnPhase` + turn lifecycle
- Macro contact resolution (`ContactResolutionRules`)
- Infection deck spread per `END_TURN`
- City demon occupation (suppression, timer, purge)
- Hero 4-action budget per turn
- Offer/accept trade v1 (`TradeOfferRules`)
- Drafting skeleton (`DraftRules` auto-pick)
- 2D play mode alignment + `phase` export column

See [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md) for status.

---

## Priority follow-ups (post–Run D)

| Priority | Work item | Why |
|---|---|---|
| 1 | **M22 hex click-to-build** | Keyboard play exists; hex selection is next UX step |
| 2 | **Dataset v2 + board featurizer** | Before serious macro RL |
| 3 | **Drafting human pick** | Replace auto-pick skeleton |
| 4 | **M26 divine instruction offers** | 3D/macro bridge when ready |
| 5 | **Legacy cleanup** | Deprecate `EncounterRules` / `PlayerTradeRules` paths |

---

## M22 — 2D human action selection (**deferred, not implemented**)

### Goal

Wire M14 human turn shell to 2D view: highlight legal build/move targets from `LegalActionQuery`, submit chosen `GameAction` through session API.

### Why it matters

First **playable** strategic experience: one human can actually play against bots on the board.

### Prerequisites (green)

- M14 human turn shell
- M18 read-only 2D board
- Session APIs for legal human actions

### Out of scope

- Drafting UI, 3D wizard embodiment, tactical combat in macro loop

**Suggested branch:** `milestone/2d-human-click-to-build`

---

## M26 — Divine instruction offer system (proposed, **not implemented**)

### Goal

Headless core bridge between future 3D wizard presentation and legal macro actions: deterministic **offer / accept / decline** flow that submits legal actions through session/rule APIs only.

### Why it matters

Lets embodied wizard UX propose macro choices without becoming a second source of truth. A wizard **cannot** directly move a hero; divine guidance advises macro actions only.

### Prerequisites

- M22 playable 2D loop (recommended)
- Macro contact resolution rules stable
- Stable encounter contracts before embodied integration

### Out of scope

- Full embodied wizard loop
- Full drafting
- Neural-network training in Godot
- Integrating spell combat into macro AI

**Suggested branch:** `milestone/divine-instruction-offers`

---

## Explicitly not next

- Integrating `SpellCombatSession` into macro hero/demon resolution
- Ports or Catan-style fixed trade ratios
- Full drafting system (until explicitly requested)
- Wizard marker → hero position binding
- Tactical combat UI in main macro loop
- Donor project merges
- Second parallel `GameState`
- Weakening architecture tests
- Neural network training inside Godot
- Merge to `main` without human PR review

See [PROJECT_STATUS.md](PROJECT_STATUS.md), [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md), and [AUTONOMOUS_SESSION_LOG.md](AUTONOMOUS_SESSION_LOG.md) for current state.
