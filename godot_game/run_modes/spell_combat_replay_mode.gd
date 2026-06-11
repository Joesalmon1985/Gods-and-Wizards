extends Node3D

## Non-playable spell combat replay mode driven by SpellCombatSession timeline.

@export var duel_seed: int = 123
@export var loadout_a: String = "hero_patrol"
@export var loadout_b: String = "demon_breach"

var _session: SpellCombatSession
var _timeline_label: Label
var _status_label: Label


func _ready() -> void:
	_session = SpellCombatSession.start_duel(duel_seed, loadout_a, loadout_b)
	_timeline_label = $UI/Panel/MarginContainer/VBox/TimelineLabel
	_status_label = $UI/Panel/MarginContainer/VBox/StatusLabel
	_run_demo_to_completion()
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_step_once()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_session = SpellCombatSession.start_duel(duel_seed, loadout_a, loadout_b)
		_refresh_view()


func _run_demo_to_completion() -> void:
	var steps := 0
	while not _session.finished and steps < 120:
		_session.step_deterministic_policy()
		steps += 1


func _step_once() -> void:
	if _session.finished:
		return
	_session.step_deterministic_policy()
	_refresh_view()


func _refresh_view() -> void:
	if _timeline_label != null:
		_timeline_label.text = SpellCombatTimelinePresenter.summary_text(_session.timeline)
	if _status_label != null:
		_status_label.text = "Finished: %s | Winner: %s | Enter: step policy | R: reset" % [
			str(_session.finished),
			_session.winner_id,
		]
