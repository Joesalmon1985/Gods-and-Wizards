# Development Card Catalog

**Version:** development_cards_v1
**Total cards:** 96 (32 per age, 4 players × 8 cards × 3 ages)

## Summary

| Age | Count | Theme |
|-----|-------|-------|
| I | 32 | Simple, cheap production and economy |
| II | 32 | Strategic heroes, anti-demon, trade |
| III | 32 | Powerful VP and game-closing effects |

## Categories (4 cards each per age)

- `production_bonuses`
- `vp_cards`
- `hero_ability`
- `anti_demon`
- `trade_economy`
- `wizard_access`
- `additional_hero`
- `hybrid`

## Age 1

### production_bonuses

#### `brickworks_a1` — Brickworks

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +1 brick production in this city. |
| flavour_text | Kilns bake clay into sturdy brick. |
| effects | `[{"type": "production_flat", "resource": "brick", "amount": 1}]` |

#### `lumber_camp_a1` — Lumber Camp

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +1 wood production in this city. |
| flavour_text | Timber flows from the forest edge. |
| effects | `[{"type": "production_flat", "resource": "wood", "amount": 1}]` |

#### `ore_shaft_a1` — Ore Shaft

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +1 ore production in this city. |
| flavour_text | A shallow mine taps nearby ore. |
| effects | `[{"type": "production_flat", "resource": "ore", "amount": 1}]` |

#### `pasture_grant_a1` — Pasture Grant

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +1 sheep production in this city. |
| flavour_text | Flocks graze the city outskirts. |
| effects | `[{"type": "production_flat", "resource": "sheep", "amount": 1}]` |

### vp_cards

#### `garden_terrace_a1` — Garden Terrace

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +1 victory points. |
| flavour_text | Terraced gardens delight citizens. |
| effects | `[{"type": "vp_flat", "amount": 1}]` |

#### `monument_a1` — Monument

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +1 victory points. |
| flavour_text | A stone marker of civic pride. |
| effects | `[{"type": "vp_flat", "amount": 1}]` |

#### `obelisk_a1` — Obelisk

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +1 victory points. |
| flavour_text | Rising stone honours the founders. |
| effects | `[{"type": "vp_flat", "amount": 1}]` |

#### `tapestry_hall_a1` — Tapestry Hall

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +1 victory points. |
| flavour_text | Woven histories adorn the walls. |
| effects | `[{"type": "vp_flat", "amount": 1}]` |

### hero_ability

#### `militia_yard_a1` — Militia Yard

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Drill grounds for town guards. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `ranger_post_a1` — Ranger Post

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Scouts train for swift patrols. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `signal_beacon_a1` — Signal Beacon

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Beacons coordinate hero movement. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `supply_cache_a1` — Supply Cache

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Stores extend expedition range. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

### anti_demon

#### `blessed_wall_a1` — Blessed Wall

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 1 round(s) before purge. |
| flavour_text | Consecrated stone resists occupation. |
| effects | `[{"type": "city_demon_protection", "amount": 1}]` |

#### `holy_font_a1` — Holy Font

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 1 round(s) before purge. |
| flavour_text | Blessed water guards the threshold. |
| effects | `[{"type": "city_demon_protection", "amount": 1}]` |

#### `sentinel_shrine_a1` — Sentinel Shrine

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 1 round(s) before purge. |
| flavour_text | Shrines watch for demonic presence. |
| effects | `[{"type": "city_demon_protection", "amount": 1}]` |

#### `ward_stone_a1` — Ward Stone

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 1 round(s) before purge. |
| flavour_text | Runes repel minor corruption. |
| effects | `[{"type": "city_demon_protection", "amount": 1}]` |

### trade_economy

#### `exchange_booth_a1` — Exchange Booth

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | Official booth for fair deals. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

#### `market_stall_a1` — Market Stall

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | Merchants barter surplus goods. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

#### `merchant_tent_a1` — Merchant Tent

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | Travelling traders rest here. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

#### `trade_post_a1` — Trade Post

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | A post for neighbourly exchange. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

