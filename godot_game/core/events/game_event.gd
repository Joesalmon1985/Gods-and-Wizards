class_name GameEvent
extends RefCounted

var event_type: String = "game_event"


func to_dict() -> Dictionary:
	return {"type": event_type}
