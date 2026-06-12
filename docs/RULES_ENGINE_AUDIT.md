# Rules Engine Audit — Design vs Implementation

**Last updated:** 2026-06-12 (post–Run C design clarification)  
**Purpose:** Map intended v1 rules ([RULEBOOK.md](RULEBOOK.md)) to current headless implementation. Flags gaps without prescribing implementation in this pass.

---

## How to read this document

| Status | Meaning |
|---|---|
| **Implemented** | Rule exists in `godot_game/core/` with test coverage |
| **Partial** | Some behaviour exists but differs from design intent |
| **Stub** | Placeholder or minimal path only |
| **Not implemented** | No code path |
| **Legacy / debug** | Exists but not part of intended macro product loop |

---

## Terminology alignment

| Term | Implementation today | Design intent |
|---|---|---|
| Tactical combat | `SpellCombatSession` (isolated); `CombatResolver` card duel (legacy) | `SpellCombatSession` canonical; **not in macro loop** |
| Macro contact resolution | `EncounterRules` uses `CombatResolver` card duel | **Instant deterministic** removal — no spell combat |
| 3D human encounter | Placeholder embodied scripts; wizard marker cosmetic | Future layer; pauses game; may lead to tactical combat |
| Hero | Macro piece with persistent ID; one move = one action step | Generic macro piece; 4 actions/turn; removes all demons on contact |

---

## Win / loss

| Rule | Status | Notes |
|---|---|---|
| Win at 21 VP | **Implemented** | `GameConstants.VP_TO_WIN := 21` |
| Breach collective loss | **Partial** | Design target: breach at **10**; code: `BREACH_LIMIT := 7` — update `GameConstants` and breach tests when aligned |
| VP-only win | **Implemented** | No alternate win paths |

---

## Macro contact resolution (hero / demon)

| Rule | Status | Notes |
|---|---|---|
| Hero removes all demons on node | **Not implemented** | `MoveRules` / `_apply_move_hero` moves hero only; no demon clearance |
| Demon cannot coexist with hero on node | **Partial** | `MoveRules.can_move_hero` blocks moving **into** occupied hero node; no purge on arrival |
| Demon spawn onto hero node → demon removed | **Not implemented** | Spread skips hero nodes but does not remove demons that would land on heroes |
| No SpellCombatSession in macro AI | **Correct by omission** | Macro loop does not invoke spell combat |
| `EncounterRules.resolve_hero_vs_demon` | **Legacy / debug** | Uses `CombatResolver` card duel — **not** intended v1 macro rule |

---

## Heroes

| Rule | Status | Notes |
|---|---|---|
| Persistent hero IDs | **Implemented** | `Hero.id`, `heroes_by_id` |
| No leveling / equipment | **Implemented** | No level/equipment fields |
| 4 actions per hero per turn | **Not implemented** | Unlimited hero moves per turn today |
| Move to adjacent node | **Implemented** | `MoveRules.can_move_hero` |
| God commands via macro actions | **Implemented** | `MOVE_HERO` action kind |
| Development card hero modifiers | **Not implemented** | No drafting/modifiers |
| Wizard as macro piece | **Not implemented** | Wizard exists only in 3D presentation |
| Wizard cannot move hero | **N/A** | No wizard macro piece yet |

---

## Demons and spread

| Rule | Status | Notes |
|---|---|---|
| Max 3 demons per node | **Partial** | `OUTBREAK_THRESHOLD := 3` triggers breach when count **≥ 3** after spread; semantics differ from “4th causes breach without placing” |
| 4th demon → breach, not placed | **Partial** | Breach fires on nodes at threshold; spread adds demons without pre-check cap in all paths |
| Infection deck (Pandemic-style) | **Not implemented** | No deck of node locations |
| Spread end of each player turn | **Not implemented** | Spread at **round boundary** in `_apply_end_turn` |
| Infection rate draws per turn | **Not implemented** | Adjacent propagation from all demon nodes |
| No chain outbreaks v1 | **Implemented** | Single propagation pass |
| Age-based infection rate +1 | **Not implemented** | No age system |
| Deck reshuffle by age | **Not implemented** | No infection deck |

