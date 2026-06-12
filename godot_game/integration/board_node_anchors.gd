class_name BoardNodeAnchors
extends RefCounted


static func node_to_world(node: BoardNode, board: HexBoard) -> Vector3:
	var hexes := board.get_hexes_for_vertex(node)
	if hexes.is_empty():
		return Vector3.ZERO
	var center := Vector3.ZERO
	for hex in hexes:
		var axial := _hex_to_world(hex)
		center += axial
	center /= float(hexes.size())
	return center


static func _hex_to_world(hex: HexCoord) -> Vector3:
	var x := WorldPresentationScale.HEX_SIZE * (sqrt(3.0) * hex.q + sqrt(3.0) / 2.0 * hex.r)
	var z := WorldPresentationScale.HEX_SIZE * (3.0 / 2.0 * hex.r)
	return Vector3(x, 0.0, z)
