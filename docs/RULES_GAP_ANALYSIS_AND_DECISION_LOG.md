# Rules Gap Analysis and Decision Log

**Last updated:** 2026-06-12 (post–Run D v1 macro implementation)  
**Purpose:** Record known gaps between design intent and current implementation, with explicit decisions and follow-ups. Prefixes: **NTD-** = neural training data; **INT-** = integration; **GD-** = game design (Run C clarification).

---

## How to use this log

| Column | Meaning |
|---|---|
| **ID** | Stable decision reference |
| **Area** | Subsystem |
| **Gap** | What is missing or provisional |
| **Decision** | What we chose to do (for now) |
| **Date** | When logged |
| **Rationale** | Why |
| **Follow-up** | Future milestone or schema work |

Authoritative design rules: [RULEBOOK.md](RULEBOOK.md). Implementation status: [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md).

---

## Game design decisions (Run C clarification)

| ID | Area | Gap | Decision | Date | Rationale | Follow-up |
|---|---|---|---|---|---|---|
| **GD-001** | Macro vs tactical | Risk of integrating spell combat into macro loop | **Do not integrate** `SpellCombatSession` into macro economy; macro hero/demon = instant contact resolution | 2026-06-12 | Tactical combat is for 3D human encounters and isolated sim modes | Implement instant demon removal in macro rules |
| **GD-002** | Macro contact | Hero/demon coexistence unclear in code | **v1:** hero removes **all** demons on node immediately; demon cannot remain on hero node | 2026-06-12 | Pandemic-style containment without RPG combat | **Done (Run D)** — `ContactResolutionRules` |
| **GD-003** | Demons | Spread model differs from Pandemic design | **v1 intent:** infection deck, draw `infection_rate` nodes per player turn, cap 3, 4th → breach | 2026-06-12 | Design clarity for balancing | Replace adjacent spread; per-player-turn timing |
| **GD-004** | Cities / demons | No occupation timer or dev purge | **v1 intent:** demon > 0 suppresses production; full round occupied purges developments | 2026-06-12 | Underworld threatens civilisation growth | Track `city_demon_occupied_since_round` |
| **GD-005** | Heroes | No action budget | **v1:** 4 actions per hero per turn default | 2026-06-12 | Limits hero mobility per turn | Hero action counter in `GameState` |
| **GD-006** | Turn model | Docs implied one action per turn | **Multi-step turn** until `END_TURN`; each build/trade/hero move = one legal step | 2026-06-12 | RL masks and human UX | Phase enum; align production/spread timing |
| **GD-007** | Trading | Instant 1:1 in code vs design | **Offer/accept only**; no ports; asymmetric ratios; provisional 1:1 kept until replaced | 2026-06-12 | Catan ports not planned | New trade session + action kinds |
| **GD-008** | Drafting | Not implemented | **Seven Wonders-style** at round end; 8 cards × 3 ages; passed pack terminology | 2026-06-12 | Explicit deferral with documented intent | Drafting milestone when requested |
| **GD-009** | 3D layer | Risk of 3D owning state | **3D reads macro state; submits via APIs only**; long-term default product mode | 2026-06-12 | Architecture rule | Encounter radius + pause deferred |
| **GD-010** | Win condition | — | **VP-only win at 21**; collective breach loss at **10** | 2026-06-12 | Aligns with `GameConstants.VP_TO_WIN` | **Done (Run D)** — `BREACH_LIMIT := 10` |
| **GD-011** | Legacy combat | `EncounterRules` uses card duel | **Legacy/debug**; not v1 macro resolution; `SpellCombatSession` is canonical tactical model | 2026-06-12 | Terminology clarity | Deprecate or rewrite `EncounterRules` |
| **GD-012** | Macro RL observation | Export is active-player aggregates | **Design target:** full global state for macro RL | 2026-06-12 | Multi-agent centralized training | Dataset v2 + board featurizer |
| **GD-013** | Infection surge | Simple discard reshuffle only | **Underworld Surge** after each player END: Age I 0%, II 10%, III 20% (`roll_d10`); emit `UnderworldSurgeEvent` | 2026-06-12 | RC-B-007 Run H | `TestRuleContractInfectionSurge` |
| **GD-014** | Hero stacking | All nodes blocked for heroes | **Friendly deny; hostile clash** removes both heroes; `HeroClashEvent` | 2026-06-12 | RC-C-004 Run H | `TestRuleContractHeroStacking` |
| **GD-015** | Dev in occupied city | Build blocked; ambiguous | **Cannot build** new development while demons > 0 on city vertex | 2026-06-12 | RC-D-006 Run H | `TestRuleContractOccupiedDevelopment` |
| **GD-016** | Production timing | Round-wrap production | **Active-player turn-start** production (`PRODUCTION` phase); only active player's cities | 2026-06-12 | RC-F-005 Run H | `TestRuleContractProductionTiming` |
| **GD-017** | Trade offer persistence | Cross-turn until accept | **Expire after full player cycle** (turn-age ≥ player count); see RUN_H_RULE_DECISIONS §5 | 2026-06-12 | RC-G-007 Run H | `TestRuleContractTrading` |

---

## Unresolved design questions (flagged, not decided)

| Area | Question |
|---|---|
| Hero stacking | Can multiple friendly heroes occupy one node? |
| Wizard/hero contact | Same-owner wizard and hero on same node — what happens? |
| Hero vs hero | Enemy hero vs enemy hero contact resolution? |
| Wizard vs hero | Enemy wizard vs hero — always remove demons/heroes? |
| City dev while occupied | Can demon-occupied cities receive new development cards? |
| Development costs | Final resource costs and slot replacement rules? |
| Infection reshuffle | Exact age-by-age reshuffle probabilities for infection discard? |
| Initial infection rate | Confirm initial `infection_rate` (probably 2)? |
| Production timing | Per-player turn start vs round boundary? |
| Macro/3D timing | AI wizard/hero movement animation between macro turns? |
| Trade action bounds | Hard cap on distinct offers per turn for RL action space? |

