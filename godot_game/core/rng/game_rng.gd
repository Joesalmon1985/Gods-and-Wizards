class_name GameRng
extends RefCounted

var _rng: RandomNumberGenerator
var _injected_rolls: PackedInt32Array = PackedInt32Array()
var _stream_rolls: PackedInt32Array = PackedInt32Array()
var _use_fixed_stream_for_all: bool = false


func _init() -> void:
	_rng = RandomNumberGenerator.new()


func seed(value: int) -> void:
	_rng.seed = value
	_injected_rolls = PackedInt32Array()
	_stream_rolls = PackedInt32Array()
	_use_fixed_stream_for_all = false


func enable_deterministic_stream(base_seed: int, roll_count: int = 2048) -> void:
	var stream := RandomNumberGenerator.new()
	stream.seed = base_seed
	_stream_rolls = PackedInt32Array()
	for _i in range(roll_count):
		_stream_rolls.append(stream.randi_range(0, 999999))
	_use_fixed_stream_for_all = true


func randf() -> float:
	return _rng.randf()


func rand_range(from_value: float, to_value: float) -> float:
	return _rng.randf_range(from_value, to_value)


func randi_range(from_value: int, to_value: int) -> int:
	if _use_fixed_stream_for_all and _stream_rolls.size() > 0:
		var raw: int = _stream_rolls[0]
		_stream_rolls = _stream_rolls.slice(1)
		var span: int = to_value - from_value + 1
		return from_value + (absi(raw) % span)
	return _rng.randi_range(from_value, to_value)


func roll_d10() -> int:
	if _use_fixed_stream_for_all and _stream_rolls.size() > 0:
		var raw: int = _stream_rolls[0]
		_stream_rolls = _stream_rolls.slice(1)
		return absi(raw) % 10
	if _injected_rolls.size() > 0:
		var roll: int = _injected_rolls[0]
		_injected_rolls = _injected_rolls.slice(1)
		return roll
	return _rng.randi_range(0, 9)


func roll_die(sides: int) -> int:
	if sides <= 0:
		return 0
	if _use_fixed_stream_for_all and _stream_rolls.size() > 0:
		var raw: int = _stream_rolls[0]
		_stream_rolls = _stream_rolls.slice(1)
		return 1 + (absi(raw) % sides)
	if _injected_rolls.size() > 0:
		var roll: int = _injected_rolls[0]
		_injected_rolls = _injected_rolls.slice(1)
		return roll
	return _rng.randi_range(1, sides)


func enqueue_fixed_rolls(rolls: Array) -> void:
	for roll in rolls:
		_injected_rolls.append(int(roll))


func fixed_rolls_remaining() -> int:
	return _injected_rolls.size()
