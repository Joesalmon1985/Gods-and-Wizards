class_name SpellCombatRules
extends RefCounted

const PASS_SPELL_ID := "__pass__"


static func is_pass(spell_id: String) -> bool:
	return spell_id == PASS_SPELL_ID


static func can_cast(
	spell: SpellDefinition,
	caster_mana: float,
	sim_time: float,
	cooldown_until: float
) -> bool:
	if spell == null:
		return false
	if caster_mana < spell.mana_cost:
		return false
	if sim_time < cooldown_until:
		return false
	return true


static func legal_spell_ids(
	loadout: CombatantSpellLoadout,
	catalog: SpellCatalog,
	caster_mana: float,
	sim_time: float,
	cooldowns: Dictionary
) -> Array[String]:
	var legal: Array[String] = []
	for spell_id in loadout.spell_ids:
		var spell := catalog.get_spell(spell_id)
		var ready_at := float(cooldowns.get(spell_id, 0.0))
		if can_cast(spell, caster_mana, sim_time, ready_at):
			legal.append(spell_id)
	legal.sort()
	return legal


static func apply_spell_effects(
	spell: SpellDefinition,
	caster: Dictionary,
	target: Dictionary
) -> Dictionary:
	var damage_to_target := 0.0
	var heal_to_caster := 0.0

	if spell.damage > 0.0 and not spell.target_self_ok:
		damage_to_target = spell.damage
	elif spell.damage > 0.0 and spell.target_self_ok:
		damage_to_target = 0.0

	if spell.heal > 0.0:
		if spell.target_self_ok:
			heal_to_caster = spell.heal
		else:
			damage_to_target = maxf(0.0, damage_to_target - spell.heal)

	caster["health"] = float(caster["health"]) + spell.delta_hp_caster + heal_to_caster
	caster["mana"] = float(caster["mana"]) + spell.delta_mana_caster - spell.mana_cost
	target["health"] = maxf(0.0, float(target["health"]) - damage_to_target)

	if spell.lifesteal_frac > 0.0 and damage_to_target > 0.0:
		caster["health"] = float(caster["health"]) + damage_to_target * spell.lifesteal_frac

	return {
		"damage_to_target": damage_to_target,
		"heal_to_caster": heal_to_caster,
	}
