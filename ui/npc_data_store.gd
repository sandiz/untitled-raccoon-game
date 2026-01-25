class_name NPCDataStore
## Centralized data store for NPC state - no autoload, uses static pattern.
## Both speech bubble and info panel read from here to stay in sync.

# Static instance (lazy initialized)
static var _instance: NPCDataStore = null

# Signals for reactive updates
signal state_changed(npc_id: String, data: Dictionary)
signal emotions_changed(npc_id: String, emotions: Dictionary)

# NPC data: {npc_id: {state, dialogue, emotions, personality, etc}}
var _npc_data: Dictionary = {}

# Current focused NPC (for UI display)
var _focused_npc_id: String = ""


static func get_instance() -> NPCDataStore:
	if _instance == null:
		_instance = NPCDataStore.new()
	return _instance


## Update NPC state and dialogue - called by shopkeeper/NPC
func update_npc_state(npc_id: String, state: String, dialogue: String) -> void:
	if not _npc_data.has(npc_id):
		_npc_data[npc_id] = {}
	
	_npc_data[npc_id]["state"] = state
	_npc_data[npc_id]["dialogue"] = dialogue
	
	state_changed.emit(npc_id, _npc_data[npc_id])


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


## Set which NPC is currently focused (for UI)
func set_focused_npc(npc_id: String) -> void:
	_focused_npc_id = npc_id


## Get focused NPC id
func get_focused_npc_id() -> String:
	return _focused_npc_id


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
