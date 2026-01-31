class_name ChatBubbleManager
extends Node
## Manages chat bubble visibility for UNSELECTED NPCs.
## Selected NPCs always show their bubbles (handled by NPCStateIndicator).
## This manager controls spam/cooldowns/max visible for background chatter.
##
## Uses static singleton pattern (like NPCDataStore) - not autoload.
## Press B to toggle debug view.

static var _instance: ChatBubbleManager = null

# Configuration
var max_unselected_bubbles: int = 2  # Max bubbles for unselected NPCs
var per_npc_cooldown: float = 8.0  # Seconds before same NPC can show again
var min_display_time: float = 2.0  # Minimum time a bubble stays visible
var max_distance: float = 20.0  # Don't show bubbles beyond this distance

# State tracking
var _active_bubbles: Dictionary = {}  # npc_id -> {indicator, show_time}
var _cooldowns: Dictionary = {}  # npc_id -> cooldown_end_time
var _queue: Array[Dictionary] = []  # [{npc_id, indicator, priority, distance}]

# References
var _data_store: NPCDataStore

# Debug
var _debug_visible: bool = false
var _debug_label: Label
var _scale: float = 1.0


func _s(val: int) -> int:
	return int(val * _scale)


static func get_instance() -> ChatBubbleManager:
	if _instance == null:
		_instance = ChatBubbleManager.new()
		# Add to tree so _process runs
		if Engine.get_main_loop():
			var root = Engine.get_main_loop().root
			if root:
				root.call_deferred("add_child", _instance)
	return _instance


func _ready() -> void:
	# Connect to data store
	_data_store = NPCDataStore.get_instance()
	if _data_store:
		_data_store.state_changed.connect(_on_npc_state_changed)
		_data_store.selection_changed.connect(_on_selection_changed)
	
	# Setup debug label
	_setup_debug_ui()


func _setup_debug_ui() -> void:
	# Get display scale
	_scale = DisplayServer.screen_get_scale()
	if _scale <= 0:
		_scale = 1.0
	
	_debug_label = Label.new()
	_debug_label.name = "ChatBubbleDebug"
	_debug_label.position = Vector2(_s(10), _s(10))
	_debug_label.add_theme_font_size_override("font_size", _s(16))
	_debug_label.add_theme_color_override("font_color", Color.WHITE)
	_debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_debug_label.add_theme_constant_override("outline_size", _s(4))
	_debug_label.visible = false
	
	# Add to CanvasLayer so it's always on top
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(_debug_label)
	add_child(canvas)


func _input(event: InputEvent) -> void:
	# B to toggle debug view
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		_debug_visible = not _debug_visible
		_debug_label.visible = _debug_visible


func _process(_delta: float) -> void:
	_update_cooldowns()
	_check_expired_bubbles()
	_try_show_queued()
	
	if _debug_visible:
		_update_debug_display()


## Called when any NPC's state changes
func _on_npc_state_changed(npc_id: String, data: Dictionary) -> void:
	# If NPC is selected, don't manage their bubble (indicator handles it)
	if _data_store.is_selected(npc_id):
		return
	
	# If no dialogue, nothing to show
	var dialogue = data.get("dialogue", "")
	if dialogue.is_empty():
		return
	
	# Get indicator reference
	var indicator = _get_indicator_for_npc(npc_id)
	if not indicator:
		return
	
	# Check cooldown
	if _is_on_cooldown(npc_id):
		return
	
	# Check distance
	var distance = _get_npc_distance(npc_id)
	if distance > max_distance:
		return
	
	# Get priority from data
	var priority = data.get("priority", NPCDataStore.Priority.NORMAL)
	
	# Try to show or queue
	_request_bubble(npc_id, indicator, priority, distance)


## When selection changes, update managed bubbles
func _on_selection_changed(selected_ids: Array) -> void:
	# Hide managed bubbles for newly selected NPCs (they handle themselves now)
	for npc_id in selected_ids:
		if _active_bubbles.has(npc_id):
			_hide_bubble(npc_id, false)  # No cooldown - they're selected now
	
	# Remove from queue if selected
	_queue = _queue.filter(func(req): return req.npc_id not in selected_ids)


