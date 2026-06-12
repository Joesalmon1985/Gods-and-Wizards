extends SceneTree

## Headless macro baseline evaluation. Usage:
## godot --headless --path godot_game -s res://run_modes/run_macro_baseline_eval.gd -- --seed 42 --episodes 4 --output logs/macro_baseline.csv


func _init() -> void:
	var args := _parse_args()
	var seed_value := int(args.get("seed", 42))
	var episodes := int(args.get("episodes", 4))
	var output := str(args.get("output", "user://macro_baseline_eval.csv"))
	var rows: Array = []
	for policy in [
		MacroBaselinePolicies.POLICY_RANDOM,
		MacroBaselinePolicies.POLICY_HEURISTIC,
		MacroBaselinePolicies.POLICY_GREEDY_VP,
		MacroBaselinePolicies.POLICY_SURVIVAL,
	]:
		rows.append(TrainingEvaluationHarness.evaluate_macro(policy, seed_value, episodes, 40))
	var csv := TrainingEvaluationHarness.render_metrics_csv(rows)
	_write(output, csv)
	print("Macro baseline eval written: %s" % output)
	quit(0)


func _parse_args() -> Dictionary:
	var result := {"seed": 42, "episodes": 4, "output": "user://macro_baseline_eval.csv"}
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
