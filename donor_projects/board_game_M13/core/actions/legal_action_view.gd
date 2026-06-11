class_name LegalActionView
extends RefCounted

var action_ids: Array[int] = []
var legal_mask: Array[bool] = []


func _init(action_space: ActionSpace) -> void:
	for action in action_space.all_actions_sorted():
		action_ids.append(action.action_id)
		legal_mask.append(false)


func to_dict() -> Dictionary:
	return {
		"action_ids": action_ids.duplicate(),
		"legal_mask": legal_mask.duplicate(),
	}
