class_name GameRng
extends RefCounted

var _rng := RandomNumberGenerator.new()
var _fixed_rolls: Array[int]
var _use_fixed_stream_for_all: bool = false


func seed(value: int) -> void:
	_rng.seed = value
	if _fixed_rolls != null:
		_fixed_rolls.clear()
	_use_fixed_stream_for_all = false


func enable_deterministic_stream(base_seed: int, roll_count: int = 2048) -> void:
	var stream := RandomNumberGenerator.new()
	stream.seed = base_seed
	if _fixed_rolls == null:
		_fixed_rolls = []
	else:
		_fixed_rolls.clear()
	for _i in range(roll_count):
		_fixed_rolls.append(stream.randi_range(0, 999999))
	_use_fixed_stream_for_all = true


func randf() -> float:
	return _rng.randf()


func rand_range(from_value: float, to_value: float) -> float:
	return _rng.randf_range(from_value, to_value)


func randi_range(from_value: int, to_value: int) -> int:
	if _use_fixed_stream_for_all and _fixed_rolls != null and not _fixed_rolls.is_empty():
		var raw: int = _fixed_rolls.pop_front()
		var span: int = to_value - from_value + 1
		return from_value + (absi(raw) % span)
	return _rng.randi_range(from_value, to_value)


func roll_d10() -> int:
	if _use_fixed_stream_for_all and _fixed_rolls != null and not _fixed_rolls.is_empty():
		var raw: int = _fixed_rolls.pop_front()
		return absi(raw) % 10
	if _fixed_rolls != null and not _fixed_rolls.is_empty():
		return int(_fixed_rolls.pop_front())
	return randi_range(0, 9)


func roll_die(sides: int) -> int:
	if sides <= 0:
		return 0
	if _use_fixed_stream_for_all and _fixed_rolls != null and not _fixed_rolls.is_empty():
		var raw: int = _fixed_rolls.pop_front()
		return 1 + (absi(raw) % sides)
	if _fixed_rolls != null and not _fixed_rolls.is_empty():
		return int(_fixed_rolls.pop_front())
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
