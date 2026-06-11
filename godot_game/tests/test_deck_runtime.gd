class_name TestDeckRuntime
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var rng_a := GameRng.new()
	rng_a.seed(42)
	var rng_b := GameRng.new()
	rng_b.seed(42)

	var deck_a := CombatDeckRuntime.new()
	var deck_b := CombatDeckRuntime.new()
	var definition := CombatResolver.default_warrior_deck()
	deck_a.init_from(definition, rng_a)
	deck_b.init_from(definition, rng_b)

	test_assert.eq(deck_a.draw_pile.size(), deck_b.draw_pile.size(), "same seed should shuffle to same pile size")
	deck_a.draw_until(3, rng_a)
	deck_b.draw_until(3, rng_b)
	test_assert.eq(deck_a.hand.size(), deck_b.hand.size(), "same seed should draw same hand size")

	var first_moves: Array[String] = []
	var second_moves: Array[String] = []
	for card in deck_a.hand:
		first_moves.append(String(card.move_id))
	for card in deck_b.hand:
		second_moves.append(String(card.move_id))
	test_assert.eq(JSON.stringify(first_moves), JSON.stringify(second_moves), "draw order should be deterministic")