---

## Neural training data (Run C)

| ID | Area | Gap | Decision | Date | Rationale | Follow-up |
|---|---|---|---|---|---|---|
| **NTD-001** | Training infrastructure | No in-engine or bundled NN training | **Defer** all NN training to external pipelines; headless CSV telemetry is the contract boundary | 2026-06-12 | Architecture rule: core is deterministic rules engine; UI and ML are consumers | Audit only until explicit milestone for dataset v2 |
| **NTD-002** | Macro rewards | VP delta + terminal +10 is provisional | **Keep provisional** reward in `MacroTrainingEnv`; document reward profiles in audit | 2026-06-12 | No design sign-off on strategic reward shaping | Implement `WinMaxAgent`, `VPAgent`, etc. in export v2 |
| **NTD-003** | Episode identity | No `episode_id` in v1 schemas | **Accept composite keys** until v2: macro `(seed, policy_name, step_index)`; tactical `(seed, loadout_a, loadout_b, step_index)` | 2026-06-12 | v1 schemas shipped without UUID; adding column is breaking change | Schema v2 with `episode_id` |
| **NTD-004** | Macro observation | No board topology / hero / demon map in export | **Keep aggregate observation** until board encoding spec exists; **design target is full global state** | 2026-06-12 | Full hex featurizer is large scope | Board featurizer design doc + dataset v2 |
| **NTD-005** | Tactical pass action | `__pass__` outside `legal_mask_json` | **Keep pass implicit**; IL/RL consumers treat pass as extra action or parse `selected_spell_id` | 2026-06-12 | Mask is loadout-sized only; pass is global fallback | v2: `pass_legal` column or extended mask |
| **NTD-006** | Macro–tactical linkage | Datasets are independent files | **Do not merge** macro and tactical CSVs; macro uses instant contact resolution, not spell combat | 2026-06-12 | Different action spaces, row grains, observation shapes | 3D encounter milestone for join keys |
| **NTD-007** | Provenance | No rules version, catalog version, or commit SHA in CSV | **Defer to schema v2** metadata row or sidecar manifest | 2026-06-12 | Exporters focus on step rows; provenance needs build-time injection | CI step to stamp exports |
| **NTD-008** | Export source of truth | Multiple CSV exporters exist | **`MacroTrainingTelemetryExporter` and `MicroCombatTelemetryExporter` only** are NN telemetry sources; `PlaythroughCsvExporter` and `DuelLogExporter` are debug/legacy | 2026-06-12 | Wrong grain, no masks, or wrong combat model | Document in audit and test matrix |
| **NTD-009** | Macro action parameters | CSV has action ID + kind, not vertex/edge/hero | **Consumers must decode** via `ActionSpace.to_layout_key()` for fixed board radius | 2026-06-12 | Full parameter export would widen schema significantly | Export `action_space_layout_key` in v2 |
| **NTD-010** | Tactical terminal outcome | `winner_id` column is pre-step; empty on last row | **Parse `timeline_event_summary`** for `combat_end` until post-step column added | 2026-06-12 | Exporter captures obs before step | v2: post-step `winner_id` or structured events |
| **NTD-011** | Export policy | Only bot/deterministic policy during export | **Accept for v1**; human trajectories need separate collection path | 2026-06-12 | Human macro UI not complete; tactical export hardcodes policy | Human play logging milestone |
| **NTD-012** | Classification honesty | Risk of overstating ML readiness | **Classify macro as Partial, tactical as Mostly Ready/Partial**; v1 is prototyping only | 2026-06-12 | Telemetry ≠ production dataset | Re-audit after schema v2 |

---

## Integration and rules (existing context)

| ID | Area | Gap | Decision | Date | Rationale | Follow-up |
|---|---|---|---|---|---|---|
| **INT-001** | Macro–tactical runtime | No spell combat in macro loop | Macro AI uses instant contact resolution; tactical combat isolated | 2026-06-12 | GD-001 design decision | Instant demon removal rules |
| **INT-002** | Card duel vs spell combat | Two combat models in codebase | **SpellCombatSession** is canonical tactical model; **CombatResolver** card duel is legacy/debug | 2026-06-12 | M7 card contract vs spell session | Docs + eventual code deprecation |
| **INT-003** | EncounterBridge | Uses card duel for hero vs demon | **Not intended v1 macro behaviour**; bridge deferred until 3D encounters | 2026-06-12 | Macro contact is instant, not tactical | Rewrite or bypass for macro path |

---

## Open gaps (no decision yet)

| Area | Gap | Notes |
|---|---|---|
| Macro multi-agent RL | Only active player POV per row | Design target is full global state — see GD-012 |
| Reward design | Both macro and tactical use interim shaping | Reward profiles documented; values need design approval |
| Batch datasets | Single episode per CLI run | Needs runner + manifest for large-scale ML |
| LOCAL_VERIFICATION | §4 checklist omits macro/micro CSV success checks | Doc drift flagged in audit |
| Phase enum | No fine-grained phase in `GameState` | Needed for UI and telemetry `phase` column |

---

## Related docs

- [RULEBOOK.md](RULEBOOK.md) — intended v1 rules
- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md) — design vs implementation
- [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md) — multi-step turns
- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md) — detailed readiness assessment
- [RULES_ENFORCEMENT_TEST_MATRIX.md](RULES_ENFORCEMENT_TEST_MATRIX.md) — test coverage and gaps
- [MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md) — target dataset relationship
- [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md) — explicit deferral of NN training in-engine
