class_name StrategicActionPicker
extends RefCounted


static func build_options(legal_actions: Array) -> Array:
	var options: Array = []
	for action in legal_actions:
		if action == null:
			continue
		options.append({
			"action_id": action.action_id,
			"label": LegalActionReport.format_action(action),
			"action": action,
		})
	return options


static func action_at_index(options: Array, index: int) -> GameAction:
	if index < 0 or index >= options.size():
		return null
	return options[index].get("action")
