class_name TestProduction
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var state := TestScenario.build_standard_game(42)
	var events := TestScenario.run_production_rounds(state, 1)

	var check_count := 0
	var gain_count := 0
	for event in events:
		if event is ProductionCheckEvent:
			check_count += 1
		if event is ResourceGainedEvent:
			gain_count += 1

	test_assert.check(check_count > 0, "production round should emit check events")
	test_assert.check(gain_count > 0, "production round should grant at least one resource")

	var alice := state.players[0]
	var bob := state.players[1]
	var total_resources := 0
	for resource in ResourceType.all():
		total_resources += alice.get_resource(resource)
		total_resources += bob.get_resource(resource)
	test_assert.eq(total_resources, gain_count, "resource totals should match gain events")

	test_assert.eq(state.turn_number, 1, "one production round should advance turn to 1")

	var events_round_two := ProductionRules.resolve_start_of_turn_production(state)
	test_assert.check(not events_round_two.is_empty(), "second production round should emit events")
	test_assert.eq(state.turn_number, 2, "second production round should advance turn to 2")
