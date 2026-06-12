class_name WizardWorldInput
extends RefCounted

enum Action {
	NONE,
	ADVANCE,
	TOGGLE_CAMERA,
	TOGGLE_AUTOPLAY,
	AUTOPLAY_FASTER,
	AUTOPLAY_SLOWER,
	RESET,
	TOGGLE_HELP,
}


static func action_from_keycode(keycode: int) -> Action:
	match keycode:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_N:
			return Action.ADVANCE
		KEY_C:
			return Action.TOGGLE_CAMERA
		KEY_P:
			return Action.TOGGLE_AUTOPLAY
		KEY_EQUAL, KEY_KP_ADD:
			return Action.AUTOPLAY_FASTER
		KEY_MINUS, KEY_KP_SUBTRACT:
			return Action.AUTOPLAY_SLOWER
		KEY_R:
			return Action.RESET
		KEY_H:
			return Action.TOGGLE_HELP
		_:
			return Action.NONE


static func advance_keycodes() -> Array[int]:
	return [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_N]


static func uses_ui_accept_for_advance() -> bool:
	return false
