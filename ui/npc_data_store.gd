class_name NPCDataStore
extends Node
## Centralized data store for NPC state - no autoload, uses static pattern.
## Both speech bubble and info panel read from here to stay in sync.
## Handles message priority - high priority messages block lower priority updates.

# Static instance (lazy initialized)
static var _instance: NPCDataStore = null

# Signals for reactive updates
signal state_changed(npc_id: String, data: Dictionary)
signal emotions_changed(npc_id: String, emotions: Dictionary)
signal selection_changed(selected_ids: Array)

# Message priority levels
enum Priority { LOW = 0, NORMAL = 1, HIGH = 2, CRITICAL = 3 }

# Minimum display times per priority (seconds)
const PRIORITY_MIN_TIMES := {
	Priority.LOW: 0.0,       # Can be replaced immediately
	Priority.NORMAL: 1.0,    # At least 1 second
	Priority.HIGH: 2.5,      # Important messages stay 2.5s
	Priority.CRITICAL: 4.0,  # Critical stays 4s
}

# State to priority mapping
const STATE_PRIORITIES := {
	"idle": Priority.LOW,
	"calm": Priority.LOW,
	"returning": Priority.LOW,
	"alert": Priority.NORMAL,
	"suspicious": Priority.NORMAL,
	"investigating": Priority.NORMAL,
	"searching": Priority.HIGH,
	"chasing": Priority.HIGH,
	"angry": Priority.HIGH,
	"tired": Priority.NORMAL,
	"frustrated": Priority.NORMAL,
	"gave_up": Priority.NORMAL,
	"caught": Priority.CRITICAL,
}

# NPC data: {npc_id: {state, dialogue, emotions, personality, node, etc}}
var _npc_data: Dictionary = {}

# Priority tracking per NPC: {npc_id: {priority, locked_until}}
var _npc_priority: Dictionary = {}

# Selected NPCs (max 3)
var _selected_npc_ids: Array[String] = []
const MAX_SELECTED: int = 3

# NPC node references for raycasting
var _npc_nodes: Dictionary = {}  # npc_id -> Node3D

# Session tracking - detect game restarts
var _session_frame: int = -1  # Frame when session started


static func get_instance() -> NPCDataStore:
	if _instance == null:
		_instance = NPCDataStore.new()
		_instance._session_frame = Engine.get_process_frames()
		# Add to tree so _process runs for priority timing
		if Engine.get_main_loop():
			var root = Engine.get_main_loop().root
			if root:
				root.call_deferred("add_child", _instance)
	else:
		# Instance exists - check if this is a new game session
		# New session = frame count reset to lower value than our recorded session frame
		var current_frame = Engine.get_process_frames()
		if current_frame < _instance._session_frame or _instance._session_frame < 0:
			# Frame counter reset or uninitialized = new game session
			print("[NPCDataStore] New session detected (frame %d < %d), resetting" % [current_frame, _instance._session_frame])
			_instance.reset()
			_instance._session_frame = current_frame
	return _instance


func _process(_delta: float) -> void:
	# Update priority locks based on elapsed time
	var current_time = Time.get_ticks_msec() / 1000.0
	for npc_id in _npc_priority:
		var pdata = _npc_priority[npc_id]
		if pdata.locked_until > 0.0 and current_time >= pdata.locked_until:
			pdata.locked_until = 0.0  # Unlock


## Update NPC state and dialogue - called by shopkeeper/NPC
## Optional priority parameter (-1 = auto-derive from state)
func update_npc_state(npc_id: String, state: String, dialogue: String, priority: int = -1) -> void:
	if not _npc_data.has(npc_id):
		_npc_data[npc_id] = {}
	
	# Determine priority from state if not explicitly provided
	var msg_priority = priority if priority >= 0 else STATE_PRIORITIES.get(state, Priority.NORMAL)
	
	# Initialize priority tracking for this NPC if needed
	if not _npc_priority.has(npc_id):
		_npc_priority[npc_id] = {"priority": Priority.LOW, "locked_until": 0.0}
	
	var pdata = _npc_priority[npc_id]
	var current_time = Time.get_ticks_msec() / 1000.0
	var is_locked = pdata.locked_until > current_time
	
	# Check if current message is locked with higher priority
	if is_locked and msg_priority < pdata.priority:
		# Can't replace - current message has higher priority and is still locked
		return
	
	# Same or lower priority can't replace if locked
	if is_locked and msg_priority <= pdata.priority:
		return
	
	# Update allowed - set new priority and lock time
	pdata.priority = msg_priority
	var min_time = PRIORITY_MIN_TIMES.get(msg_priority, 0.0)
	pdata.locked_until = current_time + min_time if min_time > 0.0 else 0.0
	
	# Store state and dialogue
	_npc_data[npc_id]["state"] = state
	_npc_data[npc_id]["dialogue"] = dialogue
	_npc_data[npc_id]["priority"] = msg_priority
	
	state_changed.emit(npc_id, _npc_data[npc_id])


