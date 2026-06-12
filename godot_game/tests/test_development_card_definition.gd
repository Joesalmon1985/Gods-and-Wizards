class_name TestDevelopmentCardDefinition
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_from_dict_parses_fields(test_assert)
	_test_from_dict_parses_effects_and_cost(test_assert)


static func _test_from_dict_parses_fields(test_assert: TestAssert) -> void:
	var card := DevelopmentCardDefinition.from_dict({
		"id": "lumber_camp_a1",
		"name": "Lumber Camp",
		"age": 1,
		"category": "production_bonuses",
		"slot_type": "economic",
		"vp": 0,
		"rules_text": "+1 wood production.",
		"implementation_status": "implemented",
	})
	test_assert.eq(card.id, "lumber_camp_a1", "id parsed")
	test_assert.eq(card.age, 1, "age parsed")
	test_assert.eq(card.category, "production_bonuses", "category parsed")


static func _test_from_dict_parses_effects_and_cost(test_assert: TestAssert) -> void:
	var card := DevelopmentCardDefinition.from_dict({
		"id": "monument_a1",
		"name": "Monument",
		"age": 1,
		"cost": {"wheat": 1},
		"effects": [{"type": "vp_flat", "amount": 1}],
		"tags": ["vp_cards"],
	})
	test_assert.eq(card.cost.get("wheat", 0), 1, "cost parsed")
	test_assert.eq(card.effects.size(), 1, "effects parsed")
	test_assert.eq(str(card.effects[0].get("type", "")), "vp_flat", "effect type parsed")
