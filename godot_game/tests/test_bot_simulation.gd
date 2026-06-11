class_name TestBotSimulation
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var first := JSON.stringify(GameSimulator.run(42, 3)["snapshot"])
	var second := JSON.stringify(GameSimulator.run(42, 3)["snapshot"])
	test_assert.eq(first, second, "same seed should produce identical simulation snapshots")

	var different := JSON.stringify(GameSimulator.run(43, 3)["snapshot"])
	test_assert.check(first != different, "different seeds should produce different snapshots")

	var result := GameSimulator.run(42, 3)
	var build_count := 0
	for event in result["events"]:
		if event is CityBuiltEvent:
			build_count += 1
	test_assert.check(build_count >= 1, "simulation should apply at least one BUILD_CITY")

	test_assert.eq(result["state"].players.size(), 2, "default simulation should use two players")