### wizard_access

#### `arcane_study_a1` — Arcane Study

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +1 victory points. |
| flavour_text | Novices glimpse the wizard path. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 1}]` |

#### `mystic_circle_a1` — Mystic Circle

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +1 victory points. |
| flavour_text | A circle for minor enchantments. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 1}]` |

#### `novice_tower_a1` — Novice Tower

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +1 victory points. |
| flavour_text | A tower for aspiring mages. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 1}]` |

#### `spell_shelf_a1` — Spell Shelf

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +1 victory points. |
| flavour_text | Scrolls await a worthy reader. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 1}]` |

### additional_hero

#### `levy_barracks_a1` — Levy Barracks

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Barracks house new champions. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `recruit_hall_a1` — Recruit Hall

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Volunteers answer the call. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `town_champion_a1` — Town Champion

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | A champion rises from the city. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `volunteer_corps_a1` — Volunteer Corps

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Citizens train as auxiliaries. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

### hybrid

#### `granary_shrine_a1` — Granary Shrine

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +1 wheat production in this city. +1 victory points. |
| flavour_text | Food and faith sustain the city. |
| effects | `[{"type": "production_flat", "resource": "wheat", "amount": 1}, {"type": "vp_flat", "amount": 1}]` |

#### `hero_monument_a1` — Hero Monument

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +1 victory points. +1 hero action(s) per turn for your heroes. |
| flavour_text | Heroes and history share a plinth. |
| effects | `[{"type": "vp_flat", "amount": 1}, {"type": "hero_actions_bonus", "amount": 1}]` |

#### `mage_market_a1` — Mage Market

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hybrid, wizard_trade_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +1 extra resource in trades you accept. |
| flavour_text | Arcane goods trade openly. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_trade_unlock"}, {"type": "trade_bonus", "amount": 1}]` |

#### `trade_watch_a1` — Trade Watch

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +1 extra resource in trades you accept. Demon occupation timer extended by 1 round(s) before purge. |
| flavour_text | Guards protect merchant routes. |
| effects | `[{"type": "trade_bonus", "amount": 1}, {"type": "city_demon_protection", "amount": 1}]` |

## Age 2

### production_bonuses

#### `brickworks_a2` — Brickworks

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +2 brick production in this city. |
| flavour_text | Kilns bake clay into sturdy brick. |
| effects | `[{"type": "production_flat", "resource": "brick", "amount": 2}]` |

#### `lumber_camp_a2` — Lumber Camp

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +2 wood production in this city. |
| flavour_text | Timber flows from the forest edge. |
| effects | `[{"type": "production_flat", "resource": "wood", "amount": 2}]` |

#### `ore_shaft_a2` — Ore Shaft

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +2 ore production in this city. |
| flavour_text | A shallow mine taps nearby ore. |
| effects | `[{"type": "production_flat", "resource": "ore", "amount": 2}]` |

#### `pasture_grant_a2` — Pasture Grant

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +2 sheep production in this city. |
| flavour_text | Flocks graze the city outskirts. |
| effects | `[{"type": "production_flat", "resource": "sheep", "amount": 2}]` |

### vp_cards

#### `garden_terrace_a2` — Garden Terrace

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +2 victory points. |
| flavour_text | Terraced gardens delight citizens. |
| effects | `[{"type": "vp_flat", "amount": 2}]` |

#### `monument_a2` — Monument

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +2 victory points. |
| flavour_text | A stone marker of civic pride. |
| effects | `[{"type": "vp_flat", "amount": 2}]` |

#### `obelisk_a2` — Obelisk

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +2 victory points. |
| flavour_text | Rising stone honours the founders. |
| effects | `[{"type": "vp_flat", "amount": 2}]` |

#### `tapestry_hall_a2` — Tapestry Hall

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +2 victory points. |
| flavour_text | Woven histories adorn the walls. |
| effects | `[{"type": "vp_flat", "amount": 2}]` |

### hero_ability

