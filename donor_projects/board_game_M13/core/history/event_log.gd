class_name EventLog
extends RefCounted

var entries: Array = []
var _next_sequence_id: int = 0


func append(event: GameEvent) -> void:
	entries.append({
		"sequence_id": _next_sequence_id,
		"type": event.event_type,
		"payload": event.to_dict(),
	})
	_next_sequence_id += 1


func append_legal_mask(view: LegalActionView, round_number: int, player_id: int) -> void:
	entries.append({
		"sequence_id": _next_sequence_id,
		"type": "action_mask_recorded",
		"payload": {
			"round": round_number,
			"player_id": player_id,
			"action_ids": view.action_ids.duplicate(),
			"legal_mask": view.legal_mask.duplicate(),
		},
	})
	_next_sequence_id += 1


func to_dict() -> Array:
	var copy: Array = []
	for entry in entries:
		copy.append(entry.duplicate(true))
	return copy
