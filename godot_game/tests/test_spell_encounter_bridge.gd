class_name TestSpellEncounterBridge
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_create_session_deterministic(test_assert)
	_test_round_trip_when_hero_wins(test_assert)
	_test_outcome_noop_when_unfinished(test_assert)


static func _test_create_session_deterministic(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(99)
	var hero := state.heroes[0]
	var node_key := hero.node.to_key()
	var session_a := SpellEncounterBridge.create_session(state, node_key, hero.id)
	var session_b := SpellEncounterBridge.create_session(state, node_key, hero.id)
	test_assert.eq(session_a.seed, session_b.seed, "bridge should derive deterministic combat seed")
	test_assert.eq(session_a.combatants.size(), 2, "bridge should start 1v1 duel")


static func _test_round_trip_when_hero_wins(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var hero := state.heroes[0]
	var node := hero.node
	SetupRules.set_demon_count(state, node, 2)
	var combat := SpellEncounterBridge.create_session(state, node.to_key(), hero.id)
	SpellEncounterBridge.run_to_completion(combat, 120)
	if combat.winner_id != EncounterSessionRules.HERO_LOADOUT:
		return
	var events := SpellEncounterBridge.apply_outcome(state, combat, hero.id, node.to_key())
	test_assert.eq(SetupRules.get_demon_count(state, node), 0, "hero win should clear demons via bridge")
	test_assert.check(events.size() >= 1, "hero win should emit clearance events")


static func _test_outcome_noop_when_unfinished(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(7)
	var hero := state.heroes[0]
	var combat := SpellEncounterBridge.create_session(state, hero.node.to_key(), hero.id)
	var events := SpellEncounterBridge.apply_outcome(state, combat, hero.id, hero.node.to_key())
	test_assert.eq(events.size(), 0, "unfinished combat should not apply macro outcome")
