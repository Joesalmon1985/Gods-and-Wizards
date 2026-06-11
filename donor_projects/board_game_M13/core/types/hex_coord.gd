class_name HexCoord
extends RefCounted

const CUBE_DIRS: Array[Vector3i] = [
	Vector3i(1, -1, 0),
	Vector3i(1, 0, -1),
	Vector3i(0, 1, -1),
	Vector3i(-1, 1, 0),
	Vector3i(-1, 0, 1),
	Vector3i(0, -1, 1),
]

var q: int
var r: int


func _init(p_q: int = 0, p_r: int = 0) -> void:
	q = p_q
	r = p_r


func to_cube() -> Vector3i:
	return Vector3i(q, r, -q - r)


static func from_cube(cube: Vector3i) -> HexCoord:
	return HexCoord.new(cube.x, cube.y)


func to_key() -> String:
	return "%04d,%04d" % [r, q]


func sort_key() -> String:
	return to_key()


func get_s() -> int:
	return -q - r


func distance_to(other: HexCoord) -> int:
	var a := to_cube()
	var b := other.to_cube()
	return int((absi(a.x - b.x) + absi(a.y - b.y) + absi(a.z - b.z)) / 2)


func get_neighbor(direction: int) -> HexCoord:
	var dir := CUBE_DIRS[posmod(direction, 6)]
	var cube := to_cube() + dir
	return HexCoord.from_cube(cube)


func get_neighbors() -> Array[HexCoord]:
	var neighbors: Array[HexCoord] = []
	for direction in range(6):
		neighbors.append(get_neighbor(direction))
	return neighbors


func equals(other: HexCoord) -> bool:
	return q == other.q and r == other.r


func to_dict() -> Dictionary:
	return {"q": q, "r": r}
