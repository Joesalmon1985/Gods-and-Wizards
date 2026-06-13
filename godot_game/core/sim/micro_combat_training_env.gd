class_name MicroCombatTrainingEnv
extends RefCounted

var session: SpellCombatSession = null
var max_steps: int = 100


func reset(
	game_seed: int,
	loadout_a_id: String = "hero_patrol",
	loadout_b_id: String = "demon_breach"
) -> Dictionary:
	session = SpellCombatSession.start_duel(game_seed, loadout_a_id, loadout_b_id)
	return session.observe()


func get_legal_spell_ids() -> Array[String]:
	if session == null:
		return []
	return session.get_legal_spell_ids()


func build_legal_mask() -> Array[int]:
	if session == null:
		return []
	return MicroLegalActionLayout.build_mask(session)


func step(spell_id: String) -> Dictionary:
	if session == null or session.finished:
		return _empty_step()
	var actor_id: String = session.get_active_combatant()["id"]
	var result := session.step(spell_id)
	var reward := session.get_rewards(actor_id, result.get("events", []))
	result["reward"] = reward
	result["selected_spell_id"] = spell_id
	return result


func step_policy() -> Dictionary:
	if session == null or session.finished:
		return _empty_step()
	var legal := get_legal_spell_ids()
	var spell_id := legal[0] if not legal.is_empty() else SpellCombatRules.PASS_SPELL_ID
	return step(spell_id)


func is_done() -> bool:
	return session != null and session.finished


func _empty_step() -> Dictionary:
	return {
		"events": [],
		"done": true,
		"winner_id": session.winner_id if session != null else "",
		"observation": session.observe() if session != null else {},
		"timeline": session.timeline.duplicate() if session != null else [],
		"reward": 0.0,
		"selected_spell_id": "",
	}
