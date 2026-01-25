extends CharacterBody3D
## Player raccoon controller with third-person movement.

# ═══════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════

@export_group("Movement")
@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var acceleration: float = 10.0
@export var deceleration: float = 15.0
@export var rotation_speed: float = 10.0

@export_group("Jump")
@export var jump_velocity: float = 5.0
@export var gravity_multiplier: float = 1.5
@export var fall_multiplier: float = 2.0

@export_group("Actions")
@export var honk_cooldown: float = 0.5

# ═══════════════════════════════════════
# STATE
# ═══════════════════════════════════════

var is_running: bool = false
var is_stunned: bool = false
var stun_timer: float = 0.0
var last_honk_time: float = 0.0
var _honk_player: AudioStreamPlayer3D = null
var input_direction: Vector2 = Vector2.ZERO
var move_direction: Vector3 = Vector3.ZERO

# ═══════════════════════════════════════
# REFERENCES
# ═══════════════════════════════════════

@onready var animation_tree: AnimationTree = $Visuals/AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

# ═══════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════

signal honked(position: Vector3)

# ═══════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════

func _ready() -> void:
	add_to_group("player")
	_setup_honk_audio()
	
	# Ensure animation tree is active
	if animation_tree:
		animation_tree.active = true

func _physics_process(delta: float) -> void:
	# Handle stun timer
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			stun_timer = 0.0
	
	if not is_stunned:
		_handle_input()
	else:
		input_direction = Vector2.ZERO
		move_direction = Vector3.ZERO
	
	_apply_gravity(delta)
	_apply_movement(delta)
	_update_rotation(delta)
	_update_animation()
	move_and_slide()

# ═══════════════════════════════════════
# INPUT HANDLING
# ═══════════════════════════════════════

func _handle_input() -> void:
	# Movement input
	input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Run toggle (hold shift)
	is_running = Input.is_action_pressed("run")
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Honk (spacebar or dedicated button)
	if Input.is_action_just_pressed("honk"):
		_honk()

func _unhandled_input(event: InputEvent) -> void:
	# Fallback controls if actions not defined
	if event is InputEventKey:
		match event.keycode:
			KEY_SPACE:
				if event.pressed and is_on_floor():
					velocity.y = jump_velocity
			KEY_E, KEY_Q:
				if event.pressed:
					_honk()

# ═══════════════════════════════════════
# MOVEMENT
# ═══════════════════════════════════════

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
		
		# Apply stronger gravity when falling
		if velocity.y < 0:
			velocity.y -= gravity * fall_multiplier * delta
		else:
			velocity.y -= gravity * gravity_multiplier * delta

func _apply_movement(delta: float) -> void:
	# Get camera-relative direction
	var camera = get_viewport().get_camera_3d()
	if camera and input_direction.length() > 0.1:
		var cam_forward = -camera.global_transform.basis.z
		var cam_right = camera.global_transform.basis.x
		
		# Flatten to horizontal plane
		cam_forward.y = 0
		cam_right.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		
		# Calculate move direction
		move_direction = (cam_right * input_direction.x + cam_forward * -input_direction.y).normalized()
		
		# Apply speed
		var target_speed = run_speed if is_running else walk_speed
		var target_velocity = move_direction * target_speed
		
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		# Decelerate
		move_direction = Vector3.ZERO
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

func _update_rotation(delta: float) -> void:
	# Rotate to face movement direction
	if move_direction.length() > 0.1:
		var target_rotation = atan2(move_direction.x, move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

# ═══════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════

func _update_animation() -> void:
	if not state_machine:
		return
	
	var current = state_machine.get_current_node()
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	if not is_on_floor():
		# Airborne
		if velocity.y > 0:
			if current != "Jump":
				state_machine.travel("Jump")
		else:
			if current != "Fall" and current != "Land":
				state_machine.travel("Fall")
	else:
		# Grounded
		if current == "Fall":
			state_machine.travel("Land")
		elif current == "Land":
			pass  # Let it auto-advance to Idle
		elif horizontal_speed > 0.5:
			if is_running and horizontal_speed > walk_speed * 0.8:
				if current != "Run":
					state_machine.travel("Run")
			else:
				if current != "Walk":
					state_machine.travel("Walk")
		else:
			if current != "Idle" and current != "Land":
				state_machine.travel("Idle")

# ═══════════════════════════════════════
# ACTIONS
# ═══════════════════════════════════════

func _honk() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_honk_time < honk_cooldown:
		return
	
	last_honk_time = current_time
	
	# Play honk sound
	_play_honk_sound()
	
	# Emit signal for NPCs to hear
	honked.emit(global_position)
	
	# Broadcast to nearby NPCs via their perception
	_broadcast_honk()

func _broadcast_honk() -> void:
	# Find all NPCs and let them hear the honk
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.has_method("on_heard_honk"):
			npc.on_heard_honk(global_position)
		elif npc.get("perception"):
			npc.perception.hear_sound(global_position, "honk", 1.0)

# ═══════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════

func get_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

func is_moving() -> bool:
	return get_speed() > 0.5

func stun(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	velocity.x = 0
	velocity.z = 0

func apply_knockback(direction: Vector3, force: float = 5.0) -> void:
	var knockback = direction.normalized() * force
	knockback.y = 2.0  # Small upward pop
	velocity = knockback

func drop_held_item() -> void:
	# Placeholder for when item system is implemented
	pass

# ═══════════════════════════════════════
# HONK AUDIO (Procedural)
# ═══════════════════════════════════════

func _setup_honk_audio() -> void:
	_honk_player = AudioStreamPlayer3D.new()
	_honk_player.name = "HonkPlayer"
	_honk_player.max_distance = 20.0
	_honk_player.unit_size = 3.0
	_honk_player.volume_db = 6.0
	add_child(_honk_player)
	
	# Pre-generate the honk sound
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
		
		# Soft sine wave (no harsh harmonics)
		var sample = sin(t * freq * TAU) * 0.4
		
		# Gentle fade in and out
		var envelope = sin(progress * PI)  # Smooth bell curve
		envelope = pow(envelope, 0.7)  # Soften it more
		
		sample *= envelope * 0.6
		
		var sample_int = int(clamp(sample * 32000.0, -32768, 32767))
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	return stream

func _play_honk_sound() -> void:
	if _honk_player:
		_honk_player.pitch_scale = randf_range(0.85, 1.15)
		_honk_player.play()
