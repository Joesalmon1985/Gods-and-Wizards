class_name MicroNeuralTrainer
extends RefCounted

const RULES_VERSION := "run_g_v1"
const LEARNING_RATE := 0.05


static func collect_policy_samples(game_seed: int, max_steps: int = 40) -> Array:
	var env := MicroCombatTrainingEnv.new()
	env.reset(game_seed)
	var samples: Array = []
	var steps := 0
	while not env.is_done() and steps < max_steps:
		var obs := env.session.observe()
		obs["legal_spell_count"] = env.get_legal_spell_ids().size()
		var legal := env.get_legal_spell_ids()
		var spell_id := legal[0] if not legal.is_empty() else SpellCombatRules.PASS_SPELL_ID
		var target_index := legal.find(spell_id)
		if target_index < 0:
			target_index = 0
		samples.append({
			"features": MicroCombatFeatureFeaturizer.extract(obs),
			"target_index": target_index,
			"legal_mask": env.build_legal_mask(),
		})
		env.step(spell_id if not spell_id.is_empty() else SpellCombatRules.PASS_SPELL_ID)
		steps += 1
	return samples


static func train_from_seed(
	game_seed: int,
	train_episodes: int = 3,
	max_steps: int = 30,
	learning_rate: float = LEARNING_RATE
) -> Dictionary:
	var net := TinyNeuralNetwork.from_seed(
		MicroCombatFeatureFeaturizer.FEATURE_SIZE,
		MicroCombatFeatureFeaturizer.MAX_SPELL_ACTIONS,
		game_seed
	)
	var losses: Array = []
	for episode in range(train_episodes):
		var samples := collect_policy_samples(game_seed + episode, max_steps)
		for sample in samples:
			var loss := net.train_supervised_step(
				sample["features"],
				int(sample["target_index"]),
				learning_rate
			)
			losses.append(loss)
	var eval_result := evaluate_policy(net, game_seed + 777, 60)
	return {
		"seed": game_seed,
		"rules_version": RULES_VERSION,
		"train_episodes": train_episodes,
		"sample_count": losses.size(),
		"avg_loss": _average(losses),
		"eval": eval_result,
		"network": net.to_dict(),
	}


static func evaluate_policy(net: TinyNeuralNetwork, game_seed: int, max_steps: int = 60) -> Dictionary:
	var env := MicroCombatTrainingEnv.new()
	env.reset(game_seed)
	var illegal_count := 0
	var steps := 0
	var total_reward := 0.0
	while not env.is_done() and steps < max_steps:
		var obs := env.session.observe()
		obs["legal_spell_count"] = env.get_legal_spell_ids().size()
		var mask := env.build_legal_mask()
		var logits := net.forward(MicroCombatFeatureFeaturizer.extract(obs))
		var action_index := net.choose_action_index(logits, mask)
		var legal := env.get_legal_spell_ids()
		var spell_id := SpellCombatRules.PASS_SPELL_ID
		if action_index >= 0 and action_index < legal.size():
			spell_id = legal[action_index]
		elif not legal.is_empty():
			spell_id = legal[0]
		if not legal.has(spell_id) and spell_id != SpellCombatRules.PASS_SPELL_ID:
			illegal_count += 1
			spell_id = SpellCombatRules.PASS_SPELL_ID if legal.is_empty() else legal[0]
		var result := env.step(spell_id)
		total_reward += float(result.get("reward", 0.0))
		steps += 1
	return {
		"steps": steps,
		"illegal_actions": illegal_count,
		"total_reward": total_reward,
		"finished": env.is_done(),
		"winner_id": env.session.winner_id if env.session != null else "",
	}


static func render_metrics_csv(result: Dictionary) -> String:
	var eval_data: Dictionary = result.get("eval", {})
	return "\n".join([
		"seed,rules_version,train_episodes,sample_count,avg_loss,eval_steps,illegal_actions,total_reward,finished,winner_id",
		"%d,%s,%d,%d,%s,%d,%d,%s,%s,%s" % [
			int(result.get("seed", 0)),
			str(result.get("rules_version", "")),
			int(result.get("train_episodes", 0)),
			int(result.get("sample_count", 0)),
			str(result.get("avg_loss", 0.0)),
			int(eval_data.get("steps", 0)),
			int(eval_data.get("illegal_actions", 0)),
			str(eval_data.get("total_reward", 0.0)),
			str(eval_data.get("finished", false)).to_lower(),
			str(eval_data.get("winner_id", "")),
		],
	]) + "\n"


static func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())
