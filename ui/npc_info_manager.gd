class_name NPCInfoManager
extends Node
## Manages NPC selection via click and info panel display.
## Click NPC to select, click elsewhere to deselect.

@export var info_panel_path: NodePath
@export var camera_path: NodePath
@export var player_path: NodePath
@export var max_click_distance: float = 30.0

var _info_panel: NPCInfoPanel
var _camera: Camera3D
var _player: Node3D
var _data_store: NPCDataStore


func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	_info_panel = get_node_or_null(info_panel_path)
	_camera = get_node_or_null(camera_path)
	_player = get_node_or_null(player_path)
	_data_store = NPCDataStore.get_instance()
	
	if not _info_panel:
		push_warning("NPCInfoManager: info_panel_path not set or invalid: %s" % info_panel_path)
	if not _camera:
		push_warning("NPCInfoManager: camera_path not set or invalid: %s" % camera_path)
	
	# Connect to selection changes
	_data_store.selection_changed.connect(_on_selection_changed)
	
	# Disabled: Auto-select closest NPC after 2 seconds
	# get_tree().create_timer(2.0).timeout.connect(func(): _auto_select_closest_npc())


func _input(event: InputEvent) -> void:
	if not _camera:
		return
	
	# Handle mouse click for NPC selection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)


func _handle_click(screen_pos: Vector2) -> void:
	# Don't process click if it's on UI
	var viewport = get_viewport()
	if viewport and viewport.gui_get_hovered_control() != null:
		return  # Click was on UI, ignore
	
	var clicked_npc = _raycast_for_npc(screen_pos)
	
	if clicked_npc:
		# Clicked on NPC - select it
		var npc_id = _data_store.get_npc_id_from_node(clicked_npc)
		if not npc_id.is_empty():
			if _data_store.is_selected(npc_id):
				# Already selected - deselect
				_data_store.deselect_npc(npc_id)
			else:
				# Select this NPC (will deselect others if at max)
				_data_store.select_npc(npc_id)
	else:
		# Clicked on empty 3D space - deselect all
		_data_store.deselect_all()


func _raycast_for_npc(screen_pos: Vector2) -> Node3D:
	var from = _camera.project_ray_origin(screen_pos)
	var to = from + _camera.project_ray_normal(screen_pos) * max_click_distance
	
	var space_state = _camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # NPC collision layer
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		return _find_npc_parent(result.collider)
	
	return null


func _find_npc_parent(node: Node) -> Node3D:
	while node:
		if node.is_in_group("npc"):
			return node as Node3D
		node = node.get_parent()
	return null


func _on_selection_changed(_selected_ids: Array) -> void:
	# NPCInfoPanel handles its own visibility and content switching
	# (raccoon info when empty, NPC info when selected)
	pass


func _auto_select_closest_npc() -> void:
	if not _player:
		return
	
	var closest_npc: Node3D = null
	var closest_dist: float = INF
	
	for npc in get_tree().get_nodes_in_group("npc"):
		if not npc is Node3D:
			continue
		var dist = _player.global_position.distance_to(npc.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_npc = npc
	
	if closest_npc:
		var npc_id = _data_store.get_npc_id_from_node(closest_npc)
		if not npc_id.is_empty():
			_data_store.select_npc(npc_id)
