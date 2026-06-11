extends Node3D

## Wizard-world mode: shared BotGameSession plus read-only 3D board visualisation.

@export var game_seed: int = 42

var _session: BotGameSession
var _header_label: Label
var _scoreboard_label: Label
var _log_label: Label
var _help_label: Label
var _wizard_marker: Node3D
var _board_visualizer: BoardStateVisualizer
var _autoplay := false
var _autoplay_interval := 1.0
var _autoplay_timer := 0.0
var _show_help := true


func _ready() -> void:
	_start_session()
	_header_label = $UI/Panel/MarginContainer/VBox/HeaderLabel
	_scoreboard_label = $UI/Panel/MarginContainer/VBox/ScoreboardLabel
	_log_label = $UI/Panel/MarginContainer/VBox/LogLabel
	_help_label = $UI/Panel/MarginContainer/VBox/HelpLabel
	_wizard_marker = $WizardMarker
	_board_visualizer = $BoardVisuals
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance_simulation_step()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_N:
			_advance_simulation_step()
		KEY_SPACE:
			_autoplay = not _autoplay
			_autoplay_timer = 0.0
			_refresh_view()
		KEY_EQUAL, KEY_KP_ADD:
			_autoplay_interval = maxf(0.25, _autoplay_interval - 0.25)
			_refresh_view()
		KEY_MINUS, KEY_KP_SUBTRACT:
			_autoplay_interval = minf(5.0, _autoplay_interval + 0.25)
			_refresh_view()
		KEY_R:
			_reset_session()
		KEY_H:
			_show_help = not _show_help
			_refresh_view()


func _process(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		move.z += 1.0
	if Input.is_key_pressed(KEY_A):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move.x += 1.0
	if move != Vector3.ZERO:
		_wizard_marker.translate(move.normalized() * 3.0 * delta)

	if _autoplay and _session != null and not _session.finished:
		_autoplay_timer += delta
		if _autoplay_timer >= _autoplay_interval:
			_autoplay_timer = 0.0
			_advance_simulation_step()


func _start_session() -> void:
	_session = BotGameSession.start_four_player(game_seed)


func _reset_session() -> void:
	_autoplay = false
	_autoplay_timer = 0.0
	_start_session()
	_refresh_view()


func _advance_simulation_step() -> void:
	if _session.finished:
		_refresh_view()
		return
	_session.advance_one_player_turn()
	_refresh_view()


func _refresh_view() -> void:
	if _board_visualizer != null:
		_board_visualizer.sync_from_session(_session)
	_update_overlay()


func _update_overlay() -> void:
	if _session == null:
		return
	var summary := GameStateSummary.build(_session.state, _session)
	if _header_label != null:
		_header_label.text = GameStateSummary.format_header(summary)
	if _scoreboard_label != null:
		_scoreboard_label.text = GameStateSummary.format_scoreboard(summary)
	if _log_label != null:
		_log_label.text = TurnReport.format_recent_log(_session, 5)
	if _help_label != null:
		_help_label.visible = _show_help
		if _show_help:
			_help_label.text = _help_text()


func _help_text() -> String:
	return (
		"Enter/N: advance turn | Space: autoplay (%s) | +/-: speed %.1fs | R: reset | H: hide help | WASD: wizard marker"
		% ["ON" if _autoplay else "OFF", _autoplay_interval]
	)
