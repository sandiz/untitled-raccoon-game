@tool
extends BTAction
## Investigates a sound: turns to face the source and stares for a duration.
## Returns SUCCESS when done, FAILURE if no investigate_position set.

@export var duration: float = 2.0
@export var turn_speed: float = 12.0
@export var wait_for_target_time: float = 0.1  # Grace period to wait for blackboard

var _timer: float = 0.0
var _wait_timer: float = 0.0
var _target_pos: Vector3

func _generate_name() -> String:
	return "InvestigateSound (%.1fs)" % duration

func _enter() -> void:
	_timer = 0.0
	_wait_timer = 0.0
	_target_pos = Vector3.INF
	agent.velocity = Vector3.ZERO

func _tick(delta: float) -> Status:
	# Get fresh position each tick (might be set after _enter)
	var pos = blackboard.get_var(&"investigate_position", Vector3.INF)
	if pos != Vector3.INF:
		_target_pos = pos
	
	# No position to investigate - wait briefly for callback
	if _target_pos == Vector3.INF:
		_wait_timer += delta
		if _wait_timer >= wait_for_target_time:
			return FAILURE
		return RUNNING  # Wait for position to be set
	
	# Set state to investigating (only once we have a target)
	if agent.has_method("set_current_state") and agent.current_state != "investigating":
		agent.set_current_state("investigating")
	
	# Abort if we should chase
	var emo = blackboard.get_var(&"emotional_state")
	if not emo:
		emo = agent.get("emotional_state")
	if emo and emo.will_chase:
		return FAILURE
	
	# Face the sound source
	var direction = _target_pos - agent.global_position
	direction.y = 0
	if direction.length() > 0.1:
		var target_angle = atan2(direction.x, direction.z)
		agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, delta * turn_speed)
	
	# Stay still
	agent.velocity = Vector3.ZERO
	
	# Count down
	_timer += delta
	if _timer >= duration:
		# Clear investigate position when done (use INF as "no target")
		blackboard.set_var(&"investigate_position", Vector3.INF)
		return SUCCESS
	
	return RUNNING

func _exit() -> void:
	# Return to idle when done
	if agent.has_method("set_current_state"):
		agent.set_current_state("idle")
