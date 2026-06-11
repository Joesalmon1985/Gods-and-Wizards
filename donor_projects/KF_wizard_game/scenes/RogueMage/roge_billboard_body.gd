extends StaticBody3D
class_name rogue_billboard_body

signal health_changed(new_health)
signal enemy_clicked(enemy: StaticBody3D)
signal enemy_died
signal enemy_attacked(damage: int)
signal fireball_startup_progress(time_left: float)
signal shield_startup_progress(time_left: float)
signal damage_blocked(blocked_amount: int)
signal damage_dealt(amount: int, target: String, blocked: int)  # Fixed: Added blocked parameter

@export var max_health := 100
var health := max_health
var is_casting := false
var current_cast_type := ""  # "fireball" or "shield"
var is_facing_player := false

@export var fireball_damage := 50
@export var fireball_startup := 3.0
@export var fireball_cooldown := 2.5
@export var fireball_mesh_scene: PackedScene
var fireball_instance: MeshInstance3D = null
var fireball_speed := 5.0
var can_fireball := true
var fireball_has_hit := false  # Add this with your other fireball variables

@export var shield_block := 40
@export var shield_startup := 1
@export var shield_cooldown := 4.0
@export var shield_mesh_scene: PackedScene
var shield_instance: MeshInstance3D = null
var can_shield := true
var shield_active := false

@onready var ui = get_node("/root/Main/CanvasLayer")
@onready var player = get_node("/root/Main/Player")
@onready var mesh: MeshInstance3D = $enemy
var default_material: StandardMaterial3D
var highlight_material: StandardMaterial3D
var shield_material: StandardMaterial3D

var last_position = Vector3.ZERO

func _ready():
	collision_layer = 0b0010
	collision_mask = 0
	
		# Make sure the enemy is not affected by physics
	# StaticBody3D should already be static, but let's double-check
	set_physics_process(false)
	set_process(false)
	
	# Disable any potential physics interactions
	collision_priority = 1.0
	
	# Initialize materials
	default_material = StandardMaterial3D.new()
	default_material.albedo_color = Color(1, 1, 1)  # White
	
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(2, 1, 1)  # Bright white
	
	shield_material = StandardMaterial3D.new()
	shield_material.albedo_color = Color(0.2, 0.2, 1.0)  # Blue

	if has_node("AITimer"):
		$AITimer.start(randf_range(1.0, 3.0))
	else:
		push_error("AITimer node is missing!")

