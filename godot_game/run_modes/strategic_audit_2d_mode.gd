extends Node2D

## Read-only 2D macro audit mode: bot advance with legal-action and event readout.

@export var game_seed: int = 42
@export var batch_step_count: int = 5

var _session: BotGameSession
var _board_view: Node2D
var _header_label: Label
var _scoreboard_label: Label
var _legal_label: Label
var _events_label: Label
var _help_label: Label
var _batch_running := false


func _ready() -> void:
	_session = BotGameSession.start_four_player(game_seed)
	_board_view = $BoardView
	_header_label = $UI/Panel/MarginContainer/VBox/HeaderLabel
	_scoreboard_label = $UI/Panel/MarginContainer/VBox/ScoreboardLabel
	_legal_label = $UI/Panel/MarginContainer/VBox/LegalLabel
	_events_label = $UI/Panel/MarginContainer/VBox/EventsLabel
	_help_label = $UI/Panel/MarginContainer/VBox/HelpLabel
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		StrategicAuditController.advance_one_bot_step(_session)
		_refresh_view()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_N:
			StrategicAuditController.advance_one_bot_step(_session)
			_refresh_view()
		KEY_B:
			_toggle_batch_advance()
		KEY_P:
			_batch_running = false
			_refresh_view()


func _process(_delta: float) -> void:
	if not _batch_running or _session.finished:
		return
	StrategicAuditController.advance_one_bot_step(_session)
	_refresh_view()
	if _session.finished:
		_batch_running = false


func _toggle_batch_advance() -> void:
	if _session.finished:
		_batch_running = false
		return
	_batch_running = not _batch_running
	_refresh_view()


func _refresh_view() -> void:
	var snapshot := BoardWorldMapper.build_snapshot(_session.state, _session.events)
	if _board_view != null and _board_view.has_method("sync_from_snapshot"):
		_board_view.sync_from_snapshot(snapshot)
	var model := StrategicAuditViewModel.build(_session)
	if _header_label != null:
		var header: String = model.get("header_text", "")
		header += " | Breaches: %d | Demons: %d" % [
			int(model.get("breach_count", 0)),
			int(model.get("total_demons", 0)),
		]
		if _session.finished:
			header += " | GAME OVER"
		_header_label.text = header
	if _scoreboard_label != null:
		_scoreboard_label.text = model.get("scoreboard_text", "")
	if _legal_label != null:
		_legal_label.text = StrategicAuditViewModel.format_legal_actions(model)
	if _events_label != null:
		_events_label.text = StrategicAuditViewModel.format_recent_events(model)
	if _help_label != null:
		var help := "Enter/N: one bot step | B: pause/resume batch (%d/step) | P: pause"
		if _batch_running:
			help += " | BATCH RUNNING"
		_help_label.text = help
