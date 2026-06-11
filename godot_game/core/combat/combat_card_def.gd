class_name CombatCardDef
extends RefCounted

var name: String = "Unnamed"
var move_id: StringName = &"thrust"


func _init(p_name: String = "Unnamed", p_move_id: StringName = &"thrust") -> void:
	name = p_name
	move_id = p_move_id
