class_name TestEncounterProximity
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_detects_city_in_range(test_assert)
	_test_out_of_range(test_assert)
	_test_deterministic_from_snapshot(test_assert)


static func _test_detects_city_in_range(test_assert: TestAssert) -> void:
	var snapshot := _snapshot_with_city_at(Vector3(0.0, 0.0, 0.0))
	var result := EncounterProximity.check(snapshot, {"x": 0.5, "y": 0.0, "z": 0.5}, 2.0)
	test_assert.check(bool(result.get("in_range", false)), "marker near city should be in range")
	test_assert.eq(str(result.get("target_type", "")), "city", "nearest target should be city")


static func _test_out_of_range(test_assert: TestAssert) -> void:
	var snapshot := _snapshot_with_city_at(Vector3(0.0, 0.0, 0.0))
	var result := EncounterProximity.check(snapshot, {"x": 50.0, "y": 0.0, "z": 50.0}, 2.0)
	test_assert.check(not bool(result.get("in_range", false)), "distant marker should be out of range")


static func _test_deterministic_from_snapshot(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var snapshot := BoardWorldMapper.build_snapshot(state, [])
	var marker := snapshot.get("nodes", [])[0].get("world", {})
	var a := EncounterProximity.check(snapshot, marker, 20.0)
	var b := EncounterProximity.check(snapshot, marker, 20.0)
	test_assert.eq(JSON.stringify(a), JSON.stringify(b), "proximity check should be deterministic")


static func _snapshot_with_city_at(world: Vector3) -> Dictionary:
	return {
		"nodes": [{"id": "n0", "world": {"x": world.x, "y": world.y, "z": world.z}}],
		"cities": [{"id": "city:n0", "node_id": "n0", "player_id": 0}],
		"heroes": [],
		"demons": [],
	}
