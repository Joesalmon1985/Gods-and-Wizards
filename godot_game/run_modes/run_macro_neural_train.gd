extends SceneTree

## Tiny macro neural training smoke run.


func _init() -> void:
	var args := _parse_args()
	var seed_value := int(args.get("seed", 42))
	var output := str(args.get("output", "user://macro_neural_train_metrics.csv"))
	var result := MacroNeuralTrainer.train_from_seed(seed_value, 2, 10)
	var csv := MacroNeuralTrainer.render_metrics_csv(result)
	_write(output, csv)
	print("Macro neural training metrics: illegal=%s reward=%s" % [
		str(result.get("eval", {}).get("illegal_actions", 0)),
		str(result.get("eval", {}).get("total_reward", 0.0)),
	])
	quit(0)


func _parse_args() -> Dictionary:
	var result := {"seed": 42, "output": "user://macro_neural_train_metrics.csv"}
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--seed" and index + 1 < args.size():
			result["seed"] = int(args[index + 1])
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
