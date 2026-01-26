extends Camera3D
## Stable isometric-style follow camera.
## Follows raccoon by default, switches to NPC when selected.
## Smooth transition when switching targets, no yaw/pitch/zoom changes.

@export var target_path: NodePath
@export var distance: float = 14.0
@export var height: float = 12.0
@export var look_height_offset: float = -2.0
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.4
@export var zoom_smoothing: float = 8.0
@export var rotate_speed: float = 0.005
@export var rotate_smoothing: float = 8.0
@export var follow_smoothing: float = 8.0

var target: Node3D
var _default_target: Node3D
var current_zoom: float = 1.0  # Default zoom to show full hearing range (10m)
var target_zoom: float = 1.0
var current_angle: float = 0.0
var target_angle: float = 0.0
var is_dragging: bool = false

# Smoothed positions for stable camera
var _smooth_target_pos: Vector3 = Vector3.ZERO
var _initialized: bool = false


func _ready() -> void:
	if target_path:
		target = get_node_or_null(target_path)
	_default_target = target
	
	# Snap camera to target immediately on start
	if target:
		_snap_to_target()
	
	call_deferred("_connect_to_data_store")


func _snap_to_target() -> void:
	if not target:
		return
	_smooth_target_pos = target.global_position
	_initialized = true
	
	var zoomed_distance = distance * current_zoom
	var zoomed_height = height * current_zoom
	var offset = Vector3(
		sin(current_angle) * zoomed_distance,
		zoomed_height,
		cos(current_angle) * zoomed_distance
	)
	global_position = _smooth_target_pos + offset
	look_at(_smooth_target_pos + Vector3(0, look_height_offset, 0), Vector3.UP)
	rotation.z = 0


func _connect_to_data_store() -> void:
	var data_store = NPCDataStore.get_instance()
	if data_store:
		data_store.selection_changed.connect(_on_selection_changed)


func _on_selection_changed(selected_ids: Array) -> void:
	var new_target: Node3D = null
	
	if selected_ids.is_empty():
		new_target = _default_target
	else:
		var data_store = NPCDataStore.get_instance()
		new_target = data_store.get_npc_node(selected_ids[0])
	
	if new_target:
		target = new_target
		# Don't reset _smooth_target_pos - let it lerp naturally


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - zoom_speed * 0.2, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + zoom_speed * 0.2, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.pressed
	
	if event is InputEventMouseMotion and is_dragging:
		target_angle -= event.relative.x * rotate_speed
	
	if event is InputEventPanGesture:
		target_angle -= event.delta.x * rotate_speed * 10.0
	
	if event is InputEventMagnifyGesture:
		target_zoom = clamp(target_zoom / event.factor, min_zoom, max_zoom)


func _process(delta: float) -> void:
	if not target:
		return
	
	# Initialize smooth position on first frame
	if not _initialized:
		_smooth_target_pos = target.global_position
		_initialized = true
	
	# Smooth the target position (this handles target switching smoothly)
	_smooth_target_pos = _smooth_target_pos.lerp(target.global_position, delta * follow_smoothing)
	
	# Smooth zoom
	current_zoom = lerp(current_zoom, target_zoom, delta * zoom_smoothing)
	
	# Smooth rotation
	current_angle = lerp_angle(current_angle, target_angle, delta * rotate_smoothing)
	
	# Calculate camera position from smoothed target
	var zoomed_distance = distance * current_zoom
	var zoomed_height = height * current_zoom
	
	var offset = Vector3(
		sin(current_angle) * zoomed_distance,
		zoomed_height,
		cos(current_angle) * zoomed_distance
	)
	
	# Camera follows the smoothed target position
	global_position = _smooth_target_pos + offset
	
	# Look at smoothed target position (not actual target - prevents pitch wobble)
	look_at(_smooth_target_pos + Vector3(0, look_height_offset, 0), Vector3.UP)
	rotation.z = 0
