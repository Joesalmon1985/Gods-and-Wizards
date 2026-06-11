class_name SpellCombatPlayController
extends RefCounted


static func step_spell(session: SpellCombatSession, spell_id: String) -> Dictionary:
	if session == null or session.finished:
		return {}
	return session.step(spell_id)


static func step_option(session: SpellCombatSession, options: Array, index: int) -> Dictionary:
	var spell_id := SpellActionPicker.spell_id_at_index(options, index)
	if spell_id == "":
		return {}
	return step_spell(session, spell_id)
