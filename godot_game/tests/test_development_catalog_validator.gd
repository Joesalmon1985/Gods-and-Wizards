class_name TestDevelopmentCatalogValidator
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_snake_case_validation(test_assert)
	_test_invalid_resource_rejected(test_assert)
	_test_malformed_catalog_fails(test_assert)
	_test_duplicate_id_rejected(test_assert)


static func _test_snake_case_validation(test_assert: TestAssert) -> void:
	var errors := DevelopmentCatalogValidator.validate_catalog_data({
		"schema_version": "development_cards_v1",
		"cards": [_card_dict("Bad-ID", 1)],
	})
	test_assert.check(not errors.is_empty(), "non snake_case id should fail")


static func _test_invalid_resource_rejected(test_assert: TestAssert) -> void:
	var data := _minimal_catalog([_card_dict("valid_card_a1", 1)])
	data["cards"][0]["cost"] = {"gold": 1}
	var errors := DevelopmentCatalogValidator.validate_catalog_data(data)
	test_assert.check(not errors.is_empty(), "invalid resource should fail")


static func _test_malformed_catalog_fails(test_assert: TestAssert) -> void:
	var errors := DevelopmentCatalogValidator.validate_catalog_data({"schema_version": "wrong"})
	test_assert.check(not errors.is_empty(), "wrong schema should fail")


static func _test_duplicate_id_rejected(test_assert: TestAssert) -> void:
	var card := _card_dict("dup_card_a1", 1)
	var errors := DevelopmentCatalogValidator.validate_catalog_data(_minimal_catalog([card, card]))
	test_assert.check(not errors.is_empty(), "duplicate id should fail")


static func _minimal_catalog(cards: Array) -> Dictionary:
	while cards.size() < 96:
		var age := (cards.size() % 3) + 1
		cards.append(_card_dict("filler_%d_a%d" % [cards.size(), age], age))
	return {"schema_version": "development_cards_v1", "cards": cards}


static func _card_dict(card_id: String, age: int) -> Dictionary:
	return {
		"id": card_id,
		"name": card_id.capitalize(),
		"age": age,
		"category": "vp_cards",
		"slot_type": "civic",
		"cost": {"wheat": 1},
		"vp": 1,
		"rules_text": "Test card.",
		"effects": [{"type": "vp_flat", "amount": 1}],
		"tags": ["vp_cards"],
		"implementation_status": "implemented",
	}
