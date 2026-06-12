extends SceneTree

## Headless micro baseline evaluation.


func _init() -> void:
	var args := _parse_args()
	var seed_value := int(args.get("seed", 42))
	var episodes := int(args.get("episodes", 4))
	var output := str(args.get("output", "user://micro_baseline_eval.csv"))
	var rows: Array = []
	for policy in [
		MicroBaselinePolicies.POLICY_RANDOM,
		MicroBaselinePolicies.POLICY_DAMAGE_FIRST,
		MicroBaselinePolicies.POLICY_SURVIVAL,
		MicroBaselinePolicies.POLICY_MANA_EFFICIENT,
	]:
		rows.append(TrainingEvaluationHarness.evaluate_micro(policy, seed_value, episodes, 80))
	var csv := TrainingEvaluationHarness.render_metrics_csv(rows)
	_write(output, csv)
	print("Micro baseline eval written: %s" % output)
	quit(0)


func _parse_args() -> Dictionary:
	var result := {"seed": 42, "episodes": 4, "output": "user://micro_baseline_eval.csv"}
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--seed" and index + 1 < args.size():
			result["seed"] = int(args[index + 1])
			index += 2
			continue
		if arg == "--episodes" and index + 1 < args.size():
			result["episodes"] = int(args[index + 1])
			index += 2
			continue
		if arg == "--output" and index + 1 < args.size():
			result["output"] = args[index + 1]
			index += 2
			continue
		index += 1
	return result


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write %s" % path)
		return
	file.store_string(text)
	file.close()
