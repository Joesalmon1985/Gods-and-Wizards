# Run J2 — Micro Combat Donor Adapter Plan (stub)

**Status:** Deferred — do not implement in Run J  
**Branch:** `milestone/run-j2-micro-combat-donor-adapter`  
**Parent planning:** [RUN_J_PLANNING_DARK_FANTASY_REUSE.md](RUN_J_PLANNING_DARK_FANTASY_REUSE.md) §7

## Scope (Run J2 only)

- Headless SpellSimDef → neutral DTO adapter (MC-1–MC-6)
- Gap analysis against `spell_catalog_v1.json` and `DevelopmentCatalog`
- **No** `SpellCombatSession` replacement
- **No** `DuelSim` / `MageSim` / `EvoEngine` runtime imports

## First tests (Run J2)

- MC-1: Donor spell definitions parse into neutral DTOs without scene/UI dependencies
- MC-2: Donor spell names map to current taxonomy or marked new
- MC-5: Unsupported donor effects rejected/flagged
- MC-11: Existing `SpellCombatSession` tests still pass

## Run K / experimental sandbox (after J2)

- AI legal action masks, policy features, EvoEngine-style training
- CSV duel logging enhancements
- Regen/wither/haste parity review (MC-7–MC-12)

## Run J delivered (visual-only)

- Spell icons and class billboards via `godot_game/assets/billboards/manifest.json`
- No combat sim migration
