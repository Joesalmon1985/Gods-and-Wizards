extends Resource
class_name DevCard

@export var card_type: String = ""   # e.g. "VP", "Knight", etc.
@export var description: String = ""

func _init(_type: String = "", _desc: String = "") -> void:
    card_type = _type
    description = _desc

func debug_string() -> String:
    return "[DevCard type=%s desc=%s]" % [card_type, description]

