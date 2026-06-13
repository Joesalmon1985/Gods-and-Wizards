class_name TestMicroLegalActionLayout
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_pass_slot_always_legal(test_assert)
	_test_mask_width_matches_policy_head(test_assert)


static func _test_pass_slot_always_legal(test_assert: TestAssert) -> void:
	var env := MicroCombatTrainingEnv.new()
	env.reset(5, "hero_patrol", "demon_breach")
	var caster: Dictionary = env.session.get_active_combatant()
	caster["mana"] = 0.0
	var mask := MicroLegalActionLayout.build_mask(env.session)
	var pass_index := MicroLegalActionLayout.pass_slot_index(caster["loadout"])
	test_assert.check(mask.size() == pass_index + 1, "mask should include pass slot")
	test_assert.eq(mask[pass_index], 1, "pass slot should be legal when spells exhausted")


static func _test_mask_width_matches_policy_head(test_assert: TestAssert) -> void:
	var env := MicroCombatTrainingEnv.new()
	env.reset(8, "hero_patrol", "demon_breach")
	var mask := env.build_legal_mask()
	test_assert.eq(mask.size(), 6, "hero_patrol mask should be five spells plus pass")
