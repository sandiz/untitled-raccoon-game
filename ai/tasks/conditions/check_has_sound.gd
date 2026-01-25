extends BTCondition
## Guards P3: Investigate branch. Checks for pending sound AND is_calm.

func _check() -> bool:
	var has_sound = blackboard.get_var(&"has_sound_to_investigate", false)
	if not has_sound:
		return false
	
	var emo = blackboard.get_var(&"emotional_state")
	if emo and emo.will_chase:
		return false  # Don't investigate while wanting to chase
	
	return true
