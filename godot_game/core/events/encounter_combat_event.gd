class_name EncounterCombatEvent
extends GameEvent

var winner_id: String
var loser_id: String
var node_key: String


func _init(p_winner_id: String, p_loser_id: String, p_node_key: String) -> void:
	winner_id = p_winner_id
	loser_id = p_loser_id
	node_key = p_node_key
	event_type = "encounter_combat"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"winner_id": winner_id,
		"loser_id": loser_id,
		"node_key": node_key,
	}
