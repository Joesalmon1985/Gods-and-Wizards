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


static func from_legal_actions(action_space: ActionSpace, legal_actions: Array) -> LegalActionView:
	var view := LegalActionView.new(action_space)
	var legal_ids: Dictionary = {}
	for action in legal_actions:
		legal_ids[int(action.action_id)] = true
	for i in range(view.action_ids.size()):
		view.legal_mask[i] = legal_ids.has(view.action_ids[i])
	return view
