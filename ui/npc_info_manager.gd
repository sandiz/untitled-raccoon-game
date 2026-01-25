class_name NPCInfoManager
extends Node
## Manages NPC info panel display based on player look direction or proximity.
## Includes debounce to prevent rapid switching.

@export var info_panel_path: NodePath
@export var camera_path: NodePath
@export var player_path: NodePath
@export var max_distance: float = 15.0
@export var show_on_proximity: bool = true
@export var proximity_distance: float = 5.0
@export var switch_delay: float = 0.5  # Seconds before switching to new NPC

var _info_panel: NPCInfoPanel
var _camera: Camera3D
var _player: Node3D
var _current_target: Node3D = null
var _pending_target: Node3D = null
var _pending_timer: float = 0.0


func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	_info_panel = get_node_or_null(info_panel_path)
	_camera = get_node_or_null(camera_path)
	_player = get_node_or_null(player_path)
	
	if not _info_panel:
		push_warning("NPCInfoManager: info_panel_path not set or invalid: %s" % info_panel_path)
	if not _camera:
		push_warning("NPCInfoManager: camera_path not set or invalid: %s" % camera_path)
	if not _player:
		push_warning("NPCInfoManager: player_path not set: %s" % player_path)


func _process(delta: float) -> void:
	if not _camera or not _info_panel:
		return
	
	var target = _find_target_npc()
	
	# Debounce logic to prevent rapid switching
	if target != _current_target:
		if target == _pending_target:
			# Same pending target - accumulate time
			_pending_timer += delta
			if _pending_timer >= switch_delay:
				_switch_to_target(target)
		else:
			# New pending target - reset timer
			_pending_target = target
			_pending_timer = 0.0
	else:
		# Current target is stable - clear pending
		_pending_target = null
		_pending_timer = 0.0


func _switch_to_target(target: Node3D) -> void:
	_current_target = target
	_pending_target = null
	_pending_timer = 0.0
	
	if target:
		_info_panel.show_npc(target)
	else:
		_info_panel.hide_panel()


func _find_target_npc() -> Node3D:
	# Method 1: Raycast from camera center
	var viewport = get_viewport()
	if not viewport:
		return null
	
	var screen_center = viewport.get_visible_rect().size / 2.0
	var from = _camera.project_ray_origin(screen_center)
	var to = from + _camera.project_ray_normal(screen_center) * max_distance
	
	var space_state = _camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # NPC collision layer
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		var npc = _find_npc_parent(result.collider)
		if npc:
			return npc
	
	# Method 2: Check proximity to player
	if show_on_proximity and _player:
		var closest_npc: Node3D = null
		var closest_dist: float = proximity_distance
		
		for npc in get_tree().get_nodes_in_group("npc"):
			if not npc is Node3D:
				continue
			var dist = _player.global_position.distance_to(npc.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_npc = npc
		
		return closest_npc
	
	return null


func _find_npc_parent(node: Node) -> Node3D:
	while node:
		if node.is_in_group("npc"):
			return node as Node3D
		node = node.get_parent()
	return null