## Request to show a bubble for unselected NPC
func _request_bubble(npc_id: String, indicator: Node, priority: int, distance: float) -> void:
	# If already showing for this NPC, update it
	if _active_bubbles.has(npc_id):
		_active_bubbles[npc_id].show_time = Time.get_ticks_msec() / 1000.0
		return
	
	# Check if we have room
	if _active_bubbles.size() < max_unselected_bubbles:
		_show_bubble(npc_id, indicator)
	else:
		# Try to replace lower priority bubble or queue
		var replaced = _try_replace_lower_priority(npc_id, indicator, priority, distance)
		if not replaced:
			_add_to_queue(npc_id, indicator, priority, distance)


## Show bubble for NPC
func _show_bubble(npc_id: String, indicator: Node) -> void:
	_active_bubbles[npc_id] = {
		"indicator": indicator,
		"show_time": Time.get_ticks_msec() / 1000.0
	}
	
	if indicator.has_method("show_managed"):
		indicator.show_managed()


## Hide bubble and optionally start cooldown
func _hide_bubble(npc_id: String, start_cooldown: bool = true) -> void:
	if not _active_bubbles.has(npc_id):
		return
	
	var bubble_data = _active_bubbles[npc_id]
	var indicator = bubble_data.indicator
	
	if is_instance_valid(indicator) and indicator.has_method("hide_managed"):
		indicator.hide_managed()
	
	_active_bubbles.erase(npc_id)
	
	if start_cooldown:
		_start_cooldown(npc_id)


## Try to replace a lower priority bubble
func _try_replace_lower_priority(npc_id: String, indicator: Node, priority: int, distance: float) -> bool:
	var lowest_priority_id: String = ""
	var lowest_priority: int = priority
	var furthest_distance: float = 0.0
	
	for active_id in _active_bubbles:
		var active_data = _data_store.get_npc_data(active_id)
		var active_priority = active_data.get("priority", NPCDataStore.Priority.NORMAL)
		var active_distance = _get_npc_distance(active_id)
		
		# Check min display time
		var show_time = _active_bubbles[active_id].show_time
		var elapsed = Time.get_ticks_msec() / 1000.0 - show_time
		if elapsed < min_display_time:
			continue
		
		# Prefer replacing lower priority, or same priority but further away
		if active_priority < lowest_priority or (active_priority == lowest_priority and active_distance > furthest_distance):
			lowest_priority = active_priority
			lowest_priority_id = active_id
			furthest_distance = active_distance
	
	if not lowest_priority_id.is_empty() and (priority > lowest_priority or (priority == lowest_priority and distance < furthest_distance)):
		_hide_bubble(lowest_priority_id)
		_show_bubble(npc_id, indicator)
		return true
	
	return false


## Add to queue sorted by priority then distance
func _add_to_queue(npc_id: String, indicator: Node, priority: int, distance: float) -> void:
	# Don't queue duplicates
	for req in _queue:
		if req.npc_id == npc_id:
			return
	
	_queue.append({
		"npc_id": npc_id,
		"indicator": indicator,
		"priority": priority,
		"distance": distance,
		"timestamp": Time.get_ticks_msec()
	})
	
	# Sort: higher priority first, then closer distance
	_queue.sort_custom(func(a, b):
		if a.priority != b.priority:
			return a.priority > b.priority
		return a.distance < b.distance
	)
	
	# Limit queue size
	if _queue.size() > 5:
		_queue.resize(5)


## Try to show queued bubbles
func _try_show_queued() -> void:
	if _queue.is_empty():
		return
	
	if _active_bubbles.size() >= max_unselected_bubbles:
		return
	
	# Find first valid queued request
	for i in range(_queue.size()):
		var req = _queue[i]
		var npc_id = req.npc_id
		
		# Skip if on cooldown or selected
		if _is_on_cooldown(npc_id) or _data_store.is_selected(npc_id):
			continue
		
		# Skip if indicator no longer valid
		if not is_instance_valid(req.indicator):
			_queue.remove_at(i)
			continue
		
		# Skip if too old (stale)
		var age = (Time.get_ticks_msec() - req.timestamp) / 1000.0
		if age > 10.0:
			_queue.remove_at(i)
			continue
		
		# Show it
		_queue.remove_at(i)
		_show_bubble(npc_id, req.indicator)
		return


## Check and hide expired bubbles
func _check_expired_bubbles() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var to_hide: Array[String] = []
	
	for npc_id in _active_bubbles:
		var show_time = _active_bubbles[npc_id].show_time
		var elapsed = current_time - show_time
		
		# Get display duration from priority
		var data = _data_store.get_npc_data(npc_id)
		var priority = data.get("priority", NPCDataStore.Priority.NORMAL)
		var duration = _get_duration_for_priority(priority)
		
		if elapsed >= duration:
			to_hide.append(npc_id)
	
	for npc_id in to_hide:
		_hide_bubble(npc_id)


