class_name TestEncounterResolver
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var rng_a := GameRng.new()
	rng_a.seed(123)
	rng_a.enqueue_fixed_rolls([10, 4, 10, 4, 10, 4])

	var rng_b := GameRng.new()
	rng_b.seed(123)
	rng_b.enqueue_fixed_rolls([10, 4, 10, 4, 10, 4])

	var result_a := _run_encounter(rng_a)
	var result_b := _run_encounter(rng_b)
	test_assert.eq(JSON.stringify(result_a), JSON.stringify(result_b), "encounter should be deterministic")
	test_assert.check(result_a["winner_id"] != "", "encounter should produce a winner")


static func _run_encounter(rng: GameRng) -> Dictionary:
	var attacker_deck := CombatDeckRuntime.new()
	var defender_deck := CombatDeckRuntime.new()
	attacker_deck.init_from(CombatResolver.default_warrior_deck(), rng)
	defender_deck.init_from(CombatResolver.default_warrior_deck(), rng)
	var attacker := CombatantState.new("hero", 10, attacker_deck)
	var defender := CombatantState.new("demon", 5, defender_deck)
	return CombatResolver.resolve_encounter(
		rng,
		attacker,
		defender,
		[&"thrust", &"thrust", &"thrust", &"thrust"],
		[&"swing", &"swing", &"swing", &"swing"]
	)
