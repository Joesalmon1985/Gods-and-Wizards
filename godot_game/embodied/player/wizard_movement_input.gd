class_name WizardMovementInput
extends RefCounted

const DEFAULT_TURN_SPEED := 2.0


static func compute_move_delta(
	keys: Dictionary,
	delta: float,
	speed: float = -1.0,
	yaw_rad: float = 0.0
) -> Vector3:
	var move_speed := speed if speed >= 0.0 else WorldPresentationScale.walk_speed()
	var move := Vector3.ZERO
	if bool(keys.get("w", false)):
		move += WizardOrientation.forward(yaw_rad)
	if bool(keys.get("s", false)):
		move -= WizardOrientation.forward(yaw_rad)
	if bool(keys.get("a", false)):
		move -= WizardOrientation.right(yaw_rad)
	if bool(keys.get("d", false)):
		move += WizardOrientation.right(yaw_rad)
	if move == Vector3.ZERO:
		return Vector3.ZERO
	return move.normalized() * move_speed * delta


static func compute_yaw_delta(keys: Dictionary, delta: float, turn_speed: float = DEFAULT_TURN_SPEED) -> float:
	var yaw := 0.0
	if bool(keys.get("q", false)):
		yaw += turn_speed * delta
	if bool(keys.get("e", false)):
		yaw -= turn_speed * delta
	return yaw


static func keys_from_pressed(w: bool, a: bool, s: bool, d: bool, q: bool, e: bool) -> Dictionary:
	return {"w": w, "a": a, "s": s, "d": d, "q": q, "e": e}
