# Game of the Gods / Gods and Wizards

This project is a clean Godot rebuild combining two previous prototypes.

The game has two experiences built on one shared world state.

## Strategic layer (macro — authoritative)

The strategic game is a board-game simulation inspired by Catan, Pandemic, and Seven Wonders.

Players are gods guiding mortal civilisations.

Hexes produce resources.

Corner nodes hold cities, heroes, demons, and developments.

Edges connect nodes and support roads, hero movement, and demon spread.

Players build roads and cities, gather resources, develop cities with special cards, and compete for civilisation score (21 VP to win).

At the same time, the underworld spreads across the node network. Players must contain demons or the world falls (collective breach loss at **10** — design target; code may still use 7).

**Macro hero/demon interaction** is instant deterministic contact resolution — a hero removes all demons on its node. This is **not** tactical spell combat.

**Heroes** are generic macro pieces commanded through macro actions (4 actions per turn by default). They are not player-controlled RPG characters.

**Trading:** no ports; intended model is active-player offer/accept with asymmetric ratios. Current 1:1 instant trade is provisional.

**Drafting:** Seven Wonders-style at end of each full round (deferred in implementation).

## Tactical combat (isolated)

`SpellCombatSession` is the canonical tactical combat system for spell duels — used in isolated simulation, replay, telemetry export, and future 3D human encounters.

It is **not** part of the normal macro economy loop. Macro AI must not invoke spell combat.

The legacy `CombatResolver` card-duel model is debug/reference only.

## Embodied wizard layer (long-term product default)

The player may eventually enter the world as a wizard — the god avatar.

This layer lets the player experience local events from inside the world:

* travelling between nodes (~30 seconds per node length);
* visiting cities;
* triggering 3D encounters (pause game);
* optional tactical combat via `SpellCombatSession`;
* seeing city developments physically represented.

The 3D world is generated from macro state. The embodied layer **does not own game state** — it reads snapshots and submits actions through session/rule APIs only.

**Near-term development default:** 2D strategic playable/debug mode until macro rules are stable.

## Source of truth

The board engine (`GameState`) is authoritative.

The embodied layer reads from the board state and sends action requests back to the core rules.

There must be one shared GameState, not two games loosely connected.

## Design slogan

One world state. Two ways to experience it.

The board mode controls the simulation.

The wizard mode lets the player inhabit key moments within that simulation — when implemented.

## Related docs

- `docs/RULEBOOK.md` — intended v1 rules
- `docs/TURN_TIMING_AND_PHASE_MODEL.md` — multi-step turns
- `docs/GAME_DESIGN_BRIEF.md` — product vision
