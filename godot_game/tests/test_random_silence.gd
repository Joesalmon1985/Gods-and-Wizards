class_name TestRandomSilence
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_quiet_applies_random_silence(test_assert)
	_test_random_silence_event_emitted(test_assert)


static func _target() -> Dictionary:
	return {
		"id": "b",
		"health": 100.0,
		"mana": 100.0,
		"max_health": 100.0,
		"max_mana": 100.0,
		"statuses": [],
	}


static func _test_quiet_applies_random_silence(test_assert: TestAssert) -> void:
	var catalog := SpellCatalog.load_default()
	var spell := catalog.get_spell("quiet")
	test_assert.check(spell != null, "quiet spell should exist")
	test_assert.check(spell.silence_random_duration > 0.0, "quiet should define silence_random_duration")
	var target := _target()
	var caster := _target()
	caster["id"] = "a"
	SpellCombatRules.apply_spell_effects(spell, caster, target, 5.0)
	test_assert.check(SpellCombatStatusRules.is_silenced(target, 5.5), "quiet should silence target")


static func _test_random_silence_event_emitted(test_assert: TestAssert) -> void:
	var catalog := SpellCatalog.load_default()
	var spell := catalog.get_spell("spell_shock")
	var target := _target()
	var events := SpellCombatStatusRules.apply_spell_statuses(spell, _target(), target, 0.0)
	var found := false
	for event in events:
		if str(event.get("type", "")) == "random_silence_applied":
			found = true
	test_assert.check(found, "spell_shock random silence should emit random_silence_applied")
