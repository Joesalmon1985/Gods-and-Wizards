class_name MicroBaselinePolicies
extends RefCounted

const POLICY_RANDOM := "random"
const POLICY_DAMAGE_FIRST := "damage_first"
const POLICY_SURVIVAL := "survival"
const POLICY_MANA_EFFICIENT := "mana_efficient"


static func choose_spell_id(env: MicroCombatTrainingEnv, policy_name: String) -> String:
	var legal := env.get_legal_spell_ids()
	if legal.is_empty():
		return SpellCombatRules.PASS_SPELL_ID
	match policy_name:
		POLICY_RANDOM:
			return legal[_seeded_index(env.session.seed + env.session.timeline.size(), legal.size())]
		POLICY_DAMAGE_FIRST:
			return _choose_damage_first(env, legal)
		POLICY_SURVIVAL:
			return _choose_survival(env, legal)
		POLICY_MANA_EFFICIENT:
			return _choose_mana_efficient(env, legal)
		_:
			return legal[0]


static func _choose_damage_first(_env: MicroCombatTrainingEnv, legal: Array[String]) -> String:
	for spell_id in legal:
		if spell_id.contains("bolt") or spell_id.contains("strike") or spell_id.contains("blast"):
			return spell_id
	return legal[0]


static func _choose_survival(env: MicroCombatTrainingEnv, legal: Array[String]) -> String:
	var caster: Dictionary = env.session.get_active_combatant()
	if float(caster.get("health", 100.0)) < 35.0:
		for spell_id in legal:
			if spell_id.contains("heal") or spell_id.contains("ward"):
				return spell_id
	return legal[0]


static func _choose_mana_efficient(_env: MicroCombatTrainingEnv, legal: Array[String]) -> String:
	return legal[0]


static func _seeded_index(seed: int, size: int) -> int:
	if size <= 0:
		return 0
	var rng := GameRng.new()
	rng.seed = seed
	return rng.randi_range(0, size - 1)
