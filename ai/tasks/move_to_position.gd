@tool
extends BTAction
## Moves agent to a target position. Returns RUNNING while moving.
## Note: Checks will_chase for responsiveness since BTSelector doesn't re-evaluate during RUNNING.

@export var position_var: StringName = &"wander_target"
@export var speed: float = 1.5
@export var arrival_distance: float = 0.5

func _generate_name() -> String:
	return "MoveToPosition (speed: %s)" % speed

func _enter() -> void:
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim:
		for anim_name in ["default/Walk", "default/Jog_Fwd"]:
			if anim.has_animation(anim_name):
				anim.play(anim_name)
				return

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
		return SUCCESS
	
	var nav: NavigationAgent3D = agent.get_node_or_null("NavigationAgent3D")
	if nav:
		nav.target_position = target_pos
		
		# Wait for path to be computed (don't check is_finished on first frame)
		if nav.is_navigation_finished() and distance < arrival_distance * 2:
			return SUCCESS
		
		var next_pos = nav.get_next_path_position()
		var direction = (next_pos - agent.global_position).normalized()
		direction.y = 0
		
		if direction.length_squared() < 0.001:
			# No valid direction - path might not be ready yet
			return RUNNING
		
		agent.velocity = direction * speed
		agent.move_and_slide()
		
		if direction.length_squared() > 0.001:
			var target_angle = atan2(direction.x, direction.z)
			agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, delta * 10.0)
	
	return RUNNING

func _exit() -> void:
	agent.velocity = Vector3.ZERO
