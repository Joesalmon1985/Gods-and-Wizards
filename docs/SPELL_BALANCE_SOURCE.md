# Spell balance source material

**Workbook (local, not committed):** `data/design/New Balance Dark Fantasy Duels Analysis.xlsx`

## Sheet roles

| Sheet | Role in v1 |
|-------|------------|
| **SpellSpecs** | Source of truth for encoded spell definitions |
| **SpellStats** | Balance/context notes only — not runtime rules |
| **Balance** | Buff/nerf notes only — not runtime rules |
| **Duels** | Match context for future tuning — not runtime rules |
| **Summary** | High-level notes — not runtime rules |
| **Matchups** | Matchup context — not runtime rules |

## Repo encoding

- `godot_game/data/spells/spell_catalog_v1.json` — headless spell definitions
- `godot_game/data/spells/combatant_loadouts_v1.json` — generic combatant loadouts (hero, demon, class archetypes)
- Regenerate with: `python scripts/export_spell_catalog_from_workbook.py`

## Stable IDs

- Spell IDs are snake_case derived from the workbook `id` column (e.g. `PainHex` → `pain_hex`).
- Combatant loadout IDs are snake_case (e.g. `hero_patrol`, `demon_breach`, `apostate`).
- Heroes, demons, and wizards all use `CombatantSpellLoadout` — spells are not wizard-only.

## v1 scope

M28 encodes catalogue/data only. M29 introduces `SpellCombatSession` resolution and telemetry.