func _get_duration_for_priority(priority: int) -> float:
	match priority:
		NPCDataStore.Priority.LOW: return 3.0
		NPCDataStore.Priority.NORMAL: return 4.0
		NPCDataStore.Priority.HIGH: return 5.0
		NPCDataStore.Priority.CRITICAL: return 6.0
	return 4.0


## Cooldown management
func _start_cooldown(npc_id: String) -> void:
	_cooldowns[npc_id] = Time.get_ticks_msec() / 1000.0 + per_npc_cooldown


func _is_on_cooldown(npc_id: String) -> bool:
	if not _cooldowns.has(npc_id):
		return false
	return Time.get_ticks_msec() / 1000.0 < _cooldowns[npc_id]


func _update_cooldowns() -> void:
	var current = Time.get_ticks_msec() / 1000.0
	var expired: Array[String] = []
	for npc_id in _cooldowns:
		if current >= _cooldowns[npc_id]:
			expired.append(npc_id)
	for npc_id in expired:
		_cooldowns.erase(npc_id)


## Get distance from camera to NPC
func _get_npc_distance(npc_id: String) -> float:
	var npc_node = _data_store.get_npc_node(npc_id)
	if not npc_node:
		return INF
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return INF
	
	return npc_node.global_position.distance_to(camera.global_position)


## Get indicator for NPC
func _get_indicator_for_npc(npc_id: String) -> Node:
	var npc_node = _data_store.get_npc_node(npc_id)
	if not npc_node:
		return null
	
	# Look for NPCStateIndicator child
	for child in npc_node.get_children():
		if child is NPCStateIndicator:
			return child
	
	# Try recursive search
	return _find_indicator_recursive(npc_node)


func _find_indicator_recursive(node: Node) -> Node:
	for child in node.get_children():
		if child is NPCStateIndicator:
			return child
		var result = _find_indicator_recursive(child)
		if result:
			return result
	return null


## Debug display
func _update_debug_display() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var lines: Array[String] = []
	
	lines.append("[B] BUBBLES %d/%d | CD %.0fs | Dist %.0fm" % [_active_bubbles.size(), max_unselected_bubbles, per_npc_cooldown, max_distance])
	
	# Active bubbles (compact)
	if not _active_bubbles.is_empty():
		var active_parts: Array[String] = []
		for npc_id in _active_bubbles:
			var data = _active_bubbles[npc_id]
			var elapsed = current_time - data.show_time
			var npc_data = _data_store.get_npc_data(npc_id)
			var priority = npc_data.get("priority", 1)
			var duration = _get_duration_for_priority(priority)
			var remaining = duration - elapsed
			active_parts.append("%s[%s]%.0fs" % [_short_id(npc_id), _get_priority_name(priority), remaining])
		lines.append("Active: " + " | ".join(active_parts))
	
	# Queue (compact)
	if not _queue.is_empty():
		var queue_parts: Array[String] = []
		for i in range(mini(_queue.size(), 3)):
			var req = _queue[i]
			queue_parts.append("%s[%s]" % [_short_id(req.npc_id), _get_priority_name(req.priority)])
		lines.append("Queue: " + " ".join(queue_parts))
	
	# Cooldowns (compact)
	if not _cooldowns.is_empty():
		var cd_parts: Array[String] = []
		for npc_id in _cooldowns:
			var remaining = _cooldowns[npc_id] - current_time
			if remaining > 0:
				cd_parts.append("%s:%.0fs" % [_short_id(npc_id), remaining])
		if not cd_parts.is_empty():
			lines.append("CD: " + " ".join(cd_parts))
	
	_debug_label.text = "\n".join(lines)


func _short_id(npc_id: String) -> String:
	# Shorten "shopkeeper_1" to "shop1"
	return npc_id.replace("keeper", "").replace("_", "")


func _get_priority_name(priority: int) -> String:
	match priority:
		NPCDataStore.Priority.LOW: return "LOW"
		NPCDataStore.Priority.NORMAL: return "NORM"
		NPCDataStore.Priority.HIGH: return "HIGH"
		NPCDataStore.Priority.CRITICAL: return "CRIT"
	return "?"
