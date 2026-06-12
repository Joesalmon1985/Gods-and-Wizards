# Rules Engine Audit — Design vs Implementation

**Last updated:** 2026-06-12 (post–Run D v1 macro implementation)  
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
| Breach collective loss | **Implemented** | `BREACH_LIMIT := 10`; `BreachEndCondition` uses `BalanceConfig.breach_limit()` |
| VP-only win | **Implemented** | No alternate win paths |

---

## Macro contact resolution (hero / demon)

| Rule | Status | Notes |
|---|---|---|
| Hero removes all demons on node | **Implemented** | `ContactResolutionRules` via `_apply_move_hero` |
| Demon cannot coexist with hero on node | **Implemented** | Instant clearance on hero enter and post-placement hook |
| Demon spawn onto hero node → demon removed | **Implemented** | Infection placement calls contact resolution |
| No SpellCombatSession in macro AI | **Correct by omission** | Macro loop does not invoke spell combat |
| `EncounterRules.resolve_hero_vs_demon` | **Legacy / debug** | Uses `CombatResolver` card duel — **not** intended v1 macro rule |

---

## Heroes

| Rule | Status | Notes |
|---|---|---|
| Persistent hero IDs | **Implemented** | `Hero.id`, `heroes_by_id` |
| No leveling / equipment | **Implemented** | No level/equipment fields |
| 4 actions per hero per turn | **Implemented** | `hero_actions_remaining`; `GameConstants.HERO_ACTIONS_PER_TURN` |
| Move to adjacent node | **Implemented** | `MoveRules.can_move_hero` |
| God commands via macro actions | **Implemented** | `MOVE_HERO` action kind |
| Development card hero modifiers | **Not implemented** | No drafting/modifiers |
| Wizard as macro piece | **Not implemented** | Wizard exists only in 3D presentation |
| Wizard cannot move hero | **N/A** | No wizard macro piece yet |

---

## Demons and spread

| Rule | Status | Notes |
|---|---|---|
| Max 3 demons per node | **Implemented** | `SpreadRules.MAX_DEMONS_PER_NODE := 3` |
| 4th demon → breach, not placed | **Implemented** | `try_add_demon` increments breach, no placement |
| Infection deck (Pandemic-style) | **Implemented** | `infection_draw_pile` / discard; seeded shuffle |
| Spread end of each player turn | **Implemented** | `SpreadRules.resolve_player_turn_end` on each `END_TURN` |
| Infection rate draws per turn | **Implemented** | Initial rate **2**; `state.infection_rate` |
| No chain outbreaks v1 | **Implemented** | Single draw pass per turn |
| Age-based infection rate +1 | **Partial** | `DraftRules._advance_age` increments rate; age-reshuffle probabilities stubbed |
| Deck reshuffle by age | **Partial** | Simple discard reshuffle; age-weighted reshuffle deferred |

---

## Demon / city interaction

| Rule | Status | Notes |
|---|---|---|
| Demon on city → 0 production | **Implemented** | `CityOccupationRules.is_city_suppressed` in `ProductionRules` |
| Full round occupied → purge developments | **Implemented** | `city_demon_occupied_since_round`; `evaluate_round_start_purges` |
| Cannot build dev in occupied city | **Implemented** | `DevelopmentRules.can_build` blocks |
| Timer reset on demon clear | **Implemented** | `SetupRules.set_demon_count` → `on_demon_count_changed` |

---

## Turn and phase model

| Rule | Status | Notes |
|---|---|---|
| Multi-step turn until `END_TURN` | **Implemented** | `BotTurnResolver` loops; human session same pattern |
| Step-level legal masks | **Implemented** | `LegalActionQuery`, `ActionSpace` |
| `END_TURN` legal action | **Implemented** | |
| Formal phase enum | **Implemented** | `TurnPhase`; `GameState.current_phase` |
| Production at turn/round start | **Partial** | Production at round boundary only (unchanged v1) |
| Spread at end of each player turn | **Implemented** | Infection draw per `END_TURN` |

See [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md).

---

## Trading

| Rule | Status | Notes |
|---|---|---|
| No ports | **Correct** | No port concept in code |
| Offer/accept asymmetric trades | **Implemented** | `TradeOfferRules`; amounts 1–3 per side |
| Instant 1:1 player trade | **Deprecated** | `PLAYER_TRADE` illegal; `PlayerTradeRules` legacy |
| Bank trade 4:1 | **Implemented** | Unchanged |
| One offer per target per turn dedup | **Implemented** | `trade_offers_made_this_turn` signatures |

---

## Development cards and drafting

| Rule | Status | Notes |
|---|---|---|
| Seven Wonders drafting | **Partial (skeleton)** | `DraftRules`; auto-pick at round end; pass-left packs |
| Play dev card from hand | **Implemented** | `DevelopmentRules`; hand required |
| 3 slots per city | **Implemented** | `city.developments` max 3 |
| 3 ages × 8 cards | **Partial** | Age advance after 8 draft rounds; full human pick UI deferred |

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
| Macro export partial | **Implemented** | `macro_training_v1` + `phase` column — not production RL-ready |
| Full global state observation (design) | **Not implemented** | Aggregate scalars only |
| Dataset v2 schema | **Not implemented** | Documented in NTD audit |
| No NN training in Godot | **Correct** | Export only |

See [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md).

---

## Priority implementation gaps (post–Run D)

1. M22 hex click-to-build human UI (keyboard play mode exists)  
2. Dataset v2 schema + board featurizer  
3. Drafting human pick actions (replace auto-pick skeleton)  
4. Age-weighted infection deck reshuffle probabilities  
5. Deprecate/remove legacy `EncounterRules` / `PlayerTradeRules` code paths  
6. Production timing per-player vs round boundary (design TBD)  

---

## Related docs

- [RULEBOOK.md](RULEBOOK.md)  
- [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md)  
- [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md)  
- [RULES_ENFORCEMENT_TEST_MATRIX.md](RULES_ENFORCEMENT_TEST_MATRIX.md)  
- [PROJECT_STATUS.md](PROJECT_STATUS.md)  
