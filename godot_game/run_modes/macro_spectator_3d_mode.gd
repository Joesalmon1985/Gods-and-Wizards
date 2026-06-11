extends Node3D

## Read-only 3D macro spectator with manual and timer-based bot advance.

@export var game_seed: int = 42

var _session: BotGameSession
var _header_label: Label
var _scoreboard_label: Label
var _log_label: Label
var _help_label: Label
var _board_visualizer: BoardStateVisualizer
var _camera_marker: Node3D
var _autoplay := false
var _autoplay_interval := 1.0
var _autoplay_timer := 0.0


func _ready() -> void:
	_session = BotGameSession.start_four_player(game_seed)
	_header_label = $UI/Panel/MarginContainer/VBox/HeaderLabel
	_scoreboard_label = $UI/Panel/MarginContainer/VBox/ScoreboardLabel
	_log_label = $UI/Panel/MarginContainer/VBox/LogLabel
	_help_label = $UI/Panel/MarginContainer/VBox/HelpLabel
	_board_visualizer = $BoardVisuals
	_camera_marker = $CameraMarker
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		MacroSpectatorController.advance_one_step(_session)
		_refresh_view()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_N:
			MacroSpectatorController.advance_one_step(_session)
			_refresh_view()
		KEY_SPACE:
			_autoplay = not _autoplay
			_autoplay_timer = 0.0
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
	if move != Vector3.ZERO and _camera_marker != null:
		_camera_marker.translate(move.normalized() * 3.0 * delta)

	if _autoplay and _session != null and not _session.finished:
		_autoplay_timer += delta
		if MacroSpectatorController.advance_if_timer_elapsed(_session, _autoplay_timer, _autoplay_interval, 0.0):
			_autoplay_timer = 0.0
			_refresh_view()


func _refresh_view() -> void:
	if _board_visualizer != null:
		_board_visualizer.sync_from_session(_session)
	var summary := GameStateSummary.build(_session.state, _session)
	summary["title"] = "3D Macro Spectator"
	if _header_label != null:
		_header_label.text = GameStateSummary.format_header(summary)
	if _scoreboard_label != null:
		_scoreboard_label.text = GameStateSummary.format_scoreboard(summary)
	if _log_label != null:
		_log_label.text = TurnReport.format_recent_log(_session, 3)
	if _help_label != null:
		_help_label.text = "Enter/N: advance | Space: autoplay | WASD: move camera marker only"
