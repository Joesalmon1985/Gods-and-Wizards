class_name ActionSpace
extends RefCounted

var _actions_by_id: Dictionary = {}
var _sorted_actions: Array[GameAction] = []


static func from_board(board: HexBoard) -> ActionSpace:
	var space := ActionSpace.new()
	var next_id := 0

	var end_turn := GameAction.new(next_id, ActionKind.Kind.END_TURN)
	space._register(end_turn)
	next_id += 1

	for vertex in board.get_all_vertices_sorted():
		var build_action := GameAction.new(next_id, ActionKind.Kind.BUILD_CITY, vertex)
		space._register(build_action)
		next_id += 1

	return space


func size() -> int:
	return _sorted_actions.size()


func get_action(action_id: int) -> GameAction:
	return _actions_by_id.get(action_id)


func all_actions_sorted() -> Array[GameAction]:
	return _sorted_actions.duplicate()


func to_layout_key() -> String:
	var parts: Array[String] = []
	for action in _sorted_actions:
		parts.append(_action_layout_part(action))
	return "|".join(parts)


func _register(action: GameAction) -> void:
	_actions_by_id[action.action_id] = action
	_sorted_actions.append(action)


static func _action_layout_part(action: GameAction) -> String:
	if action.kind == ActionKind.Kind.BUILD_CITY and action.vertex != null:
		return "%d:%s:%s" % [
			action.action_id,
			ActionKind.to_key(action.kind),
			action.vertex.to_key(),
		]
	return "%d:%s" % [action.action_id, ActionKind.to_key(action.kind)]
