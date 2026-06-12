# Gods and Wizards — Rulebook (Design Intent)

**Last updated:** 2026-06-12 (post–Run C design clarification)  
**Purpose:** Authoritative **design intent** for the macro board game. This document describes intended v1 rules. Implementation may lag; see [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md) for current code status.

---

## Terminology

| Term | Meaning |
|---|---|
| **Macro game** | Turn-based board simulation on a hex map: cities, roads, resources, heroes, demons, developments, VP, breach loss. Authoritative state is `GameState`. |
| **Macro contact resolution** | Instant, deterministic board resolution when macro pieces share a node. **Not** tactical combat. |
| **Tactical combat** | `SpellCombatSession` — canonical spell-duel system for isolated simulation, replay, telemetry, and future human-controlled 3D wizard encounters. **Not** part of the normal macro economy loop. |
| **Legacy card duel** | `CombatResolver` / card-duel model. Debug/reference only unless explicitly revived. |
| **3D human encounter** | Future player-facing encounter in the 3D wizard layer. May result in text, avoidance, or tactical combat. **Not implemented** in the macro loop. |
| **Wizard (macro)** | A god-AI-controlled macro piece that moves like a hero with limited actions. Distinct from the human wizard avatar in 3D. |
| **Hero (macro)** | Generic macro piece commanded by a god through macro actions. Not an RPG character. |

---

## Win and loss

| Condition | Rule |
|---|---|
| **Win** | Reach **21 victory points** (target VP for now). Only VP wins the game. |
| **Loss (breach)** | **Collective** breach loss when the global breach counter reaches the limit (**10**). |

---

## Macro vs tactical combat

- **Do not** integrate tactical spell combat into the macro economy yet.
- Macro hero-vs-demon interaction is **instant deterministic resolution** (macro contact resolution).
- Heroes and demons are **generic macro counters/pieces** for now.
- Up to **3 demons** may occupy a node. A 4th demon that would be placed on a node causes a **breach** instead (increment breach counter; do not add the demon).
- Tactical combat (`SpellCombatSession`) happens only in:
  - isolated training / replay / simulation modes, or
  - the future human-controlled **3D wizard layer**.
- Macro AI-controlled encounters **must not** use `SpellCombatSession` for now.

---

## Board model

- Hexes produce resources (Catan-style adjacency to cities).
- **Nodes** (corners) hold cities, heroes, demons, and developments.
- **Edges** connect nodes; roads are built on edges.
- Demon spread travels node-to-node along edges.

---

## Turn structure (intended)

A macro turn is a **multi-step active-player turn**, not a single action. See [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md) for the formal phase model.

At a high level, each active player's turn:

