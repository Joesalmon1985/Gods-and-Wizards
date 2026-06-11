# Headless debug run CSV export.
# Windows:
#   godot --headless --path "<project>" -s res://debug/export_debug_run.gd -- --seed 42 --rounds 3

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var game_seed: int = parsed["seed"]
	var rounds: int = parsed["rounds"]

	var result := GameSimulator.run(game_seed, rounds)
	var global_path := DebugRunExporter.write_to_user_path(result, game_seed, rounds)
	if global_path.is_empty():
		push_error("Failed to export debug run CSV")
		quit(1)
		return

	print("Debug run CSV written to: %s" % global_path)
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 42
	var rounds := 3
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--seed" and index + 1 < args.size():
			game_seed = int(args[index + 1])
			index += 2
			continue
		if arg == "--rounds" and index + 1 < args.size():
			rounds = int(args[index + 1])
			index += 2
			continue
		index += 1
	return {"seed": game_seed, "rounds": rounds}
