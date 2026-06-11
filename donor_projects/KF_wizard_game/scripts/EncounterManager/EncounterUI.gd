extends CanvasLayer
class_name EncounterUI

signal chose_dialogue
signal chose_combat
signal chose_leave

@export var debug_verbose := true

@onready var _panel: Panel        = $Panel
@onready var _label: Label        = $Panel/VBox/Label
@onready var _btn_talk: Button    = $Panel/VBox/TalkButton
@onready var _btn_fight: Button   = $Panel/VBox/FightButton
@onready var _btn_leave: Button   = $Panel/VBox/LeaveButton

var _prev_mouse_mode := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	if debug_verbose:
		print("[EncounterUI] ready on ", get_path())
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_process_unhandled_input(true)

	visible = false
	if is_instance_valid(_panel):
		_panel.visible = false
		_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_panel.focus_mode = Control.FOCUS_ALL

	_btn_talk.focus_mode = Control.FOCUS_ALL
	_btn_fight.focus_mode = Control.FOCUS_ALL
	_btn_leave.focus_mode = Control.FOCUS_ALL

	_btn_talk.pressed.connect(func ():
		if debug_verbose: print("[EncounterUI] talk pressed (button)")
		chose_dialogue.emit()
	)
	_btn_fight.pressed.connect(func ():
		if debug_verbose: print("[EncounterUI] fight pressed (button)")
		chose_combat.emit()
	)
	_btn_leave.pressed.connect(func ():
		if debug_verbose: print("[EncounterUI] leave pressed (button)")
		chose_leave.emit()
	)

func open(prompt: String) -> void:
	show_with_prompt(prompt)

func show_with_prompt(prompt_or_name: String) -> void:
	var text := prompt_or_name
	if not text.contains("[R]"):
		text = "You’ve encountered %s.\n[R] Talk   [T] Fight   [Y] Leave" % prompt_or_name
	if is_instance_valid(_label):
		_label.text = text

	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_prev_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	visible = true
	if is_instance_valid(_panel):
		_panel.visible = true

	if debug_verbose:
		print("[EncounterUI] show_with_prompt: pm=", process_mode, " mouse ", _prev_mouse_mode, "->", Input.get_mouse_mode(), " visible=", visible)
	await get_tree().process_frame
	_btn_talk.grab_focus()

func hide_ui() -> void:
	if debug_verbose:
		print("[EncounterUI] hide_ui")
	visible = false
	if is_instance_valid(_panel):
		_panel.visible = false
	Input.set_mouse_mode(_prev_mouse_mode)

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	var k := event as InputEventKey
	if k and k.is_pressed() and not k.is_echo():
		if debug_verbose:
			print("[EncounterUI] key=", k.physical_keycode, " unicode=", k.unicode)
		match k.physical_keycode:
			KEY_R:
				if debug_verbose: print("[EncounterUI] shortcut R -> talk")
				get_viewport().set_input_as_handled()
				chose_dialogue.emit()
			KEY_T:
				if debug_verbose: print("[EncounterUI] shortcut T -> fight")
				get_viewport().set_input_as_handled()
				chose_combat.emit()
			KEY_Y:
				if debug_verbose: print("[EncounterUI] shortcut Y -> leave")
				get_viewport().set_input_as_handled()
				chose_leave.emit()
