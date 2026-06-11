class_name TestDeterminism
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_m1_production_determinism(test_assert)
	_test_full_simulation_snapshot(test_assert)
	_test_full_event_log(test_assert)
	_test_different_seed(test_assert)
	_test_action_trace(test_assert)


static func _test_m1_production_determinism(test_assert: TestAssert) -> void:
	var first := JSON.stringify(_run_m1_scenario(42))
	var second := JSON.stringify(_run_m1_scenario(42))
	test_assert.eq(first, second, "same seed should produce identical M1 production snapshots")


static func _test_full_simulation_snapshot(test_assert: TestAssert) -> void:
	var first := JSON.stringify(GameSimulator.run(42, 3)["snapshot"])
	var second := JSON.stringify(GameSimulator.run(42, 3)["snapshot"])
	test_assert.eq(first, second, "same seed should produce identical full simulation snapshots")


static func _test_full_event_log(test_assert: TestAssert) -> void:
	var first := JSON.stringify(GameSimulator.run(42, 3)["event_log"].to_dict())
	var second := JSON.stringify(GameSimulator.run(42, 3)["event_log"].to_dict())
	test_assert.eq(first, second, "same seed should produce identical event logs")


static func _test_different_seed(test_assert: TestAssert) -> void:
	var seed_42 := JSON.stringify(_run_m1_scenario(42))
	var seed_43 := JSON.stringify(_run_m1_scenario(43))
	test_assert.check(seed_42 != seed_43, "different seeds should produce different M1 snapshots")

	var sim_42 := JSON.stringify(GameSimulator.run(42, 3)["snapshot"])
	var sim_43 := JSON.stringify(GameSimulator.run(43, 3)["snapshot"])
	test_assert.check(sim_42 != sim_43, "different seeds should produce different simulation snapshots")


static func _test_action_trace(test_assert: TestAssert) -> void:
	var first := _simulation_action_trace(42, 3)
	var second := _simulation_action_trace(42, 3)
	test_assert.eq(first, second, "same seed should produce identical simulation action trace")


static func _run_m1_scenario(game_seed: int) -> Dictionary:
	var state := TestScenario.build_standard_game(game_seed)
	var events := TestScenario.run_production_rounds(state, 3)
	return GameSnapshot.snapshot(state, events)


static func _simulation_action_trace(game_seed: int, rounds: int) -> Array:
	var result := GameSimulator.run(game_seed, rounds)
	var log: EventLog = result["event_log"]
	var trace: Array = []
	for entry in log.entries:
		var entry_type: String = entry["type"]
		if entry_type in ["city_built", "turn_ended", "action_mask_recorded"]:
			trace.append(entry_type)
	return trace
