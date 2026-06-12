class_name SpreadRules
extends RefCounted

const INITIAL_INFECTION_RATE := 2
const MAX_DEMONS_PER_NODE := 3


static func initialize_deck(state: GameState) -> void:
	state.infection_draw_pile.clear()
	state.infection_discard_pile.clear()
	state.infection_rate = INITIAL_INFECTION_RATE
	var keys: Array[String] = []
	for node in state.board.get_all_nodes_sorted():
		keys.append(node.to_key())
	_shuffle_draw_pile(state, keys)
	state.infection_draw_pile = keys


static func resolve_player_turn_end(state: GameState) -> Array:
	var events: Array = []
	var drawn := _draw_nodes(state, state.infection_rate)
	for node in drawn:
		events.append_array(try_add_demon(state, node))
	return events


static func try_add_demon(state: GameState, node: BoardNode) -> Array:
	var events: Array = []
	var current := SetupRules.get_demon_count(state, node)
	if current >= MAX_DEMONS_PER_NODE:
		state.breach_count += 1
		events.append(BreachEvent.new(state.round_number, state.breach_count))
		return events

	SetupRules.set_demon_count(state, node, current + 1)
	events.append(DemonSpreadEvent.new(state.round_number, node, node, 1))
	events.append_array(ContactResolutionRules.resolve_hero_node_after_demon_placement(state, node))
	return events


static func _draw_nodes(state: GameState, count: int) -> Array[BoardNode]:
	var nodes: Array[BoardNode] = []
	for _i in count:
		var key := _draw_one_key(state)
		if key == "":
			break
		var node := _node_from_key(state, key)
		if node != null:
			nodes.append(node)
	return nodes


static func _draw_one_key(state: GameState) -> String:
	if state.infection_draw_pile.is_empty():
		_reshuffle_discard_into_draw(state)
	if state.infection_draw_pile.is_empty():
		return ""
	var key: String = state.infection_draw_pile.pop_front()
	state.infection_discard_pile.append(key)
	return key


static func _reshuffle_discard_into_draw(state: GameState) -> void:
	if state.infection_discard_pile.is_empty():
		return
	var keys := state.infection_discard_pile.duplicate()
	state.infection_discard_pile.clear()
	_shuffle_draw_pile(state, keys)
	state.infection_draw_pile = keys


static func _shuffle_draw_pile(state: GameState, keys: Array[String]) -> void:
	for i in range(keys.size() - 1, 0, -1):
		var j := state.rng.randi_range(0, i)
		var tmp: String = keys[i]
		keys[i] = keys[j]
		keys[j] = tmp


static func _node_from_key(state: GameState, key: String) -> BoardNode:
	for node in state.board.get_all_nodes_sorted():
		if node.to_key() == key:
			return node
	return null
