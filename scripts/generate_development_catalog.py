#!/usr/bin/env python3
"""Generate docs/DEVELOPMENT_CARD_CATALOG.md and development_cards_v1.json (96 cards)."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD_OUT = ROOT / "docs" / "DEVELOPMENT_CARD_CATALOG.md"
JSON_OUT = ROOT / "godot_game" / "data" / "development" / "development_cards_v1.json"

CATEGORIES = [
    "production_bonuses",
    "vp_cards",
    "hero_ability",
    "anti_demon",
    "trade_economy",
    "wizard_access",
    "additional_hero",
    "hybrid",
]

SLOT_BY_CATEGORY = {
    "production_bonuses": "economic",
    "vp_cards": "civic",
    "hero_ability": "military",
    "anti_demon": "military",
    "trade_economy": "economic",
    "wizard_access": "arcane",
    "additional_hero": "military",
    "hybrid": "civic",
}

# 4 card templates per category; scaled per age (1/2/3).
CARD_TEMPLATES: dict[str, list[dict]] = {
    "production_bonuses": [
        {
            "stem": "lumber_camp",
            "name": "Lumber Camp",
            "resource": "wood",
            "slot": "economic",
            "flavour": "Timber flows from the forest edge.",
        },
        {
            "stem": "brickworks",
            "name": "Brickworks",
            "resource": "brick",
            "slot": "economic",
            "flavour": "Kilns bake clay into sturdy brick.",
        },
        {
            "stem": "pasture_grant",
            "name": "Pasture Grant",
            "resource": "sheep",
            "slot": "economic",
            "flavour": "Flocks graze the city outskirts.",
        },
        {
            "stem": "ore_shaft",
            "name": "Ore Shaft",
            "resource": "ore",
            "slot": "economic",
            "flavour": "A shallow mine taps nearby ore.",
        },
    ],
    "vp_cards": [
        {"stem": "monument", "name": "Monument", "flavour": "A stone marker of civic pride."},
        {"stem": "obelisk", "name": "Obelisk", "flavour": "Rising stone honours the founders."},
        {"stem": "tapestry_hall", "name": "Tapestry Hall", "flavour": "Woven histories adorn the walls."},
        {"stem": "garden_terrace", "name": "Garden Terrace", "flavour": "Terraced gardens delight citizens."},
    ],
    "hero_ability": [
        {"stem": "ranger_post", "name": "Ranger Post", "flavour": "Scouts train for swift patrols."},
        {"stem": "militia_yard", "name": "Militia Yard", "flavour": "Drill grounds for town guards."},
        {"stem": "supply_cache", "name": "Supply Cache", "flavour": "Stores extend expedition range."},
        {"stem": "signal_beacon", "name": "Signal Beacon", "flavour": "Beacons coordinate hero movement."},
    ],
    "anti_demon": [
        {"stem": "ward_stone", "name": "Ward Stone", "flavour": "Runes repel minor corruption."},
        {"stem": "holy_font", "name": "Holy Font", "flavour": "Blessed water guards the threshold."},
        {"stem": "sentinel_shrine", "name": "Sentinel Shrine", "flavour": "Shrines watch for demonic presence."},
        {"stem": "blessed_wall", "name": "Blessed Wall", "flavour": "Consecrated stone resists occupation."},
    ],
    "trade_economy": [
        {"stem": "market_stall", "name": "Market Stall", "flavour": "Merchants barter surplus goods."},
        {"stem": "trade_post", "name": "Trade Post", "flavour": "A post for neighbourly exchange."},
        {"stem": "merchant_tent", "name": "Merchant Tent", "flavour": "Travelling traders rest here."},
        {"stem": "exchange_booth", "name": "Exchange Booth", "flavour": "Official booth for fair deals."},
    ],
    "wizard_access": [
        {"stem": "arcane_study", "name": "Arcane Study", "flavour": "Novices glimpse the wizard path."},
        {"stem": "mystic_circle", "name": "Mystic Circle", "flavour": "A circle for minor enchantments."},
        {"stem": "spell_shelf", "name": "Spell Shelf", "flavour": "Scrolls await a worthy reader."},
        {"stem": "novice_tower", "name": "Novice Tower", "flavour": "A tower for aspiring mages."},
    ],
    "additional_hero": [
        {"stem": "recruit_hall", "name": "Recruit Hall", "flavour": "Volunteers answer the call."},
        {"stem": "levy_barracks", "name": "Levy Barracks", "flavour": "Barracks house new champions."},
        {"stem": "volunteer_corps", "name": "Volunteer Corps", "flavour": "Citizens train as auxiliaries."},
        {"stem": "town_champion", "name": "Town Champion", "flavour": "A champion rises from the city."},
    ],
    "hybrid": [
        {"stem": "granary_shrine", "name": "Granary Shrine", "flavour": "Food and faith sustain the city."},
        {"stem": "trade_watch", "name": "Trade Watch", "flavour": "Guards protect merchant routes."},
        {"stem": "mage_market", "name": "Mage Market", "flavour": "Arcane goods trade openly."},
        {"stem": "hero_monument", "name": "Hero Monument", "flavour": "Heroes and history share a plinth."},
    ],
}

AGE_COSTS = {
    1: {"wheat": 1},
    2: {"wheat": 1, "sheep": 1},
    3: {"wheat": 1, "sheep": 1, "ore": 1},
}

AGE_VP = {1: 1, 2: 2, 3: 3}
AGE_PROD = {1: 1, 2: 2, 3: 3}
AGE_HERO_ACTIONS = {1: 1, 2: 1, 3: 2}
AGE_TRADE_BONUS = {1: 1, 2: 1, 3: 2}
AGE_DEMON_PROT = {1: 1, 2: 2, 3: 3}


def effects_for(category: str, age: int, template: dict) -> list[dict]:
    if category == "production_bonuses":
        amount = AGE_PROD[age]
        resource = template["resource"]
        return [{"type": "production_flat", "resource": resource, "amount": amount}]
    if category == "vp_cards":
        if age == 3 and template["stem"] == "wonder":
            return [
                {"type": "vp_flat", "amount": 3},
                {"type": "end_game_vp_per_city", "amount": 1},
            ]
        if age == 3 and template["stem"] == "triumph":
            return [
                {"type": "vp_flat", "amount": 2},
                {"type": "end_game_vp_per_hero", "amount": 1},
            ]
        return [{"type": "vp_flat", "amount": AGE_VP[age]}]
    if category == "hero_ability":
        return [{"type": "hero_actions_bonus", "amount": AGE_HERO_ACTIONS[age]}]
    if category == "anti_demon":
        if age == 3 and template["stem"] == "purifying_flame":
            return [{"type": "demon_clear_on_play", "amount": 1}]
        return [{"type": "city_demon_protection", "amount": AGE_DEMON_PROT[age]}]
    if category == "trade_economy":
        effects = [{"type": "trade_bonus", "amount": AGE_TRADE_BONUS[age]}]
        if age == 3 and template["stem"] == "free_port":
            effects.append({"type": "draft_bonus", "amount": 1})
        return effects
    if category == "wizard_access":
        macro = {"type": "vp_flat", "amount": 1 if age == 1 else 2}
        wizard = {"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}
        return [wizard, macro]
    if category == "additional_hero":
        if age == 1:
            return [{"type": "hero_actions_bonus", "amount": 1}]
        return [{"type": "hero_spawn", "amount": 1}]
    if category == "hybrid":
        return hybrid_effects(template["stem"], age)
    return []


def hybrid_effects(stem: str, age: int) -> list[dict]:
    table = {
        "granary_shrine": [
            {"type": "production_flat", "resource": "wheat", "amount": age},
            {"type": "vp_flat", "amount": 1 if age < 3 else 2},
        ],
        "trade_watch": [
            {"type": "trade_bonus", "amount": 1},
            {"type": "city_demon_protection", "amount": 1 if age < 3 else 2},
        ],
        "mage_market": [
            {"type": "wizard_access", "amount": 1, "tag": "wizard_trade_unlock"},
            {"type": "trade_bonus", "amount": age},
        ],
        "hero_monument": [
            {"type": "vp_flat", "amount": age},
            {"type": "hero_actions_bonus", "amount": 1 if age < 3 else 2},
        ],
    }
    return table.get(stem, [{"type": "vp_flat", "amount": age}])


def rules_text(category: str, age: int, template: dict, effects: list[dict]) -> str:
    parts: list[str] = []
    for eff in effects:
        t = eff["type"]
        if t == "production_flat":
            parts.append(f"+{eff['amount']} {eff['resource']} production in this city.")
        elif t == "vp_flat":
            parts.append(f"+{eff['amount']} victory points.")
        elif t == "hero_actions_bonus":
            parts.append(f"+{eff['amount']} hero action(s) per turn for your heroes.")
        elif t == "city_demon_protection":
            parts.append(
                f"Demon occupation timer extended by {eff['amount']} round(s) before purge."
            )
        elif t == "demon_clear_on_play":
            parts.append("When played, remove 1 demon from this city if present.")
        elif t == "trade_bonus":
            parts.append(f"+{eff['amount']} extra resource in trades you accept.")
        elif t == "draft_bonus":
            parts.append("At next age start, look at the top card of your pack.")
        elif t == "wizard_access":
            parts.append("Grants wizard encounter access (macro: bonus VP as shown).")
        elif t == "hero_spawn":
            parts.append("Spawn 1 hero at this city when played.")
        elif t == "end_game_vp_per_city":
            parts.append(f"+{eff['amount']} VP per city you own at game end.")
        elif t == "end_game_vp_per_hero":
            parts.append(f"+{eff['amount']} VP per hero you control at game end.")
        elif t == "end_game_vp_per_development":
            parts.append(f"+{eff['amount']} VP per development you built at game end.")
        elif t == "production_discount":
            parts.append(f"Reduce development build cost by {eff['amount']}.")
    return " ".join(parts)


def build_cards() -> list[dict]:
    cards: list[dict] = []
    # Rename age-3 vp templates for special end-game cards
    vp_age3_names = {
        "monument": ("palace", "Palace"),
        "obelisk": ("wonder", "Wonder"),
        "tapestry_hall": ("cathedral", "Cathedral"),
        "garden_terrace": ("triumph", "Triumph"),
    }
    trade_age3_names = {
        "market_stall": ("grand_bazaar", "Grand Bazaar"),
        "trade_post": ("trade_emporium", "Trade Emporium"),
        "merchant_tent": ("merchant_prince", "Merchant Prince"),
        "exchange_booth": ("free_port", "Free Port"),
    }
    demon_age3_names = {
        "ward_stone": ("holy_citadel", "Holy Citadel"),
        "holy_font": ("archon_seal", "Archon Seal"),
        "sentinel_shrine": ("purifying_flame", "Purifying Flame"),
        "blessed_wall": ("demon_barrier", "Demon Barrier"),
    }

    for age in (1, 2, 3):
        for category in CATEGORIES:
            for template in CARD_TEMPLATES[category]:
                stem = template["stem"]
                name = template["name"]
                if category == "vp_cards" and age == 3 and stem in vp_age3_names:
                    stem, name = vp_age3_names[stem]
                if category == "trade_economy" and age == 3 and stem in trade_age3_names:
                    stem, name = trade_age3_names[stem]
                if category == "anti_demon" and age == 3 and stem in demon_age3_names:
                    stem, name = demon_age3_names[stem]

                card_id = f"{stem}_a{age}"
                display_name = f"{name} (Age {age})"
                tpl = dict(template)
                tpl["stem"] = stem
                effects = effects_for(category, age, tpl)
                vp = sum(e.get("amount", 0) for e in effects if e["type"] == "vp_flat")
                card = {
                    "id": card_id,
                    "name": display_name,
                    "age": age,
                    "category": category,
                    "slot_type": template.get("slot", SLOT_BY_CATEGORY[category]),
                    "cost": dict(AGE_COSTS[age]),
                    "vp": vp,
                    "rules_text": rules_text(category, age, tpl, effects),
                    "flavour_text": template.get("flavour", ""),
                    "effects": effects,
                    "tags": _tags(category, effects),
                    "implementation_status": "implemented",
                }
                cards.append(card)
    return cards


def _tags(category: str, effects: list[dict]) -> list[str]:
    tags = [category]
    for eff in effects:
        if eff["type"] == "wizard_access":
            tags.append(eff.get("tag", "wizard_access"))
    return tags


def render_markdown(cards: list[dict]) -> str:
    lines = [
        "# Development Card Catalog",
        "",
        "**Version:** development_cards_v1",
        "**Total cards:** 96 (32 per age, 4 players × 8 cards × 3 ages)",
        "",
        "## Summary",
        "",
        "| Age | Count | Theme |",
        "|-----|-------|-------|",
        "| I | 32 | Simple, cheap production and economy |",
        "| II | 32 | Strategic heroes, anti-demon, trade |",
        "| III | 32 | Powerful VP and game-closing effects |",
        "",
        "## Categories (4 cards each per age)",
        "",
    ]
    for cat in CATEGORIES:
        lines.append(f"- `{cat}`")
    lines.append("")
    for age in (1, 2, 3):
        lines.append(f"## Age {age}")
        lines.append("")
        age_cards = [c for c in cards if c["age"] == age]
        by_cat: dict[str, list] = {}
        for c in age_cards:
            by_cat.setdefault(c["category"], []).append(c)
        for cat in CATEGORIES:
            lines.append(f"### {cat}")
            lines.append("")
            for c in sorted(by_cat.get(cat, []), key=lambda x: x["id"]):
                lines.append(f"#### `{c['id']}` — {c['name']}")
                lines.append("")
                lines.append(f"| Field | Value |")
                lines.append(f"|-------|-------|")
                lines.append(f"| category | {c['category']} |")
                lines.append(f"| slot_type | {c['slot_type']} |")
                lines.append(f"| cost | {json.dumps(c['cost'])} |")
                lines.append(f"| vp | {c['vp']} |")
                lines.append(f"| implementation_status | {c['implementation_status']} |")
                lines.append(f"| tags | {', '.join(c['tags'])} |")
                lines.append(f"| rules_text | {c['rules_text']} |")
                if c.get("flavour_text"):
                    lines.append(f"| flavour_text | {c['flavour_text']} |")
                lines.append(f"| effects | `{json.dumps(c['effects'])}` |")
                lines.append("")
    return "\n".join(lines)


def main() -> None:
    cards = build_cards()
    assert len(cards) == 96, len(cards)
    assert len({c["id"] for c in cards}) == 96
    for age in (1, 2, 3):
        assert len([c for c in cards if c["age"] == age]) == 32

    MD_OUT.parent.mkdir(parents=True, exist_ok=True)
    JSON_OUT.parent.mkdir(parents=True, exist_ok=True)

    MD_OUT.write_text(render_markdown(cards), encoding="utf-8")
    JSON_OUT.write_text(
        json.dumps({"schema_version": "development_cards_v1", "cards": cards}, indent=2)
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {MD_OUT} ({len(cards)} cards)")
    print(f"Wrote {JSON_OUT}")


if __name__ == "__main__":
    main()
