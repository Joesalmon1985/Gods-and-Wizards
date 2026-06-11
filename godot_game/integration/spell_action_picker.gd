class_name SpellActionPicker
extends RefCounted


static func build_options(session: SpellCombatSession) -> Array:
	var options: Array = []
	for spell_id in session.get_legal_spell_ids():
		options.append({
			"spell_id": spell_id,
			"label": _label_for_spell(spell_id),
		})
	return options


static func spell_id_at_index(options: Array, index: int) -> String:
	if index < 0 or index >= options.size():
		return ""
	return str(options[index].get("spell_id", ""))


static func _label_for_spell(spell_id: String) -> String:
	if SpellCombatRules.is_pass(spell_id):
		return "Pass"
	return spell_id
