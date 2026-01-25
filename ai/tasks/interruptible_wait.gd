@tool
extends BTAction
## Waits for a random duration. Aborts if will_chase becomes true.
## Note: Checks will_chase for responsiveness since BTSelector doesn't re-evaluate during RUNNING.

@export var min_duration: float = 2.0
@export var max_duration: float = 5.0

var _duration: float = 0.0
var _elapsed: float = 0.0

func _generate_name() -> String:
	return "InterruptibleWait (%.1f-%.1f sec)" % [min_duration, max_duration]

func _enter() -> void:
	_duration = randf_range(min_duration, max_duration)
	_elapsed = 0.0

func _tick(delta: float) -> Status:
	# Abort check for responsiveness (only if emotional_state exists in blackboard)
	if blackboard.has_var(&"emotional_state"):
		var emo = blackboard.get_var(&"emotional_state")
		if emo and emo.will_chase:
			return FAILURE
	
	_elapsed += delta
	if _elapsed >= _duration:
		return SUCCESS
	return RUNNING
