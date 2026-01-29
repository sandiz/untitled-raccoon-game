@tool
extends BTAction
## Selects a random position near home for wandering.
##
## RESPONSIBILITY: Picks position only. Does not change state or animation.

@export var position_var: StringName = &"wander_target"
@export var radius: float = 8.0
@export var min_distance: float = 3.0  # Minimum distance to ensure movement

func _generate_name() -> String:
	return "SelectRandomPosition (radius: %s)" % radius

func _tick(_delta: float) -> Status:
	# Abort check for responsiveness - check if we should chase
	var emo = blackboard.get_var(&"emotional_state")
	if not emo:
		emo = agent.get("emotional_state")
	if emo and emo.will_chase:
		return FAILURE
	
	# Reset to idle state when starting a new wander cycle
	# This clears temporary states like "suspicious", "alert", "caught", "frustrated"
	if agent.has_method("set_current_state"):
		var current = agent.get("current_state")
		if current not in ["idle", "chasing"]:
			agent.set_current_state("idle")
	
	var home: Vector3 = blackboard.get_var(&"home_position", agent.global_position)
	var angle = randf() * TAU
	var random_pos = home + Vector3(cos(angle), 0, sin(angle)) * randf_range(min_distance, radius)
	blackboard.set_var(position_var, random_pos)
	return SUCCESS