#### `militia_yard_a2` — Militia Yard

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Drill grounds for town guards. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `ranger_post_a2` — Ranger Post

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Scouts train for swift patrols. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `signal_beacon_a2` — Signal Beacon

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Beacons coordinate hero movement. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

#### `supply_cache_a2` — Supply Cache

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +1 hero action(s) per turn for your heroes. |
| flavour_text | Stores extend expedition range. |
| effects | `[{"type": "hero_actions_bonus", "amount": 1}]` |

### anti_demon

#### `blessed_wall_a2` — Blessed Wall

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 2 round(s) before purge. |
| flavour_text | Consecrated stone resists occupation. |
| effects | `[{"type": "city_demon_protection", "amount": 2}]` |

#### `holy_font_a2` — Holy Font

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 2 round(s) before purge. |
| flavour_text | Blessed water guards the threshold. |
| effects | `[{"type": "city_demon_protection", "amount": 2}]` |

#### `sentinel_shrine_a2` — Sentinel Shrine

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 2 round(s) before purge. |
| flavour_text | Shrines watch for demonic presence. |
| effects | `[{"type": "city_demon_protection", "amount": 2}]` |

#### `ward_stone_a2` — Ward Stone

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 2 round(s) before purge. |
| flavour_text | Runes repel minor corruption. |
| effects | `[{"type": "city_demon_protection", "amount": 2}]` |

### trade_economy

#### `exchange_booth_a2` — Exchange Booth

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | Official booth for fair deals. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

#### `market_stall_a2` — Market Stall

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | Merchants barter surplus goods. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

#### `merchant_tent_a2` — Merchant Tent

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | Travelling traders rest here. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

#### `trade_post_a2` — Trade Post

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +1 extra resource in trades you accept. |
| flavour_text | A post for neighbourly exchange. |
| effects | `[{"type": "trade_bonus", "amount": 1}]` |

### wizard_access

#### `arcane_study_a2` — Arcane Study

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | Novices glimpse the wizard path. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

#### `mystic_circle_a2` — Mystic Circle

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | A circle for minor enchantments. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

#### `novice_tower_a2` — Novice Tower

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | A tower for aspiring mages. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

#### `spell_shelf_a2` — Spell Shelf

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | Scrolls await a worthy reader. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

### additional_hero

#### `levy_barracks_a2` — Levy Barracks

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | Barracks house new champions. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

#### `recruit_hall_a2` — Recruit Hall

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | Volunteers answer the call. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

#### `town_champion_a2` — Town Champion

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | A champion rises from the city. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

#### `volunteer_corps_a2` — Volunteer Corps

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | Citizens train as auxiliaries. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

### hybrid

#### `granary_shrine_a2` — Granary Shrine

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 1 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +2 wheat production in this city. +1 victory points. |
| flavour_text | Food and faith sustain the city. |
| effects | `[{"type": "production_flat", "resource": "wheat", "amount": 2}, {"type": "vp_flat", "amount": 1}]` |

#### `hero_monument_a2` — Hero Monument

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +2 victory points. +1 hero action(s) per turn for your heroes. |
| flavour_text | Heroes and history share a plinth. |
| effects | `[{"type": "vp_flat", "amount": 2}, {"type": "hero_actions_bonus", "amount": 1}]` |

#### `mage_market_a2` — Mage Market

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hybrid, wizard_trade_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 extra resource in trades you accept. |
| flavour_text | Arcane goods trade openly. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_trade_unlock"}, {"type": "trade_bonus", "amount": 2}]` |

#### `trade_watch_a2` — Trade Watch

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +1 extra resource in trades you accept. Demon occupation timer extended by 1 round(s) before purge. |
| flavour_text | Guards protect merchant routes. |
| effects | `[{"type": "trade_bonus", "amount": 1}, {"type": "city_demon_protection", "amount": 1}]` |

## Age 3

### production_bonuses

#### `brickworks_a3` — Brickworks

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +3 brick production in this city. |
| flavour_text | Kilns bake clay into sturdy brick. |
| effects | `[{"type": "production_flat", "resource": "brick", "amount": 3}]` |

