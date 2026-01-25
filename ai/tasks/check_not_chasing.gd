extends BTCondition
## Returns SUCCESS if NPC should NOT chase (allows wander to continue).
## Returns FAILURE if NPC should chase (aborts wander, lets chase take over).

func _check() -> bool:
	var emotional_state = blackboard.get_var(&"emotional_state")
	if not emotional_state:
		emotional_state = agent.get("emotional_state")
	if not emotional_state:
		return true  # No state, keep wandering
	# Return true (success) if NOT chasing, false (failure) if should chase
	return not emotional_state.will_chase
