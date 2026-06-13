# Live macro policy evaluation with exported JSON weights (Route B).
extends SceneTree


func _init() -> void:
	var args := _parse_args()
	var report := LearnedPolicyEvaluator.evaluate_macro(
		args["weights"],
		args["seed"],
		args["max_steps"],
		args["output"]
	)
	if report.has("error"):
		push_error(str(report["error"]))
		quit(1)
		return
	print(JSON.stringify(report))
	quit(0)


func _parse_args() -> Dictionary:
	var weights := ""
	var game_seed := 900
	var max_steps := 300
	var output := ""
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var arg: String = args[i]
		if arg == "--weights" and i + 1 < args.size():
			weights = args[i + 1]
			i += 2
			continue
		if arg == "--checkpoint" and i + 1 < args.size():
			weights = args[i + 1]
			i += 2
			continue
		if arg == "--seed" and i + 1 < args.size():
			game_seed = int(args[i + 1])
			i += 2
			continue
		if arg == "--episodes" and i + 1 < args.size():
			# single-episode runner; episodes loop handled by caller
			i += 2
			continue
		if arg == "--max-steps" and i + 1 < args.size():
			max_steps = int(args[i + 1])
			i += 2
			continue
		if arg == "--output" and i + 1 < args.size():
			output = args[i + 1]
			i += 2
			continue
		i += 1
	return {"weights": weights, "seed": game_seed, "max_steps": max_steps, "output": output}
