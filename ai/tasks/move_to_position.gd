@tool
extends BTAction
## Moves agent to a target position. Returns RUNNING while moving.
## Note: Checks will_chase for responsiveness since BTSelector doesn't re-evaluate during RUNNING.
##
## RESPONSIBILITY: Sets velocity and rotation only. NPC handles animation.

@export var position_var: StringName = &"wander_target"
@export var speed: float = 1.5
@export var arrival_distance: float = 0.5

func _generate_name() -> String:
	return "MoveToPosition (speed: %s)" % speed

func _enter() -> void:
	agent.velocity = Vector3.ZERO

func _tick(delta: float) -> Status:
	# Abort check for responsiveness - check if we should chase
	var emo = blackboard.get_var(&"emotional_state")
	if not emo:
		emo = agent.get("emotional_state")
	if emo and emo.will_chase:
		agent.velocity = Vector3.ZERO
		return FAILURE
	
	# Also abort if there's a sound to investigate
	var investigate_pos = blackboard.get_var(&"investigate_position", Vector3.INF)
	if investigate_pos != Vector3.INF:
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
		
		# Wait for path to be computed
		if nav.is_navigation_finished() and distance < arrival_distance * 2:
			agent.velocity = Vector3.ZERO
			return SUCCESS
		
		var next_pos = nav.get_next_path_position()
		var direction = (next_pos - agent.global_position).normalized()
		direction.y = 0
		
		if direction.length_squared() < 0.001:
			# No valid direction - path might not be ready yet
			agent.velocity = Vector3.ZERO
			return RUNNING
		
		# Rotate toward target
		var target_angle = atan2(direction.x, direction.z)
		var angle_diff = abs(wrapf(target_angle - agent.rotation.y, -PI, PI))
		agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, delta * 12.0)
		
		# Only move when mostly facing target (within 45 degrees)
		if angle_diff < deg_to_rad(45):
			agent.velocity = direction * speed
		else:
			agent.velocity = Vector3.ZERO  # Just rotate, don't move yet
	else:
		agent.velocity = Vector3.ZERO
		return SUCCESS
	
	return RUNNING

func _exit() -> void:
	agent.velocity = Vector3.ZERO
