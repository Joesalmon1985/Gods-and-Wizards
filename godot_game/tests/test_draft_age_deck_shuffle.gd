class_name TestDraftAgeDeckShuffle
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_shuffle_deterministic(test_assert)
	_test_shuffle_uses_age_cards_only(test_assert)


static func _test_shuffle_deterministic(test_assert: TestAssert) -> void:
	var state_a := ScenarioBuilder.build_four_player_bot_game(42)
	var state_b := ScenarioBuilder.build_four_player_bot_game(42)
	var deck_a := DraftRules.build_shuffled_age_deck(state_a, 1)
	var deck_b := DraftRules.build_shuffled_age_deck(state_b, 1)
	test_assert.eq(deck_a, deck_b, "same seed should shuffle age deck identically")


static func _test_shuffle_uses_age_cards_only(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(99)
	var deck := DraftRules.build_shuffled_age_deck(state, 2)
	test_assert.eq(deck.size(), 32, "age deck should contain 32 cards")
	for card_id in deck:
		var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
		test_assert.check(card != null, "deck card should exist in catalog")
		test_assert.eq(card.age, 2, "age II deck should only contain age 2 cards")
