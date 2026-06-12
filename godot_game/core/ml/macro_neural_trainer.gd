class_name MacroNeuralTrainer
extends RefCounted

const RULES_VERSION := "run_g_v1"
const LEARNING_RATE := 0.05


static func collect_heuristic_samples(game_seed: int, max_steps: int = 24) -> Array:
	var env := MacroTrainingEnv.new()
	env.reset(game_seed, BotTurnResolver.POLICY_HEURISTIC)
	var samples: Array = []
	var steps := 0
	while not env.is_game_over() and steps < max_steps:
		var player_id := env.session.get_active_player_id()
		var view := env.get_legal_action_view(player_id)
		var obs := env.get_observation(player_id)
		var legal := env.get_legal_actions(player_id)
		var heuristic := env.choose_policy_action()
		var target_index := _action_index(view, heuristic)
		if target_index >= 0:
			samples.append({
				"features": MacroFeatureFeaturizer.extract(obs),
				"target_index": target_index,
				"legal_mask": _mask_bits(view.legal_mask),
			})
		env.step(heuristic if heuristic != null else legal[0])
		steps += 1
	return samples


static func train_from_seed(
	game_seed: int,
	train_episodes: int = 3,
	max_steps: int = 20,
	learning_rate: float = LEARNING_RATE
) -> Dictionary:
	var net := TinyNeuralNetwork.from_seed(
		MacroFeatureFeaturizer.FEATURE_SIZE,
		MacroFeatureFeaturizer.MAX_LEGAL_ACTIONS,
		game_seed
	)
	var losses: Array = []
	for episode in range(train_episodes):
		var samples := collect_heuristic_samples(game_seed + episode, max_steps)
		for sample in samples:
			var loss := net.train_supervised_step(
				sample["features"],
				int(sample["target_index"]),
				learning_rate
			)
			losses.append(loss)
	var eval_result := evaluate_policy(net, game_seed + 999, 12)
	return {
		"seed": game_seed,
		"rules_version": RULES_VERSION,
		"train_episodes": train_episodes,
		"sample_count": losses.size(),
		"avg_loss": _average(losses),
		"eval": eval_result,
		"network": net.to_dict(),
	}


static func evaluate_policy(net: TinyNeuralNetwork, game_seed: int, max_steps: int = 16) -> Dictionary:
	var env := MacroTrainingEnv.new()
	env.reset(game_seed, BotTurnResolver.POLICY_HEURISTIC)
	var illegal_count := 0
	var steps := 0
	var total_reward := 0.0
	while not env.is_game_over() and steps < max_steps:
		var player_id := env.session.get_active_player_id()
		var view := env.get_legal_action_view(player_id)
		var obs := env.get_observation(player_id)
		var mask := _mask_bits(view.legal_mask)
		var logits := net.forward(MacroFeatureFeaturizer.extract(obs))
		var action_index := net.choose_action_index(logits, mask)
		var action: GameAction = null
		if action_index >= 0 and action_index < view.action_ids.size() and view.legal_mask[action_index]:
			action = env.session.state.action_space.get_action(view.action_ids[action_index])
		var legal := env.get_legal_actions(player_id)
		if action == null:
			action = legal[0] if not legal.is_empty() else env.choose_policy_action()
		elif not _contains_action(legal, action):
			illegal_count += 1
			action = legal[0] if not legal.is_empty() else env.choose_policy_action()
		var result := env.step(action)
		total_reward += float(result.get("rewards", {}).get(player_id, 0.0))
		steps += 1
	return {
		"steps": steps,
		"illegal_actions": illegal_count,
		"total_reward": total_reward,
		"finished": env.is_game_over(),
	}


static func render_metrics_csv(result: Dictionary) -> String:
	var eval_data: Dictionary = result.get("eval", {})
	return "\n".join([
		"seed,rules_version,train_episodes,sample_count,avg_loss,eval_steps,illegal_actions,total_reward,finished",
		"%d,%s,%d,%d,%s,%d,%d,%s,%s" % [
			int(result.get("seed", 0)),
			str(result.get("rules_version", "")),
			int(result.get("train_episodes", 0)),
			int(result.get("sample_count", 0)),
			str(result.get("avg_loss", 0.0)),
			int(eval_data.get("steps", 0)),
			int(eval_data.get("illegal_actions", 0)),
			str(eval_data.get("total_reward", 0.0)),
			str(eval_data.get("finished", false)).to_lower(),
		],
	]) + "\n"


static func _action_index(view: LegalActionView, action: GameAction) -> int:
	if action == null:
		return -1
	for i in range(view.action_ids.size()):
		if view.action_ids[i] == action.action_id:
			return i
	return -1


static func _mask_bits(mask: Array) -> Array:
	var bits: Array = []
	for entry in mask:
		bits.append(1 if bool(entry) else 0)
	return bits


static func _contains_action(legal: Array, action: GameAction) -> bool:
	if action == null:
		return false
	for candidate in legal:
		if candidate.action_id == action.action_id:
			return true
	return false


static func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())
