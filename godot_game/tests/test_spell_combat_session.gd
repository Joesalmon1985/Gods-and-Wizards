class_name TestSpellCombatSession
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_seeded_duel_deterministic(test_assert)
	_test_legal_spells_respect_mana_and_cooldown(test_assert)
	_test_illegal_spell_rejected(test_assert)
	_test_timeline_has_terminal_event(test_assert)
	_test_headless_no_scene_imports(test_assert)


static func _test_seeded_duel_deterministic(test_assert: TestAssert) -> void:
	var session_a := SpellCombatSession.start_duel(123, "hero_patrol", "demon_breach")
	var session_b := SpellCombatSession.start_duel(123, "hero_patrol", "demon_breach")
	var steps := 0
	while not session_a.finished and steps < 80:
		session_a.step_deterministic_policy()
		session_b.step_deterministic_policy()
		steps += 1
	test_assert.eq(session_a.winner_id, session_b.winner_id, "same seed should produce same winner")
	test_assert.eq(
		JSON.stringify(session_a.timeline),
		JSON.stringify(session_b.timeline),
		"same seed should produce identical timeline"
	)


static func _test_legal_spells_respect_mana_and_cooldown(test_assert: TestAssert) -> void:
	var session := SpellCombatSession.start_duel(7, "hero_patrol", "demon_breach")
	var caster: Dictionary = session.get_active_combatant()
	caster["mana"] = 0.0
	var legal := session.get_legal_spell_ids()
	test_assert.eq(legal.size(), 0, "zero mana should leave no legal spells")


static func _test_illegal_spell_rejected(test_assert: TestAssert) -> void:
	var session := SpellCombatSession.start_duel(7, "hero_patrol", "demon_breach")
	var health_before := float(session.get_opponent()["health"])
	var result := session.step("not_a_real_spell")
	test_assert.check(result["events"].is_empty(), "illegal spell should produce no events")
	test_assert.eq(float(session.get_opponent()["health"]), health_before, "illegal spell should not mutate health")


static func _test_timeline_has_terminal_event(test_assert: TestAssert) -> void:
	var session := SpellCombatSession.start_duel(123, "hero_patrol", "demon_breach")
	var steps := 0
	while not session.finished and steps < 120:
		session.step_deterministic_policy()
		steps += 1
	test_assert.check(session.finished, "duel should finish within step budget")
	var has_end := false
	for event in session.timeline:
		if str(event.get("type", "")) == "combat_end":
			has_end = true
	test_assert.check(has_end, "timeline should include combat_end")


static func _test_headless_no_scene_imports(test_assert: TestAssert) -> void:
	for path in [
		"res://core/combat/spell_combat_session.gd",
		"res://core/combat/spell_combat_rules.gd",
		"res://core/sim/micro_combat_training_env.gd",
	]:
		var text := FileAccess.get_file_as_string(path)
		test_assert.check("Node2D" not in text and "Node3D" not in text, "%s should stay headless" % path)
