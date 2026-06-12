class_name TestSpellEffectFidelity
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_dot_damage_over_time(test_assert)
	_test_barrier_absorbs_damage(test_assert)
	_test_shield_blocks_hit(test_assert)
	_test_silence_blocks_cast(test_assert)
	_test_status_expires(test_assert)
	_test_observe_includes_status_and_cooldowns(test_assert)
	_test_deterministic_replay(test_assert)


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


static func _test_dot_damage_over_time(test_assert: TestAssert) -> void:
	var target := _target()
	SpellCombatStatusRules.apply_spell_statuses(_spell_with_dot(), _caster(), target, 0.0)
	var hp_before := float(target["health"])
	var events := SpellCombatStatusRules.tick_statuses(target, 1.0)
	test_assert.check(float(target["health"]) < hp_before, "DoT should damage over time")
	test_assert.check(not events.is_empty(), "DoT emits tick event")


static func _test_barrier_absorbs_damage(test_assert: TestAssert) -> void:
	var target := _target()
	target["statuses"] = [{"kind": "barrier", "absorb": 10.0, "expires_at": 99.0, "spell_id": "harden"}]
	var resolved := SpellCombatStatusRules.resolve_incoming_damage(target, 6.0, 1.0)
	test_assert.eq(float(resolved["damage"]), 0.0, "barrier absorbs incoming damage")


static func _test_shield_blocks_hit(test_assert: TestAssert) -> void:
	var target := _target()
	target["statuses"] = [{"kind": "shield", "charges": 1, "expires_at": 99.0, "spell_id": "shield"}]
	var resolved := SpellCombatStatusRules.resolve_incoming_damage(target, 20.0, 1.0)
	test_assert.eq(float(resolved["damage"]), 0.0, "shield blocks hit")


static func _test_silence_blocks_cast(test_assert: TestAssert) -> void:
	var caster := _caster()
	caster["statuses"] = [{"kind": "silence", "expires_at": 99.0, "spell_id": "silence"}]
	var spell := SpellDefinition.new()
	spell.mana_cost = 1.0
	test_assert.check(not SpellCombatRules.can_cast(spell, caster, 10.0, 0.0, 0.0), "silence blocks cast")


static func _test_status_expires(test_assert: TestAssert) -> void:
	var target := _target()
	target["statuses"] = [{"kind": "dot", "dps": 1.0, "expires_at": 1.0, "spell_id": "blight"}]
	var events := SpellCombatStatusRules.tick_statuses(target, 2.0)
	var expired := false
	for event in events:
		if str(event.get("type", "")) == "status_expired":
			expired = true
	test_assert.check(expired, "status expiry emits event")


static func _test_observe_includes_status_and_cooldowns(test_assert: TestAssert) -> void:
	var session := SpellCombatSession.start_duel(42, "hero_patrol", "demon_breach")
	session.step(SpellCombatRules.PASS_SPELL_ID)
	var obs := session.observe()
	test_assert.check(obs.has("cooldowns_by_spell_id"), "observation includes cooldown map")
	test_assert.check(obs.has("statuses"), "observation includes statuses")


static func _test_deterministic_replay(test_assert: TestAssert) -> void:
	var a := _timeline_signature(77)
	var b := _timeline_signature(77)
	test_assert.eq(a, b, "spell combat replay deterministic from seed")


static func _timeline_signature(seed: int) -> String:
	var session := SpellCombatSession.start_duel(seed, "hero_patrol", "demon_breach")
	for _i in 8:
		if session.finished:
			break
		session.step_deterministic_policy()
	var parts: Array[String] = []
	for event in session.timeline:
		parts.append("%s:%s" % [str(event.get("type", "")), str(event.get("spell_id", ""))])
	return "|".join(parts)


static func _spell_with_dot() -> SpellDefinition:
	var spell := SpellDefinition.new()
	spell.spell_id = "blight"
	spell.dot_dps = 5.0
	spell.dot_duration = 3.0
	return spell
