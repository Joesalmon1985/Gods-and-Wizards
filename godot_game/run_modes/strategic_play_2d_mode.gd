extends Node2D

## Playable 2D macro mode: one human god plus three bots.

@export var game_seed: int = 42
@export var human_player_id: int = 0

var _session: BotGameSession
var _board_view: Node2D
var _header_label: Label
var _scoreboard_label: Label
var _legal_label: Label
var _status_label: Label
var _help_label: Label
var _draft_label: Label
var _development_label: Label
var _action_options: Array = []
var _selected_index := 0


func _ready() -> void:
	_session = BotGameSession.start_one_human_three_bots(game_seed, human_player_id)
	_board_view = $BoardView
	_header_label = $UI/Panel/MarginContainer/VBox/HeaderLabel
	_scoreboard_label = $UI/Panel/MarginContainer/VBox/ScoreboardLabel
	_legal_label = $UI/Panel/MarginContainer/VBox/LegalLabel
	_status_label = $UI/Panel/MarginContainer/VBox/StatusLabel
	_help_label = $UI/Panel/MarginContainer/VBox/HelpLabel
	_draft_label = $UI/Panel/MarginContainer/VBox/DraftLabel
	_development_label = $UI/Panel/MarginContainer/VBox/DevelopmentLabel
	StrategicPlayController.advance_until_human_or_stopped(_session)
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_UP:
			_selected_index = maxi(0, _selected_index - 1)
			_refresh_view()
		KEY_DOWN:
			_selected_index = mini(maxi(0, _action_options.size() - 1), _selected_index + 1)
			_refresh_view()
		KEY_ENTER, KEY_KP_ENTER:
			_submit_selected()
		KEY_SPACE:
			_submit_selected()


func _submit_selected() -> void:
	if not _session.is_waiting_for_human():
		return
	if _action_options.is_empty():
		return
	StrategicPlayController.submit_option(_session, _action_options, _selected_index)
	if not _session.is_waiting_for_human():
		StrategicPlayController.advance_until_human_or_stopped(_session)
	_selected_index = 0
	_refresh_view()


func _refresh_view() -> void:
	var snapshot := BoardWorldMapper.build_snapshot(_session.state, _session.events)
	if _board_view != null and _board_view.has_method("sync_from_snapshot"):
		_board_view.sync_from_snapshot(snapshot)
	var summary := GameStateSummary.build(_session.state, _session)
	summary["title"] = "2D One-God Play Mode"
	if _header_label != null:
		_header_label.text = GameStateSummary.format_header(summary)
	if _scoreboard_label != null:
		_scoreboard_label.text = GameStateSummary.format_scoreboard(summary)
	if _session.is_waiting_for_human():
		_action_options = StrategicActionPicker.build_options(_session.get_legal_human_actions())
	else:
		_action_options = []
	_selected_index = clampi(_selected_index, 0, maxi(0, _action_options.size() - 1))
	if _legal_label != null:
		_legal_label.text = _format_action_list()
	if _status_label != null:
		if _session.finished:
			_status_label.text = "Game over."
		elif _session.is_waiting_for_human():
			_status_label.text = "Waiting for human (player %d) | phase=%s | infection=%d | breach=%d/%d" % [
				human_player_id,
				summary.get("phase", "?"),
				int(summary.get("infection_rate", 0)),
				int(summary.get("breach_count", 0)),
				int(summary.get("breach_limit", GameConstants.BREACH_LIMIT)),
			]
		else:
			_status_label.text = "Bots playing..."
	var draft_model := StrategicDraftViewModel.build(_session, human_player_id)
	var development_model := StrategicDevelopmentViewModel.build(_session, human_player_id)
	if _draft_label != null:
		_draft_label.text = "%s\n%s" % [
			StrategicDraftViewModel.format_pack_summary(draft_model),
			StrategicDraftViewModel.format_hand_summary(draft_model),
		]
	if _development_label != null:
		_development_label.text = "%s\n%s" % [
			StrategicDevelopmentViewModel.format_city_slots(development_model),
			StrategicDevelopmentViewModel.format_hand_rules(development_model),
		]
	if _help_label != null:
		_help_label.text = "Up/Down: select legal action | Enter/Space: submit | Read-only board lens"


func _format_action_list() -> String:
	if _action_options.is_empty():
		return "Legal actions: (none — bot turn or game over)"
	var lines: PackedStringArray = ["Legal actions:"]
	for i in _action_options.size():
		var prefix := ">" if i == _selected_index else " "
		lines.append("%s [%d] %s" % [prefix, i, _action_options[i].get("label", "?")])
	return "\n".join(lines)
