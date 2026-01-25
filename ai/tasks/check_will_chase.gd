extends BTCondition
## Checks if NPC's emotional state says they should chase.

static var _call_count: int = 0

func _check() -> bool:
	_call_count += 1
	if _call_count <= 5 or _call_count % 60 == 0:
		print("[BT] check_will_chase called (", _call_count, ")")
	
	var emotional_state = blackboard.get_var(&"emotional_state")
	if not emotional_state:
		emotional_state = agent.get("emotional_state")
	if not emotional_state:
		return false
	
	return emotional_state.will_chase
