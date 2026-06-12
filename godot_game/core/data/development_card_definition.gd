class_name DevelopmentCardDefinition
extends RefCounted

var id: String = ""
var name: String = ""
var age: int = 0
var category: String = ""
var slot_type: String = ""
var cost: Dictionary = {}
var vp: int = 0
var rules_text: String = ""
var flavour_text: String = ""
var effects: Array = []
var tags: Array[String] = []
var implementation_status: String = "implemented"


static func from_dict(data: Dictionary) -> DevelopmentCardDefinition:
	var card := DevelopmentCardDefinition.new()
	card.id = str(data.get("id", ""))
	card.name = str(data.get("name", card.id))
	card.age = int(data.get("age", 0))
	card.category = str(data.get("category", ""))
	card.slot_type = str(data.get("slot_type", ""))
	card.vp = int(data.get("vp", 0))
	card.rules_text = str(data.get("rules_text", ""))
	card.flavour_text = str(data.get("flavour_text", ""))
	card.implementation_status = str(data.get("implementation_status", "implemented"))

	var cost_data = data.get("cost", {})
	if typeof(cost_data) == TYPE_DICTIONARY:
		for key in cost_data.keys():
			card.cost[str(key)] = int(cost_data[key])

	var effects_data = data.get("effects", [])
	if typeof(effects_data) == TYPE_ARRAY:
		for entry in effects_data:
			if typeof(entry) == TYPE_DICTIONARY:
				card.effects.append(entry.duplicate(true))

	var tags_data = data.get("tags", [])
	if typeof(tags_data) == TYPE_ARRAY:
		for tag in tags_data:
			card.tags.append(str(tag))

	return card