#### `lumber_camp_a3` — Lumber Camp

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +3 wood production in this city. |
| flavour_text | Timber flows from the forest edge. |
| effects | `[{"type": "production_flat", "resource": "wood", "amount": 3}]` |

#### `ore_shaft_a3` — Ore Shaft

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +3 ore production in this city. |
| flavour_text | A shallow mine taps nearby ore. |
| effects | `[{"type": "production_flat", "resource": "ore", "amount": 3}]` |

#### `pasture_grant_a3` — Pasture Grant

| Field | Value |
|-------|-------|
| category | production_bonuses |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | production_bonuses |
| rules_text | +3 sheep production in this city. |
| flavour_text | Flocks graze the city outskirts. |
| effects | `[{"type": "production_flat", "resource": "sheep", "amount": 3}]` |

### vp_cards

#### `cathedral_a3` — Cathedral

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 3 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +3 victory points. |
| flavour_text | Woven histories adorn the walls. |
| effects | `[{"type": "vp_flat", "amount": 3}]` |

#### `palace_a3` — Palace

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 3 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +3 victory points. |
| flavour_text | A stone marker of civic pride. |
| effects | `[{"type": "vp_flat", "amount": 3}]` |

#### `triumph_a3` — Triumph

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +2 victory points. +1 VP per hero you control at game end. |
| flavour_text | Terraced gardens delight citizens. |
| effects | `[{"type": "vp_flat", "amount": 2}, {"type": "end_game_vp_per_hero", "amount": 1}]` |

#### `wonder_a3` — Wonder

| Field | Value |
|-------|-------|
| category | vp_cards |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 3 |
| implementation_status | implemented |
| tags | vp_cards |
| rules_text | +3 victory points. +1 VP per city you own at game end. |
| flavour_text | Rising stone honours the founders. |
| effects | `[{"type": "vp_flat", "amount": 3}, {"type": "end_game_vp_per_city", "amount": 1}]` |

### hero_ability

#### `militia_yard_a3` — Militia Yard

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +2 hero action(s) per turn for your heroes. |
| flavour_text | Drill grounds for town guards. |
| effects | `[{"type": "hero_actions_bonus", "amount": 2}]` |

#### `ranger_post_a3` — Ranger Post

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +2 hero action(s) per turn for your heroes. |
| flavour_text | Scouts train for swift patrols. |
| effects | `[{"type": "hero_actions_bonus", "amount": 2}]` |

#### `signal_beacon_a3` — Signal Beacon

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +2 hero action(s) per turn for your heroes. |
| flavour_text | Beacons coordinate hero movement. |
| effects | `[{"type": "hero_actions_bonus", "amount": 2}]` |

#### `supply_cache_a3` — Supply Cache

| Field | Value |
|-------|-------|
| category | hero_ability |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hero_ability |
| rules_text | +2 hero action(s) per turn for your heroes. |
| flavour_text | Stores extend expedition range. |
| effects | `[{"type": "hero_actions_bonus", "amount": 2}]` |

### anti_demon

#### `archon_seal_a3` — Archon Seal

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 3 round(s) before purge. |
| flavour_text | Blessed water guards the threshold. |
| effects | `[{"type": "city_demon_protection", "amount": 3}]` |

#### `demon_barrier_a3` — Demon Barrier

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 3 round(s) before purge. |
| flavour_text | Consecrated stone resists occupation. |
| effects | `[{"type": "city_demon_protection", "amount": 3}]` |

#### `holy_citadel_a3` — Holy Citadel

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | Demon occupation timer extended by 3 round(s) before purge. |
| flavour_text | Runes repel minor corruption. |
| effects | `[{"type": "city_demon_protection", "amount": 3}]` |

#### `purifying_flame_a3` — Purifying Flame

| Field | Value |
|-------|-------|
| category | anti_demon |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | anti_demon |
| rules_text | When played, remove 1 demon from this city if present. |
| flavour_text | Shrines watch for demonic presence. |
| effects | `[{"type": "demon_clear_on_play", "amount": 1}]` |

