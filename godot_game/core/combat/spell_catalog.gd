class_name SpellCatalog
extends RefCounted

const DEFAULT_CATALOG_PATH := "res://data/spells/spell_catalog_v1.json"

var schema_version: String = ""
var spells_by_id: Dictionary = {}


static func load_default() -> SpellCatalog:
	return load_from_path(DEFAULT_CATALOG_PATH)


static func load_from_path(path: String) -> SpellCatalog:
	var catalog := SpellCatalog.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open spell catalog: %s" % path)
		return catalog

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid spell catalog JSON: %s" % path)
		return catalog

	catalog.schema_version = str(parsed.get("schema_version", ""))
	for entry in parsed.get("spells", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var spell := SpellDefinition.from_dict(entry)
		if spell.spell_id == "":
			continue
		catalog.spells_by_id[spell.spell_id] = spell

	return catalog


func has_spell(spell_id: String) -> bool:
	return spells_by_id.has(spell_id)


func get_spell(spell_id: String) -> SpellDefinition:
	return spells_by_id.get(spell_id)


func all_spell_ids_sorted() -> Array[String]:
	var ids: Array[String] = []
	for key in spells_by_id.keys():
		ids.append(str(key))
	ids.sort()
	return ids


func spell_count() -> int:
	return spells_by_id.size()
