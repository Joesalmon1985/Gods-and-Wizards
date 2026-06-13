class_name BreachSpreadSkippedEvent
extends GameEvent

var round_number: int
var skipped_node: BoardNode
var breach_source_node: BoardNode


func _init(p_round_number: int, p_skipped: BoardNode, p_breach_source: BoardNode) -> void:
	round_number = p_round_number
	skipped_node = p_skipped
	breach_source_node = p_breach_source
	event_type = "breach_spread_skipped"


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"round_number": round_number,
		"skipped_node": skipped_node.to_dict(),
		"breach_source_node": breach_source_node.to_dict(),
	}
