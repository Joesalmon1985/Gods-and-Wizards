# Turn Timing and Phase Model

**Last updated:** 2026-06-12 (post–Run C design clarification)  
**Purpose:** Formal model for macro turn structure, action granularity, and implications for bots, human UI, and RL legal masks.

---

## Core principle

A **macro turn** is a **multi-step active-player turn**, not a single action. The active player may take multiple legal actions (trades, builds, hero moves) before explicitly ending the turn with `END_TURN`.

This differs from a naive “one action per turn” model. The rules engine should eventually expose **step-level** legal actions while grouping them under one player turn for production, spread, and drafting timing.

---

## Intended turn sequence

For each active player turn:

| Step | Phase | Description |
|---|---|---|
| 1 | **Start turn** | Active player becomes current; turn-scoped counters reset (e.g. hero action budgets, trade-offer dedup) |
| 2 | **Victory / breach check** | Evaluate win/loss; if terminal, stop |
| 3 | **Production** | Resolve resource production for this player or round (see timing note below) |
| 4 | **Trade phase** | Active player may offer trades; partners accept/reject (intended offer/accept model) |
| 5 | **Build / develop** | Build roads, cities, play development cards from hand |
| 6 | **Hero command** | Move heroes (and god-AI wizards); macro contact resolution on demon nodes |
| 7 | **Optional end turn** | `END_TURN` is always a legal action when the player chooses to stop |
| 8 | **Demon spread** | Draw from infection deck; place demons or increment breach — **end of this player's turn** |
| 9 | **End-turn cleanup** | Reset per-turn flags; advance turn counter |
| 10 | **Next player** | Pass active player to next in order |

Steps 4–7 repeat as many times as the player wishes before step 7 (`END_TURN`).

---

## Action granularity (RL and legal masks)

Each of the following should be an **individual legal action step**:

- Each trade offer (or accept/reject response — TBD in offer/accept design)
- Each build road
- Each build city
- Each development card play
- Each hero move (consumes 1 hero action from that hero's budget)
- `END_TURN`

**Implications:**

- Legal action mask size grows with board state but remains finite per step.
- Bots and RL agents choose one action per `step()` call, not one action per turn.
- Unlimited builds/trades within a turn are allowed, bounded by resources and legality.
- `END_TURN` must appear in the legal mask whenever the player may stop.

---

## Hero action budget (per turn)

- Each hero has **4 actions** by default per active-player turn.
- Each adjacent node move costs **1 action**.
- Development cards may later modify per-hero action counts.
- When a hero's budget is exhausted, hero move actions for that hero are illegal until next turn.
- Heroes are **not** controlled like the human wizard in 3D.

**Current implementation gap:** no per-hero action budget tracked in `GameState`.

---

## Production timing

**Design intent (to confirm):** Production may occur at start of active player turn (step 3) or at round boundary depending on final Catan-style alignment.

**Current implementation:** Production runs when `active_player_index` wraps to 0 (start of new round) inside `_apply_end_turn`, not at each player turn start.

---

## Demon spread timing

**Design intent:** Demon spread (infection deck draw) happens at **end of each player's turn** (step 8).

**Current implementation:** Spread runs at **round boundary** (when player index wraps to 0), via adjacent-node propagation, not infection deck.

---

## Drafting timing (intended, not implemented)

- Drafting occurs at end of each **full table round** (after every player has completed a turn).
- See [RULEBOOK.md](RULEBOOK.md) § Development cards and drafting.

---

## Phase enum (future)

`GameState` does not yet expose a fine-grained phase enum. Future work should add explicit phases (e.g. `TRADE`, `BUILD`, `HERO`, `END_TURN_PENDING`) for UI overlay and telemetry `phase` column.

---

## Current vs intended summary

| Aspect | Intended | Current code |
|---|---|---|
| Multi-step turn | Yes — loop until `END_TURN` | **Partial** — `BotTurnResolver` loops until `END_TURN` |
| Step-level legal mask | Each action is one step | **Yes** — one mask per action in bot loop |
| `END_TURN` action | Explicit end of turn | **Yes** |
| Production timing | TBD — likely per player or round start | **Round boundary only** |
| Demon spread timing | End of each player turn | **Round boundary only** |
| Hero action budget | 4 per hero per turn | **Not implemented** |
| Phase enum in state | Yes | **Not implemented** |

---

## RL / training implications

- Export row grain = **one policy step** (one legal action), not one full player turn.
- Multiple rows may share the same `turn_number` before `END_TURN`.
- Telemetry should include `phase` and `action_kind` per step.
- Multi-step turn model may require action-space and session API updates — see [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md).

---

## Related docs

- [RULEBOOK.md](RULEBOOK.md)  
- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md)  
- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md)  
