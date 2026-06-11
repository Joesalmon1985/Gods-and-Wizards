class_name GameRng
extends RefCounted

var _rng := RandomNumberGenerator.new()
var _fixed_rolls: Array[int]


func seed(value: int) -> void:
	_rng.seed = value
	if _fixed_rolls != null:
		_fixed_rolls.clear()


func randf() -> float:
	return _rng.randf()


func rand_range(from_value: float, to_value: float) -> float:
	return _rng.randf_range(from_value, to_value)


func randi_range(from_value: int, to_value: int) -> int:
	return _rng.randi_range(from_value, to_value)


func roll_d10() -> int:
	if _fixed_rolls != null and not _fixed_rolls.is_empty():
		return _fixed_rolls.pop_front()
	return randi_range(0, 9)


func roll_die(sides: int) -> int:
	if sides <= 0:
		return 0
	if _fixed_rolls != null and not _fixed_rolls.is_empty():
		return _fixed_rolls.pop_front()
	return randi_range(1, sides)


func enqueue_fixed_rolls(rolls: Array) -> void:
	if _fixed_rolls == null:
		_fixed_rolls = []
	for roll in rolls:
		_fixed_rolls.append(int(roll))


func fixed_rolls_remaining() -> int:
	if _fixed_rolls == null:
		return 0
	return _fixed_rolls.size()
