class_name TestCounterSpell
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_counter_spell_applies_silence(test_assert)
	_test_counter_spell_clears_dots(test_assert)


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
		"statuses": [{"kind": "dot", "dps": 5.0, "expires_at": 99.0, "spell_id": "blight"}],
	}


static func _test_counter_spell_applies_silence(test_assert: TestAssert) -> void:
	var caster := _caster()
	var target := _target()
	var events := SpellCombatStatusRules.apply_counter_spell(caster, target, 1.0)
	var found := false
	for event in events:
		if str(event.get("type", "")) == "counter_spell_applied":
			found = true
	test_assert.check(found, "counter spell should emit counter_spell_applied event")
	test_assert.check(SpellCombatStatusRules.is_silenced(target, 1.5), "target should be silenced after counter")


static func _test_counter_spell_clears_dots(test_assert: TestAssert) -> void:
	var target := _target()
	SpellCombatStatusRules.apply_counter_spell(_caster(), target, 0.0)
	var has_dot := false
	for status in target["statuses"]:
		if str(status.get("kind", "")) == "dot":
			has_dot = true
	test_assert.check(not has_dot, "counter spell should clear DoT statuses")
