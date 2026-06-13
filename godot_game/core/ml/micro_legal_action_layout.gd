class_name MicroLegalActionLayout
extends RefCounted

## Loadout spell indices plus a dedicated pass slot (last index).

const LAYOUT_VERSION := "loadout_spells_plus_pass_v1"


static func pass_slot_index(loadout: CombatantSpellLoadout) -> int:
	return loadout.spell_ids.size()


static func build_mask(session: SpellCombatSession) -> Array[int]:
	var loadout: CombatantSpellLoadout = session.get_active_combatant()["loadout"]
	var legal := session.get_legal_spell_ids()
	var mask: Array[int] = []
	for spell_id in loadout.spell_ids:
		mask.append(1 if legal.has(spell_id) else 0)
	mask.append(1)
	return mask


static func spell_id_for_slot(loadout: CombatantSpellLoadout, slot_index: int) -> String:
	var pass_index := pass_slot_index(loadout)
	if slot_index == pass_index:
		return SpellCombatRules.PASS_SPELL_ID
	if slot_index < 0 or slot_index >= pass_index:
		return SpellCombatRules.PASS_SPELL_ID
	return loadout.spell_ids[slot_index]
