class_name WizardCameraRig
extends RefCounted

enum Mode { BOARD_OVERVIEW, WIZARD_MARKER }

const BOARD_PITCH_DEG := -55.0


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
			var back := WizardOrientation.forward(marker_yaw_rad) * WorldPresentationScale.wizard_back_offset()
			var position := marker_position + Vector3(0.0, WorldPresentationScale.wizard_eye_height(), 0.0) - back
			var look_target := marker_position + Vector3(
				WizardOrientation.forward(marker_yaw_rad).x,
				WorldPresentationScale.wizard_eye_height() * 0.5,
				WizardOrientation.forward(marker_yaw_rad).z
			)
			return {
				"position": position,
				"look_at": look_target,
				"mode": "wizard_marker",
			}
		_:
			var radius := maxf(board_radius, WorldPresentationScale.hex_radius() * 8.0)
			return {
				"position": board_center + Vector3(0.0, WorldPresentationScale.board_height(), radius * 1.2),
				"look_at": board_center,
				"mode": "board_overview",
			}
