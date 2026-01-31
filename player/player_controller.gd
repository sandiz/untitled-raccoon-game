extends CharacterBody3D
## Raccoon - player's avatar. Can pick up items to steal and HONK!

signal possessed_npc(npc: Node3D)
signal released_npc(npc: Node3D)
signal item_picked_up(item: Node3D)
signal item_dropped(item: Node3D)
signal honked(position: Vector3)

var _current_possessed: Node3D = null
var _selection_ring: SelectionRing = null

## Pickup system
var held_item: Node3D = null  # StealableItem currently held
var nearby_items: Array = []  # Items in pickup range
@export var pickup_range: float = 1.5

## Honk system
@export var honk_cooldown: float = 0.5
var _last_honk_time: float = 0.0
var _honk_player: AudioStreamPlayer3D = null

## Debug: enable WASD movement for testing (disabled - use right-click to move)
@export var debug_movement: bool = false
@export var debug_speed: float = 5.0

## Click-to-move system
var _nav_agent: NavigationAgent3D = null
var _click_indicator: ClickIndicator = null
var _is_moving: bool = false
@export var move_speed: float = 4.0
@export var model_rotation_offset: float = 0.3  # Compensate for baked model rotation (~17 degrees)

## Debug item for testing theft detection
var _debug_item: Node3D = null

## Pickup prompt
var _pickup_prompt: Label3D = null


func _ready() -> void:
	add_to_group("player")
	_setup_selection_ring()
	_setup_pickup_area()
	_setup_pickup_prompt()
	_setup_honk_audio()
	_setup_click_to_move()
	
	# Connect to NPC selection to show ring when no NPC selected
	call_deferred("_connect_to_data_store")


func _setup_selection_ring() -> void:
	# Use SelectionRing class directly like shopkeeper does
	_selection_ring = SelectionRing.new()
	add_child(_selection_ring)
	# Configure after add_child (after _ready sets up mesh)
	_selection_ring.set_color(Color(0.6, 0.2, 0.5, 0.85))  # Magenta/purple - complementary to green
	# Always show ring for player avatar
	_selection_ring.show_ring()


func _setup_pickup_area() -> void:
	var pickup_area = Area3D.new()
	pickup_area.name = "PickupArea"
	
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = pickup_range
	shape.shape = sphere
	pickup_area.add_child(shape)
	
	# Only detect stealable items (layer 4)
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = 8  # Layer 4
	
	pickup_area.area_entered.connect(_on_item_nearby)
	pickup_area.area_exited.connect(_on_item_left)
	add_child(pickup_area)


func _setup_pickup_prompt() -> void:
	_pickup_prompt = Label3D.new()
	_pickup_prompt.text = "[E] Pick up"
	_pickup_prompt.font_size = 48
	_pickup_prompt.modulate = Color(1, 1, 1, 0.9)
	_pickup_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_pickup_prompt.no_depth_test = true
	_pickup_prompt.visible = false
	add_child(_pickup_prompt)


func _connect_to_data_store() -> void:
	var data_store = NPCDataStore.get_instance()
	if data_store:
		data_store.selection_changed.connect(_on_selection_changed)
	# Player ring is always visible - don't depend on selection


func _on_selection_changed(_selected_ids: Array) -> void:
	# Player ring stays visible regardless of NPC selection
	pass


func _show_ring() -> void:
	if _selection_ring and _selection_ring.has_method("show_ring"):
		_selection_ring.show_ring()


func _hide_ring() -> void:
	if _selection_ring and _selection_ring.has_method("hide_ring"):
		_selection_ring.hide_ring()


func is_possessing() -> bool:
	return _current_possessed != null


func get_possessed() -> Node3D:
	return _current_possessed


func possess(npc: Node3D) -> void:
	if _current_possessed:
		release()
	_current_possessed = npc
	possessed_npc.emit(npc)


func release() -> void:
	if _current_possessed:
		var old = _current_possessed
		_current_possessed = null
		released_npc.emit(old)


# ═══════════════════════════════════════
# PICKUP SYSTEM
# ═══════════════════════════════════════

func is_holding_item() -> bool:
	return held_item != null


func get_held_item() -> Node3D:
	return held_item