# Detect mouse clicks on enemy
func _input_event(_camera, event, _click_position, _click_normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("enemy_clicked", self)
		print("enemy targeted")

func set_targeted(is_targeted: bool) -> void:
	if mesh and mesh.get_active_material(0) is StandardMaterial3D:
		var mat := mesh.get_active_material(0)
		mat.albedo_color = highlight_material.albedo_color if is_targeted else default_material.albedo_color

func face_player():
	if not player or not mesh:
		return
	
	# Calculate direction to player (ignore Y axis)
	var direction = Vector3(player.global_position.x - global_position.x, 0, player.global_position.z - global_position.z).normalized()
	
	if direction.length() > 0:
		# Calculate target angle and smoothly rotate mesh
		var target_angle = atan2(direction.x, direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_angle, 0.1)

# Update the _process function to always face player
func _process(_delta):
	if player and is_facing_player:
		face_player()

	if global_position != last_position:
		print("Enemy moved from ", last_position, " to ", global_position)
		last_position = global_position

func take_damage(amount: int) -> void:
	var blocked = 0
	var _damage_taken = amount

	if shield_active:
		blocked = min(shield_block, amount)
		amount = max(0, amount - shield_block)
		shield_active = false
		emit_signal("damage_blocked", blocked)
		print("Enemy blocked ", blocked, " damage with shield!")
		
		# Remove shield visual when it blocks damage
		if shield_instance:
			shield_instance.queue_free()
			shield_instance = null

	health = clamp(health - amount, 0, max_health)
	emit_signal("health_changed", health)
	emit_signal("damage_dealt", amount, "enemy", blocked)
	print("Enemy took ", amount, " damage | Health: ", health)

	if health <= 0:
		# Cancel any ongoing spells
		cancel_all_spells()
		
		# Clean up shield visual
		if shield_instance:
			shield_instance.queue_free()
			shield_instance = null
			
		# Clean up fireball visual
		if fireball_instance:
			fireball_instance.queue_free()
			fireball_instance = null
			
		print("enemy died!")
		emit_signal("enemy_died")
		await get_tree().process_frame
		queue_free()

# Add these functions to enemy.gd as well:
func cancel_all_spells():
	# Cancel fireball if casting
	if is_casting and current_cast_type == "fireball":
		cancel_fireball()
	
	# Cancel shield if casting or active
	if is_casting and current_cast_type == "shield":
		cancel_shield()
	elif shield_active:
		deactivate_shield()

func cast_fireball():
	if not can_fireball or not player or is_casting:
		return
		
	is_casting = true
	current_cast_type = "fireball"
	
	# Make sure enemy is facing player before casting
	if player:
		face_player()
		await get_tree().create_timer(0.2).timeout  # Brief pause to complete rotation
		
	ui.show_enemy_casting("Fireball", fireball_startup)
	can_fireball = false
	print("Enemy charging fireball...")
	
	# Startup phase with countdown
	var startup_time = fireball_startup
	while startup_time > 0:
		emit_signal("fireball_startup_progress", startup_time)
		ui.show_enemy_casting("Fireball", startup_time)
		await get_tree().create_timer(0.1).timeout
		startup_time = max(0, startup_time - 0.1)

	ui.hide_enemy_casting()

	# Create and launch fireball effect
	create_fireball_effect()
	
	# Reset casting state
	is_casting = false
	current_cast_type = ""

	# Cooldown countdown (no UI updates for enemy)
	var t = fireball_cooldown
	while t > 0:
		await get_tree().create_timer(1.0).timeout
		t -= 1

	can_fireball = true
	print("Enemy fireball ready")

func create_fireball_effect():
	# Remove any existing fireball
	if fireball_instance:
		fireball_instance.queue_free()
		fireball_instance = null
	
	# Get the fireball mesh from the main node
	var fireball_template = get_node("/root/Main/Fireball")
	if fireball_template and player:
		fireball_instance = fireball_template.duplicate()
		add_child(fireball_instance)
		
		# Make sure it's visible
		fireball_instance.visible = true
		
		# Position the fireball at eye level (approximate player eye height)
		var eye_height = 1.7  # Approximate eye height from ground
		fireball_instance.global_position = global_position + Vector3(0, eye_height, 0)
		
		# Make the fireball face the player initially
		var direction_to_player = (player.global_position - fireball_instance.global_position).normalized()
		if direction_to_player.length() > 0:
			fireball_instance.look_at(fireball_instance.global_position + direction_to_player, Vector3.UP)
		
		print("Enemy fireball visual created")
		
		# Start moving the fireball toward the player
		move_fireball_toward_player()
	else:
		print("ERROR: Fireball template or player not found")

func move_fireball_toward_player():
	if not fireball_instance or not player:
		return
	
	var max_travel_time = 8.0
	var elapsed = 0.0
	fireball_has_hit = false  # Reset hit flag
	
	while elapsed < max_travel_time and fireball_instance and is_instance_valid(fireball_instance) and player and is_instance_valid(player):
		# Get current player position (updated each frame)
		var target_position = player.global_position + Vector3(0, 1.0, 0)
		
		# Calculate direction to current player position
		var direction = (target_position - fireball_instance.global_position).normalized()
		
		# Move toward current player position
		fireball_instance.global_position += direction * fireball_speed * get_process_delta_time()
		
		# Make fireball face the direction it's moving
		if direction.length() > 0:
			fireball_instance.look_at(fireball_instance.global_position + direction, Vector3.UP)
		
		# Add some rotation for visual effect
		fireball_instance.rotate_y(deg_to_rad(5))
		
		# Check if hit player
		var distance_to_player = fireball_instance.global_position.distance_to(target_position)
		if distance_to_player < 2.0 and not fireball_has_hit:  # Add hit check
			print("Enemy fireball hit player!")
			fireball_has_hit = true  # Mark as hit
			
			# Apply damage here
			if player.has_method("take_damage"):
				player.take_damage(fireball_damage)
				emit_signal("enemy_attacked", fireball_damage)
			break
		
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	
	# Remove fireball after hitting player or timing out
	if fireball_instance and is_instance_valid(fireball_instance):
		fireball_instance.queue_free()
		fireball_instance = null

func cancel_fireball():
	print("Enemy canceling fireball cast")
	is_casting = false
	current_cast_type = ""
	can_fireball = true
	
	# Remove fireball visual
	if fireball_instance:
		fireball_instance.queue_free()
		fireball_instance = null
	
	# Hide casting UI
	if ui:
		ui.hide_enemy_casting()

func _on_fireball_cooldown_timeout():
	can_fireball = true

func activate_shield():
	if not can_shield or is_casting:  # Add is_casting check
		return
		
	is_casting = true  # Set casting state
	current_cast_type = "shield"
		
	face_player()
		
	# Show casting message without await
	ui.show_enemy_casting("Shield", shield_startup)
	can_shield = false
	print("Enemy raising shield...")
	
	# Startup phase
	var startup_time = shield_startup
	while startup_time > 0:
		emit_signal("shield_startup_progress", startup_time)
		ui.show_enemy_casting("Shield", startup_time)
		await get_tree().create_timer(0.1).timeout
		startup_time = max(0, startup_time - 0.1)
	
	# Hide casting message when done
	ui.hide_enemy_casting()
	
	# Reset casting state
	is_casting = false
	current_cast_type = ""
	
	# Activate shield and create visual effect
	shield_active = true
	create_shield_effect()
	
	# Shield stays active for duration
	$ShieldTimer.start(2.0)
	await $ShieldTimer.timeout
	
	# Deactivate shield and remove visual
	shield_active = false
	if shield_instance:
		shield_instance.queue_free()
		shield_instance = null
	
	# Cooldown countdown (no UI updates for enemy)
	var t = shield_cooldown
	while t > 0:
		# Don't emit cooldown signals for enemy (hidden from UI)
		await get_tree().create_timer(1.0).timeout
		t -= 1
	
	can_shield = true
	print("Enemy shield ready")

func create_shield_effect():
	print("=== CREATING ENEMY SHIELD DEBUG ===")
	
	# Safety check
	if not is_instance_valid(self) or not is_inside_tree():
		print("Cannot create shield - enemy not valid")
		return
	
	# Remove any existing shield
	if shield_instance and is_instance_valid(shield_instance):
		shield_instance.queue_free()
		shield_instance = null
	
	# Get the shield mesh from the main node
	var shield_template = get_node("/root/Main/Shield")
	
	if shield_template and is_instance_valid(shield_template):
		print("Shield template found")
		
		# Duplicate the shield
		shield_instance = shield_template.duplicate()
		
		# Add to scene with safety check
		if is_instance_valid(shield_instance):
			add_child(shield_instance)
			
			# Make sure it's visible and make it 10x taller
			shield_instance.visible = true
			shield_instance.scale = Vector3(10.0, 40.0, 2.0)  # 10x taller on Y axis
			
			# Position the shield in front of the enemy
			shield_instance.position = Vector3(0, 5.0, -1.5)  # Higher position to match increased height
			
			# Make shield face the same direction as enemy
			shield_instance.rotation = rotation
			
			print("Enemy shield created successfully")
			print("Shield position: ", shield_instance.position)
			print("Shield scale: ", shield_instance.scale)
			print("Shield visible: ", shield_instance.visible)
		else:
			print("Failed to create shield instance")
	else:
		print("ERROR: Shield template not found or invalid!")
	
	print("=== ENEMY SHIELD DEBUG COMPLETE ===")

func _on_shield_cooldown_timeout() -> void:
	pass # Replace with function body.

func _on_shield_timer_timeout():
	shield_active = false
	# Remove shield visual
	if shield_instance:
		shield_instance.queue_free()
		shield_instance = null

func cancel_shield():
	print("Enemy canceling shield cast")
	is_casting = false
	current_cast_type = ""
	can_shield = true
	
	# Hide casting UI
	if ui:
		ui.hide_enemy_casting()

func deactivate_shield():
	print("Enemy deactivating shield")
	shield_active = false
	
	# Remove shield visual
	if shield_instance:
		shield_instance.queue_free()
		shield_instance = null
	
	can_shield = true

func _on_ai_timer_timeout():
	# Don't make decisions if currently casting
	if is_casting:
		$AITimer.start(randf_range(1.0, 2.0))
		return
	
	# Enable facing player during decision making
	is_facing_player = true
	
	# Simple decision making
	var decision = randi() % 3  # 0-2 random number
	match decision:
		0: 
			if can_fireball:
				cast_fireball()
		1: 
			if can_shield:
				activate_shield()
	
	# Disable facing after decision
	is_facing_player = false
	
	$AITimer.start(randf_range(1.0, 3.0))
