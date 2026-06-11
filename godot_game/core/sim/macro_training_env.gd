class_name MacroTrainingEnv
extends RefCounted

## Headless macro training wrapper over BotGameSession.
##
## Reward model (provisional, documented):
## - Each step: +1.0 per victory point gained by that player since the previous step.
## - Terminal: +10.0 to winner_id on game over; +0.0 to other players.
## - Shared breach loss (winner_id == -1): +0.0 to all players.

const TERMINAL_WIN_REWARD := 10.0

var session: BotGameSession = null
var _vp_before_step: Dictionary = {}


func reset(game_seed: int, policy: String = BotTurnResolver.POLICY_HEURISTIC) -> Dictionary:
	session = BotGameSession.start_four_player(game_seed, policy)
	_capture_vp_snapshot()
	return get_observation(session.get_active_player_id())


func get_observation(player_id: int) -> Dictionary:
	if session == null:
		return {}
	var state := session.state
	var player := _player_by_id(player_id)
	if player == null:
		return {}
	return {
		"seed": session.seed,
		"player_id": player_id,
		"round_number": state.round_number,
		"active_player_id": session.get_active_player_id(),
		"is_active_player": player_id == session.get_active_player_id(),
		"waiting_for_human": session.is_waiting_for_human(),
		"victory_points": player.victory_points,
		"resources": _resource_dict(player),
		"city_count": _count_for_player(state.cities, player_id),
		"road_count": _count_for_player(state.roads, player_id),
		"breach_count": state.breach_count,
		"total_demons": _total_demons(state),
		"game_finished": state.game_finished,
		"winner_id": state.winner_id,
		"policy_name": session.policy_name,
	}


func get_legal_action_view(player_id: int) -> LegalActionView:
	if session == null:
		return LegalActionView.new(ActionSpace.new())
	if player_id != session.get_active_player_id():
		var empty_space := session.state.action_space if session.state != null else ActionSpace.new()
		return LegalActionView.new(empty_space)
	return LegalActionQuery.get_view(session.state)


func choose_policy_action() -> GameAction:
	if session == null:
		return null
	return BotTurnResolver.choose_action(session.state, session.policy_name)


func step_policy_action() -> Dictionary:
	var action := choose_policy_action()
	if action == null:
		return _step_result([])
	return step(action)


func get_legal_actions(player_id: int) -> Array[GameAction]:
	if session == null:
		return []
	if player_id != session.get_active_player_id():
		return []
	if session.is_waiting_for_human():
		return session.get_legal_human_actions()
	return LegalActionQuery.get_legal_actions_sorted(session.state)


func step(action: GameAction) -> Dictionary:
	if session == null or session.finished:
		return _step_result([])
	var events: Array = []
	if session.is_waiting_for_human():
		events = session.submit_human_action(action)
	else:
		events = ActionRules.apply(session.state, action)
		if not events.is_empty():
			for event in events:
				session.events.append(event)
				session.event_log.append(event)
			if action.kind == ActionKind.Kind.END_TURN:
				session.player_turn_count += 1
			session.finished = session.state.game_finished
			if not session.finished:
				var game_over := GameOverRules.evaluate(session.state)
				if game_over != null:
					session.state.game_finished = true
					session.state.winner_id = game_over.winner_id
					session._record_event(game_over)
					session.finished = true
	return _step_result(events)


func step_bot_turn() -> Dictionary:
	if session == null or session.finished:
		return _step_result([])
	return _step_result(session.advance_one_player_turn())


func is_game_over() -> bool:
	return session != null and session.finished


func get_rewards() -> Dictionary:
	var rewards := {}
	if session == null:
		return rewards
	for player in session.state.players:
		var player_id: int = player.id
		var vp_delta := player.victory_points - int(_vp_before_step.get(player_id, player.victory_points))
		rewards[player_id] = float(vp_delta)
	if is_game_over():
		var winner_id := session.state.winner_id
		if winner_id >= 0:
			for player_id in rewards.keys():
				rewards[player_id] = float(rewards[player_id]) + (TERMINAL_WIN_REWARD if player_id == winner_id else 0.0)
	_capture_vp_snapshot()
	return rewards


func get_summary() -> Dictionary:
	if session == null:
		return {}
	var state := session.state
	return {
		"seed": session.seed,
		"policy_name": session.policy_name,
		"finished": session.finished,
		"winner_id": state.winner_id,
		"player_turn_count": session.player_turn_count,
		"round_number": state.round_number,
		"city_count": state.cities.size(),
		"road_count": state.roads.size(),
		"breach_count": state.breach_count,
		"demon_count": _total_demons(state),
		"vp_by_player": _vp_by_player(state),
		"outcome_reason": _outcome_reason(state),
	}


func _step_result(events: Array) -> Dictionary:
	return {
		"events": events,
		"done": is_game_over(),
		"rewards": get_rewards(),
		"summary": get_summary(),
		"observation": get_observation(session.get_active_player_id()) if session != null else {},
	}


func _capture_vp_snapshot() -> void:
	_vp_before_step = {}
	if session == null:
		return
	for player in session.state.players:
		_vp_before_step[player.id] = player.victory_points


func _player_by_id(player_id: int) -> Player:
	if session == null:
		return null
	for player in session.state.players:
		if player.id == player_id:
			return player
	return null


func _resource_dict(player: Player) -> Dictionary:
	var resources := {}
	for resource in ResourceType.all():
		resources[ResourceType.to_key(resource)] = player.get_resource(resource)
	return resources


func _count_for_player(items: Array, player_id: int) -> int:
	var count := 0
	for item in items:
		if item.player_id == player_id:
			count += 1
	return count


func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total


func _vp_by_player(state: GameState) -> Dictionary:
	var result := {}
	for player in state.players:
		result[player.id] = player.victory_points
	return result


func _outcome_reason(state: GameState) -> String:
	if not state.game_finished:
		return ""
	for i in range(session.events.size() - 1, -1, -1):
		var event = session.events[i]
		if event is GameOverEvent:
			return event.reason
	return ""
