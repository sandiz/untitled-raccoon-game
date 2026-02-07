class_name NPCInfoManager
extends Node
## Manages NPC selection via click and info panel display.
## Click NPC to select, click elsewhere to deselect.

@export var info_panel_path: NodePath
@export var camera_path: NodePath
@export var player_path: NodePath
@export var max_click_distance: float = 30.0

var _info_panel: Control  # NPCInfoPanel, but use Control to avoid type issues after reparenting
var _camera: Camera3D
var _player: Node3D
var _data_store: NPCDataStore


func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	# Try direct path first, then search for reparented panel
	_info_panel = get_node_or_null(info_panel_path)
	if not _info_panel:
		# Panel may have been reparented by ScrollableWidgetContainer
		_info_panel = _find_info_panel()
	
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


func _find_info_panel() -> Control:
	# Search for NPCInfoPanel in UI tree (may have been reparented)
	var ui_layer = get_parent()
	if ui_layer:
		return _find_node_by_class(ui_layer, "NPCInfoPanel")
	return null


func _find_node_by_class(node: Node, class_name_str: String) -> Control:
	if node.get_class() == class_name_str or (node.get_script() and node.get_script().get_global_name() == class_name_str):
		return node as Control
	for child in node.get_children():
		var result = _find_node_by_class(child, class_name_str)
		if result:
			return result
	return null


func _input(event: InputEvent) -> void:
	if not _camera:
		return
	
	# Handle keyboard for NPC cycling
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_BRACKETLEFT:  # [ - previous NPC
				_data_store.cycle_selection(-1)
				get_viewport().set_input_as_handled()
			KEY_BRACKETRIGHT:  # ] - next NPC
				_data_store.cycle_selection(1)
				get_viewport().set_input_as_handled()
	
	# Handle mouse click for NPC selection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)


func _handle_click(screen_pos: Vector2) -> void:
	# Don't process click if it's on UI
	# NOTE: On web, gui_get_hovered_control() can return false positives.
	# We check if the hovered control is a real interactive element (not just a container).
	var viewport = get_viewport()
	if viewport:
		var hovered = viewport.gui_get_hovered_control()
		if hovered and _is_interactive_control(hovered):
			return  # Click was on actual UI element, ignore
	
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


## Check if a control is actually interactive (button, panel with content, etc.)
## Returns false for layout containers that shouldn't block clicks.
func _is_interactive_control(control: Control) -> bool:
	if not control:
		return false
	
	# Check mouse filter - IGNORE means it shouldn't block
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	
	# PASS means it passes to children but doesn't block
	if control.mouse_filter == Control.MOUSE_FILTER_PASS:
		return false
	
	# Interactive types that should block clicks
	if control is Button or control is LineEdit or control is TextEdit:
		return true
	if control is ScrollContainer or control is ProgressBar:
		return true
	if control is PanelContainer and control.visible:
		# Only block if the panel has visible content
		return control.get_child_count() > 0
	
	# Default: check if control has meaningful size and is set to stop mouse
	if control.mouse_filter == Control.MOUSE_FILTER_STOP:
		return control.size.x > 10 and control.size.y > 10
	
	return false
