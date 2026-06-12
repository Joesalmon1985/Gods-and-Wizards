# Next Milestones (Proposed)

**Last updated:** 2026-06-12 (post–Run C design clarification)

**Strategic direction:** Macro-first, trainable mythic civilisation simulation. One authoritative `GameState`. Headless core and `BotGameSession` are source of truth. **Near-term dev default:** 2D strategic playable/debug. **Long-term product default:** 3D wizard spectator/RPG. See [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md) and [RULEBOOK.md](RULEBOOK.md).

**Architecture constraints (all milestones):**

- One authoritative `GameState`; no second state machine.
- Core is headless; no UI in `godot_game/core/`.
- UI, `run_modes/`, `integration/`, and `embodied/` submit legal actions only — they do not directly mutate `GameState`.
- **Do not integrate `SpellCombatSession` into the macro economy loop.** Macro contact resolution is instant.
- Donor projects under `donor_projects/` are reference-only.

---

## Run C complete (documentation only)

Run C captured design decisions in:

- [RULEBOOK.md](RULEBOOK.md)
- [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md)
- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md)
- Updated gap/decision log, test matrix, neural export audit, macro/tactical integration design

No gameplay code, tests, or scenes were changed in Run C.

---

## Priority implementation follow-ups (next coding run)

Suggested order based on [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md):

| Priority | Work item | Why |
|---|---|---|
| 1 | **Macro contact resolution** — hero removes all demons on enter | Core v1 underworld containment; replaces legacy card duel in macro path |
| 2 | **Infection deck spread** — per-player-turn, cap 3, breach on 4th | Aligns demon threat with Pandemic-style design |
| 3 | **City demon occupation** — production suppression, timer, dev purge | Connects underworld to economy |
| 4 | **Hero action budget** — 4 actions per hero per turn | Turn model completeness |
| 5 | **Offer/accept trading** — replace provisional 1:1 | Design-aligned trade model; no ports |
| 6 | **Phase enum + turn timing alignment** | Production/spread timing; telemetry `phase` column |
| 7 | **Dataset v2 schema + board featurizer spec** | Before serious macro RL (not NN training in Godot) |
| 8 | **2D human action selection (M22)** | First playable macro loop for humans |
| 9 | **Drafting session** | When explicitly scheduled — Seven Wonders-style at round end |

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
