class_name TestSpellCatalog
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_catalog_loads(test_assert)
	_test_required_fields(test_assert)
	_test_loadouts_validate(test_assert)
	_test_hero_and_demon_loadouts(test_assert)
	_test_deterministic_iteration(test_assert)
	_test_card_smoke_duel_still_passes(test_assert)


static func _test_catalog_loads(test_assert: TestAssert) -> void:
	var catalog := SpellCatalog.load_default()
	test_assert.check(catalog.spell_count() > 0, "catalog should load at least one spell")
	test_assert.eq(catalog.schema_version, "spell_catalog_v1", "catalog schema version should match")


static func _test_required_fields(test_assert: TestAssert) -> void:
	var catalog := SpellCatalog.load_default()
	for spell_id in catalog.all_spell_ids_sorted():
		var spell: SpellDefinition = catalog.get_spell(spell_id)
		test_assert.check(spell.spell_id != "", "spell should have stable spell_id")
		test_assert.check(spell.display_name != "", "spell should have display_name")
		test_assert.check(spell.mana_cost >= 0.0, "mana_cost should be non-negative for %s" % spell_id)
		test_assert.check(spell.cooldown >= 0.0, "cooldown should be non-negative for %s" % spell_id)


static func _test_loadouts_validate(test_assert: TestAssert) -> void:
	var catalog := SpellCatalog.load_default()
	var loadouts := CombatantSpellLoadout.load_all_default()
	test_assert.check(loadouts.size() > 0, "should load combatant loadouts")
	for loadout_id in loadouts.keys():
		var loadout: CombatantSpellLoadout = loadouts[loadout_id]
		var errors := loadout.validate_against_catalog(catalog)
		test_assert.eq(errors.size(), 0, "loadout %s should resolve all spell ids" % loadout_id)


static func _test_hero_and_demon_loadouts(test_assert: TestAssert) -> void:
	var loadouts := CombatantSpellLoadout.load_all_default()
	test_assert.check(loadouts.has("hero_patrol"), "hero loadout fixture should exist")
	test_assert.check(loadouts.has("demon_breach"), "demon loadout fixture should exist")
	var hero: CombatantSpellLoadout = loadouts["hero_patrol"]
	var demon: CombatantSpellLoadout = loadouts["demon_breach"]
	test_assert.check(hero.spell_ids.size() > 0, "hero loadout should include spells")
	test_assert.check(demon.spell_ids.size() > 0, "demon loadout should include spells")


static func _test_deterministic_iteration(test_assert: TestAssert) -> void:
	var catalog_a := SpellCatalog.load_default()
	var catalog_b := SpellCatalog.load_default()
	test_assert.eq(
		JSON.stringify(catalog_a.all_spell_ids_sorted()),
		JSON.stringify(catalog_b.all_spell_ids_sorted()),
		"catalog iteration order should be deterministic"
	)


static func _test_card_smoke_duel_still_passes(test_assert: TestAssert) -> void:
	var result := CombatResolver.run_seeded_smoke_duel(123)
	test_assert.check(str(result.get("winner_id", "")) != "", "legacy card smoke duel should still resolve")
