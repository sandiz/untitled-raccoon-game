@tool
extends BTAction
## Moves agent to a target position. Returns RUNNING while moving.
## Note: Checks will_chase for responsiveness since BTSelector doesn't re-evaluate during RUNNING.

@export var position_var: StringName = &"wander_target"
@export var speed: float = 1.5
@export var arrival_distance: float = 0.5

var _walk_anim_playing: bool = false

func _generate_name() -> String:
	return "MoveToPosition (speed: %s)" % speed

func _enter() -> void:
	_walk_anim_playing = false
	# Don't start walk animation yet - wait for valid direction

func _tick(delta: float) -> Status:
	# Abort check for responsiveness (only if emotional_state exists in blackboard)
	if blackboard.has_var(&"emotional_state"):
		var emo = blackboard.get_var(&"emotional_state")
		if emo and emo.will_chase:
			agent.velocity = Vector3.ZERO
			return FAILURE
	
	var target_pos: Vector3 = blackboard.get_var(position_var, agent.global_position)
	var distance = agent.global_position.distance_to(target_pos)
	
	if distance < arrival_distance:
		agent.velocity = Vector3.ZERO
		agent.move_and_slide()
		return SUCCESS
	
	var nav: NavigationAgent3D = agent.get_node_or_null("NavigationAgent3D")
	if nav:
		nav.target_position = target_pos
		
		# Wait for path to be computed (don't check is_finished on first frame)
		if nav.is_navigation_finished() and distance < arrival_distance * 2:
			agent.velocity = Vector3.ZERO
			agent.move_and_slide()
			return SUCCESS
		
		var next_pos = nav.get_next_path_position()
		var direction = (next_pos - agent.global_position).normalized()
		direction.y = 0
		
		if direction.length_squared() < 0.001:
			# No valid direction - path might not be ready yet, stay idle
			agent.velocity = Vector3.ZERO
			agent.move_and_slide()
			return RUNNING
		
		# Now we have a valid direction - start walk animation if not already
		if not _walk_anim_playing:
			_walk_anim_playing = true
			var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
			if anim:
				for anim_name in ["default/Walk", "default/Jog_Fwd"]:
					if anim.has_animation(anim_name):
						anim.play(anim_name)
						break
		
		# Rotate toward target FIRST, then move
		var target_angle = atan2(direction.x, direction.z)
		var angle_diff = abs(wrapf(target_angle - agent.rotation.y, -PI, PI))
		
		# Rotate faster, only move when mostly facing target
		agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, delta * 12.0)
		
		if angle_diff < deg_to_rad(45):  # Only move when within 45 degrees of target
			agent.velocity = direction * speed
		else:
			agent.velocity = Vector3.ZERO  # Just rotate, don't move yet
		
		agent.move_and_slide()
	else:
		# No nav agent - just stop
		agent.velocity = Vector3.ZERO
		agent.move_and_slide()
		return SUCCESS
	
	return RUNNING

func _exit() -> void:
	agent.velocity = Vector3.ZERO
	agent.move_and_slide()
	_walk_anim_playing = false
