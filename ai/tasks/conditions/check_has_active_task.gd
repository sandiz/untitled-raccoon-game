extends BTCondition
## Guards P4: Continue Task branch.

func _check() -> bool:
	return blackboard.get_var(&"has_active_task", false)
