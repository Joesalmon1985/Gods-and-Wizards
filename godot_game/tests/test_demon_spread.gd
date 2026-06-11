class_name TestDemonSpread
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_bot_ready_game(42)
	var source := state.cities[0].vertex
	SetupRules.set_demon_count(state, source, 2)

	var events := SpreadRules.resolve_spread(state)
	test_assert.check(events.size() >= 1, "demons should spread from occupied node")

	var spread_events := 0
	for event in events:
		if event is DemonSpreadEvent:
			spread_events += 1
	test_assert.check(spread_events >= 1, "spread should emit DemonSpreadEvent")

	var first := _spread_signature(_fresh_demon_state())
	var second := _spread_signature(_fresh_demon_state())
	test_assert.eq(first, second, "spread should be deterministic with fixed setup")


static func _fresh_demon_state() -> GameState:
	var state := ScenarioBuilder.build_bot_ready_game(99)
	state.rng.seed(99)
	var source := state.cities[0].vertex
	SetupRules.set_demon_count(state, source, 2)
	return state


static func _spread_signature(state: GameState) -> String:
	var events := SpreadRules.resolve_spread(state)
	var parts: Array[String] = []
	for event in events:
		if event is DemonSpreadEvent:
			var spread: DemonSpreadEvent = event
			parts.append("%s->%s:%d" % [spread.from_node.to_key(), spread.to_node.to_key(), spread.amount])
		elif event is BreachEvent:
			var breach: BreachEvent = event
			parts.append("breach:%d" % breach.breach_count)
	return "|".join(parts)
