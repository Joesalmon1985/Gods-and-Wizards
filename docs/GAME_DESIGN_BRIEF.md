# Game Design Brief — Gods and Wizards

**Last updated:** 2026-06-12 (post–Run C design clarification)  
**Purpose:** Macro-first design anchor for headless development, training tooling, and presentation layers.

---

## Vision

A competitive **mythic civilisation** simulation on a hex map. The authoritative game is a **macro turn-based board state machine** (`GameState`). All modes — headless CSV, batch balance, 2D strategic, 3D wizard observatory — are **lenses** on one state machine. Presentation layers **read and submit**; they do not own or directly mutate simulation state.

---

## Core pillars

| Pillar | Source | Macro role |
|--------|--------|------------|
| Production economy | Catan-style | Cities adjacent to producing hexes; production rolls |
| Underworld threat | Pandemic-style | Infection deck; demons spread; heroes contain; breach loss |
| Civilisation growth | Build rules | Roads, cities, distance rule, network connectivity |
| Development cards | Seven Wonders-style | Drafting at round end; play into cities — **deferred in implementation** |
| Wizard experience | 3D embodied layer | God avatar; long-term default player mode — **deferred** |
| Tactical combat | Spell combat | `SpellCombatSession` for isolated sim/replay/3D — **not in macro loop** |

---

## Terminology (mandatory)

| Term | Meaning |
|------|---------|
| **Macro contact resolution** | Instant deterministic board resolution when macro pieces share a node. Hero removes all demons. **Not** tactical combat. |
| **Tactical combat** | `SpellCombatSession` — canonical spell duel for training, replay, and future 3D wizard encounters. |
| **Legacy card duel** | `CombatResolver` — debug/reference unless revived. |
| **3D human encounter** | Future pause-and-resolve in wizard layer; not implemented in macro loop. |
| **Hero** | Generic macro piece commanded by a god; not an RPG character. |
| **Wizard (macro)** | God-AI macro piece that moves like a hero; distinct from human 3D avatar. |

See [RULEBOOK.md](RULEBOOK.md) for full intended rules.

---

## Architecture (non-negotiable)

1. **One `GameState`** — no parallel state, no donor merges.
2. **Headless core first** — rules under `godot_game/core/`; deterministic from seed + legal actions.
3. **Rules mutate state only through rule functions** — return events; never silent patches.
4. **Presentation reads and submits** — UI, integration, embodied, run-modes call session/rule APIs only.
5. **Training/balance** — headless batch runners and env wrappers export telemetry; **no neural network training in Godot**.

---

## Product modes

| Horizon | Default mode | Role |
|---------|--------------|------|
| **Long-term product** | 3D wizard spectator/RPG | Human experiences world as god avatar |
| **Near-term development** | 2D strategic playable/debug | Macro rules stable before 3D polish |
| **Developer-only** | Headless CSV, batch sim, telemetry export, audit scenes | Testing and balancing |

---

## Mode roadmap

| Mode | Role | Status |
|------|------|--------|
| Headless test suite | Rules proof | Complete |
| Bot CSV playthrough | Debug / export | Complete |
| Human turn shell (M14) | Session API for legal actions | Complete |
| Macro training env | reset / observe / step skeleton | Complete (partial export) |
| Batch balance runner | N-seed aggregate stats | Complete |
| 2D strategic (read-only + playable) | Near-term dev default | In progress |
| Spell combat replay/play | Isolated tactical combat | Complete |
| 3D wizard-world / spectator | Long-term default; read-only today | Exists (bot-advance) |
| Offer/accept trading | Intended v1 trade model | Not implemented |
| Full drafting | Seven Wonders-style | Not implemented |
| 3D human encounters | Pause + optional tactical combat | Not implemented |

---

## Macro vs tactical combat (design decision)

- **Do not** integrate `SpellCombatSession` into the macro economy loop.
- Macro hero-vs-demon = **instant macro contact resolution** (all demons removed on hero contact).
- Tactical combat is for isolated modes and future 3D human encounters only.
- Macro AI must not invoke spell combat.

---

## Explicit deferrals

- Full drafting and development-card library
- Offer/accept player trading (replacing provisional 1:1)
- Infection deck demon spread (replacing adjacent propagation)
- Hero action budgets and city demon occupation rules
- Full embodied wizard encounter loop in main scene
- Neural network training infrastructure (export only)
- Multiplayer networking and save/load
- Art, animation, and 3D polish
- Second `GameState` or donor-project merges
- **Ports** — not planned

---

## Related docs

- [RULEBOOK.md](RULEBOOK.md) — intended v1 rules
- [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md) — multi-step turns
- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md) — design vs implementation
- [MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md) — dataset separation
- [PROJECT_STATUS.md](PROJECT_STATUS.md)
- [NEXT_MILESTONES.md](NEXT_MILESTONES.md)
- [TESTING_AND_GIT_WORKFLOW.md](TESTING_AND_GIT_WORKFLOW.md)
