class_name CombatantSpellLoadout
extends RefCounted

const DEFAULT_LOADOUTS_PATH := "res://data/spells/combatant_loadouts_v1.json"

var combatant_id: String = ""
var display_name: String = ""
var base_health: float = 100.0
var base_mana: float = 100.0
var spell_ids: Array[String] = []


static func load_all_default() -> Dictionary:
	return load_all_from_path(DEFAULT_LOADOUTS_PATH)


static func load_all_from_path(path: String) -> Dictionary:
	var loadouts: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open combatant loadouts: %s" % path)
		return loadouts

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid combatant loadouts JSON: %s" % path)
		return loadouts

	for key in parsed.get("loadouts", {}).keys():
		var entry = parsed["loadouts"][key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var loadout := from_dict(entry)
		if loadout.combatant_id != "":
			loadouts[loadout.combatant_id] = loadout

	return loadouts


static func from_dict(data: Dictionary) -> CombatantSpellLoadout:
	var loadout := CombatantSpellLoadout.new()
	loadout.combatant_id = str(data.get("combatant_id", ""))
	loadout.display_name = str(data.get("display_name", loadout.combatant_id))
	loadout.base_health = float(data.get("base_health", 100.0))
	loadout.base_mana = float(data.get("base_mana", 100.0))
	loadout.spell_ids = []
	for spell_id in data.get("spell_ids", []):
		loadout.spell_ids.append(str(spell_id))
	loadout.spell_ids.sort()
	return loadout


func validate_against_catalog(catalog: SpellCatalog) -> Array[String]:
	var errors: Array[String] = []
	for spell_id in spell_ids:
		if not catalog.has_spell(spell_id):
			errors.append("Unknown spell_id '%s' in loadout '%s'" % [spell_id, combatant_id])
	return errors
