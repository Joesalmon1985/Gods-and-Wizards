extends Control

## Read-only 2D strategic mode: BotGameSession lens with auto-scaled board and side HUD.

const TARGET_WINDOW_SIZE := Vector2i(1920, 1080)
const BOARD_PADDING := 24.0

@export var game_seed: int = 42

var _session: BotGameSession
var _map_host: Control
var _board_view: StrategicBoardView
var _title_label: Label
var _status_label: Label
var _threat_label: Label
var _scoreboard_label: Label
var _events_label: Label
var _help_label: Label


func _ready() -> void:
	_session = BotGameSession.start_four_player(game_seed)
	_map_host = $Layout/MapHost
	_board_view = $Layout/MapHost/BoardView
	_title_label = $Layout/HudPanel/HudMargin/HudScroll/HudVBox/TitleLabel
	_status_label = $Layout/HudPanel/HudMargin/HudScroll/HudVBox/StatusLabel
	_threat_label = $Layout/HudPanel/HudMargin/HudScroll/HudVBox/ThreatLabel
	_scoreboard_label = $Layout/HudPanel/HudMargin/HudScroll/HudVBox/ScoreboardLabel
	_events_label = $Layout/HudPanel/HudMargin/HudScroll/HudVBox/EventsLabel
	_help_label = $Layout/HudPanel/HudMargin/HudScroll/HudVBox/HelpLabel
	_map_host.resized.connect(_on_map_host_resized)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_apply_window_size()
	_refresh_view()
	call_deferred("_fit_board")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_fit_board")


func _apply_window_size() -> void:
	var window := get_window()
	if window != null:
		window.size = TARGET_WINDOW_SIZE


func _on_map_host_resized() -> void:
	_fit_board()


func _on_viewport_resized() -> void:
	_fit_board()


func _fit_board() -> void:
	if _board_view == null or _map_host == null:
		return
	_board_view.fit_to_container(_map_host.size, BOARD_PADDING)


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
	if _board_view != null:
		_board_view.sync_from_snapshot(snapshot)
		_fit_board()
	var summary := GameStateSummary.build(_session.state, _session)
	_update_hud(summary, snapshot)
	if _session.finished and _help_label != null:
		_help_label.text = "Game over — Enter/N still refreshes the view."


func _update_hud(summary: Dictionary, snapshot: Dictionary) -> void:
	if _title_label != null:
		_title_label.text = "Strategic 2D Mode (seed %d)" % summary.get("seed", 0)
	if _status_label != null:
		_status_label.text = _format_status(summary)
	if _threat_label != null:
		_threat_label.text = _format_threat(summary, snapshot)
	if _scoreboard_label != null:
		_scoreboard_label.text = GameStateSummary.format_scoreboard(summary)
	if _events_label != null:
		_events_label.text = _format_recent_events(snapshot)
	if _help_label != null and not _session.finished:
		_help_label.text = "Controls: Enter or N — advance one player turn"


func _format_status(summary: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("Active: %s" % summary.get("active_player_name", "?"))
	lines.append(
		"Round %d | Turn %d | Phase: %s" % [
			summary.get("round_number", 0),
			summary.get("turn_number", 0),
			summary.get("phase", ""),
		]
	)
	lines.append(
		"Board: %d cities | %d roads | Draft age %d | Infection rate %d" % [
			summary.get("total_cities", 0),
			summary.get("total_roads", 0),
			summary.get("draft_age", 0),
			summary.get("infection_rate", 0),
		]
	)
	if summary.get("game_finished", false):
		var winner: String = summary.get("winner_name", "")
		if winner != "":
			lines.append("Game over — winner: %s" % winner)
		else:
			lines.append("Game over — shared loss (underworld breach).")
	else:
		lines.append(
			"Leader: %s (%d VP)" % [
				summary.get("leader_name", "?"),
				summary.get("leader_vp", 0),
			]
		)
	return "\n".join(lines)


func _format_threat(summary: Dictionary, snapshot: Dictionary) -> String:
	return "Threat: %d/%d breaches | %d demons on board" % [
		int(summary.get("breach_count", snapshot.get("breach_count", 0))),
		int(summary.get("breach_limit", GameConstants.BREACH_LIMIT)),
		int(summary.get("total_demons", snapshot.get("total_demons", 0))),
	]


func _format_recent_events(snapshot: Dictionary) -> String:
	var events: Array = snapshot.get("recent_events", [])
	if events.is_empty():
		return "Recent events:\n  (none yet)"
	var lines: PackedStringArray = ["Recent events:"]
	var start := maxi(0, events.size() - 8)
	for index in range(start, events.size()):
		lines.append("  • %s" % str(events[index]))
	return "\n".join(lines)
