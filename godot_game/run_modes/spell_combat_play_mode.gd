extends Node3D

## Playable 3D spell combat prototype — human submits legal spells to SpellCombatSession.

@export var duel_seed: int = 321
@export var loadout_a: String = "hero_patrol"
@export var loadout_b: String = "demon_breach"

var _session: SpellCombatSession
var _timeline_label: Label
var _legal_label: Label
var _status_label: Label
var _help_label: Label
var _options: Array = []
var _selected_index := 0


func _ready() -> void:
	_session = SpellCombatSession.start_duel(duel_seed, loadout_a, loadout_b)
	_timeline_label = $UI/Panel/MarginContainer/VBox/TimelineLabel
	_legal_label = $UI/Panel/MarginContainer/VBox/LegalLabel
	_status_label = $UI/Panel/MarginContainer/VBox/StatusLabel
	_help_label = $UI/Panel/MarginContainer/VBox/HelpLabel
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if _session.finished:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_UP:
			_selected_index = maxi(0, _selected_index - 1)
			_refresh_view()
		KEY_DOWN:
			_selected_index = mini(maxi(0, _options.size() - 1), _selected_index + 1)
			_refresh_view()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_submit_selected()


func _submit_selected() -> void:
	if _options.is_empty():
		return
	SpellCombatPlayController.step_option(_session, _options, _selected_index)
	_selected_index = 0
	_refresh_view()


func _refresh_view() -> void:
	_options = SpellActionPicker.build_options(_session)
	_selected_index = clampi(_selected_index, 0, maxi(0, _options.size() - 1))
	if _legal_label != null:
		_legal_label.text = _format_options()
	if _timeline_label != null:
		_timeline_label.text = SpellCombatTimelinePresenter.summary_text(_session.timeline)
	if _status_label != null:
		var active: Dictionary = _session.get_active_combatant()
		_status_label.text = "Active: %s | HP %.0f | Mana %.0f | Finished: %s" % [
			active.get("id", "?"),
			float(active.get("health", 0)),
			float(active.get("mana", 0)),
			str(_session.finished),
		]
	if _help_label != null:
		_help_label.text = "Up/Down: select legal spell | Enter/Space: cast"


func _format_options() -> String:
	if _options.is_empty():
		return "Legal spells: (none)"
	var lines: PackedStringArray = ["Legal spells:"]
	for i in _options.size():
		var prefix := ">" if i == _selected_index else " "
		lines.append("%s [%d] %s" % [prefix, i, _options[i].get("label", "?")])
	return "\n".join(lines)
