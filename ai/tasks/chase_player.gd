@tool
extends BTAction
## Actively chases the player. Updates last_known_position and exhaustion.
##
## RESPONSIBILITY: Sets velocity, state changes, and chase logic. NPC handles animation.

@export var chase_speed: float = 5.0
@export var stop_distance: float = 1.5  # Stop when this close to player
@export var celebration_time: float = 2.0  # How long to celebrate after catching
@export var lost_sight_timeout: float = 2.0  # Seconds before giving up chase when can't see

var _chase_started: bool = false
var _caught_player: bool = false
var _celebration_timer: float = 0.0
var _time_since_seen: float = 0.0

func _generate_name() -> String:
	return "ChasePlayer (speed: %s)" % chase_speed

func _enter() -> void:
	_chase_started = false
	_caught_player = false
	_celebration_timer = 0.0
	_time_since_seen = 0.0
	blackboard.set_var(&"search_time", 0.0)
	agent.velocity = Vector3.ZERO

func _tick(delta: float) -> Status:
	# If caught player, wait for celebration then SUCCESS
	if _caught_player:
		agent.velocity = Vector3.ZERO
		_celebration_timer += delta
		if _celebration_timer >= celebration_time:
			var npc_id = agent.get("npc_id")
			if npc_id:
				NPCDataStore.get_instance().clear_priority_lock(npc_id)
			_set_state("idle")
			return SUCCESS
		return RUNNING
	
	# Check cooldown - don't chase if we just caught player
	if blackboard.get_var(&"chase_on_cooldown", false):
		return FAILURE
	
	# Get emotional state
	var emo = blackboard.get_var(&"emotional_state")
	if not emo:
		emo = agent.get("emotional_state")
	
	# Only check will_chase at START - once chasing, commit to it
	if not _chase_started:
		if not emo or not emo.will_chase:
			return FAILURE
	
	var nav_agent: NavigationAgent3D = agent.get_node_or_null("NavigationAgent3D")
	if not nav_agent:
		return FAILURE
	
	var player = _get_player()
	if not player:
		return FAILURE
	
	# Start chase once
	if not _chase_started:
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
		if _time_since_seen >= lost_sight_timeout:
			_on_lost_player()
			return FAILURE
	
	# Update stamina drain while chasing
	if emo:
		emo.on_chasing(delta)
		if emo.will_give_up:
			_give_up_chase()
			return FAILURE
	
	# Check distance to player
	var distance = agent.global_position.distance_to(player.global_position)
	
	# Close enough - caught the player!
	if distance < stop_distance:
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
		speed *= emo.chase_speed_multiplier
	
	agent.velocity = direction * speed
	
	# Face movement direction
	if direction.length() > 0.1:
		var target_angle = atan2(direction.x, direction.z)
		agent.rotation.y = lerp_angle(agent.rotation.y, target_angle, 0.15)
	
	return RUNNING

func _start_chase() -> void:
	_set_state("chasing")
	if agent.has_method("on_chase_started"):
		agent.on_chase_started()

func _on_caught_player(_player: Node3D) -> void:
	_set_state("caught")
	if agent.has_method("on_chase_ended"):
		agent.on_chase_ended(true)

func _give_up_chase() -> void:
	_set_state("frustrated")
	agent.velocity = Vector3.ZERO
	blackboard.set_var(&"chase_on_cooldown", true)
	if agent.has_method("on_chase_ended"):
		agent.on_chase_ended(false)

func _on_lost_player() -> void:
	_set_state("searching")
	agent.velocity = Vector3.ZERO
	blackboard.set_var(&"needs_search", true)

func _exit() -> void:
	agent.velocity = Vector3.ZERO
	_chase_started = false
	_caught_player = false

func _get_player() -> Node3D:
	var players = agent.get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null

func _set_state(state: String) -> void:
	if agent.has_method("set_current_state"):
		agent.set_current_state(state)
	else:
		agent.current_state = state
