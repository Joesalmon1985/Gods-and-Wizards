# Run H Rule Decisions (H1)

**Date:** 2026-06-12  
**Branch:** `milestone/run-h-rules-card-spell-fidelity`  
**Authority:** v1 design lock for RC-B-007, RC-C-004, RC-D-006, RC-F-005, RC-G-007

## 1. Age-weighted infection deck reshuffle (RC-B-007)

- After infection draws each `END_TURN`, perform Underworld Surge check.
- Surge chance: Age I 0%, Age II 10%, Age III 20% (`draft_age`).
- On surge: shuffle discard, prepend on draw pile; emit `underworld_surge` event.
- Age advancement still `infection_rate += 1`.

## 2. Friendly hero stacking (RC-C-004)

- Friendly stacking **not allowed** in v1.
- Enemy hero entering hostile hero node **removes both**; emit `hero_clash` event.

## 3. New developments in demon-occupied cities (RC-D-006)

- Cannot build new development while demons > 0 on city.
- Existing developments remain until full-round purge.
- Hand unaffected; no queued build.

## 4. Production timing (RC-F-005)

- Production at active player turn start, `PRODUCTION` phase, before main actions.
- Only active player's cities produce (unless card says otherwise).
- Demon-occupied cities produce 0.
- Infection spread remains at `END_TURN`.

## 5. Pending trade offers (RC-G-007)

- Offers active-turn only; expire after one full player cycle.
- Expiry: `turn_number - created_turn_number >= player_count` checked after each `END_TURN` increment (`expire_stale_offers`).
- Survives offerer's first `END_TURN` in the same cycle so the target may accept on their turn.
- Accept resolves immediately; reject clears offer.
- Duplicate exact offer to same target blocked within active turn.

## Conflicts resolved

| Conflict | Resolution |
|---|---|
| Round-wrap production tests | Update to turn-start v1 |
| Pending offer survives test | Rewrite for expiration |
| All-node hero block | Allow enemy-on-enemy for clash |

See GD-013..GD-017 in [RULES_GAP_ANALYSIS_AND_DECISION_LOG.md](RULES_GAP_ANALYSIS_AND_DECISION_LOG.md).
