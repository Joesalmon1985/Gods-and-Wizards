class_name VertexCoord
extends RefCounted

var _key: String = ""
var _geometric_hex_keys: Array[String] = []


static func from_hex_corner(hex: HexCoord, corner: int) -> VertexCoord:
	return from_geometric_hexes(_geometric_hexes(hex, corner))


static func from_geometric_hexes(hexes: Array[HexCoord]) -> VertexCoord:
	var vertex := VertexCoord.new()
	var keys: Array[String] = []
	for hex in hexes:
		keys.append(hex.to_key())
	keys.sort()
	vertex._geometric_hex_keys = keys
	vertex._key = "|".join(keys)
	return vertex


static func _geometric_hexes(hex: HexCoord, corner: int) -> Array[HexCoord]:
	var direction := posmod(corner, 6)
	var previous := posmod(corner - 1, 6)
	return [
		hex,
		hex.get_neighbor(direction),
		hex.get_neighbor(previous),
	]


func to_key() -> String:
	return _key


func equals(other: VertexCoord) -> bool:
	return _key == other._key


func to_dict() -> Dictionary:
	return {"geometric_hexes": _geometric_hex_keys.duplicate()}


static func from_dict(data: Dictionary) -> VertexCoord:
	var vertex := VertexCoord.new()
	var keys: Array[String] = []
	for key in data.get("geometric_hexes", []):
		keys.append(key)
	keys.sort()
	vertex._geometric_hex_keys = keys
	vertex._key = "|".join(keys)
	return vertex
