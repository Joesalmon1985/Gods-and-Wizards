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

	for node in board.get_all_nodes_sorted():
		var build_action := GameAction.new(next_id, ActionKind.Kind.BUILD_CITY, node)
		space._register(build_action)
		next_id += 1

	for edge in board.get_all_edges_sorted():
		var road_action := GameAction.new(next_id, ActionKind.Kind.BUILD_ROAD, null, edge)
		space._register(road_action)
		next_id += 1

	for node in board.get_all_nodes_sorted():
		var dev_action := GameAction.new(next_id, ActionKind.Kind.BUILD_DEVELOPMENT, node)
		space._register(dev_action)
		next_id += 1

	_register_bank_trades(space)
	_register_player_trades(space, 4)
	return space


static func _register_bank_trades(space: ActionSpace) -> void:
	for give_resource in ResourceType.all():
		for receive_resource in ResourceType.all():
			if give_resource == receive_resource:
				continue
			var trade_action := GameAction.new(
				space.size(),
				ActionKind.Kind.BANK_TRADE,
				null,
				null,
				-1,
				null,
				give_resource,
				receive_resource
			)
			space._register(trade_action)


static func _register_player_trades(space: ActionSpace, player_count: int) -> void:
	for partner_id in player_count:
		for give_resource in ResourceType.all():
			for receive_resource in ResourceType.all():
				if give_resource == receive_resource:
					continue
				var trade_action := GameAction.new(
					space.size(),
					ActionKind.Kind.PLAYER_TRADE,
					null,
					null,
					-1,
					null,
					give_resource,
					receive_resource,
					partner_id
				)
				space._register(trade_action)


static func from_state(state: GameState) -> ActionSpace:
	var space := from_board(state.board)

	for hero in state.heroes:
		for node in state.board.get_all_nodes_sorted():
			var move_action := GameAction.new(
				space.size(),
				ActionKind.Kind.MOVE_HERO,
				null,
				null,
				hero.id,
				node
			)
			space._register(move_action)

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
	match action.kind:
		ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_DEVELOPMENT:
			if action.vertex != null:
				return "%d:%s:%s" % [action.action_id, ActionKind.to_key(action.kind), action.vertex.to_key()]
		ActionKind.Kind.BUILD_ROAD:
			if action.edge != null:
				return "%d:%s:%s" % [action.action_id, ActionKind.to_key(action.kind), action.edge.to_key()]
		ActionKind.Kind.MOVE_HERO:
			var target_key := action.target_node.to_key() if action.target_node != null else "none"
			return "%d:%s:%d:%s" % [action.action_id, ActionKind.to_key(action.kind), action.hero_id, target_key]
		ActionKind.Kind.BANK_TRADE:
			return "%d:%s:%s->%s" % [
				action.action_id,
				ActionKind.to_key(action.kind),
				ResourceType.to_key(action.give_resource),
				ResourceType.to_key(action.receive_resource),
			]
		ActionKind.Kind.PLAYER_TRADE:
			return "%d:%s:p%d:%s->%s" % [
				action.action_id,
				ActionKind.to_key(action.kind),
				action.partner_player_id,
				ResourceType.to_key(action.give_resource),
				ResourceType.to_key(action.receive_resource),
			]
	return "%d:%s" % [action.action_id, ActionKind.to_key(action.kind)]
