extends BTAction
## Searches for player at last known position. Updates search_time.

@export var search_speed: float = 3.0
@export var look_around_time: float = 2.0

enum SearchPhase { MOVE_TO_LAST, LOOK_AROUND, CHECK_NEARBY }

var _phase: SearchPhase = SearchPhase.MOVE_TO_LAST
var _look_timer: float = 0.0
var _search_points: Array[Vector3] = []
var _current_point_index: int = 0

func _enter() -> void:
	_phase = SearchPhase.MOVE_TO_LAST
	_look_timer = 0.0
	_current_point_index = 0
	_search_points.clear()
	
	# Set state
	_set_state("searching")
	
	# Play walk animation
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("default/Walk_Loop"):
		anim.play("default/Walk_Loop")
	
	# Generate search points around last known position
	var last_pos = blackboard.get_var(&"last_known_position", agent.global_position)
	_search_points.append(last_pos)
	
	# Add nearby points to check
	for i in range(3):
		var angle = randf() * TAU
		var offset = Vector3(cos(angle), 0, sin(angle)) * randf_range(2.0, 4.0)
		_search_points.append(last_pos + offset)

func _tick(delta: float) -> Status:
	# Increment search time
	var search_time = blackboard.get_var(&"search_time", 0.0)
	blackboard.set_var(&"search_time", search_time + delta)
	
	# Check if player became visible
	var perception = agent.get("perception")
	if perception and perception.can_see_target:
		_on_found_player()
		return SUCCESS
	
	match _phase:
		SearchPhase.MOVE_TO_LAST:
			return _do_move_to_point(delta)
		SearchPhase.LOOK_AROUND:
			return _do_look_around(delta)
		SearchPhase.CHECK_NEARBY:
			return _do_check_nearby(delta)
	
	return RUNNING

func _do_move_to_point(delta: float) -> Status:
	if _current_point_index >= _search_points.size():
		return FAILURE  # No more points, give up
	
	var target = _search_points[_current_point_index]
	var dist = agent.global_position.distance_to(target)
	
	if dist < 0.5:
		# Arrived, look around
		_phase = SearchPhase.LOOK_AROUND
		_look_timer = 0.0
		
		var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
		if anim and anim.has_animation("default/Idle_LookAround_Loop"):
			anim.play("default/Idle_LookAround_Loop")
		return RUNNING
	
	# Move toward point
	var nav: NavigationAgent3D = agent.get_node_or_null("NavigationAgent3D")
	if nav:
		nav.target_position = target
		var next_pos = nav.get_next_path_position()
		var direction = (next_pos - agent.global_position).normalized()
		direction.y = 0
		
		agent.velocity = direction * search_speed
		agent.move_and_slide()
		
		if direction.length_squared() > 0.001:
			var target_angle = atan2(direction.x, direction.z)
			agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, delta * 8.0)
	
	return RUNNING

func _do_look_around(delta: float) -> Status:
	_look_timer += delta
	
	# Slowly rotate while looking
	agent.rotation.y += delta * 1.5
	
	if _look_timer >= look_around_time:
		_current_point_index += 1
		if _current_point_index >= _search_points.size():
			return FAILURE  # Searched all points, give up
		
		_phase = SearchPhase.MOVE_TO_LAST
		var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
		if anim and anim.has_animation("default/Walk_Loop"):
			anim.play("default/Walk_Loop")
	
	return RUNNING

func _do_check_nearby(_delta: float) -> Status:
	# This phase could do additional checks
	return FAILURE

func _on_found_player() -> void:
	# Reset search time since we found them
	blackboard.set_var(&"search_time", 0.0)
	_set_state("chasing")

func _exit() -> void:
	agent.velocity = Vector3.ZERO


## Helper to set state through proper method (updates data store for UI sync)
func _set_state(state: String) -> void:
	if agent.has_method("set_current_state"):
		agent.set_current_state(state)
	else:
		agent.current_state = state
