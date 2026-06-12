class_name BotGameSession
extends RefCounted

const DEFAULT_MAX_PLAYER_TURNS := 200

var seed: int = 0
var policy_name: String = BotTurnResolver.POLICY_HEURISTIC
var state: GameState
var event_log: EventLog
var events: Array = []
var replay_baseline: Dictionary = {}
var player_turn_count: int = 0
var finished: bool = false
var human_player_ids: Array[int] = []
var waiting_for_human: bool = false
var waiting_for_draft: bool = false


static func start_four_player(game_seed: int, policy: String = BotTurnResolver.POLICY_HEURISTIC) -> BotGameSession:
	return _start_session(game_seed, policy, [], ScenarioBuilder.build_four_player_bot_game(game_seed))


static func start_four_player_underworld_pressure(
	game_seed: int,
	policy: String = BotTurnResolver.POLICY_HEURISTIC
) -> BotGameSession:
	return _start_session(
		game_seed,
		policy,
		[],
		ScenarioBuilder.build_underworld_pressure_game(game_seed)
	)


static func start_one_human_three_bots(
	game_seed: int,
	human_player_id: int = 0,
	policy: String = BotTurnResolver.POLICY_HEURISTIC
) -> BotGameSession:
	return _start_session(game_seed, policy, [human_player_id])


static func _start_session(
	game_seed: int,
	policy: String,
	human_ids: Array[int],
	initial_state: GameState = null
) -> BotGameSession:
	var session := BotGameSession.new()
	session.seed = game_seed
	session.policy_name = policy
	session.human_player_ids = human_ids.duplicate()
	session.state = initial_state if initial_state != null else ScenarioBuilder.build_four_player_bot_game(game_seed)
	session.event_log = EventLog.new()
	session.replay_baseline = EventLogReplay.capture_baseline(session.state)

	for event in GameStartRules.start_game(session.state):
		session._record_event(event)

	if session._active_player_is_human():
		session._open_human_turn()

	return session


func advance_one_player_turn() -> Array:
	if finished:
		return []
	if waiting_for_human or waiting_for_draft or _active_player_is_human():
		_open_human_turn()
		return []

	var turn_events := BotTurnResolver.resolve_player_turn(state, event_log, policy_name)
	for event in turn_events:
		events.append(event)

	var draft_events := _resolve_draft_if_needed()
	for event in draft_events:
		events.append(event)
		_record_event(event)

	player_turn_count += 1
	finished = _check_game_over()
	return turn_events + draft_events


func advance_until_human_or_game_over() -> void:
	while not finished and not waiting_for_human and not waiting_for_draft:
		if _active_player_is_human():
			_open_human_turn()
			return
		advance_one_player_turn()


func is_human_player(player_id: int) -> bool:
	return human_player_ids.has(player_id)


func get_active_player_id() -> int:
	return TurnRules.get_active_player_id(state)


func is_waiting_for_human() -> bool:
	return (waiting_for_human or waiting_for_draft) and not finished


func get_legal_human_actions() -> Array[GameAction]:
	if not is_waiting_for_human():
		return []
	if waiting_for_draft:
		return _legal_human_draft_actions()
	return LegalActionQuery.get_legal_actions_sorted(state)


func submit_human_action(action: GameAction) -> Array:
	if not is_waiting_for_human():
		return []
	if waiting_for_draft:
		return submit_human_draft_action(action)
	if not is_human_player(get_active_player_id()):
		return []

	var applied := ActionRules.apply(state, action)
	if applied.is_empty():
		return []

	_record_legal_mask()
	for event in applied:
		_record_event(event)

	if action.kind == ActionKind.Kind.END_TURN:
		waiting_for_human = false
		player_turn_count += 1
		var draft_events := _resolve_draft_if_needed()
		for event in draft_events:
			_record_event(event)
		applied.append_array(draft_events)
		finished = _check_game_over()

	return applied


func submit_human_draft_action(action: GameAction) -> Array:
	if action.kind != ActionKind.Kind.DRAFT_PICK:
		return []
	if not is_human_player(action.draft_player_id):
		return []
	var applied := ActionRules.apply(state, action)
	if applied.is_empty():
		return []
	for event in applied:
		_record_event(event)
	if not state.awaiting_draft_step:
		waiting_for_draft = false
		waiting_for_human = false
		finished = _check_game_over()
	return applied


func run_until_finished(max_player_turns: int = DEFAULT_MAX_PLAYER_TURNS) -> void:
	while not finished and player_turn_count < max_player_turns:
		if waiting_for_human or _active_player_is_human():
			return
		advance_one_player_turn()


func to_result() -> Dictionary:
	return {
		"seed": seed,
		"state": state,
		"events": events,
		"event_log": event_log,
		"replay_baseline": replay_baseline,
		"finished": finished,
		"winner_id": state.winner_id,
		"player_turn_count": player_turn_count,
		"human_player_ids": human_player_ids.duplicate(),
		"waiting_for_human": waiting_for_human,
		"waiting_for_draft": waiting_for_draft,
	}


func status_line() -> String:
	var active := TurnRules.get_active_player(state)
	var name := active.display_name if active != null else "?"
	var human_hint := " | WAITING FOR HUMAN" if is_waiting_for_human() else ""
	return "Seed %d | Round %d | Active %s | Turns %d%s%s" % [
		seed,
		state.round_number,
		name,
		player_turn_count,
		" | FINISHED" if finished else "",
		human_hint,
	]


func _open_human_turn() -> void:
	waiting_for_human = true


func _legal_human_draft_actions() -> Array[GameAction]:
	var legal: Array[GameAction] = []
	for human_id in human_player_ids:
		for action in LegalActionQuery.get_legal_draft_actions_for_player(state, human_id):
			legal.append(action)
	return legal


func _resolve_draft_if_needed() -> Array:
	if not state.awaiting_draft_step:
		waiting_for_draft = false
		return []
	var bot_ids: Array[int] = []
	for player in state.players:
		if not is_human_player(player.id):
			bot_ids.append(player.id)
	DraftRules.apply_bot_draft_picks(state, bot_ids)
	if DraftRules.all_picks_received(state):
		waiting_for_draft = false
		return DraftRules.finalize_round_after_draft(state)
	waiting_for_draft = true
	waiting_for_human = true
	SetupRules.rebuild_action_space(state)
	return []


func _active_player_is_human() -> bool:
	return is_human_player(get_active_player_id())


func _record_legal_mask() -> void:
	var view := LegalActionQuery.get_view(state)
	event_log.append_legal_mask(
		view,
		state.round_number,
		TurnRules.get_active_player_id(state)
	)


func _record_event(event) -> void:
	events.append(event)
	event_log.append(event)


func _check_game_over() -> bool:
	if state.game_finished:
		return true
	var game_over := GameOverRules.evaluate(state)
	if game_over == null:
		return false
	state.game_finished = true
	state.winner_id = game_over.winner_id
	_record_event(game_over)
	return true
