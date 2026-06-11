class_name TestEventLog
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var log := EventLog.new()
	var event_a := TurnEndedEvent.new(1, 0)
	var event_b := CityBuiltEvent.new(1, 0, VertexCoord.from_hex_corner(HexCoord.new(0, 0), 1))

	log.append(event_a)
	log.append(event_b)
	test_assert.eq(log.entries.size(), 2, "event log should store entries")
	test_assert.eq(log.entries[0]["sequence_id"], 0, "first sequence id should be 0")
	test_assert.eq(log.entries[1]["sequence_id"], 1, "sequence ids should be monotonic")

	var state := ScenarioBuilder.build_bot_ready_game(42)
	var view := LegalActionQuery.get_view(state)
	log.append_legal_mask(view, state.round_number, TurnRules.get_active_player_id(state))
	test_assert.eq(log.entries.size(), 3, "mask recording should append an entry")
	test_assert.eq(log.entries[2]["type"], "action_mask_recorded", "mask entry should be typed")

	var result := GameSimulator.run(42, 2)
	var sim_log: EventLog = result["event_log"]
	test_assert.check(sim_log.entries.size() > 0, "simulator should populate event log")

	var mask_count := 0
	for entry in sim_log.entries:
		if entry["type"] == "action_mask_recorded":
			mask_count += 1
	test_assert.check(mask_count > 0, "simulation should record action masks")

	var first := JSON.stringify(sim_log.to_dict())
	var second := JSON.stringify(GameSimulator.run(42, 2)["event_log"].to_dict())
	test_assert.eq(first, second, "event log should be deterministic")

	_assert_sequence_ids_match_indices(test_assert, sim_log)


static func _assert_sequence_ids_match_indices(test_assert: TestAssert, log: EventLog) -> void:
	for i in range(log.entries.size()):
		var entry: Dictionary = log.entries[i]
		test_assert.eq(
			entry["sequence_id"],
			i,
			"event log sequence_id should equal entry index"
		)
		if i > 0:
			var previous: Dictionary = log.entries[i - 1]
			test_assert.check(
				entry["sequence_id"] > previous["sequence_id"],
				"event log sequence_id should strictly increase"
			)