### trade_economy

#### `free_port_a3` — Free Port

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +2 extra resource in trades you accept. At next age start, look at the top card of your pack. |
| flavour_text | Official booth for fair deals. |
| effects | `[{"type": "trade_bonus", "amount": 2}, {"type": "draft_bonus", "amount": 1}]` |

#### `grand_bazaar_a3` — Grand Bazaar

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +2 extra resource in trades you accept. |
| flavour_text | Merchants barter surplus goods. |
| effects | `[{"type": "trade_bonus", "amount": 2}]` |

#### `merchant_prince_a3` — Merchant Prince

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +2 extra resource in trades you accept. |
| flavour_text | Travelling traders rest here. |
| effects | `[{"type": "trade_bonus", "amount": 2}]` |

#### `trade_emporium_a3` — Trade Emporium

| Field | Value |
|-------|-------|
| category | trade_economy |
| slot_type | economic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | trade_economy |
| rules_text | +2 extra resource in trades you accept. |
| flavour_text | A post for neighbourly exchange. |
| effects | `[{"type": "trade_bonus", "amount": 2}]` |

### wizard_access

#### `arcane_study_a3` — Arcane Study

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | Novices glimpse the wizard path. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

#### `mystic_circle_a3` — Mystic Circle

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | A circle for minor enchantments. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

#### `novice_tower_a3` — Novice Tower

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | A tower for aspiring mages. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

#### `spell_shelf_a3` — Spell Shelf

| Field | Value |
|-------|-------|
| category | wizard_access |
| slot_type | arcane |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | wizard_access, wizard_encounter_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +2 victory points. |
| flavour_text | Scrolls await a worthy reader. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_encounter_unlock"}, {"type": "vp_flat", "amount": 2}]` |

### additional_hero

#### `levy_barracks_a3` — Levy Barracks

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | Barracks house new champions. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

#### `recruit_hall_a3` — Recruit Hall

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | Volunteers answer the call. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

#### `town_champion_a3` — Town Champion

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | A champion rises from the city. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

#### `volunteer_corps_a3` — Volunteer Corps

| Field | Value |
|-------|-------|
| category | additional_hero |
| slot_type | military |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | additional_hero |
| rules_text | Spawn 1 hero at this city when played. |
| flavour_text | Citizens train as auxiliaries. |
| effects | `[{"type": "hero_spawn", "amount": 1}]` |

### hybrid

#### `granary_shrine_a3` — Granary Shrine

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 2 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +3 wheat production in this city. +2 victory points. |
| flavour_text | Food and faith sustain the city. |
| effects | `[{"type": "production_flat", "resource": "wheat", "amount": 3}, {"type": "vp_flat", "amount": 2}]` |

#### `hero_monument_a3` — Hero Monument

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 3 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +3 victory points. +2 hero action(s) per turn for your heroes. |
| flavour_text | Heroes and history share a plinth. |
| effects | `[{"type": "vp_flat", "amount": 3}, {"type": "hero_actions_bonus", "amount": 2}]` |

#### `mage_market_a3` — Mage Market

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hybrid, wizard_trade_unlock |
| rules_text | Grants wizard encounter access (macro: bonus VP as shown). +3 extra resource in trades you accept. |
| flavour_text | Arcane goods trade openly. |
| effects | `[{"type": "wizard_access", "amount": 1, "tag": "wizard_trade_unlock"}, {"type": "trade_bonus", "amount": 3}]` |

#### `trade_watch_a3` — Trade Watch

| Field | Value |
|-------|-------|
| category | hybrid |
| slot_type | civic |
| cost | {"wheat": 1, "sheep": 1, "ore": 1} |
| vp | 0 |
| implementation_status | implemented |
| tags | hybrid |
| rules_text | +1 extra resource in trades you accept. Demon occupation timer extended by 2 round(s) before purge. |
| flavour_text | Guards protect merchant routes. |
| effects | `[{"type": "trade_bonus", "amount": 1}, {"type": "city_demon_protection", "amount": 2}]` |
