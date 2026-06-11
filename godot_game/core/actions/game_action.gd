class_name GameAction
extends RefCounted

var action_id: int = -1
var kind: ActionKind.Kind = ActionKind.Kind.END_TURN
var vertex: BoardNode = null
var edge: EdgeCoord = null
var hero_id: int = -1
var target_node: BoardNode = null


func _init(
	p_action_id: int = -1,
	p_kind: ActionKind.Kind = ActionKind.Kind.END_TURN,
	p_vertex: BoardNode = null,
	p_edge: EdgeCoord = null,
	p_hero_id: int = -1,
	p_target_node: BoardNode = null
) -> void:
	action_id = p_action_id
	kind = p_kind
	vertex = p_vertex
	edge = p_edge
	hero_id = p_hero_id
	target_node = p_target_node


func equals(other: GameAction) -> bool:
	if other == null:
		return false
	if action_id != other.action_id or kind != other.kind:
		return false
	match kind:
		ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_DEVELOPMENT:
			if vertex == null or other.vertex == null:
				return false
			return vertex.equals(other.vertex)
		ActionKind.Kind.BUILD_ROAD:
			if edge == null or other.edge == null:
				return false
			return edge.equals(other.edge)
		ActionKind.Kind.MOVE_HERO:
			return hero_id == other.hero_id and target_node != null and other.target_node != null and target_node.equals(other.target_node)
		_:
			return true


func to_dict() -> Dictionary:
	var data := {
		"action_id": action_id,
		"kind": ActionKind.to_key(kind),
	}
	if kind in [ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_DEVELOPMENT] and vertex != null:
		data["vertex"] = vertex.to_dict()
	if kind == ActionKind.Kind.BUILD_ROAD and edge != null:
		data["edge"] = edge.to_dict()
	if kind == ActionKind.Kind.MOVE_HERO:
		data["hero_id"] = hero_id
		if target_node != null:
			data["target_node"] = target_node.to_dict()
	return data


static func from_dict(data: Dictionary) -> GameAction:
	var kind := _kind_from_key(data.get("kind", ""))
	var vertex: BoardNode = null
	var edge: EdgeCoord = null
	var target_node: BoardNode = null
	if kind in [ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_DEVELOPMENT] and data.has("vertex"):
		vertex = BoardNode.from_dict(data["vertex"])
	if kind == ActionKind.Kind.BUILD_ROAD and data.has("edge"):
		edge = EdgeCoord.from_dict(data["edge"])
	if kind == ActionKind.Kind.MOVE_HERO and data.has("target_node"):
		target_node = BoardNode.from_dict(data["target_node"])
	return GameAction.new(
		data.get("action_id", -1),
		kind,
		vertex,
		edge,
		data.get("hero_id", -1),
		target_node
	)


static func _kind_from_key(key: String) -> ActionKind.Kind:
	match key:
		"end_turn":
			return ActionKind.Kind.END_TURN
		"build_city":
			return ActionKind.Kind.BUILD_CITY
		"build_road":
			return ActionKind.Kind.BUILD_ROAD
		"move_hero":
			return ActionKind.Kind.MOVE_HERO
		"build_development":
			return ActionKind.Kind.BUILD_DEVELOPMENT
		_:
			return ActionKind.Kind.END_TURN
