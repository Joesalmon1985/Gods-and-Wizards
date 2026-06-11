class_name GameAction
extends RefCounted

var action_id: int = -1
var kind: ActionKind.Kind = ActionKind.Kind.END_TURN
var vertex: VertexCoord = null


func _init(p_action_id: int = -1, p_kind: ActionKind.Kind = ActionKind.Kind.END_TURN, p_vertex: VertexCoord = null) -> void:
	action_id = p_action_id
	kind = p_kind
	vertex = p_vertex


func equals(other: GameAction) -> bool:
	if other == null:
		return false
	if action_id != other.action_id or kind != other.kind:
		return false
	if kind == ActionKind.Kind.BUILD_CITY:
		if vertex == null or other.vertex == null:
			return false
		return vertex.equals(other.vertex)
	return true


func to_dict() -> Dictionary:
	var data := {
		"action_id": action_id,
		"kind": ActionKind.to_key(kind),
	}
	if kind == ActionKind.Kind.BUILD_CITY and vertex != null:
		data["vertex"] = vertex.to_dict()
	return data


static func from_dict(data: Dictionary) -> GameAction:
	var kind := _kind_from_key(data.get("kind", ""))
	var vertex: VertexCoord = null
	if kind == ActionKind.Kind.BUILD_CITY and data.has("vertex"):
		var vertex_data: Dictionary = data["vertex"]
		vertex = VertexCoord.from_dict(vertex_data)
	return GameAction.new(data.get("action_id", -1), kind, vertex)


static func _kind_from_key(key: String) -> ActionKind.Kind:
	match key:
		"end_turn":
			return ActionKind.Kind.END_TURN
		"build_city":
			return ActionKind.Kind.BUILD_CITY
		_:
			return ActionKind.Kind.END_TURN
