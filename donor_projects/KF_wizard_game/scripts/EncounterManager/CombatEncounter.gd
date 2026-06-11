extends Encounter
class_name CombatEncounter

@export var debug_verbose: bool = true

func start() -> void:
	started = true
	if debug_verbose:
		var names: Array[String] = []
		for p in participants:
			if p and is_instance_valid(p):
				names.append(p.name)
		print("[Encounter/Combat] start -> participants=", names)
	# Lock actors during the encounter
	for p in participants:
		if p and is_instance_valid(p) and p.has_method("set_encounter_locked"):
			p.set_encounter_locked(true)

# Called by the manager when the fight should conclude
func resolve_now() -> void:
	var valid: Array[Node3D] = []
	for p in participants:
		if p and is_instance_valid(p):
			valid.append(p)
	if valid.size() > 0:
		var idx := randi() % valid.size()
		result = {"winner": valid[idx]}
	else:
		result = {"winner": null}
	if debug_verbose:
		var wn: Node3D = null
		if result.has("winner") and result["winner"] is Node3D:
			wn = result["winner"] as Node3D
		var wname: String = "none"
		if wn != null:
			wname = wn.name
		print("[Encounter/Combat] resolved -> winner=", wname)
	end()

func end() -> void:
	if finished:
		return
	finished = true
	if debug_verbose:
		print("[Encounter/Combat] end -> unlocking participants")
	for p in participants:
		if p and is_instance_valid(p) and p.has_method("set_encounter_locked"):
			p.set_encounter_locked(false)

func set_participants(list: Array) -> void:
	participants.clear()
	for p in list:
		if p is Node3D:
			participants.append(p)
