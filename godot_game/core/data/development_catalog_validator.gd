class_name DevelopmentCatalogValidator
extends RefCounted

const SNAKE_CASE_PATTERN := "^[a-z][a-z0-9_]*$"
const VALID_RESOURCES := ["wood", "brick", "wheat", "sheep", "ore"]


static func validate_catalog_data(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if typeof(data) != TYPE_DICTIONARY:
		return ["catalog root must be a dictionary"]

	var schema_version := str(data.get("schema_version", ""))
	if schema_version != "development_cards_v1":
		errors.append("schema_version must be development_cards_v1")

	var cards = data.get("cards", [])
	if typeof(cards) != TYPE_ARRAY:
		errors.append("cards must be an array")
		return errors

	if cards.size() != 96:
		errors.append("catalog must contain exactly 96 cards (found %d)" % cards.size())

	var ids_seen: Dictionary = {}
	var names_seen: Dictionary = {}
	var age_counts := {1: 0, 2: 0, 3: 0}

	for index in cards.size():
		var entry = cards[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("card at index %d must be a dictionary" % index)
			continue
		errors.append_array(_validate_card(entry, ids_seen, names_seen, age_counts))

	for age in age_counts.keys():
		if age_counts[age] != 32:
			errors.append("age %d must have 32 cards (found %d)" % [age, age_counts[age]])

	return errors


static func _validate_card(
	data: Dictionary,
	ids_seen: Dictionary,
	names_seen: Dictionary,
	age_counts: Dictionary
) -> Array[String]:
	var errors: Array[String] = []
	var card_id := str(data.get("id", ""))
	if card_id == "":
		return ["card missing id"]
	if not _is_snake_case(card_id):
		errors.append("card id '%s' must be snake_case" % card_id)
	if ids_seen.has(card_id):
		errors.append("duplicate card id '%s'" % card_id)
	ids_seen[card_id] = true

	var card_name := str(data.get("name", ""))
	if card_name == "":
		errors.append("card '%s' missing name" % card_id)
	elif names_seen.has(card_name):
		errors.append("duplicate card name '%s'" % card_name)
	names_seen[card_name] = true

	var age := int(data.get("age", 0))
	if age not in [1, 2, 3]:
		errors.append("card '%s' has invalid age %d" % [card_id, age])
	else:
		age_counts[age] = age_counts.get(age, 0) + 1

	var status := str(data.get("implementation_status", ""))
	if status == "implemented":
		if str(data.get("rules_text", "")).strip_edges() == "":
			errors.append("implemented card '%s' must have rules_text" % card_id)

	for resource in data.get("cost", {}).keys():
		if str(resource) not in VALID_RESOURCES:
			errors.append("card '%s' has invalid cost resource '%s'" % [card_id, str(resource)])

	var effects = data.get("effects", [])
	if typeof(effects) == TYPE_ARRAY:
		for effect in effects:
			if typeof(effect) != TYPE_DICTIONARY:
				errors.append("card '%s' has non-dictionary effect" % card_id)
				continue
			var effect_type := str(effect.get("type", ""))
			if not DevelopmentEffectType.is_known(effect_type):
				errors.append("card '%s' has unknown effect type '%s'" % [card_id, effect_type])

	return errors


static func _is_snake_case(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile(SNAKE_CASE_PATTERN)
	return regex.search(value) != null
