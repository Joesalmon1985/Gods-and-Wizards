extends Resource
class_name DeckDefinition

@export var entries: Array[DeckEntry] = []
@export var hand_size: int = 3

func add_entry(e: DeckEntry) -> void:
	if e != null:
		entries.append(e)
