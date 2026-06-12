# Rules Gap Analysis and Decision Log

**Last updated:** 2026-06-12  
**Purpose:** Record known gaps between design intent and current implementation, with explicit decisions and follow-ups. Run C neural-training-data entries use prefix **NTD-**.

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

---

## Neural training data (Run C)

| ID | Area | Gap | Decision | Date | Rationale | Follow-up |
|---|---|---|---|---|---|---|
| **NTD-001** | Training infrastructure | No in-engine or bundled NN training | **Defer** all NN training to external pipelines; headless CSV telemetry is the contract boundary | 2026-06-12 | Architecture rule: core is deterministic rules engine; UI and ML are consumers | Audit only until explicit milestone for dataset v2 |
| **NTD-002** | Macro rewards | VP delta + terminal +10 is provisional | **Keep provisional** reward in `MacroTrainingEnv`; document in export audit | 2026-06-12 | No design sign-off on strategic reward shaping | Game design review before RL experiments |
| **NTD-003** | Episode identity | No `episode_id` in v1 schemas | **Accept composite keys** until v2: macro `(seed, policy_name, step_index)`; micro `(seed, loadout_a, loadout_b, step_index)` | 2026-06-12 | v1 schemas shipped without UUID; adding column is breaking change | Schema v2 with `episode_id` |
| **NTD-004** | Macro observation | No board topology / hero / demon map in export | **Keep aggregate observation** until board encoding spec exists | 2026-06-12 | Full hex featurizer is large scope; premature export would churn | Board featurizer design doc + optional dense columns |
| **NTD-005** | Micro pass action | `__pass__` outside `legal_mask_json` | **Keep pass implicit**; IL/RL consumers treat pass as extra action or parse `selected_spell_id` | 2026-06-12 | Mask is loadout-sized only; pass is global fallback | v2: `pass_legal` column or extended mask |
| **NTD-006** | Macro–micro linkage | Datasets are independent files | **Do not merge** macro and micro CSVs for training until encounter bridge emits join keys | 2026-06-12 | Different action spaces, row grains, observation shapes | See [MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md) |
| **NTD-007** | Provenance | No rules version, catalog version, or commit SHA in CSV | **Defer to schema v2** metadata row or sidecar manifest | 2026-06-12 | Exporters focus on step rows; provenance needs build-time injection | CI step to stamp exports |
| **NTD-008** | Export source of truth | Multiple CSV exporters exist | **`MacroTrainingTelemetryExporter` and `MicroCombatTelemetryExporter` only** are NN telemetry sources; `PlaythroughCsvExporter` and `DuelLogExporter` are debug/legacy | 2026-06-12 | Wrong grain, no masks, or wrong combat model | Document in audit and test matrix |
| **NTD-009** | Macro action parameters | CSV has action ID + kind, not vertex/edge/hero | **Consumers must decode** via `ActionSpace.to_layout_key()` for fixed board radius | 2026-06-12 | Full parameter export would widen schema significantly | Export `action_space_layout_key` in v2 |
| **NTD-010** | Micro terminal outcome | `winner_id` column is pre-step; empty on last row | **Parse `timeline_event_summary`** for `combat_end` until post-step column added | 2026-06-12 | Exporter captures obs before step | v2: post-step `winner_id` or structured events |
| **NTD-011** | Export policy | Only bot/deterministic policy during export | **Accept for v1**; human trajectories need separate collection path | 2026-06-12 | Human macro UI not complete; micro export hardcodes policy | Human play logging milestone |
| **NTD-012** | Classification honesty | Risk of overstating ML readiness | **Classify macro as Partial, micro as Mostly Ready/Partial** in audit | 2026-06-12 | Telemetry ≠ production dataset | Re-audit after schema v2 |

---

## Integration and rules (existing context)

| ID | Area | Gap | Decision | Date | Rationale | Follow-up |
|---|---|---|---|---|---|---|
| **INT-001** | Macro–micro runtime | `EncounterBridge` not in main loop | Presentation and training exports stay decoupled | 2026-06-12 | M8 bridge partial; spell combat is separate session | Encounter-linked export (NTD-006) |
| **INT-002** | Card duel vs spell combat | Two combat models in codebase | **Spell combat** is micro training source; card duel is legacy contract | 2026-06-12 | M7 card contract vs M29 spell session | Consolidate or rename in docs only |

---

## Open gaps (no decision yet)

| Area | Gap | Notes |
|---|---|---|
| Macro multi-agent RL | Only active player POV per row | Need opponent observations or centralized trainer design |
| Reward design | Both macro and micro use interim shaping | Requires game-design approval before published benchmarks |
| Batch datasets | Single episode per CLI run | Needs runner + manifest for large-scale ML |
| LOCAL_VERIFICATION | §4 checklist omits macro/micro CSV success checks | Doc drift flagged in audit |

---

## Related docs

- [NEURAL_TRAINING_DATA_EXPORT_AUDIT.md](NEURAL_TRAINING_DATA_EXPORT_AUDIT.md) — detailed readiness assessment
- [RULES_ENFORCEMENT_TEST_MATRIX.md](RULES_ENFORCEMENT_TEST_MATRIX.md) — test coverage and gaps
- [MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md) — target dataset relationship
- [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md) — explicit deferral of NN training in-engine
