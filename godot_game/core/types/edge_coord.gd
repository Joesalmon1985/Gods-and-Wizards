class_name EdgeCoord
extends RefCounted

var _key: String = ""
var node_a: BoardNode
var node_b: BoardNode


static func from_nodes(a: BoardNode, b: BoardNode) -> EdgeCoord:
	var edge := EdgeCoord.new()
	var keys: Array[String] = [a.to_key(), b.to_key()]
	keys.sort()
	edge.node_a = a if a.to_key() == keys[0] else b
	edge.node_b = b if b.to_key() == keys[1] else a
	edge._key = "%s~%s" % [keys[0], keys[1]]
	return edge


func to_key() -> String:
	return _key


func equals(other: EdgeCoord) -> bool:
	if other == null:
		return false
	return _key == other._key


func other_node(node: BoardNode) -> BoardNode:
	if node.equals(node_a):
		return node_b
	if node.equals(node_b):
		return node_a
	return null


func to_dict() -> Dictionary:
	return {
		"node_a": node_a.to_dict(),
		"node_b": node_b.to_dict(),
	}


static func from_dict(data: Dictionary) -> EdgeCoord:
	var a := BoardNode.from_dict(data.get("node_a", {}))
	var b := BoardNode.from_dict(data.get("node_b", {}))
	return from_nodes(a, b)
