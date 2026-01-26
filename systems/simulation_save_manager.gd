class_name SimulationSaveManager
extends Node
## Auto-saves simulation state periodically. Singleton pattern (not autoload).
## Saves: time of day, NPC positions/states/emotions, camera state.

signal save_completed(slot: String)
signal load_completed(slot: String)

# Static instance (lazy initialized)
static var _instance: SimulationSaveManager = null

const SAVE_DIR := "user://saves/"
const AUTOSAVE_SLOT := "autosave"
const SAVE_VERSION := 1

## Auto-save interval in seconds
@export var autosave_interval: float = 30.0

## Auto-load last save on start
@export var auto_resume: bool = true

var _autosave_timer: float = 0.0
var _is_saving: bool = false
var _has_tried_resume: bool = false


static func get_instance() -> SimulationSaveManager:
	if _instance == null:
		_instance = SimulationSaveManager.new()
		# Add to tree so _process runs
		if Engine.get_main_loop():
			var root = Engine.get_main_loop().root
			if root:
				root.call_deferred("add_child", _instance)
	return _instance


func _ready() -> void:
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR.replace("user://", OS.get_user_data_dir() + "/"))
	
	# Auto-resume if enabled and save exists
	if auto_resume and has_save(AUTOSAVE_SLOT):
		call_deferred("_try_auto_resume")


func _try_auto_resume() -> void:
	if _has_tried_resume:
		return
	_has_tried_resume = true
	# Wait a frame for scene to be fully ready
	await get_tree().process_frame
	load_simulation(AUTOSAVE_SLOT)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F5:
				# Quick save
				force_autosave()
			KEY_F9:
				# Quick load (resume)
				if has_save(AUTOSAVE_SLOT):
					load_simulation(AUTOSAVE_SLOT)
				else:
					pass  # No save to load
			KEY_R:
				# Reset simulation (Shift+R to avoid accidental reset)
				if event.shift_pressed:
					reset_simulation()


func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= autosave_interval:
		_autosave_timer = 0.0
		save_simulation(AUTOSAVE_SLOT)


## Save current simulation state to slot
func save_simulation(slot: String = AUTOSAVE_SLOT) -> bool:
	if _is_saving:
		return false
	
	# Don't save if any NPC is in an active state (chasing, caught, alerted, etc.)
	if _any_npc_active():
		return false
	
	_is_saving = true
	
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"time_of_day": _get_time_of_day(),
		"npcs": _gather_npc_data(),
		"camera": _gather_camera_data(),
	}
	
	var path = SAVE_DIR + slot + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SimulationSaveManager: Failed to open save file: ", path)
		_is_saving = false
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	_is_saving = false
	save_completed.emit(slot)

	return true


## Load simulation state from slot
func load_simulation(slot: String = AUTOSAVE_SLOT) -> bool:
	var path = SAVE_DIR + slot + ".json"
	
	if not FileAccess.file_exists(path):
		push_warning("SimulationSaveManager: Save file not found: ", path)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SimulationSaveManager: Failed to open save file: ", path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("SimulationSaveManager: Failed to parse save file")
		return false
	
	var save_data: Dictionary = json.data
	
	# Restore time of day (default 9am = 0.125)
	_restore_time_of_day(save_data.get("time_of_day", 0.125))
	
	# Restore NPC data
	_restore_npc_data(save_data.get("npcs", {}))
	
	# Restore camera
	_restore_camera_data(save_data.get("camera", {}))
	
	load_completed.emit(slot)

	return true


## Check if a save exists
func has_save(slot: String = AUTOSAVE_SLOT) -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot + ".json")


## Get saved normalized time (0.0-1.0) or -1.0 if no save exists
func get_saved_time(slot: String = AUTOSAVE_SLOT) -> float:
	var path = SAVE_DIR + slot + ".json"
	
	if not FileAccess.file_exists(path):
		return -1.0
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return -1.0
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		return -1.0
	
	var save_data: Dictionary = json.data
	return save_data.get("time_of_day", -1.0)


## Delete a save
func delete_save(slot: String = AUTOSAVE_SLOT) -> void:
	var path = SAVE_DIR + slot + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## Reset simulation to fresh state (9am, default positions)
