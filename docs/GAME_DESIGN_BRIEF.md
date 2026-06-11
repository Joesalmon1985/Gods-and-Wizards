# Game Design Brief — Gods and Wizards

**Purpose:** Macro-first design anchor for headless development, training tooling, and presentation layers.

---

## Vision

A competitive **mythic civilisation** simulation on a hex map. The authoritative game is a **macro turn-based board state machine**. All modes (headless CSV, batch balance, 2D strategic, 3D wizard observatory) are **lenses** on one `GameState`.

---

## Core pillars

| Pillar | Source | Macro role |
|--------|--------|------------|
| Production economy | Catan-style | Cities adjacent to producing hexes; start-of-round rolls |
| Underworld threat | Pandemic-style | Demons spread; heroes contain; breach loss |
| Civilisation growth | Build rules | Roads, cities, distance rule, network connectivity |
| Development cards | Seven Wonders-style | **Deferred** — stub build only; no full drafting |
| Wizard duels | Micro encounters | **Deferred** — headless combat contract exists; not in main loop |

---

## Architecture (non-negotiable)

1. **One `GameState`** — no parallel state, no donor merges.
2. **Headless core first** — rules under `godot_game/core/`; deterministic from seed + legal actions.
3. **Rules mutate state only through rule functions** — return events; never silent patches.
4. **Presentation reads and submits** — UI, integration, embodied, run-modes call session/rule APIs; they do not mutate cities, roads, resources, demons, heroes, or scores directly.
5. **Training/balance** — headless batch runners and env wrappers; no neural network training in-engine yet.

---

## Mode roadmap

| Mode | Role | Status |
|------|------|--------|
| Headless test suite | Rules proof | Complete |
| Bot CSV playthrough | Debug / export | Complete |
| Human turn shell (M14) | Session API for legal actions | Complete |
| Macro training env | reset / observe / step skeleton | In progress |
| Batch balance runner | N-seed aggregate stats | In progress |
| 2D strategic (read-only) | Debug / training / balancing lens | Planned |
| 2D human action selection | Playable macro loop | Planned |
| 3D wizard-world | Observatory / deferred polish | Exists (bot-advance) |

---

## Explicit deferrals

- Full drafting and development-card library
- Full embodied wizard combat loop in main scene
- Neural network training infrastructure
- Multiplayer networking and save/load
- Art, animation, and 3D polish
- Second `GameState` or donor-project merges

---

## Related docs

- [PROJECT_STATUS.md](PROJECT_STATUS.md)
- [NEXT_MILESTONES.md](NEXT_MILESTONES.md)
- [TESTING_AND_GIT_WORKFLOW.md](TESTING_AND_GIT_WORKFLOW.md)
