@tool
extends BTAction

@export var position_var: StringName = &"wander_target"
@export var radius: float = 8.0
@export var min_distance: float = 3.0  # Minimum distance to ensure movement

func _generate_name() -> String:
	return "SelectRandomPosition (radius: %s)" % radius

func _tick(_delta: float) -> Status:
	# Always transition to idle state when starting wander (clears caught/frustrated/etc)
	if agent.has_method("set_current_state"):
		agent.set_current_state("idle")
	
	var home: Vector3 = blackboard.get_var(&"home_position", agent.global_position)
	var angle = randf() * TAU
	var random_pos = home + Vector3(cos(angle), 0, sin(angle)) * randf_range(min_distance, radius)
	blackboard.set_var(position_var, random_pos)
	return SUCCESS