---

## Demon / city interaction

| Rule | Status | Notes |
|---|---|---|
| Demon on city → 0 production | **Not implemented / unverified** | Production rules do not check demon occupancy |
| Full round occupied → purge developments | **Not implemented** | No `city_demon_occupied_since_round` |
| Cannot build dev in occupied city | **Not implemented** | Stub development build ignores demon state |
| Timer reset on demon clear | **Not implemented** | |

---

## Turn and phase model

| Rule | Status | Notes |
|---|---|---|
| Multi-step turn until `END_TURN` | **Implemented** | `BotTurnResolver` loops; human session same pattern |
| Step-level legal masks | **Implemented** | `LegalActionQuery`, `ActionSpace` |
| `END_TURN` legal action | **Implemented** | |
| Formal phase enum | **Not implemented** | Overlay shows generic “Player turn” |
| Production at turn/round start | **Partial** | Production at round boundary only |
| Spread at end of each player turn | **Not implemented** | Round boundary only |

See [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md).

---

## Trading

| Rule | Status | Notes |
|---|---|---|
| No ports | **Correct** | No port concept in code |
| Offer/accept asymmetric trades | **Not implemented** | |
| Instant 1:1 player trade | **Implemented (provisional)** | `PlayerTradeRules`, fixed amount 1 |
| Bank trade 4:1 | **Implemented** | Separate from player trade design |
| One offer per target per turn dedup | **Not implemented** | |

---

## Development cards and drafting

| Rule | Status | Notes |
|---|---|---|
| Seven Wonders drafting | **Not implemented** | Explicitly deferred |
| Play dev card into city (stub) | **Stub** | Single stub card path |
| 3 slots per city | **Not implemented** | |
| 3 ages × 8 cards | **Not implemented** | |

---

## Tactical combat (`SpellCombatSession`)

| Rule | Status | Notes |
|---|---|---|
| Isolated spell combat simulation | **Implemented** | `SpellCombatSession`, replay/play modes |
| Micro telemetry export | **Implemented** | `micro_combat_v1` |
| Not in macro loop | **Correct** | Separate session authority |
| Legacy `CombatResolver` card duel | **Legacy / debug** | `run_headless_duel.gd`, `EncounterRules` |

---

## 3D wizard layer

| Rule | Status | Notes |
|---|---|---|
| Generated from macro state | **Partial** | `BoardWorldMapper`, read-only snapshot |
| Does not mutate GameState | **Enforced** | Architecture tests; WASD marker cosmetic |
| Encounter radius / pause | **Not implemented** | |
| Tactical combat in 3D | **Not in macro loop** | Playable micro mode is isolated |

---

## Neural training / export

| Rule | Status | Notes |
|---|---|---|
| Macro export partial | **Implemented** | `macro_training_v1` — not production RL-ready |
| Full global state observation (design) | **Not implemented** | Aggregate scalars only |
| Dataset v2 schema | **Not implemented** | Documented in NTD audit |
| No NN training in Godot | **Correct** | Export only |

See [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md).

---

## Priority implementation gaps (for next coding run)

1. Macro contact resolution — instant demon removal on hero enter; no `CombatResolver` in macro path  
2. Demon spread — infection deck, per-player-turn timing, cap-at-3 / breach-on-4th semantics  
3. City demon occupation — production suppression, timer, development purge  
4. Hero action budget — 4 actions per hero per turn  
5. Player trade — offer/accept model replacing provisional 1:1  
6. Turn phase enum and production/spread timing alignment  
7. Drafting session (when explicitly scheduled)  

---

## Related docs

- [RULEBOOK.md](RULEBOOK.md)  
- [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md)  
- [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md)  
- [RULES_ENFORCEMENT_TEST_MATRIX.md](RULES_ENFORCEMENT_TEST_MATRIX.md)  
- [PROJECT_STATUS.md](PROJECT_STATUS.md)  
