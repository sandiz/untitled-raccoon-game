extends BTAction
## NPC gives up chase, plays frustrated animation, sets cooldown.

const FRUSTRATION_DURATION: float = 2.0

var _timer: float = 0.0
var _started: bool = false

func _enter() -> void:
	_timer = 0.0
	_started = false

func _tick(delta: float) -> Status:
	if not _started:
		_started = true
		_start_give_up()
	
	_timer += delta
	if _timer >= FRUSTRATION_DURATION:
		_finish_give_up()
		return SUCCESS
	
	return RUNNING

func _start_give_up() -> void:
	_set_state("frustrated")
	agent.velocity = Vector3.ZERO
	
	# Play frustrated/tired animation
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim:
		if anim.has_animation("default/Idle_Tired_Loop"):
			anim.play("default/Idle_Tired_Loop")
		elif anim.has_animation("default/Idle_Loop"):
			anim.play("default/Idle_Loop")
	
	# Emotional feedback
	var emo = blackboard.get_var(&"emotional_state")
	if emo and emo.has_method("add_event"):
		emo.add_event("chase_failed")

func _finish_give_up() -> void:
	# Set cooldown
	blackboard.set_var(&"chase_on_cooldown", true)
	blackboard.set_var(&"chase_cooldown_timer", 3.0)
	
	# Clear chase/search state
	blackboard.set_var(&"last_known_position", Vector3.ZERO)
	blackboard.set_var(&"search_time", 0.0)
	
	# Reset emotional state partially - recover some stamina
	var emo = blackboard.get_var(&"emotional_state")
	if emo:
		emo.stamina = minf(emo.stamina + 20.0, 100.0)  # Recover 20 stamina
		emo.on_chase_failed()  # Increases temper
	
	_set_state("idle")


## Helper to set state through proper method (updates data store for UI sync)
func _set_state(state: String) -> void:
	if agent.has_method("set_current_state"):
		agent.set_current_state(state)
	else:
		agent.current_state = state
