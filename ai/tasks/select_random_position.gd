@tool
extends BTAction

@export var position_var: StringName = &"wander_target"
@export var radius: float = 8.0

func _generate_name() -> String:
	return "SelectRandomPosition (radius: %s)" % radius

func _tick(_delta: float) -> Status:
	var home: Vector3 = blackboard.get_var(&"home_position", agent.global_position)
	var angle = randf() * TAU
	var random_pos = home + Vector3(cos(angle), 0, sin(angle)) * randf_range(2, radius)
	blackboard.set_var(position_var, random_pos)
	return SUCCESS