func try_pickup() -> void:
	if held_item:
		return  # Already holding something
	
	# Find closest valid item
	var closest: Node3D = null
	var closest_dist: float = INF
	
	for item in nearby_items:
		if not is_instance_valid(item):
			continue
		if item.is_held:
			continue
		var dist = global_position.distance_to(item.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = item
	
	if closest and closest.has_method("pickup"):
		held_item = closest
		closest.pickup(self)
		item_picked_up.emit(held_item)
		_update_pickup_prompt()


func drop_item() -> void:
	if not held_item:
		return
	
	var drop_pos = global_position + (-global_transform.basis.z * 0.5)
	if held_item.has_method("drop"):
		held_item.drop(drop_pos)
	
	item_dropped.emit(held_item)
	held_item = null
	_update_pickup_prompt()


func _on_item_nearby(area: Area3D) -> void:
	if area.is_in_group("stealable_items"):
		nearby_items.append(area)
		_update_pickup_prompt()


func _on_item_left(area: Area3D) -> void:
	nearby_items.erase(area)
	_update_pickup_prompt()


func _update_pickup_prompt() -> void:
	if not _pickup_prompt:
		return
	
	if held_item:
		_pickup_prompt.text = "[E] Drop"
		_pickup_prompt.position = Vector3(0, 1.2, 0)
		_pickup_prompt.visible = true
	elif not nearby_items.is_empty():
		# Find closest item for prompt position
		var closest = _get_closest_item()
		if closest:
			_pickup_prompt.text = "[E] Pick up"
			_pickup_prompt.global_position = closest.global_position + Vector3(0, 0.5, 0)
			_pickup_prompt.visible = true
		else:
			_pickup_prompt.visible = false
	else:
		_pickup_prompt.visible = false


func _get_closest_item() -> Node3D:
	var closest: Node3D = null
	var closest_dist: float = INF
	for item in nearby_items:
		if not is_instance_valid(item) or item.is_held:
			continue
		var dist = global_position.distance_to(item.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = item
	return closest


# ═══════════════════════════════════════
# INPUT & PHYSICS
# ═══════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if held_item:
			drop_item()
		else:
			try_pickup()
	
	# H key to honk (alerts nearby NPCs)
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		_honk()
	
	# Debug: T key toggles a fake item for testing theft detection
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		_toggle_debug_item()
	
	# Right-click to move
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_click_to_move(event.position)


func _physics_process(delta: float) -> void:
	# Debug WASD movement (disabled by default)
	if debug_movement:
		_handle_debug_movement(delta)
	else:
		# Click-to-move navigation
		_handle_nav_movement(delta)


func _handle_debug_movement(delta: float) -> void:
	# Simple WASD movement for testing
	var input_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.z -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		velocity.x = input_dir.x * debug_speed
		velocity.z = input_dir.z * debug_speed
		
		# Face movement direction
		var target_angle = atan2(-input_dir.x, -input_dir.z) + model_rotation_offset
		rotation.y = lerp_angle(rotation.y, target_angle, 0.15)
	else:
		velocity.x = 0
		velocity.z = 0
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()


func _handle_nav_movement(delta: float) -> void:
	if not _nav_agent or not _is_moving:
		# Apply gravity even when not moving
		if not is_on_floor():
			velocity.y -= 9.8 * delta
			move_and_slide()
		return
	
	if _nav_agent.is_navigation_finished():
		_is_moving = false
		velocity.x = 0
		velocity.z = 0
		# Hide indicator when raccoon arrives
		if _click_indicator:
			_click_indicator.hide_indicator()
		return
	
	var next_pos = _nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	direction.y = 0  # Keep movement horizontal
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Face movement direction
	if direction.length() > 0.01:
		var target_angle = atan2(-direction.x, -direction.z) + model_rotation_offset
		rotation.y = lerp_angle(rotation.y, target_angle, 0.15)
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()


# ═══════════════════════════════════════
# CLICK-TO-MOVE SYSTEM
# ═══════════════════════════════════════

func _setup_click_to_move() -> void:
	# Get reference to NavigationAgent3D (should be in scene)
	_nav_agent = get_node_or_null("NavigationAgent3D")
	if not _nav_agent:
		push_warning("Player: NavigationAgent3D not found, click-to-move disabled")
		return
	
	# Create click indicator (animated shrinking ring)
	_click_indicator = ClickIndicator.new()
	_click_indicator.name = "ClickIndicator"
	# Add to scene root so it stays at click position (deferred to avoid busy parent)
	get_tree().current_scene.add_child.call_deferred(_click_indicator)


func _handle_click_to_move(screen_pos: Vector2) -> void:
	if not _nav_agent:
		return
	
	# Raycast from camera to find ground position
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var to = from + dir * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # Only hit environment/ground
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return
	
	var target_pos = result.position
	
	# Set navigation target
	_nav_agent.target_position = target_pos
	_is_moving = true
	
	# Show animated indicator at target
	if _click_indicator and _click_indicator.is_inside_tree():
		_click_indicator.show_at(target_pos)


# ═══════════════════════════════════════
# DEBUG COMMANDS
# ═══════════════════════════════════════

## Toggle a debug item in hand for testing theft detection
## Press T to add/remove a fake stolen item
func _toggle_debug_item() -> void:
	if held_item:
		# Remove debug item
		if _debug_item and is_instance_valid(_debug_item):
			_debug_item.queue_free()
			_debug_item = null
		held_item = null
		item_dropped.emit(null)
		print("[DEBUG] Removed item from hand - is_holding_item() = ", is_holding_item())
	else:
		# Create a simple debug item (red cube)
		_debug_item = Node3D.new()
		_debug_item.name = "DebugStolenItem"
		
		var mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.3, 0.3, 0.3)
		mesh_instance.mesh = box
		
		# Red material to make it obvious
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.2, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.5, 0.1, 0.1)
		mesh_instance.material_override = material
		
		_debug_item.add_child(mesh_instance)
		add_child(_debug_item)
		
		# Position in front of raccoon (like holding it)
		_debug_item.position = Vector3(0, 0.5, -0.4)
		
		# Set as held item
		held_item = _debug_item
		item_picked_up.emit(held_item)
		print("[DEBUG] Added debug item to hand - is_holding_item() = ", is_holding_item())


