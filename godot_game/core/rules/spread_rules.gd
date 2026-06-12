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
	events.append_array(_check_underworld_surge(state))
	return events


static func surge_chance_for_age(draft_age: int) -> int:
	match draft_age:
		1:
			return 0
		2:
			return 10
		3:
			return 20
		_:
			return 20


static func _check_underworld_surge(state: GameState) -> Array:
	var chance := surge_chance_for_age(state.draft_age)
	if chance <= 0:
		return []
	if state.infection_discard_pile.is_empty():
		return []
	var roll := state.rng.roll_d10()
	var threshold := ceili(float(chance) / 10.0)
	if roll >= threshold:
		return []
	return _apply_underworld_surge(state)


static func _apply_underworld_surge(state: GameState) -> Array:
	var discard_count := state.infection_discard_pile.size()
	var keys := state.infection_discard_pile.duplicate()
	state.infection_discard_pile.clear()
	_shuffle_draw_pile(state, keys)
	var merged: Array[String] = []
	for key in keys:
		merged.append(key)
	for key in state.infection_draw_pile:
		merged.append(key)
	state.infection_draw_pile = merged
	return [
		UnderworldSurgeEvent.new(state.round_number, state.draft_age, discard_count),
	]


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
