class_name DevelopmentCatalog
extends RefCounted

const DEFAULT_CATALOG_PATH := "res://data/development/development_cards_v1.json"

var schema_version: String = ""
var cards_by_id: Dictionary = {}


static func load_default() -> DevelopmentCatalog:
	return load_from_path(DEFAULT_CATALOG_PATH)


static func load_from_path(path: String) -> DevelopmentCatalog:
	var catalog := DevelopmentCatalog.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open development catalog: %s" % path)
		return catalog

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid development catalog JSON: %s" % path)
		return catalog

	var errors := DevelopmentCatalogValidator.validate_catalog_data(parsed)
	if not errors.is_empty():
		for err in errors:
			push_error("Development catalog validation: %s" % err)
		return catalog

	catalog.schema_version = str(parsed.get("schema_version", ""))
	for entry in parsed.get("cards", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var card := DevelopmentCardDefinition.from_dict(entry)
		if card.id == "":
			continue
		catalog.cards_by_id[card.id] = card

	return catalog


static var _cached_catalog: DevelopmentCatalog = null


static func _default_instance() -> DevelopmentCatalog:
	if _cached_catalog == null or _cached_catalog.cards_by_id.is_empty():
		_cached_catalog = load_default()
	return _cached_catalog


static func all_ids_sorted() -> Array[String]:
	var ids: Array[String] = []
	for key in _default_instance().cards_by_id.keys():
		ids.append(str(key))
	ids.sort()
	return ids


static func ids_for_age(age: int) -> Array[String]:
	var ids: Array[String] = []
	for card_id in all_ids_sorted():
		var card: DevelopmentCardDefinition = get_card(card_id)
		if card != null and card.age == age:
			ids.append(card_id)
	return ids


static func has_id(development_id: String) -> bool:
	return _default_instance().cards_by_id.has(development_id)


static func get_card(development_id: String) -> DevelopmentCardDefinition:
	return _default_instance().cards_by_id.get(development_id)


static func display_name(development_id: String) -> String:
	var card := get_card(development_id)
	if card != null:
		return card.name
	return development_id.capitalize()


static func card_count() -> int:
	return _default_instance().cards_by_id.size()


static func victory_points_bonus(development_id: String) -> int:
	var card := get_card(development_id)
	if card == null:
		return 0
	for effect in card.effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		if str(effect.get("type", "")) == DevelopmentEffectType.VP_FLAT:
			return int(effect.get("amount", 0))
	return card.vp


static func build_cost(development_id: String) -> Dictionary:
	var card := get_card(development_id)
	if card == null:
		return {}
	return card.cost.duplicate()


static func resolve_build_id(requested_id: String) -> String:
	if requested_id != "" and has_id(requested_id):
		return requested_id
	var ids := all_ids_sorted()
	if ids.is_empty():
		return ""
	return ids[0]
