class_name WizardCameraRig
extends RefCounted

enum Mode { BOARD_OVERVIEW, WIZARD_MARKER }

const BOARD_HEIGHT := 28.0
const BOARD_PITCH_DEG := -55.0
const WIZARD_EYE_HEIGHT := 1.6
const WIZARD_BACK_OFFSET := 2.5


static func toggle_mode(current: Mode) -> Mode:
	return Mode.WIZARD_MARKER if current == Mode.BOARD_OVERVIEW else Mode.BOARD_OVERVIEW


static func mode_label(mode: Mode) -> String:
	return "Wizard" if mode == Mode.WIZARD_MARKER else "Board"


static func compute_transform(
	mode: Mode,
	marker_position: Vector3,
	marker_yaw_rad: float,
	board_center: Vector3,
	board_radius: float
) -> Dictionary:
	match mode:
		Mode.WIZARD_MARKER:
			var back := Vector3(sin(marker_yaw_rad), 0.0, cos(marker_yaw_rad)) * WIZARD_BACK_OFFSET
			var position := marker_position + Vector3(0.0, WIZARD_EYE_HEIGHT, 0.0) - back
			var look_target := marker_position + Vector3(
				sin(marker_yaw_rad),
				WIZARD_EYE_HEIGHT * 0.5,
				cos(marker_yaw_rad)
			)
			return {
				"position": position,
				"look_at": look_target,
				"mode": "wizard_marker",
			}
		_:
			var radius := maxf(board_radius, 8.0)
			return {
				"position": board_center + Vector3(0.0, BOARD_HEIGHT, radius * 1.2),
				"look_at": board_center,
				"mode": "board_overview",
			}
