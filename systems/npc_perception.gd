class_name NPCPerception
extends RefCounted
## NPC Perception system - handles sight, hearing, and attention.
## Provides a forgiving perception model where NPCs need time to notice things.

# ═══════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════

signal target_spotted(target: Node3D, spot_type: String)  # "glimpse", "noticed", "confirmed"
signal target_lost(target: Node3D)
signal sound_heard(source_position: Vector3, sound_type: String, loudness: float)
signal attention_changed(new_focus: Node3D)

# ═══════════════════════════════════════
# CONFIGURATION - Forgiving values
# ═══════════════════════════════════════

## Vision cone angle (degrees) - matches visual indicator
@export var fov_angle: float = 90.0

## Maximum sight distance
@export var sight_range: float = 10.0

## How long it takes to fully notice something (seconds)
@export var notice_time: float = 0.8

## How long before losing track of hidden target
@export var memory_duration: float = 5.0

## Hearing range for normal sounds
@export var hearing_range: float = 10.0

## Hearing range for loud sounds (honk, crash)
@export var loud_hearing_range: float = 20.0

# ═══════════════════════════════════════
# STATE
# ═══════════════════════════════════════

## Currently tracked targets with awareness levels (0-1)
var tracked_targets: Dictionary = {}  # Node3D -> {awareness: float, last_position: Vector3, last_seen: float}

## Current attention focus
var attention_focus: Node3D = null

## Recent sounds heard
var recent_sounds: Array[Dictionary] = []  # [{position, type, loudness, time}]

## Owner NPC reference
var owner_npc: Node3D = null

## Physics space for raycasts
var _space_state: PhysicsDirectSpaceState3D = null

# ═══════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════

func setup(npc: Node3D) -> void:
	owner_npc = npc
	_space_state = npc.get_world_3d().direct_space_state

func update(delta: float) -> void:
	if not owner_npc or not _space_state:
		return
	
	_update_tracked_targets(delta)
	_decay_sounds(delta)
	_update_attention_focus()

# ═══════════════════════════════════════
# VISION CHECKS
# ═══════════════════════════════════════

## Check if a target is visible (call each frame for targets in range)
func check_target_visibility(target: Node3D) -> Dictionary:
	if not owner_npc or not target:
		return {visible = false, reason = "invalid"}
	
	# Eye level - slightly below full height to avoid clipping issues
	var npc_pos = owner_npc.global_position + Vector3(0, 1.2, 0)
	var target_pos = _get_target_center(target)
	var to_target = target_pos - npc_pos
	var distance = to_target.length()
	
	# Distance check - use main sight range only (UGG-style, no peripheral)
	if distance > sight_range:
		return {visible = false, reason = "too_far"}
	
	# Angle check - main FOV only (UGG-style, no peripheral)
	# Model faces +Z, so use +Z as forward
	var npc_forward = owner_npc.global_transform.basis.z
	var angle = rad_to_deg(npc_forward.angle_to(to_target.normalized()))
	
	var in_fov = angle <= fov_angle / 2.0
	
	if not in_fov:
		return {visible = false, reason = "outside_vision"}
	
	# Line of sight check (raycast) - only check against environment (layer 1)
	var query = PhysicsRayQueryParameters3D.create(npc_pos, target_pos)
	query.collision_mask = 1  # Only environment/terrain layer
	query.exclude = [owner_npc.get_rid()]
	
	# Also exclude the target
	if target is CollisionObject3D:
		query.exclude.append(target.get_rid())
	
	var result = _space_state.intersect_ray(query)
	if result:
		return {visible = false, reason = "blocked", blocked_by = result.collider}
	
	# Determine visibility quality (no peripheral - UGG-style)
	var visibility_type = "clear"
	if distance > sight_range * 0.7:
		visibility_type = "distant"
	
	return {
		visible = true,
		type = visibility_type,
		distance = distance,
		angle = angle
	}

## Process a target being visible (builds awareness over time)
func process_visible_target(target: Node3D, visibility: Dictionary, delta: float) -> void:
	if not visibility.visible:
		return
	
	var target_data = tracked_targets.get(target, {
		awareness = 0.0,
		last_position = target.global_position,
		last_seen = Time.get_unix_time_from_system()
	})
	
	# Awareness gain rate based on visibility quality
	var awareness_rate = 1.0 / notice_time  # Full awareness in notice_time seconds
	match visibility.type:
		"distant":
			awareness_rate *= 0.5  # Slower at distance
	
	# Motion detection boost (if target is moving fast)
	if target is CharacterBody3D and target.velocity.length() > 3.0:
		awareness_rate *= 1.5
	
	var old_awareness = target_data.awareness
	target_data.awareness = minf(target_data.awareness + awareness_rate * delta, 1.0)
	target_data.last_position = target.global_position
	target_data.last_seen = Time.get_unix_time_from_system()
	
	tracked_targets[target] = target_data
	
	# Emit signals at awareness thresholds
	if old_awareness < 0.3 and target_data.awareness >= 0.3:
		target_spotted.emit(target, "glimpse")
	elif old_awareness < 0.6 and target_data.awareness >= 0.6:
		target_spotted.emit(target, "noticed")
	elif old_awareness < 1.0 and target_data.awareness >= 1.0:
		target_spotted.emit(target, "confirmed")

# ═══════════════════════════════════════
# HEARING
# ═══════════════════════════════════════

