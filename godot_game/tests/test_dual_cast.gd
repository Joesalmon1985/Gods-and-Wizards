class_name TestDualCast
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_dual_cast_doubles_damage(test_assert)


static func _caster() -> Dictionary:
	return {
		"id": "a",
		"health": 100.0,
		"mana": 100.0,
		"max_health": 100.0,
		"max_mana": 100.0,
		"statuses": [],
	}


static func _target() -> Dictionary:
	return {
		"id": "b",
		"health": 100.0,
		"mana": 100.0,
		"max_health": 100.0,
		"max_mana": 100.0,
		"statuses": [],
	}


static func _test_dual_cast_doubles_damage(test_assert: TestAssert) -> void:
	var catalog := SpellCatalog.load_default()
	var spell := catalog.get_spell("spell_shock")
	test_assert.check(spell != null and spell.dual_cast, "spell_shock should be dual_cast in catalog")

	var single_target := _target()
	var single_outcome := SpellCombatRules.apply_spell_effects(
		spell,
		_caster(),
		single_target,
		0.0
	)

	var dual_caster := _caster()
	var dual_target := _target()
	var dual_outcome := SpellCombatRules.apply_spell_effects(spell, dual_caster, dual_target, 0.0)
	if spell.dual_cast:
		var second_outcome := SpellCombatRules.apply_spell_effects(spell, dual_caster, dual_target, 0.0)
		dual_outcome["damage_to_target"] = float(dual_outcome["damage_to_target"]) + float(second_outcome["damage_to_target"])

	test_assert.eq(
		float(dual_outcome["damage_to_target"]),
		float(single_outcome["damage_to_target"]) * 2.0,
		"dual_cast should double spell_shock damage"
	)
