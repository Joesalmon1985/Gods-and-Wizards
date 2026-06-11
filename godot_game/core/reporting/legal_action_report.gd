class_name LegalActionReport
extends RefCounted


static func legal_action_labels(state: GameState) -> Array[String]:
	var labels: Array[String] = []
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		labels.append(format_action(action))
	return labels


static func format_action(action: GameAction) -> String:
	var kind_key := ActionKind.to_key(action.kind)
	match action.kind:
		ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_DEVELOPMENT:
			if action.vertex != null:
				return "%d:%s@%s" % [action.action_id, kind_key, action.vertex.to_key()]
		ActionKind.Kind.BUILD_ROAD:
			if action.edge != null:
				return "%d:%s@%s" % [action.action_id, kind_key, action.edge.to_key()]
		ActionKind.Kind.MOVE_HERO:
			var target := action.target_node.to_key() if action.target_node != null else "none"
			return "%d:%s hero=%d->%s" % [action.action_id, kind_key, action.hero_id, target]
	return "%d:%s" % [action.action_id, kind_key]