## Register a sound heard by this NPC
func hear_sound(source_position: Vector3, sound_type: String, loudness: float = 1.0) -> void:
	if not owner_npc:
		return
	
	var distance = owner_npc.global_position.distance_to(source_position)
	var effective_range = loud_hearing_range if loudness > 0.7 else hearing_range
	
	if distance > effective_range:
		return  # Too far to hear
	
	# Distance attenuation
	var perceived_loudness = loudness * (1.0 - (distance / effective_range))
	
	# Store sound event
	recent_sounds.append({
		position = source_position,
		type = sound_type,
		loudness = perceived_loudness,
		time = Time.get_unix_time_from_system()
	})
	
	# Limit stored sounds
	while recent_sounds.size() > 10:
		recent_sounds.pop_front()
	
	sound_heard.emit(source_position, sound_type, perceived_loudness)

## Get the most interesting recent sound
func get_loudest_recent_sound(max_age: float = 3.0) -> Dictionary:
	var current_time = Time.get_unix_time_from_system()
	var loudest: Dictionary = {}
	var max_loudness = 0.0
	
	for sound in recent_sounds:
		if current_time - sound.time < max_age and sound.loudness > max_loudness:
			max_loudness = sound.loudness
			loudest = sound
	
	return loudest

# ═══════════════════════════════════════
# ATTENTION MANAGEMENT
# ═══════════════════════════════════════

## Set explicit attention focus
func focus_on(target: Node3D) -> void:
	if attention_focus != target:
		attention_focus = target
		attention_changed.emit(target)

## Clear attention focus
func clear_focus() -> void:
	if attention_focus != null:
		attention_focus = null
		attention_changed.emit(null)

## Get awareness level for a target (0-1)
func get_awareness(target: Node3D) -> float:
	if target in tracked_targets:
		return tracked_targets[target].awareness
	return 0.0

## Get last known position of a target
func get_last_known_position(target: Node3D) -> Vector3:
	if target in tracked_targets:
		return tracked_targets[target].last_position
	return Vector3.ZERO

## Check if NPC is aware of any threats
func has_any_awareness() -> bool:
	for target in tracked_targets:
		if tracked_targets[target].awareness > 0.3:
			return true
	return false

## Get the most aware-of target
func get_primary_target() -> Node3D:
	var highest_awareness = 0.0
	var primary: Node3D = null
	
	for target in tracked_targets:
		if tracked_targets[target].awareness > highest_awareness:
			highest_awareness = tracked_targets[target].awareness
			primary = target
	
	return primary

## Computed property: Can NPC currently see the target? (awareness >= 0.6 = "noticed")
var can_see_target: bool:
	get:
		var target = get_primary_target()
		if not target:
			return false
		return get_awareness(target) >= 0.6

## Computed property: Is the visible target holding a stolen item?
var target_is_holding_item: bool:
	get:
		var target = get_primary_target()
		if not target or not can_see_target:
			return false
		if target.has_method("is_holding_item"):
			return target.is_holding_item()
		return false

# ═══════════════════════════════════════
# DEBUG INFO
# ═══════════════════════════════════════

func get_debug_info() -> Dictionary:
	var targets_info: Array[Dictionary] = []
	for target in tracked_targets:
		var data = tracked_targets[target]
		targets_info.append({
			name = target.name if is_instance_valid(target) else "invalid",
			awareness = data.awareness,
			last_seen = Time.get_unix_time_from_system() - data.last_seen
		})
	
	return {
		fov_angle = fov_angle,
		sight_range = sight_range,
		tracked_count = tracked_targets.size(),
		tracked_targets = targets_info,
		attention_focus = String(attention_focus.name) if attention_focus else String("none"),
		recent_sounds = recent_sounds.size()
	}

# ═══════════════════════════════════════
# PRIVATE HELPERS
# ═══════════════════════════════════════

func _update_tracked_targets(delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	var targets_to_remove: Array[Node3D] = []
	
	for target in tracked_targets:
		if not is_instance_valid(target):
			targets_to_remove.append(target)
			continue
		
		var data = tracked_targets[target]
		var time_since_seen = current_time - data.last_seen
		
		# Decay awareness over time when not visible
		if time_since_seen > 0.5:  # Grace period
			var decay_rate = 1.0 / memory_duration
			data.awareness = maxf(data.awareness - decay_rate * delta, 0.0)
			tracked_targets[target] = data
			
			# Lost target if awareness drops to zero
			if data.awareness <= 0.0:
				targets_to_remove.append(target)
				target_lost.emit(target)
	
	for target in targets_to_remove:
		tracked_targets.erase(target)

func _decay_sounds(_delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	recent_sounds = recent_sounds.filter(func(s): return current_time - s.time < 5.0)

func _update_attention_focus() -> void:
	# Auto-update focus to highest awareness target if not manually set
	if attention_focus and not is_instance_valid(attention_focus):
		clear_focus()
	
	# Could add auto-focus logic here if desired

func _get_target_center(target: Node3D) -> Vector3:
	# Try to get center of target (account for character height)
	# Use a lower height to work with scaled characters like the raccoon
	if target is CharacterBody3D:
		# Check for a Visuals node with scale to determine actual height
		var visuals = target.get_node_or_null("Visuals")
		var scale_factor = 1.0
		if visuals:
			scale_factor = visuals.scale.y
		return target.global_position + Vector3(0, 0.5 * scale_factor, 0)
	return target.global_position