## Clear priority lock for an NPC (allows any update)
func clear_priority_lock(npc_id: String) -> void:
	if _npc_priority.has(npc_id):
		_npc_priority[npc_id].locked_until = 0.0
		_npc_priority[npc_id].priority = Priority.LOW


## Check if an NPC's message is currently locked
func is_priority_locked(npc_id: String) -> bool:
	if not _npc_priority.has(npc_id):
		return false
	var current_time = Time.get_ticks_msec() / 1000.0
	return _npc_priority[npc_id].locked_until > current_time


## Get current priority level for an NPC
func get_priority(npc_id: String) -> int:
	if _npc_priority.has(npc_id):
		return _npc_priority[npc_id].priority
	return Priority.LOW


## Update NPC emotions - called by shopkeeper/NPC
func update_npc_emotions(npc_id: String, emotions: Dictionary) -> void:
	if not _npc_data.has(npc_id):
		_npc_data[npc_id] = {}
	
	_npc_data[npc_id]["emotions"] = emotions
	
	emotions_changed.emit(npc_id, emotions)


## Set NPC metadata (personality, name, title, portrait)
func set_npc_metadata(npc_id: String, metadata: Dictionary) -> void:
	if not _npc_data.has(npc_id):
		_npc_data[npc_id] = {}
	
	_npc_data[npc_id].merge(metadata, true)


## Reset all data (called on game restart or can be called manually)
func reset() -> void:
	_npc_data.clear()
	_npc_priority.clear()
	_selected_npc_ids.clear()
	_npc_nodes.clear()


## Register NPC node for selection raycasting
## Also clears any stale data for this NPC (handles game restart)
func register_npc(npc_id: String, node: Node3D) -> void:
	# Clear any stale data from previous game session
	if _npc_data.has(npc_id):
		_npc_data.erase(npc_id)
	if _npc_priority.has(npc_id):
		_npc_priority.erase(npc_id)
	if npc_id in _selected_npc_ids:
		_selected_npc_ids.erase(npc_id)
	
	_npc_nodes[npc_id] = node


## Unregister NPC node
func unregister_npc(npc_id: String) -> void:
	_npc_nodes.erase(npc_id)
	deselect_npc(npc_id)


## Get NPC node by id
func get_npc_node(npc_id: String) -> Node3D:
	return _npc_nodes.get(npc_id)


## Get NPC id from node
func get_npc_id_from_node(node: Node3D) -> String:
	for id in _npc_nodes:
		if _npc_nodes[id] == node:
			return id
	return ""


## Select an NPC (adds to selection, max 3)
func select_npc(npc_id: String) -> void:
	if npc_id in _selected_npc_ids:
		return
	if _selected_npc_ids.size() >= MAX_SELECTED:
		_selected_npc_ids.pop_front()  # Remove oldest
	_selected_npc_ids.append(npc_id)
	selection_changed.emit(_selected_npc_ids.duplicate())


## Deselect an NPC
func deselect_npc(npc_id: String) -> void:
	if npc_id in _selected_npc_ids:
		_selected_npc_ids.erase(npc_id)
		selection_changed.emit(_selected_npc_ids.duplicate())


## Deselect all NPCs
func deselect_all() -> void:
	if _selected_npc_ids.size() > 0:
		_selected_npc_ids.clear()
		selection_changed.emit(_selected_npc_ids.duplicate())


## Check if NPC is selected
func is_selected(npc_id: String) -> bool:
	return npc_id in _selected_npc_ids


## Get all selected NPC ids
func get_selected_ids() -> Array[String]:
	return _selected_npc_ids.duplicate()


## Get all selected NPC nodes
func get_selected_nodes() -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	for id in _selected_npc_ids:
		if _npc_nodes.has(id):
			nodes.append(_npc_nodes[id])
	return nodes


## Get all data for an NPC
func get_npc_data(npc_id: String) -> Dictionary:
	return _npc_data.get(npc_id, {})


## Get current state for an NPC
func get_npc_state(npc_id: String) -> String:
	var data = _npc_data.get(npc_id, {})
	return data.get("state", "idle")


## Get current dialogue for an NPC
func get_npc_dialogue(npc_id: String) -> String:
	var data = _npc_data.get(npc_id, {})
	return data.get("dialogue", "")


## Get emotions for an NPC
func get_npc_emotions(npc_id: String) -> Dictionary:
	var data = _npc_data.get(npc_id, {})
	return data.get("emotions", {})
