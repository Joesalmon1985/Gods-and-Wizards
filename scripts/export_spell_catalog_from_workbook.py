#!/usr/bin/env python3
"""Export SpellSpecs from the local balance workbook to godot_game/data/spells/*.json."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:
    print("openpyxl required: python -m pip install openpyxl", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
WORKBOOK = ROOT / "data" / "design" / "New Balance Dark Fantasy Duels Analysis.xlsx"
OUT_DIR = ROOT / "godot_game" / "data" / "spells"


def to_spell_id(raw_id: str) -> str:
    spaced = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", raw_id.strip())
    return re.sub(r"[^a-z0-9_]+", "_", spaced.lower()).strip("_")


def to_combatant_id(raw_class: str) -> str:
    return to_spell_id(raw_class)


def row_to_spell(headers: list[str], row: tuple) -> dict:
    data = {headers[i]: row[i] for i in range(len(headers))}
    spell_id = to_spell_id(str(data["id"]))

    def num(key: str) -> float:
        value = data.get(key, 0)
        return float(value or 0)

    def boolean(key: str) -> bool:
        value = data.get(key, False)
        return bool(value)

    return {
        "spell_id": spell_id,
        "display_name": str(data.get("spell", spell_id)),
        "source_class": str(data.get("class", "")),
        "cast_time": num("cast_time"),
        "cooldown": num("cooldown"),
        "mana_cost": num("mana_cost"),
        "damage": num("damage"),
        "heal": num("heal"),
        "lifesteal_frac": num("lifesteal_frac"),
        "is_counter_spell": boolean("isCounterSpell"),
        "target_self_ok": boolean("target_self_ok"),
        "buff_duration": num("buff_duration"),
        "dot_dps": num("dot_dps"),
        "dot_duration": num("dot_duration"),
        "barrier_absorb_amount": num("barrier_absorb_amount"),
        "barrier_duration": num("barrier_duration"),
        "buff_cast_rate_mult": num("buff_cast_rate_mult"),
        "buff_cooldown_rate_mult": num("buff_cooldown_rate_mult"),
        "buff_hp_regen_delta": num("buff_hp_regen_delta"),
        "buff_mana_regen_delta": num("buff_mana_regen_delta"),
        "debuff_duration": num("debuff_duration"),
        "debuff_opp_cast_rate_mult": num("debuff_opp_cast_rate_mult"),
        "debuff_opp_cooldown_rate_mult": num("debuff_opp_cooldown_rate_mult"),
        "debuff_opp_hp_regen_delta": num("debuff_opp_hp_regen_delta"),
        "debuff_opp_mana_regen_delta": num("debuff_opp_mana_regen_delta"),
        "delta_hp_caster": num("delta_hp_caster"),
        "delta_mana_caster": num("delta_mana_caster"),
        "dual_cast": boolean("dual_cast"),
        "hit_time": num("hitTime"),
        "shield_block_charges": num("shield_block_charges"),
        "shield_duration": num("shield_duration"),
        "silence_all_duration": num("silence_all_duration"),
        "silence_random_duration": num("silence_random_duration"),
        "silence_random_n": num("silence_random_n"),
    }


def main() -> int:
    if not WORKBOOK.exists():
        print(f"Workbook missing: {WORKBOOK}", file=sys.stderr)
        return 1

    wb = openpyxl.load_workbook(WORKBOOK, read_only=True, data_only=True)
    ws = wb["SpellSpecs"]
    rows = list(ws.iter_rows(values_only=True))
    headers = [str(h) for h in rows[0]]

    spells_by_id: dict[str, dict] = {}
    class_loadouts: dict[str, list[str]] = {}

    for row in rows[1:]:
        if not row or not row[2]:
            continue
        spell = row_to_spell(headers, row)
        spell_id = spell["spell_id"]
        combatant_class = to_combatant_id(spell["source_class"])
        class_loadouts.setdefault(combatant_class, [])
        if spell_id not in class_loadouts[combatant_class]:
            class_loadouts[combatant_class].append(spell_id)

        existing = spells_by_id.get(spell_id)
        if existing is None:
            spells_by_id[spell_id] = spell
        elif existing != spell:
            print(f"Warning: conflicting stats for spell_id={spell_id}; keeping first row", file=sys.stderr)

    catalog = {
        "schema_version": "spell_catalog_v1",
        "source_workbook": "data/design/New Balance Dark Fantasy Duels Analysis.xlsx",
        "source_sheet": "SpellSpecs",
        "spell_count": len(spells_by_id),
        "spells": sorted(spells_by_id.values(), key=lambda s: s["spell_id"]),
    }

    hero_spells = [sid for sid in ["smite", "renew", "purify", "pain_hex", "wither"] if sid in spells_by_id]
    demon_spells = [sid for sid in ["pain_hex", "wither", "curse", "smite", "brain_hex"] if sid in spells_by_id]

    loadouts = {
        "schema_version": "combatant_loadouts_v1",
        "loadouts": {
            "hero_patrol": {
                "combatant_id": "hero_patrol",
                "display_name": "Hero Patrol",
                "base_health": 100,
                "base_mana": 100,
                "spell_ids": hero_spells,
            },
            "demon_breach": {
                "combatant_id": "demon_breach",
                "display_name": "Demon Breach",
                "base_health": 90,
                "base_mana": 80,
                "spell_ids": demon_spells,
            },
        },
    }

    for combatant_id in sorted(class_loadouts.keys()):
        loadouts["loadouts"][combatant_id] = {
            "combatant_id": combatant_id,
            "display_name": combatant_id.replace("_", " ").title(),
            "base_health": 100,
            "base_mana": 100,
            "spell_ids": sorted(class_loadouts[combatant_id]),
        }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    catalog_path = OUT_DIR / "spell_catalog_v1.json"
    loadouts_path = OUT_DIR / "combatant_loadouts_v1.json"
    catalog_path.write_text(json.dumps(catalog, indent=2), encoding="utf-8")
    loadouts_path.write_text(json.dumps(loadouts, indent=2), encoding="utf-8")

    print(f"Wrote {catalog_path} ({catalog['spell_count']} spells)")
    print(f"Wrote {loadouts_path} ({len(loadouts['loadouts'])} loadouts)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
