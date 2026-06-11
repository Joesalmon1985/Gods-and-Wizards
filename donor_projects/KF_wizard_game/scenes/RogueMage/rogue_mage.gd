extends Node3D

func _ready():
	# Call the hide function after a short delay to ensure everything is loaded
	get_tree().create_timer(0.1).timeout.connect(hide_templates)

func hide_templates():
	# Hide the template fireball and shield
	var fireball = get_node("Fireball")
	if fireball:
		print("Hiding fireball template")
		fireball.visible = false
	else:
		print("ERROR: Fireball node not found in Main scene")
	
	var shield = get_node("Shield")
	if shield:
		print("Hiding shield template")
		shield.visible = false
	else:
		print("ERROR: Shield node not found in Main scene")
