extends Node2D

## Read-only 2D strategic mode: BotGameSession lens with placeholder board rendering.

@export var game_seed: int = 42

var _session: BotGameSession
var _board_view: Node2D
var _header_label: Label
var _scoreboard_label: Label


func _ready() -> void:
	_session = BotGameSession.start_four_player(game_seed)
	_board_view = $BoardView
	_header_label = $UI/Panel/MarginContainer/VBox/HeaderLabel
	_scoreboard_label = $UI/Panel/MarginContainer/VBox/ScoreboardLabel
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance_turn()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		_advance_turn()


func _advance_turn() -> void:
	if _session.finished:
		_refresh_view()
		return
	_session.advance_one_player_turn()
	_refresh_view()


func _refresh_view() -> void:
	var snapshot := BoardWorldMapper.build_snapshot(_session.state, _session.events)
	if _board_view != null and _board_view.has_method("sync_from_snapshot"):
		_board_view.sync_from_snapshot(snapshot)
	var summary := GameStateSummary.build(_session.state, _session)
	if _header_label != null:
		_header_label.text = GameStateSummary.format_header(summary)
	if _scoreboard_label != null:
		_scoreboard_label.text = GameStateSummary.format_scoreboard(summary)
