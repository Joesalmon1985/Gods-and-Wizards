class_name MacroRlTrainer
extends RefCounted

const RULES_VERSION := "run_e_prototype_v1"


static func run_short_episode(game_seed: int, max_steps: int = 16) -> Dictionary:
	var env := MacroTrainingEnv.new()
	var policy := TinyPolicy.default_policy()
	env.reset(game_seed, BotTurnResolver.POLICY_HEURISTIC)
	var rows: Array = []
	var step_index := 0

	while not env.is_game_over() and step_index < max_steps:
		var player_id := env.session.get_active_player_id()
		var view := env.get_legal_action_view(player_id)
		var obs := env.get_observation(player_id)
		var action_index := policy.choose_action_index(_mask_bits(view.legal_mask))
		var action: GameAction = null
		if action_index >= 0 and action_index < view.action_ids.size():
			action = env.session.state.action_space.get_action(view.action_ids[action_index])
		if action == null:
			action = env.choose_policy_action()
		var result := env.step(action)
		rows.append({
			"step_index": step_index,
			"player_id": player_id,
			"policy_score": policy.forward(obs),
			"selected_action_id": action.action_id if action != null else -1,
			"reward": float(result.get("rewards", {}).get(player_id, 0.0)),
			"done": bool(result.get("done", false)),
		})
		step_index += 1

	return {
		"seed": game_seed,
		"rules_version": RULES_VERSION,
		"rows": rows,
		"step_count": rows.size(),
	}


static func render_metrics_csv(result: Dictionary) -> String:
	var lines: PackedStringArray = [
		"seed,rules_version,step_index,player_id,policy_score,selected_action_id,reward,done",
	]
	for row in result.get("rows", []):
		lines.append(
			"%d,%s,%d,%d,%s,%d,%s,%s" % [
				int(result.get("seed", 0)),
				str(result.get("rules_version", "")),
				int(row.get("step_index", 0)),
				int(row.get("player_id", 0)),
				str(row.get("policy_score", 0.0)),
				int(row.get("selected_action_id", -1)),
				str(row.get("reward", 0.0)),
				str(row.get("done", false)).to_lower(),
			]
		)
	return "\n".join(lines) + "\n"


static func _mask_bits(mask: Array) -> Array:
	var bits: Array = []
	for entry in mask:
		bits.append(1 if bool(entry) else 0)
	return bits
