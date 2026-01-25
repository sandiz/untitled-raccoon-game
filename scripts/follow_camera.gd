extends Camera3D

@export var target_path: NodePath
@export var distance: float = 15.0
@export var height: float = 12.0
@export var smoothing: float = 5.0
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.8
@export var zoom_smoothing: float = 8.0
@export var rotate_speed: float = 0.005
@export var rotate_smoothing: float = 8.0

var target: Node3D
var current_zoom: float = 1.0
var target_zoom: float = 1.0
var current_angle: float = 0.0
var target_angle: float = 0.0
var is_dragging: bool = false

func _ready() -> void:
	if target_path:
		target = get_node_or_null(target_path)

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
	
	# Always look at target
	look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)
