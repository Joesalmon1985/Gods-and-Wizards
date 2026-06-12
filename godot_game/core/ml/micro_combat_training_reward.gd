class_name MicroCombatTrainingReward
extends RefCounted

const PROFILE_BALANCED := "balanced"
const TERMINAL_WIN := 10.0


static func compute_components(actor_id: String, events: Array, session: SpellCombatSession) -> Dictionary:
	var components := {
		"damage_dealt": 0.0,
		"healing": 0.0,
		"terminal_win": 0.0,
	}
	for event in events:
		var event_type := str(event.get("type", ""))
		if event_type == "spell_hit":
			if str(event.get("caster_id", "")) == actor_id:
				components["damage_dealt"] = float(components["damage_dealt"]) + absf(float(event.get("damage", 0.0)))
		elif event_type == "spell_heal":
			if str(event.get("caster_id", "")) == actor_id:
				components["healing"] = float(components["healing"]) + float(event.get("amount", 0.0))
	if session != null and session.finished and session.winner_id == actor_id:
		components["terminal_win"] = TERMINAL_WIN
	return components


static func total_from_components(components: Dictionary, profile: String = PROFILE_BALANCED) -> float:
	match profile:
		"damage":
			return float(components.get("damage_dealt", 0.0)) * 0.1 + float(components.get("terminal_win", 0.0))
		"survival":
			return float(components.get("healing", 0.0)) * 0.05 + float(components.get("terminal_win", 0.0))
		_:
			return (
				float(components.get("damage_dealt", 0.0)) * 0.1
				+ float(components.get("healing", 0.0)) * 0.05
				+ float(components.get("terminal_win", 0.0))
			)
