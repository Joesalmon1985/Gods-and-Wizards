extends CanvasLayer
class_name MagicCombatEncounter
@onready var health_label = $Control/healthlabel as Label
@onready var fireball_label = $Control/fireballlabel as Label
@onready var shield_label = $Control/shieldlabel as Label
@onready var death_label = $Control/Deathlabel as Label
@onready var damage_label = $Control/Damage as Label
@onready var restart_button = $Control/RestartButton as Button
@onready var casting_label = $Control/CastingLabel as Label
@onready var enemy_casting_label = $Control/EnemyCastingLabel as Label
@onready var target_label = $Control/TargetLabel as Label

# Track spell states to prevent incorrect "READY" messages
var fireball_state = "ready"  # Can be: ready, casting, cooldown
var shield_state = "ready"    # Can be: ready, casting, cooldown

# Debug styles - remove after testing
const DEBUG_STYLE = {
	"font_size": 20,
	"modulate": Color.WHITE,
	"outline": Color.BLACK,
	"outline_size": 4
}

func _ready():
	# Apply debug styling
	for label in [health_label, fireball_label, shield_label, death_label]:
		label.add_theme_font_size_override("font_size", DEBUG_STYLE.font_size)
		label.modulate = DEBUG_STYLE.modulate
		label.add_theme_constant_override("outline_size", DEBUG_STYLE.outline_size)
		label.add_theme_color_override("font_outline_color", DEBUG_STYLE.outline)

	# Initial values (will be overwritten by player signals)
	health_label.text = "HEALTH: 100"
	fireball_label.text = "FIREBALL: READY"
	shield_label.text = "SHIELD: READY"
	death_label.visible = false
	death_label.text = "YOU DIED"
	damage_label.visible = false
	restart_button.visible = false
	restart_button.text = "RESTART?"
	casting_label.visible = false
	enemy_casting_label.visible = false
	target_label.visible = false

	# Connect the restart button if not already connected
	if restart_button and not restart_button.is_connected("pressed", _on_restart_button_pressed):
		restart_button.connect("pressed", _on_restart_button_pressed)

	print("Restart button: ", restart_button)
	print("Restart button visible: ", restart_button.visible if restart_button else "null")

	# Connect to future enemies
	get_tree().node_added.connect(_on_node_added)

	## NEED TO DEVELOP METHOD TO INTERACT WITH PLAYER
	## Player connection
	#var player = get_node_or_null("/root/Main/Player")
	#if player:
		#player.player_died.connect(show_death_message)
		#player.damage_dealt.connect(show_damage_notification)
	#else:
		#push_error("Player node not found!")

	### NEED TO DEVELOP METHOD TO INTERACT WITH OPPONENT
	## Existing enemies connection
	#for enemy in get_tree().get_nodes_in_group("enemies"):
		#if not enemy.enemy_died.is_connected(show_enemy_death_message):
			#enemy.enemy_died.connect(show_enemy_death_message)
		#if not enemy.fireball_startup_progress.is_connected(update_enemy_fireball_startup):
			#enemy.fireball_startup_progress.connect(update_enemy_fireball_startup)
		#if not enemy.shield_startup_progress.is_connected(update_enemy_shield_startup):
			#enemy.shield_startup_progress.connect(update_enemy_shield_startup)
		#if not enemy.damage_dealt.is_connected(show_damage_notification):
			#enemy.damage_dealt.connect(show_damage_notification)

	print("UI System Ready")

	# Debug positioning
	death_label.position = Vector2(750, 300)

func _on_node_added(node):
	if node.is_in_group("enemies"):
		if not node.enemy_died.is_connected(show_enemy_death_message):
			node.enemy_died.connect(show_enemy_death_message)
		if not node.fireball_startup_progress.is_connected(update_enemy_fireball_startup):
			node.fireball_startup_progress.connect(update_enemy_fireball_startup)
		if not node.shield_startup_progress.is_connected(update_enemy_shield_startup):
			node.shield_startup_progress.connect(update_enemy_shield_startup)
		if not node.damage_dealt.is_connected(show_damage_notification):
			node.damage_dealt.connect(show_damage_notification)

# ------------------------
# Connected from Player
# ------------------------
func update_health(value: int):
	health_label.text = "HEALTH: %d" % value

@warning_ignore("shadowed_variable_base_class")
func update_fireball_status(ready: bool):
	# Only update if we're not in the middle of casting or cooldown
	if fireball_state != "casting" and fireball_state != "cooldown":
		fireball_state = "ready" if ready else "cooldown"
		fireball_label.text = "FIREBALL: %s" % ("READY" if ready else "COOLDOWN")

func update_fireball_startup(time_left: float):
	fireball_state = "casting"
	if time_left > 0:
		fireball_label.text = "FIREBALL: casting %.1fs" % time_left
	else:
		fireball_state = "ready"
		fireball_label.text = "FIREBALL: READY"

