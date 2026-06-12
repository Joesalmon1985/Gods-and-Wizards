class_name TestEncounterSessionRules
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_encounter_id_stable(test_assert)
	_test_combat_seed_deterministic(test_assert)
	_test_loadouts(test_assert)


static func _test_encounter_id_stable(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var id_a := EncounterSessionRules.derive_encounter_id(state, "hex|0|0|n0", 1)
	var id_b := EncounterSessionRules.derive_encounter_id(state, "hex|0|0|n0", 1)
	test_assert.eq(id_a, id_b, "encounter id should be stable")
	test_assert.check(id_a.begins_with("enc_"), "encounter id should have prefix")


static func _test_combat_seed_deterministic(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var encounter_id := EncounterSessionRules.derive_encounter_id(state, "node_a", 2)
	var seed_a := EncounterSessionRules.derive_combat_seed(state, encounter_id)
	var seed_b := EncounterSessionRules.derive_combat_seed(state, encounter_id)
	test_assert.eq(seed_a, seed_b, "combat seed should be deterministic")


static func _test_loadouts(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(1)
	var loadouts := EncounterSessionRules.derive_loadouts(state, 0)
	test_assert.eq(str(loadouts.get("hero_loadout_id", "")), "hero_patrol", "hero loadout fixture")
	test_assert.eq(str(loadouts.get("demon_loadout_id", "")), "demon_breach", "demon loadout fixture")
