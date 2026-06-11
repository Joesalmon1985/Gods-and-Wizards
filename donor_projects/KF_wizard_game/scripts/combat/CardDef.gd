extends Resource
class_name CardDef

@export var name: String = "Unnamed"
@export var move_id: StringName = &"thrust"  # one of: thrust, swing, jab, parry, block
# (die_count / die_sides no longer used by the resolver; keep if you still want them on cards)
