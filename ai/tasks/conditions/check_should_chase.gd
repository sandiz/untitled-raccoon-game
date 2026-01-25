extends BTCondition
## Guards P1: Chase branch. Checks will_chase AND NOT on cooldown.

func _check() -> bool:
	var emo = blackboard.get_var(&"emotional_state")
	if not emo:
		return false
	
	var on_cooldown = blackboard.get_var(&"chase_on_cooldown", false)
	return emo.will_chase and not on_cooldown
