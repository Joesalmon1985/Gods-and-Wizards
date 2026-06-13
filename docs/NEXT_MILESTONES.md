# Next Milestones (Proposed)

**Last updated:** 2026-06-13 (post–Run K)

**Strategic direction:** Macro-first, trainable mythic civilisation simulation. One authoritative `GameState`. Headless core and `BotGameSession` are source of truth. **Near-term dev default:** 2D strategic playable/debug. **Long-term product default:** 3D wizard spectator/RPG. See [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md) and [RULEBOOK.md](RULEBOOK.md).

---

## Run K complete (rules + training foundation)

Branch `milestone/run-k-rules-training-completion`:

- K0 breach cascade neighbor spread + contract tests
- K0B hero movement / demon-clearing contracts
- K2 audit CSV export; K3 micro spell fidelity; K4 macro board featurizer
- K5 `training/` PyTorch BC package; **Route B** live Godot eval
- K9 smoke: 10 macro + 20 micro train episodes; 5 + 10 held-out live evals
- **121 modules, ~165,649 assertions, exit 0** — see [RUN_K_RULES_TRAINING_COMPLETION.md](RUN_K_RULES_TRAINING_COMPLETION.md)

---

## Run H complete (rules / card / spell fidelity)

Branch `milestone/run-h-rules-card-spell-fidelity`:

- Macro: Underworld Surge, hero clash, turn-start production, trade offer expiry
- Cards: four stub effect types implemented; validator honesty
- Spells: prioritised status engine; [MICRO_SPELL_EFFECT_FIDELITY_MATRIX.md](MICRO_SPELL_EFFECT_FIDELITY_MATRIX.md)
- **110 modules, 151,318 assertions, exit 0** — pause for human review before merge

---

## Run I (docs-only — 3D / UI / product planning)

Branch `milestone/run-i-3d-ui-ux-product-planning` — implementation-ready specs I0–I14; future Impl I1–I7 in [IMPLEMENTATION_PLAN_3D_UI.md](IMPLEMENTATION_PLAN_3D_UI.md).

---

## Run G complete (game completion gate + training suites)

Run G on branch `milestone/run-g-game-completion-training-suites`:

- G1–G3 completion audits (macro, card economy, micro combat)
- G4 training-readiness gate: **`GO_FOR_TRAINING`**
- G5–G6 training env contracts + tests
- G8 baseline evaluation harness; G9–G11 NN prototypes (`TinyNeuralNetwork`, BC trainers)
- G12 export schema v2; G13 PowerShell scripts

See [RUN_G_PLAN.md](RUN_G_PLAN.md), [AUTONOMOUS_SESSION_LOG.md](AUTONOMOUS_SESSION_LOG.md).

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

## Run E complete (card economy vertical slice)

Run E on branch `milestone/run-e-card-economy` implemented:

- 96-card JSON catalogue + validator + generic effect engine
- Full Seven Wonders drafting (`DRAFT_PICK`, bot/human session flow)
- 2D play draft/hand/slot view models + board slot indicators
- 3D wizard slice: WASD, Q/E yaw, board/wizard camera toggle, encounter proximity prompt
- `SpellEncounterBridge` macro → tactical → macro prototype
- `TinyPolicy` + `MacroRlTrainer` headless RL prototype
- Telemetry schema `macro_training_v2` (additive columns)
- Windows export prototype docs/script

## Priority follow-ups (post–Run E)

| Priority | Work item | Why |
|---|---|---|
| 1 | **M22 hex click-to-build** | Keyboard play exists; hex selection is next UX step |
| 2 | **Board featurizer for RL** | v2 telemetry exists; featurizer still needed |
| 3 | **Integrate encounter bridge in 3D play** | Bridge is core-tested; embodied submit path deferred |
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
