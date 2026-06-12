extends Node3D

## Wizard-world mode: shared BotGameSession plus read-only 3D board visualisation.

@export var game_seed: int = 42

var _session: BotGameSession
var _header_label: Label
var _scoreboard_label: Label
var _log_label: Label
var _help_label: Label
var _encounter_label: Label
var _camera_button: Button
var _wizard_marker: Node3D
var _camera: Camera3D
var _board_visualizer: BoardStateVisualizer
var _controller := WizardWorldController.new()
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
	_encounter_label = $UI/Panel/MarginContainer/VBox/EncounterLabel
	_camera_button = $UI/Panel/MarginContainer/VBox/CameraToggleButton
	_wizard_marker = $WizardMarker
	_camera = $Camera3D
	_board_visualizer = $BoardVisuals
	if _camera_button != null:
		_camera_button.pressed.connect(_on_camera_toggle_pressed)
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
		KEY_C:
			_on_camera_toggle_pressed()


func _process(delta: float) -> void:
	var keys := WizardMovementInput.keys_from_pressed(
		Input.is_key_pressed(KEY_W),
		Input.is_key_pressed(KEY_A),
		Input.is_key_pressed(KEY_S),
		Input.is_key_pressed(KEY_D),
		Input.is_key_pressed(KEY_Q),
		Input.is_key_pressed(KEY_E)
	)
	_controller.apply_movement(keys, delta)
	_wizard_marker.position = _controller.marker_position
	_wizard_marker.rotation.y = _controller.marker_yaw_rad
	_apply_camera_transform()

	if _session != null:
		var snapshot := BoardWorldMapper.build_snapshot(_session.state, _session.events)
		_controller.update_encounter_prompt(snapshot)
		if _encounter_label != null:
			_encounter_label.text = _controller.encounter_prompt

	if _autoplay and _session != null and not _session.finished:
		_autoplay_timer += delta
		if _autoplay_timer >= _autoplay_interval:
			_autoplay_timer = 0.0
			_advance_simulation_step()


func _on_camera_toggle_pressed() -> void:
	_controller.toggle_camera()
	_apply_camera_transform()
	_refresh_view()


func _apply_camera_transform() -> void:
	if _camera == null:
		return
	var transform_data := _controller.get_camera_transform()
	_camera.global_position = transform_data.get("position", _camera.global_position)
	var look_at: Vector3 = transform_data.get("look_at", Vector3.ZERO)
	if look_at != Vector3.ZERO:
		_camera.look_at(look_at, Vector3.UP)


func _start_session() -> void:
	_session = BotGameSession.start_four_player(game_seed)
	_controller.marker_position = _wizard_marker.position if _wizard_marker != null else Vector3.ZERO
	_controller.marker_yaw_rad = _wizard_marker.rotation.y if _wizard_marker != null else 0.0


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
	var snapshot := BoardWorldMapper.build_snapshot(_session.state, _session.events)
	_controller.sync_board_bounds(snapshot)
	_apply_camera_transform()
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
	if _camera_button != null:
		_camera_button.text = "Camera: %s" % WizardCameraRig.mode_label(_controller.camera_mode)
	if _help_label != null:
		_help_label.visible = _show_help
		if _show_help:
			_help_label.text = _help_text()


func _help_text() -> String:
	return (
		"Enter/N: advance turn | Space: autoplay (%s) | +/-: speed %.1fs | R: reset | H: hide help | WASD: move | Q/E: turn | C/button: camera (%s)"
		% [
			"ON" if _autoplay else "OFF",
			_autoplay_interval,
			WizardCameraRig.mode_label(_controller.camera_mode),
		]
	)
