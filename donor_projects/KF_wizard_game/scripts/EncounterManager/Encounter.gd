extends Resource
class_name Encounter

var participants: Array[Node3D] = []
var started: bool = false
var finished: bool = false
var result: Dictionary = {}

func _init(p_list: Array = []) -> void:
	participants.clear()
	for p in p_list:
		if p and is_instance_valid(p):
			participants.append(p)

func start() -> void:
	started = true
	_on_start()

func _on_start() -> void:
	# override in subclasses
	pass

func end() -> void:
	if finished:
		return
	finished = true
	_on_end()

func _on_end() -> void:
	# override in subclasses
	pass

func set_participants(list: Array) -> void:
	participants.clear()
	for p in list:
		if p is Node3D:
			participants.append(p)
