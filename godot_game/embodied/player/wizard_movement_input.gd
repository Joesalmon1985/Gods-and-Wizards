class_name WizardMovementInput
extends RefCounted

const DEFAULT_MOVE_SPEED := 3.0
const DEFAULT_TURN_SPEED := 2.0


static func compute_move_delta(keys: Dictionary, delta: float, speed: float = DEFAULT_MOVE_SPEED) -> Vector3:
	var move := Vector3.ZERO
	if bool(keys.get("w", false)):
		move.z -= 1.0
	if bool(keys.get("s", false)):
		move.z += 1.0
	if bool(keys.get("a", false)):
		move.x -= 1.0
	if bool(keys.get("d", false)):
		move.x += 1.0
	if move == Vector3.ZERO:
		return Vector3.ZERO
	return move.normalized() * speed * delta


static func compute_yaw_delta(keys: Dictionary, delta: float, turn_speed: float = DEFAULT_TURN_SPEED) -> float:
	var yaw := 0.0
	if bool(keys.get("q", false)):
		yaw += turn_speed * delta
	if bool(keys.get("e", false)):
		yaw -= turn_speed * delta
	return yaw


static func keys_from_pressed(w: bool, a: bool, s: bool, d: bool, q: bool, e: bool) -> Dictionary:
	return {"w": w, "a": a, "s": s, "d": d, "q": q, "e": e}
