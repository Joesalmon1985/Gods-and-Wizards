# Next Milestones (Proposed)

**Not implemented.** This document proposes the next 3–5 milestones for human review.

**Strategic direction:** Macro-first, trainable mythic civilisation simulation. One authoritative `GameState`. Headless core and `BotGameSession` are source of truth. **2D strategic mode** supports debug/training/balancing; **3D wizard mode** is a deferred presentation layer. See [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md).

---

## M14 — Human player turn shell (1 human + 3 bots) — **COMPLETE**

Implemented on `milestone/macro-foundation-autonomous`: `start_one_human_three_bots`, `get_legal_human_actions`, `submit_human_action`, `TestHumanPlayerSession`.

---

### Goal

Introduce a human-controlled seat in the shared simulation: when it is the human’s turn, the game pauses bot resolution and waits for a **legal action** submitted through a session API (not direct `GameState` edits).

### Why it matters

Proves the architecture supports real interaction without forking state. Unblocks every future UI mode (2D, 3D, debug).

### Files likely to change

- `godot_game/core/sim/bot_game_session.gd` (or adjacent session controller)
- `godot_game/core/bots/bot_turn_resolver.gd`
- `godot_game/core/scenarios/scenario_builder.gd` (human + 3 bot scenario)
- `godot_game/tests/test_bot_simulation.gd` or new `test_human_player_session.gd`

### Tests first

- Human seat receives turn without bot auto-acting
- Illegal actions rejected; legal actions produce same events as `ActionRules.apply`
- Same seed + same human action sequence → deterministic event log
- Bots still resolve normally on non-human turns

### Acceptance criteria

- Headless test can simulate one human `BUILD_ROAD` or `END_TURN` via session API
- No UI required for milestone completion
- Full test suite passes
- 3D wizard-world mode unchanged or explicitly still bot-only until M15/M16 wires it

### Out of scope

- Clickable 2D board
- Drafting, new rules, combat UI
- Wizard marker affecting state

---

## M15 — 2D board state view (read-only)

### Goal

Add a 2D strategic view of the hex board: nodes, edges, cities, roads, resources overlay hooks, and the existing reporting/scoreboard — **read-only**, driven from `GameState` / `GameStateSummary`.

### Why it matters

2D is faster to iterate than 3D for understanding production, building, and threat spread. Makes the simulation legible during human play.

### Files likely to change

- `godot_game/ui/board/` (new 2D view scripts/scenes)
- `godot_game/integration/board_world_mapper.gd` (reuse or extend snapshots)
- `godot_game/run_modes/` (optional new run mode scene, or tab/mode switch)
- `godot_game/tests/test_board_visualization.gd` or new `test_board_2d_view.gd`

### Tests first

- 2D layer does not call `SetupRules`, `ActionRules`, or mutate arrays on `GameState`
- Snapshot/renderer deterministic for same state
- Cities/roads/hex keys match core topology IDs
- Architecture scan passes for new UI files

### Acceptance criteria

- Launchable scene shows current `BotGameSession` state for 4-player scenario
- Scoreboard and turn summary visible (reuse `core/reporting/`)
- Enter/N or shared session advance still works if combined with wizard/headless patterns
- Full test suite passes

### Out of scope

- Human click-to-build (M16)
- Animations, art polish
- Embodied wizard integration

---

## M16 — 2D human action selection

### Goal

Wire M14 human turn shell to M15 2D view: highlight legal build/move targets, show affordances from `LegalActionQuery`, submit chosen `GameAction` through session API.

### Why it matters

First **playable** strategic experience: one human can actually play against bots on the board.

### Files likely to change

- `godot_game/ui/board/` (input, highlights, action panel)
- `godot_game/core/sim/` (session pending-action state if needed)
- `godot_game/run_modes/` (2D-first main scene or mode selector)
- `godot_game/tests/test_legal_actions.gd`, new UI boundary tests

### Tests first

- Click/selection maps to correct `GameAction` payload
- UI never calls rule functions except via session submit
- Human build road/city/end turn updates state identically to headless path
- Illegal targets not submit-able

### Acceptance criteria

- Play 1 human + 3 bots to completion or turn limit from 2D mode
- Overlay shows human vs bot turns clearly
- Full test suite passes

### Out of scope

- Drafting UI
- Hero/demon manual control (unless already legal in core and trivial to expose)
- 3D wizard embodiment

---

## M17 — Unified run mode entry (2D primary, 3D observatory)

### Goal

Single entry point that defaults to **2D playable mode** and offers **3D wizard-world as observatory** (same `BotGameSession`, switch views without duplicate state).

### Why it matters

Reduces confusion between F5 main scene, debug overlay, and headless CSV. One session, multiple lenses.

### Files likely to change

- `godot_game/project.godot` (main scene)
- `godot_game/run_modes/`
- `godot_game/docs/run_modes.md`
- `godot_game/tests/test_run_modes.gd`

### Tests first

- Only one `GameState` instance per session when switching views
- View switch does not replay or reset seed unless requested
- Architecture tests still pass

### Acceptance criteria

- F5 launches 2D human+bot experience (after M16)
- Optional key/menu opens 3D observatory of same session
- Headless CSV mode unchanged
- Documented in `run_modes.md`

### Out of scope

- Networking, save/load
- Full embodied combat

---

## M18 — Scenario and balance tooling (optional sim milestone)

### Goal

Headless batch runner for balance experiments: N seeds, summary stats (game length, VP spread, breach rate, resource totals), CSV or JSON aggregate output.

### Why it matters

Supports design iteration before adding more gameplay systems.

### Files likely to change

- `godot_game/core/sim/`
- `godot_game/core/export/`
- `godot_game/run_modes/run_batch_sim.gd` (new)
- `godot_game/tests/test_bot_simulation.gd`

### Tests first

- Batch run deterministic per seed
- Summary metrics match known fixture games
- No mutation of core rules

### Acceptance criteria

- One headless command runs 100 seeds and writes summary file
- Full test suite passes

### Out of scope

- Neural network training
- In-editor charts/GUI

---

## M19 — Macro training environment skeleton

### Goal

Headless wrapper around `BotGameSession` exposing `reset`, `observe`, `legal_actions`, and `step` for future RL/bot training — **not** in-engine neural networks.

### Acceptance criteria

- Deterministic observations for same seed
- Illegal steps rejected without mutation
- Bot-only and human-wait modes supported via existing session API
- Full test suite passes

---

## M20 — Batch balance runner + config skeleton

### Goal

Headless N-seed runner with aggregate summary (game length, VP spread, breach rate, build counts). Optional `BalanceConfig` JSON skeleton with defaults matching `GameConstants`.

### Acceptance criteria

- One headless command runs multiple seeds and writes summary JSON/CSV
- Default balance config does not change gameplay
- Full test suite passes

---

## Priority recommendation

| Order | Milestone | Rationale |
|---|---|---|
| 1 | **M14** Human turn shell | Core interaction contract — **done** |
| 2 | **M19** Macro training env | Training/balance foundation |
| 3 | **M20** Batch balance + config | Design iteration tooling |
| 4 | **M15** 2D read-only board | Understandability |
| 5 | **M16** 2D human actions | First playable loop |
| 6 | **M17** Unified entry | UX coherence |
| 7 | **M18** Extended balance tooling | Optional extensions |

---

## Explicitly not next

- Full drafting system
- Wizard marker → hero position binding
- Combat UI in main loop
- Donor project merges
- Second parallel `GameState`
- Weakening architecture tests

See [PROJECT_STATUS.md](PROJECT_STATUS.md) for what already exists.
