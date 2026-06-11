class_name ResourceGainedEvent
extends GameEvent

var turn: int
var player_id: int
var resource: ResourceType.Type
var amount: int
var source_hex: HexCoord
var source_vertex: VertexCoord


func _init(
	p_turn: int,
	p_player_id: int,
	p_resource: ResourceType.Type,
	p_amount: int,
	p_source_hex: HexCoord,
	p_source_vertex: VertexCoord
) -> void:
	event_type = "resource_gained"
	turn = p_turn
	player_id = p_player_id
	resource = p_resource
	amount = p_amount
	source_hex = p_source_hex
	source_vertex = p_source_vertex


func to_dict() -> Dictionary:
	return {
		"type": event_type,
		"turn": turn,
		"player_id": player_id,
		"resource": ResourceType.to_key(resource),
		"amount": amount,
		"source_hex": source_hex.to_dict(),
		"source_vertex": source_vertex.to_dict(),
	}
