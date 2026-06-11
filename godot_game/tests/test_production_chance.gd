class_name TestProductionChance
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_chance_zero_skips(test_assert)
	_test_nine_roll_8_produces(test_assert)
	_test_nine_roll_9_fails(test_assert)
	_test_five_roll_4_produces(test_assert)
	_test_five_roll_5_fails(test_assert)
	_test_event_schema(test_assert)


static func _test_chance_zero_skips(test_assert: TestAssert) -> void:
	var state := ProductionFixtures.build_minimal_production_state({
		ResourceType.Type.WOOD: 0,
	})
	state.rng.enqueue_fixed_rolls([9])

	var events := ProductionRules.resolve_round_production(state)
	test_assert.eq(events.size(), 0, "chance 0 should skip production checks")
	test_assert.eq(state.rng.fixed_rolls_remaining(), 1, "chance 0 should not consume queued rolls")


static func _test_nine_roll_8_produces(test_assert: TestAssert) -> void:
	var produced := _run_single_check(ResourceType.Type.WOOD, 9, 8)
	test_assert.check(produced, "chance 9 with roll 8 should produce")


static func _test_nine_roll_9_fails(test_assert: TestAssert) -> void:
	var produced := _run_single_check(ResourceType.Type.WOOD, 9, 9)
	test_assert.check(not produced, "chance 9 with roll 9 should not produce")


static func _test_five_roll_4_produces(test_assert: TestAssert) -> void:
	var produced := _run_single_check(ResourceType.Type.WOOD, 5, 4)
	test_assert.check(produced, "chance 5 with roll 4 should produce")


static func _test_five_roll_5_fails(test_assert: TestAssert) -> void:
	var produced := _run_single_check(ResourceType.Type.WOOD, 5, 5)
	test_assert.check(not produced, "chance 5 with roll 5 should not produce")


static func _test_event_schema(test_assert: TestAssert) -> void:
	var state := ProductionFixtures.build_minimal_production_state({
		ResourceType.Type.WOOD: 9,
	})
	state.rng.enqueue_fixed_rolls([3])
	var events := ProductionRules.resolve_round_production(state)
	test_assert.eq(events.size(), 1, "single check should emit one event")

	var event: ProductionCheckEvent = events[0]
	var data := event.to_dict()
	test_assert.eq(data.get("schema_version"), 1, "production check should include schema_version")
	test_assert.eq(data.get("production_chance"), 9, "event should record production_chance")
	test_assert.eq(data.get("roll"), 3, "event should record int roll")
	test_assert.eq(data.get("produced"), true, "event should record produced flag")


static func _run_single_check(resource: ResourceType.Type, chance: int, roll: int) -> bool:
	var state := ProductionFixtures.build_minimal_production_state({
		resource: chance,
	})
	state.rng.enqueue_fixed_rolls([roll])
	var events := ProductionRules.resolve_round_production(state)
	if events.is_empty():
		return false
	var event: ProductionCheckEvent = events[0]
	return event.produced
