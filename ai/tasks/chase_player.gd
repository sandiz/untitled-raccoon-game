@tool
extends BTAction
## Actively chases the player. Updates last_known_position and exhaustion.

@export var chase_speed: float = 5.0
@export var stop_distance: float = 1.5  # Stop when this close to player
@export var exhaustion_rate: float = 0.04  # Per second
@export var celebration_time: float = 2.0  # How long to celebrate
@export var lost_sight_timeout: float = 2.0  # Seconds before giving up chase when can't see

var _chase_started: bool = false
var _caught_player: bool = false
var _celebration_timer: float = 0.0
var _time_since_seen: float = 0.0  # Track how long since we saw player

func _generate_name() -> String:
	return "ChasePlayer (speed: %s)" % chase_speed

func _enter() -> void:
	_chase_started = false
	_caught_player = false
	_celebration_timer = 0.0
	_time_since_seen = 0.0
	blackboard.set_var(&"search_time", 0.0)
	# Stop any residual movement from previous task
	agent.velocity = Vector3.ZERO

func _tick(delta: float) -> Status:
	# If caught player, wait for celebration then SUCCESS
	if _caught_player:
		# Ensure NPC stays still during celebration
		agent.velocity = Vector3.ZERO
		_celebration_timer += delta
		if _celebration_timer >= celebration_time:
			# Clear priority lock so idle can update UI
			var npc_id = agent.get("npc_id")
			if npc_id:
				NPCDataStore.get_instance().clear_priority_lock(npc_id)
			# Clear caught state before returning SUCCESS
			if agent.has_method("set_current_state"):
				agent.set_current_state("idle")
			return SUCCESS
		return RUNNING
	
	# Check cooldown - don't chase if we just caught player
	if blackboard.get_var(&"chase_on_cooldown", false):
		return FAILURE
	
	# Only check will_chase at START - once chasing, commit to it
	var emo = blackboard.get_var(&"emotional_state")
	if not emo:
		emo = agent.get("emotional_state")
	
	# Only abort if we haven't started yet
	if not _chase_started:
		if not emo or not emo.will_chase:
			return FAILURE
	
	var nav_agent: NavigationAgent3D = agent.get_node_or_null("NavigationAgent3D")
	if not nav_agent:
		return FAILURE
	
	var player = _get_player()
	if not player:
		return FAILURE
	
	# Start chase animation once
	if not _chase_started:
		agent.velocity = Vector3.ZERO
		_chase_started = true
		_start_chase()
	
	# Update last known position while we can see player
	var perception = agent.get("perception")
	var can_see = perception.can_see_target if perception else true
	
	if can_see:
		blackboard.set_var(&"last_known_position", player.global_position)
		blackboard.set_var(&"last_seen_time", Time.get_ticks_msec() / 1000.0)
		_time_since_seen = 0.0
	else:
		_time_since_seen += delta
		# Lost sight for too long - switch to search
		if _time_since_seen >= lost_sight_timeout:
			_on_lost_player()
			return FAILURE
	
	# Update stamina drain while chasing
	if emo:
		emo.on_chasing(delta)  # Drains stamina
		
		# Give up if too exhausted
		if emo.will_give_up:
			_give_up_chase()
			return FAILURE
	
	# Check distance to player
	var distance = agent.global_position.distance_to(player.global_position)
	
	# Close enough - caught the player!
	if distance < stop_distance:
		# Set cooldown IMMEDIATELY to prevent double-catch
		blackboard.set_var(&"chase_on_cooldown", true)
		blackboard.set_var(&"chase_cooldown_timer", 5.0)
		agent.velocity = Vector3.ZERO
		_caught_player = true
		_celebration_timer = 0.0
		_on_caught_player(player)
		return RUNNING
	
	# Navigate toward player
	nav_agent.target_position = player.global_position
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - agent.global_position).normalized()
	direction.y = 0
	
	# Apply chase speed with temper multiplier
	var speed = chase_speed
	if emo:
		speed *= emo.chase_speed_multiplier  # Angry = faster
	
	agent.velocity = direction * speed
	
	# Face movement direction (use atan2 to match walk behavior)
	if direction.length() > 0.1:
		var target_angle = atan2(direction.x, direction.z)
		agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, 0.15)
	
	return RUNNING

func _on_caught_player(_player: Node3D) -> void:
	# Notify agent - it handles state, animation, and emotional feedback
	if agent.has_method("on_chase_ended"):
		agent.on_chase_ended(true)

func _start_chase() -> void:
	_set_state("chasing")
	
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("default/Sprint"):
		anim.play("default/Sprint")
	
	if agent.has_method("on_chase_started"):
		agent.on_chase_started()

func _give_up_chase() -> void:
	_set_state("frustrated")
	agent.velocity = Vector3.ZERO
	
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("default/Idle_Tired"):
		anim.play("default/Idle_Tired")
	
	# Set cooldown
	blackboard.set_var(&"chase_on_cooldown", true)
	
	if agent.has_method("on_chase_ended"):
		agent.on_chase_ended(false)


func _on_lost_player() -> void:
	# Player escaped - transition to search state
	_set_state("searching")
	agent.velocity = Vector3.ZERO
	
	var anim: AnimationPlayer = agent.get_node_or_null("AnimationPlayer")
	if anim and anim.has_animation("default/Walk"):
		anim.play("default/Walk")
	
	# Mark that we need to search
	blackboard.set_var(&"needs_search", true)


func _exit() -> void:
	agent.velocity = Vector3.ZERO
	_chase_started = false
	_caught_player = false

func _get_player() -> Node3D:
	var players = agent.get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null


## Helper to set state through proper method (updates data store for UI sync)
func _set_state(state: String) -> void:
	if agent.has_method("set_current_state"):
		agent.set_current_state(state)
	else:
		agent.current_state = state
