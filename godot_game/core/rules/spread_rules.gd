class_name SpreadRules
extends RefCounted

const OUTBREAK_THRESHOLD := 3


static func resolve_spread(state: GameState) -> Array:
	var events: Array = []
	var spread_plan: Array = []

	for node in state.board.get_all_nodes_sorted():
		var count := SetupRules.get_demon_count(state, node)
		if count < 1:
			continue
		if state.heroes_by_node.has(node.to_key()):
			continue
		for adjacent in state.board.get_adjacent_nodes(node):
			if state.heroes_by_node.has(adjacent.to_key()):
				continue
			spread_plan.append({"from": node, "to": adjacent})
			break

	for entry in spread_plan:
		var from_node: BoardNode = entry["from"]
		var to_node: BoardNode = entry["to"]
		var current := SetupRules.get_demon_count(state, to_node)
		SetupRules.set_demon_count(state, to_node, current + 1)
		events.append(DemonSpreadEvent.new(state.round_number, from_node, to_node, 1))

	for node in state.board.get_all_nodes_sorted():
		if SetupRules.get_demon_count(state, node) >= OUTBREAK_THRESHOLD:
			state.breach_count += 1
			events.append(BreachEvent.new(state.round_number, state.breach_count))

	return events
