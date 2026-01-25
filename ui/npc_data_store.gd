class_name NPCDataStore
## Centralized data store for NPC state - no autoload, uses static pattern.
## Both speech bubble and info panel read from here to stay in sync.

# Static instance (lazy initialized)
static var _instance: NPCDataStore = null

# Signals for reactive updates
signal state_changed(npc_id: String, data: Dictionary)
signal emotions_changed(npc_id: String, emotions: Dictionary)
signal selection_changed(selected_ids: Array)

# NPC data: {npc_id: {state, dialogue, emotions, personality, node, etc}}
var _npc_data: Dictionary = {}

# Selected NPCs (max 3)
var _selected_npc_ids: Array[String] = []
const MAX_SELECTED: int = 3

# NPC node references for raycasting
var _npc_nodes: Dictionary = {}  # npc_id -> Node3D


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


## Register NPC node for selection raycasting
func register_npc(npc_id: String, node: Node3D) -> void:
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
