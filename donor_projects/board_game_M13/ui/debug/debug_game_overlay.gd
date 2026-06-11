extends Control

var _controller := DebugGameController.new()
var _auto_timer: Timer
var _updating_slider := false


@onready var _seed_input: LineEdit = $Panel/VBox/SeedRow/SeedInput
@onready var _rounds_input: LineEdit = $Panel/VBox/SeedRow/RoundsInput
@onready var _run_button: Button = $Panel/VBox/SeedRow/RunButton
@onready var _step_button: Button = $Panel/VBox/Controls/StepButton
@onready var _auto_button: Button = $Panel/VBox/Controls/AutoButton
@onready var _export_button: Button = $Panel/VBox/Controls/ExportButton
@onready var _step_slider: HSlider = $Panel/VBox/StepSlider
@onready var _status_label: Label = $Panel/VBox/StatusLabel
@onready var _players_label: Label = $Panel/VBox/PlayersLabel
@onready var _events_label: RichTextLabel = $Panel/VBox/EventsLabel
@onready var _board_view: Node2D = $Panel/VBox/BoardContainer/BoardView


func _ready() -> void:
	_auto_timer = Timer.new()
	_auto_timer.wait_time = 0.75
	_auto_timer.timeout.connect(_on_auto_step)
	add_child(_auto_timer)

	_run_button.pressed.connect(_on_run_pressed)
	_step_button.pressed.connect(_on_step_pressed)
	_auto_button.pressed.connect(_on_auto_pressed)
	_export_button.pressed.connect(_on_export_pressed)
	_step_slider.value_changed.connect(_on_slider_changed)
	_run_simulation()


func _on_run_pressed() -> void:
	_run_simulation()


func _on_step_pressed() -> void:
	_controller.step_forward()
	_refresh_view()


func _on_auto_pressed() -> void:
	if _auto_timer.is_stopped():
		_auto_timer.start()
		_auto_button.text = "Pause"
	else:
		_auto_timer.stop()
		_auto_button.text = "Auto-step"


func _on_export_pressed() -> void:
	var path := _controller.export_csv()
	if path.is_empty():
		push_error("Failed to export debug run CSV")
		return
	print("Debug run CSV written to: %s" % path)


func _on_auto_step() -> void:
	if _controller.can_step():
		_controller.step_forward()
		_refresh_view()
	else:
		_auto_timer.stop()
		_auto_button.text = "Auto-step"


func _on_slider_changed(value: float) -> void:
	if _updating_slider:
		return
	_controller.set_step(int(value))
	_refresh_view()


func _run_simulation() -> void:
	var game_seed := int(_seed_input.text) if _seed_input.text.is_valid_int() else 42
	var rounds := int(_rounds_input.text) if _rounds_input.text.is_valid_int() else 3
	_controller.load_simulation(game_seed, rounds)
	_refresh_view()


func _refresh_view() -> void:
	var view := _controller.current_view()
	var active_name := _active_player_name(view)
	_status_label.text = "Step %d / %d | Round %d | Active: %s" % [
		view["step"],
		view["total_steps"],
		view["round_number"],
		active_name,
	]
	_players_label.text = _format_players(view["players"])
	_events_label.text = _format_events(view)

	_updating_slider = true
	_step_slider.min_value = 0
	_step_slider.max_value = maxi(view["total_steps"], 0)
	_step_slider.step = 1
	_step_slider.value = view["step"]
	_updating_slider = false

	var result := _controller.get_result()
	var state: GameState = result.get("state")
	if state != null and _board_view.has_method("set_board_state"):
		_board_view.set_board_state(
			state.board,
			view["board"],
			view["active_player_index"]
		)


func _active_player_name(view: Dictionary) -> String:
	var players: Array = view.get("players", [])
	var active_index: int = view.get("active_player_index", 0)
	for player in players:
		if player.get("id", -1) == active_index:
			return player.get("name", "Player %d" % active_index)
	return "Player %d" % active_index


func _format_players(players: Array) -> String:
	var lines: PackedStringArray = []
	for player in players:
		var vp: int = player.get("victory_points", 0)
		lines.append("%s (%d VP): %s" % [player["name"], vp, str(player["resources"])])
	return "\n".join(lines)


func _format_events(view: Dictionary) -> String:
	var detail: String = view.get("last_event_detail", "")
	if detail.is_empty():
		return view.get("events_text", "")
	return "%s\n\nLast: %s" % [view.get("events_text", ""), detail]