1. Start turn  
2. Victory / breach check  
3. Production (timing may vary by phase model — see turn doc)  
4. Trade phase / trade actions  
5. Build / develop actions  
6. Hero command actions  
7. Optional end-turn action (`END_TURN`)  
8. Demon spread (end of **this player's** turn — intended)  
9. End-turn cleanup  
10. Next player  

For RL and legal action masks: each trade, build, develop, and hero move should be an **individual legal action step**, with `END_TURN` as a legal action. Unlimited builds/trades within a turn are allowed, bounded only by resources and legality.

---

## Heroes (macro, intended v1)

| Rule | Detail |
|---|---|
| Identity | Persistent IDs; generic macro pieces |
| Level / equipment | **No** leveling; **no** equipment |
| Action budget | **4 actions** per hero per turn (default) |
| Action use | Move from one node/corner to an adjacent node/corner (1 action per move) |
| Command | Player-controlled god commands heroes through macro actions |
| Development cards | May later modify hero action counts (e.g. “all your heroes get +1 action per turn”) |
| Contact with demons | Entering a demon node triggers **macro contact resolution** — hero removes **all** demons on that node immediately |
| Coexistence | A demon **cannot** remain on a node containing a hero |
| Demon spawn onto hero | If a demon spawns or spreads onto a hero node, the demon is **immediately removed** |
| Wizard vs hero | A wizard controlled by god AI moves like a hero; a wizard **cannot** directly move a hero |
| Divine guidance | Future wizard/human interface may advise macro actions — **deferred** |

### Unresolved edge cases (flagged, not decided)

- Friendly hero stacking on one node  
- Same-owner wizard/hero contact  
- Enemy hero vs enemy hero  
- Enemy wizard vs hero  
- Whether wizard contact always removes heroes/demons in macro simulation  

**Proposed v1 answer for demon removal:** hero removes **all** demons on contact (not one demon).

---

## Demons (macro, intended v1)

| Rule | Detail |
|---|---|
| Representation | Generic counters per node (not individual RPG entities) |
| Cap per node | Maximum **3** demons |
| 4th demon | Causes breach increment; demon is **not** placed |
| Spread timing | End of **each player's turn** (not only end of full round) |
| Spread mechanism | Pandemic-style **infection/demon deck** of node/corner locations |
| Draw count | `infection_rate` nodes drawn per player turn; initial rate probably **2** |
| Per drawn node | Add 1 demon unless node already has 3; if 3, increment breach instead |
| Chain outbreaks | **None** in v1 |
| Age escalation | At end of each development-card age, infection rate **+1** |
| Deck reshuffle | No action/player deck; age-based random chance that infection discard is shuffled back on top of existing deck; probability increases each age |
| Reshuffle probabilities | **Design gap** — exact age-by-age values not yet decided |

**Current implementation note:** spread uses adjacent-node propagation, not an infection deck. See audit doc.

---

## Demon / city interaction (intended v1)

| Rule | Detail |
|---|---|
| Production suppression | Any demon count **> 0** on a city node → that city produces **0** resources |
| Development purge | If a demon is still present in a city after a **full round**, all development cards are removed from that city |
| New developments while occupied | Demon-occupied city should **probably not** receive new development cards — **design decision pending** |
| Timer reset | Clearing all demons from a city resets its occupation timer |
| Tracking | Need `city_demon_occupied_since_round` or equivalent |
| Empty city | If city has no development cards, it simply remains suppressed while occupied |

---

## Production and resources

- Cities adjacent to producing hexes receive resources on production rolls.
- Demon-occupied cities produce nothing (see above).
- Standard build costs apply for roads and cities (see implementation constants).

---

## Development cards and drafting (intended v1)

| Rule | Detail |
|---|---|
| Style | Seven Wonders-style drafting |
| Timing | Draft at end of each **full table round** (after every player has had a turn) |
| Pack size | Each player starts an age with a pack of **8 cards** |
| Draft step | At end of each round, every player chooses **1 card** from their current pack and adds it to their **hand** |
| Passing | Remaining cards are **passed** to the next player (use “passed pack”, not “new hand”) |
| Age length | **8 draft rounds** exhaust the pack; game then advances an age |
| Ages | **3 ages** → up to **24 development cards** per player total |
| Age effect | Infection rate **+1** at end of each age |
| Playing cards | Development cards are played from **hand** into cities |
| City slots | Up to **3 development-card slots** per city |
| Card effects | Production bonuses, VP, extra hero abilities, anti-demon effects, wizard access, additional heroes |

### Design gaps (require final decision)

- Development card costs  
- Replacement rules when slots are full  
- Whether demon-occupied cities can receive new development cards  

**Current implementation:** stub build only; no drafting.

---

## Trading (intended v1/v2 direction)

| Rule | Detail |
|---|---|
| Ports | **Do not exist** — not planned |
| Model | Active-player **offer / accept** only |
| Initiator | Only the player whose turn it is may **offer** trades |
| Response | Other players may **accept** or **reject** |
| Bots | May initiate trades on their own turn; may refuse offers |
| Ratios | **No** fixed Catan-style ratio; trades may be asymmetric (1:1, 2:3, etc.) |
| Duplicate offers | Same exact offer/request pair cannot be offered to the same target more than once per turn |
| Offer volume | No hard limit on distinct offers, but practical bounds needed for action-space and bot/RL |

### Recommended bounded v1 offer format (for future implementation)

- Offer gives **1–3** total resources  
- Request asks for **1–3** total resources  
- Offer and request cannot be empty  
- Active player must own offered resources  
- Target must own requested resources to accept  

**Current implementation:** provisional instant **1:1** player trade (`PlayerTradeRules`, fixed amount 1). Likely to be replaced by offer/accept model.

Bank trade (4:1) exists in code as a separate action kind; design direction for bank trade is unchanged from existing implementation unless revised later.

---

## Wizards and the 3D layer (long-term product direction)

- The **wizard is the god avatar** — how the human player experiences the game.
- **Long-term product default:** start in 3D spectator/RPG mode as a wizard.
- **Near-term development default:** 2D strategic/debug mode until macro rules are stable.
- The 3D world is **generated from macro state** (read-only snapshot).
- Hex resource type/colour defines terrain look.
- Roads → road objects; cities → city objects; development cards → buildings; demon outbreaks → demon visuals.
- Visual style may use flat 2D sprites in a Doom-like 3D world.
- Macro economy dictates 3D world size and layout.
- Each node-to-node walk should take roughly **30 seconds** for the human wizard.
- Encounter radius near city, hero, demon, or other wizard may trigger a **3D encounter** and pause the game.
- In tactical combat, human player is frozen and chooses spells or waits.
- Some encounters may be avoidable via menu.
- **Do not implement now.** 3D layer must **not** own or directly mutate `GameState`.

### Macro / 3D timing (future design gap)

- Human wizard walking speed should allow ~**4 node lengths** during one macro economy turn tick.
- Debug mode may allow pause or manual turn advance.
- Need later design for showing AI wizard/hero movement between macro turns in 3D.

---

## Product modes

| Mode | Role |
|---|---|
| **Long-term default** | 3D wizard spectator/RPG — human inhabits the world |
| **Near-term dev/test default** | 2D strategic playable/debug mode |
| **Debug/audit modes** | Developer-only (headless CSV, batch sim, telemetry export, audit scenes) |

---

## Architecture (mandatory)

1. **One authoritative `GameState`** — no parallel state machines.  
2. **Headless core first** — rules under `godot_game/core/`.  
3. **Presentation submits, does not mutate** — UI, run modes, integration, embodied layers use session/rule APIs only.  
4. **Determinism** — same seed + same legal actions → same result.

---

## Related docs

- [TURN_TIMING_AND_PHASE_MODEL.md](TURN_TIMING_AND_PHASE_MODEL.md) — formal turn/phase model  
- [RULES_ENGINE_AUDIT.md](RULES_ENGINE_AUDIT.md) — design vs implementation  
- [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md) — decision log  
- [MACRO_MICRO_INTEGRATION_DESIGN.md](MACRO_MICRO_INTEGRATION_DESIGN.md) — macro/tactical separation  
- [GAME_DESIGN_BRIEF.md](GAME_DESIGN_BRIEF.md) — product vision  
