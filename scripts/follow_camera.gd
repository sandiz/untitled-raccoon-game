extends Camera3D

@export var target_path: NodePath
@export var distance: float = 14.0
@export var height: float = 12.0
@export var look_height_offset: float = -2.0  # Look down more at target
@export var smoothing: float = 5.0
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.4
@export var zoom_smoothing: float = 8.0
@export var rotate_speed: float = 0.005
@export var rotate_smoothing: float = 8.0

var target: Node3D
var _default_target: Node3D  # The raccoon/player
var current_zoom: float = 1.0
var target_zoom: float = 1.0
var current_angle: float = 0.0
var target_angle: float = 0.0
var is_dragging: bool = false

func _ready() -> void:
	if target_path:
		target = get_node_or_null(target_path)
	_default_target = target
	
	# Connect to NPC selection changes
	call_deferred("_connect_to_data_store")


func _connect_to_data_store() -> void:
	var data_store = NPCDataStore.get_instance()
	if data_store:
		data_store.selection_changed.connect(_on_selection_changed)


func _on_selection_changed(selected_ids: Array) -> void:
	var new_target: Node3D = null
	
	if selected_ids.is_empty():
		# No NPC selected - follow raccoon/player
		new_target = _default_target
		print("[Camera] Following player")
	else:
		# Follow selected NPC
		var data_store = NPCDataStore.get_instance()
		new_target = data_store.get_npc_node(selected_ids[0])
		if new_target:
			print("[Camera] Following NPC: ", selected_ids[0])
	
	if new_target and new_target != target:
		# Calculate angle to maintain camera position relative to new target
		var cam_pos = global_position
		var new_target_pos = new_target.global_position
		var dir_to_cam = cam_pos - new_target_pos
		dir_to_cam.y = 0  # Ignore height for yaw calculation
		
		if dir_to_cam.length() > 0.1:
			# Calculate the angle from target to camera
			var new_angle = atan2(dir_to_cam.x, dir_to_cam.z)
			target_angle = new_angle
			current_angle = new_angle
		
		target = new_target

func _input(event: InputEvent) -> void:
	# Mouse scroll wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - zoom_speed * 0.2, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + zoom_speed * 0.2, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.pressed
	
	# Mouse drag to rotate
	if event is InputEventMouseMotion and is_dragging:
		target_angle -= event.relative.x * rotate_speed
	
	# Touch pan to rotate (two finger swipe)
	if event is InputEventPanGesture:
		target_angle -= event.delta.x * rotate_speed * 10.0
	
	# Pinch to zoom
	if event is InputEventMagnifyGesture:
		target_zoom = clamp(target_zoom / event.factor, min_zoom, max_zoom)

func _process(delta: float) -> void:
	if not target:
		return
	
	# Smooth zoom interpolation
	current_zoom = lerp(current_zoom, target_zoom, delta * zoom_smoothing)
	
	# Smooth rotation interpolation
	current_angle = lerp_angle(current_angle, target_angle, delta * rotate_smoothing)
	
	# Calculate orbital position
	var zoomed_distance = distance * current_zoom
	var zoomed_height = height * current_zoom
	
	var offset = Vector3(
		sin(current_angle) * zoomed_distance,
		zoomed_height,
		cos(current_angle) * zoomed_distance
	)
	
	var target_pos = target.global_position + offset
	global_position = global_position.lerp(target_pos, delta * smoothing)
	
	# Always look at target (slightly below center to pitch camera down)
	look_at(target.global_position + Vector3(0, look_height_offset, 0), Vector3.UP)