# ═══════════════════════════════════════
# HONK SYSTEM
# ═══════════════════════════════════════

func _honk() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_honk_time < honk_cooldown:
		return
	
	_last_honk_time = current_time
	
	# Play honk sound
	if _honk_player:
		_honk_player.pitch_scale = randf_range(0.85, 1.15)
		_honk_player.play()
	
	# Emit signal
	honked.emit(global_position)
	
	# Broadcast to nearby NPCs
	_broadcast_honk()


func _broadcast_honk() -> void:
	for npc in get_tree().get_nodes_in_group("npc"):
		# Check hearing range (default 10m, or use NPC's perception range)
		var hearing_range = 10.0
		if npc.get("perception") and npc.perception.get("hearing_range"):
			hearing_range = npc.perception.hearing_range
		
		var distance = global_position.distance_to(npc.global_position)
		if distance > hearing_range:
			continue  # Too far to hear
		
		if npc.has_method("on_heard_honk"):
			npc.on_heard_honk(global_position)
		elif npc.get("perception"):
			npc.perception.hear_sound(global_position, "honk", 1.0)


func _setup_honk_audio() -> void:
	_honk_player = AudioStreamPlayer3D.new()
	_honk_player.name = "HonkPlayer"
	_honk_player.max_distance = 20.0
	_honk_player.unit_size = 3.0
	_honk_player.volume_db = 6.0
	add_child(_honk_player)
	
	_honk_player.stream = _generate_honk_stream()


func _generate_honk_stream() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.25
	var num_samples = int(sample_rate * duration)
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Soft trill: gentle wobble between two close frequencies
		var base_freq = 400.0
		var trill_speed = 25.0
		var trill_depth = 80.0
		var freq = base_freq + sin(t * trill_speed * TAU) * trill_depth
		
		# Soft sine wave
		var sample = sin(t * freq * TAU) * 0.4
		
		# Gentle fade in and out
		var envelope = sin(progress * PI)
		envelope = pow(envelope, 0.7)
		
		sample *= envelope
		
		var sample_int = int(clamp(sample * 32767, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	return stream