func reset_simulation() -> void:
	delete_save(AUTOSAVE_SLOT)
	_autosave_timer = 0.0
	
	# Reset time to 9am (0.125 normalized: 0.125 * 24 + 6 = 9)
	_restore_time_of_day(0.125)
	
	# Reset NPCs to initial state
	var npcs = get_tree().get_nodes_in_group("npc")
	for npc in npcs:
		if npc.has_method("reset_to_initial_state"):
			npc.reset_to_initial_state()
	
	print("[SimSave] Simulation reset")


## Force an immediate autosave
func force_autosave() -> void:
	save_simulation(AUTOSAVE_SLOT)


# ═══════════════════════════════════════
# SAFETY CHECKS
# ═══════════════════════════════════════

## Returns true if any NPC is in an active (non-idle) state
func _any_npc_active() -> bool:
	var npcs = get_tree().get_nodes_in_group("npc")
	const SAFE_STATES := ["idle", ""]
	
	for npc in npcs:
		var state: String = npc.get("current_state") if npc.get("current_state") else "idle"
		if state.to_lower() not in SAFE_STATES:
			return true
	
	return false


# ═══════════════════════════════════════
# GATHER DATA
# ═══════════════════════════════════════

func _get_time_of_day() -> float:
	var day_night = get_tree().get_first_node_in_group("day_night_cycle") as DayNightCycle
	if day_night:
		return day_night.get_normalized_time()
	return 0.375  # Default 9am


func _gather_npc_data() -> Dictionary:
	var data := {}
	var npcs = get_tree().get_nodes_in_group("npc")
	
	for npc in npcs:
		var npc_id: String = npc.get("npc_id") if npc.get("npc_id") else npc.name
		
		data[npc_id] = {
			"position": _vec3_to_array(npc.global_position),
			"rotation_y": npc.rotation.y,
			"state": npc.get("current_state") if npc.get("current_state") else "idle",
			"dialogue": npc.get("current_dialogue") if npc.get("current_dialogue") else "",
		}
		
		# Save emotional state if available
		if npc.get("emotional_state"):
			var es = npc.emotional_state
			data[npc_id]["emotions"] = {
				"alertness": es.alertness,
				"annoyance": es.annoyance,
				"exhaustion": es.exhaustion,
				"suspicion": es.suspicion,
			}
	
	return data


func _gather_camera_data() -> Dictionary:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return {}
	
	return {
		"position": _vec3_to_array(camera.global_position),
		"rotation": _vec3_to_array(camera.rotation),
	}


# ═══════════════════════════════════════
# RESTORE DATA
# ═══════════════════════════════════════

func _restore_time_of_day(normalized: float) -> void:
	var day_night = get_tree().get_first_node_in_group("day_night_cycle") as DayNightCycle
	if day_night:
		day_night.set_normalized_time(normalized)


func _restore_npc_data(npc_data: Dictionary) -> void:
	var npcs = get_tree().get_nodes_in_group("npc")
	
	for npc in npcs:
		var npc_id: String = npc.get("npc_id") if npc.get("npc_id") else npc.name
		
		if not npc_data.has(npc_id):
			continue
		
		var data: Dictionary = npc_data[npc_id]
		
		# Restore position
		if data.has("position"):
			npc.global_position = _array_to_vec3(data["position"])
		
		# Restore rotation
		if data.has("rotation_y"):
			npc.rotation.y = data["rotation_y"]
		
		# Restore state via data store (so UI syncs)
		if data.has("state") and data.has("dialogue"):
			var store = NPCDataStore.get_instance()
			store.clear_priority_lock(npc_id)
			store.update_npc_state(npc_id, data["state"], data["dialogue"])
		
		# Restore emotional state
		if data.has("emotions") and npc.get("emotional_state"):
			var emotions: Dictionary = data["emotions"]
			var es = npc.emotional_state
			es.alertness = emotions.get("alertness", 0.0)
			es.annoyance = emotions.get("annoyance", 0.0)
			es.exhaustion = emotions.get("exhaustion", 0.0)
			es.suspicion = emotions.get("suspicion", 0.0)


func _restore_camera_data(camera_data: Dictionary) -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera or camera_data.is_empty():
		return
	
	if camera_data.has("position"):
		camera.global_position = _array_to_vec3(camera_data["position"])
	if camera_data.has("rotation"):
		camera.rotation = _array_to_vec3(camera_data["rotation"])


# ═══════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════

func _vec3_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _array_to_vec3(a: Array) -> Vector3:
	if a.size() < 3:
		return Vector3.ZERO
	return Vector3(a[0], a[1], a[2])
