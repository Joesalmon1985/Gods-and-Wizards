# Headless debug simulation for Milestone 1.
# Windows:
#   godot --headless --path "<project>" -s res://debug/run_simulation.gd -- --seed 42 --rounds 3

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var game_seed: int = parsed["seed"]
	var rounds: int = parsed["rounds"]

	var result := GameSimulator.run(game_seed, rounds)
	var snapshot: Dictionary = result["snapshot"]
	print(JSON.stringify(snapshot))
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
