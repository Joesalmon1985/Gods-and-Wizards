class_name TestDevelopmentCatalogLoader
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_catalog_loads(test_assert)
	_test_card_counts(test_assert)
	_test_all_ids_snake_case(test_assert)
	_test_implemented_cards_have_rules_text(test_assert)
	_test_no_duplicate_ids_or_names(test_assert)


static func _test_catalog_loads(test_assert: TestAssert) -> void:
	var catalog := DevelopmentCatalog.load_default()
	test_assert.eq(catalog.schema_version, "development_cards_v1", "schema version")
	test_assert.check(catalog.card_count() > 0, "catalog should load cards")


static func _test_card_counts(test_assert: TestAssert) -> void:
	var catalog := DevelopmentCatalog.load_default()
	test_assert.eq(catalog.card_count(), 96, "exactly 96 cards")
	for age in [1, 2, 3]:
		test_assert.eq(DevelopmentCatalog.ids_for_age(age).size(), 32, "32 cards per age %d" % age)


static func _test_all_ids_snake_case(test_assert: TestAssert) -> void:
	var regex := RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*$")
	for card_id in DevelopmentCatalog.all_ids_sorted():
		test_assert.check(regex.search(card_id) != null, "id %s should be snake_case" % card_id)


static func _test_implemented_cards_have_rules_text(test_assert: TestAssert) -> void:
	for card_id in DevelopmentCatalog.all_ids_sorted():
		var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
		if card.implementation_status == "implemented":
			test_assert.check(
				card.rules_text.strip_edges() != "",
				"implemented card %s needs rules_text" % card_id
			)


static func _test_no_duplicate_ids_or_names(test_assert: TestAssert) -> void:
	var ids := DevelopmentCatalog.all_ids_sorted()
	var names: Dictionary = {}
	for card_id in ids:
		var card: DevelopmentCardDefinition = DevelopmentCatalog.get_card(card_id)
		test_assert.check(not names.has(card.name), "duplicate name %s" % card.name)
		names[card.name] = true
	test_assert.eq(ids.size(), 96, "no duplicate ids")