func update_fireball_cooldown(time_left: float):
	fireball_state = "cooldown"
	if time_left > 0:
		fireball_label.text = "FIREBALL: %ds" % int(time_left)
	else:
		fireball_state = "ready"
		fireball_label.text = "FIREBALL: READY"

@warning_ignore("shadowed_variable_base_class")
func update_shield_status(ready: bool):
	# Only update if we're not in the middle of casting or cooldown
	if shield_state != "casting" and shield_state != "cooldown":
		shield_state = "ready" if ready else "cooldown"
		shield_label.text = "SHIELD: %s" % ("READY" if ready else "COOLDOWN")

func update_shield_startup(time_left: float):
	shield_state = "casting"
	if time_left > 0:
		shield_label.text = "SHIELD: casting %.1fs" % time_left
	else:
		shield_state = "ready"
		shield_label.text = "SHIELD: READY"

func update_shield_cooldown(time_left: float):
	shield_state = "cooldown"
	if time_left > 0:
		shield_label.text = "SHIELD: %ds" % int(time_left)
	else:
		shield_state = "ready"
		shield_label.text = "SHIELD: READY"

#----------------------------
# connected to enemies group
#----------------------------
func show_enemy_death_message():
	death_label.visible = true
	death_label.text = "Enemy Died!"
	await get_tree().create_timer(2.5).timeout
	death_label.visible = false

func show_damage_notification(damage: int, target: String, blocked: int = 0):
	var _prefix = "You took " if target == "player" else "Enemy took "

	if blocked > 0:
		damage_label.text = "Damage: %d (-%d blocked)" % [damage + blocked, blocked]
		damage_label.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Orange
	else:
		damage_label.text = "Damage: %d" % damage
		damage_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red

	# Set random position between for damage to display
	damage_label.position = Vector2(randf_range(700, 900), 500)
	damage_label.visible = true
	await get_tree().create_timer(1.5).timeout
	damage_label.visible = false

#enemy casting
func update_enemy_shield_startup(time_left: float):
	enemy_casting_label.text = "Enemy casting Shield (%.1fs)" % time_left
	enemy_casting_label.visible = true

func update_enemy_fireball_startup(time_left: float):
	enemy_casting_label.text = "Enemy casting Fireball (%.1fs)" % time_left
	enemy_casting_label.visible = true

func show_death_message(): #for player deaths
	# Unpause the game first so the button can be clicked
	get_tree().paused = false
	
	death_label.visible = true
	restart_button.visible = true
	restart_button.disabled = false
	
	# Make sure button is clickable and has focus
	restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_button.grab_focus()
	
	print("Restart button visible: ", restart_button.visible)
	print("Restart button disabled: ", restart_button.disabled)
	print("Game paused: ", get_tree().paused)
	
	# Optional: Add fade-in effect
	var tween = create_tween()
	tween.tween_property(death_label, "modulate:a", 1.0, 1.0).from(0.0)

	# Don't pause the game here - keep it unpaused for UI interaction
	# get_tree().paused = true

#SPELLS FUNCTIONS
func show_enemy_casting(ability: String, time_left: float):
	enemy_casting_label.text = "Enemy casting %s (%.1fs)" % [ability, time_left]
	enemy_casting_label.visible = true
	enemy_casting_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red

func hide_enemy_casting():
	enemy_casting_label.visible = false

func show_player_casting(ability: String, time_left: float):
	casting_label.text = "Casting %s (%.1fs)" % [ability, time_left]
	casting_label.visible = true
	casting_label.add_theme_color_override("font_color", Color(0, 0, 1))  # Blue

func hide_player_casting():
	casting_label.visible = false

func show_ability_ready(ability: String, is_enemy: bool = false):
	var label = enemy_casting_label if is_enemy else casting_label
	label.text = "%s %s ready!" % [("Enemy" if is_enemy else "Player"), ability]
	label.visible = true
	await get_tree().create_timer(1.5).timeout
	label.visible = false

func update_target_label(enemy: Node3D):
	if enemy:
		target_label.text = "Target Locked: %s" % enemy.name
		target_label.visible = true
	else:
		target_label.visible = false

#GAME OVER - Fixed restart function
func _on_restart_button_pressed():
	print("=== RESTART BUTTON PRESSED ===")
	print("Game paused: ", get_tree().paused)
	
	# Immediately unpause the game
	get_tree().paused = false
	print("Game unpaused: ", get_tree().paused)
	
	# Add a small delay to ensure the button press is processed
	await get_tree().create_timer(0.2).timeout
	
	print("Reloading scene...")
	
	# Use a more reliable scene reload method
	var current_scene = get_tree().current_scene
	var scene_path = current_scene.scene_file_path
	
	if scene_path:
		print("Loading scene from path: ", scene_path)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("No scene path found, using reload_current_scene")
		get_tree().reload_current_scene()
