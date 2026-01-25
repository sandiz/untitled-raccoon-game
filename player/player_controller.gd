extends CharacterBody3D
## Raccoon - player's avatar. No direct control.
## Player influences NPCs through possession/clicking.

signal possessed_npc(npc: Node3D)
signal released_npc(npc: Node3D)

var _current_possessed: Node3D = null
var _selection_ring: Node3D = null


func _ready() -> void:
	add_to_group("player")
	_setup_selection_ring()
	
	# Connect to NPC selection to show ring when no NPC selected
	call_deferred("_connect_to_data_store")


func _setup_selection_ring() -> void:
	var ring_scene = load("res://npcs/selection_ring.gd")
	if ring_scene:
		_selection_ring = Node3D.new()
		_selection_ring.set_script(ring_scene)
		_selection_ring.ring_color = Color(1.0, 1.0, 1.0, 0.9)
		_selection_ring.ring_size = 1.5  # Smaller for raccoon
		add_child(_selection_ring)


func _connect_to_data_store() -> void:
	var data_store = NPCDataStore.get_instance()
	if data_store:
		data_store.selection_changed.connect(_on_selection_changed)
		# Show ring initially if no NPC selected
		if data_store.get_selected_ids().is_empty():
			_show_ring()


func _on_selection_changed(selected_ids: Array) -> void:
	if selected_ids.is_empty():
		_show_ring()
	else:
		_hide_ring()


func _show_ring() -> void:
	if _selection_ring and _selection_ring.has_method("show_ring"):
		_selection_ring.show_ring()


func _hide_ring() -> void:
	if _selection_ring and _selection_ring.has_method("hide_ring"):
		_selection_ring.hide_ring()


func is_possessing() -> bool:
	return _current_possessed != null


func get_possessed() -> Node3D:
	return _current_possessed


func possess(npc: Node3D) -> void:
	if _current_possessed:
		release()
	_current_possessed = npc
	possessed_npc.emit(npc)


func release() -> void:
	if _current_possessed:
		var old = _current_possessed
		_current_possessed = null
		released_npc.emit(old)
