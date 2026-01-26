class_name PerceptionRange
extends Node3D
## Shows NPC vision/hearing range as ground indicators.
## Vision = cone in front, Hearing = full circle.
## Toggle with V key.

@export var vision_range: float = 10.0
@export var vision_angle: float = 90.0  # Degrees, total arc
@export var hearing_range: float = 10.0  # Same as vision
@export var vision_start_offset: float = 1.0  # Start cone 1m ahead of feet
@export var vision_color: Color = Color(0.2, 0.75, 0.3, 0.5)  # Vivid green (idle)
@export var vision_outline_color: Color = Color(0.1, 0.6, 0.2, 0.9)  # Strong green outline
@export var hearing_color: Color = Color(0.6, 0.2, 0.7, 0.25)  # Vivid violet - contrasts with green
@export var show_hearing: bool = true

# State colors - more saturated for daytime visibility
const STATE_COLORS := {
	"idle": Color(0.2, 0.75, 0.3, 0.5),        # Vivid green
	"curious": Color(1.0, 0.8, 0.1, 0.55),     # Bright amber
	"suspicious": Color(1.0, 0.8, 0.1, 0.55),  # Bright amber
	"alert": Color(1.0, 0.5, 0.0, 0.6),        # Bright orange
	"investigating": Color(1.0, 0.5, 0.0, 0.6),# Bright orange
	"chasing": Color(1.0, 0.15, 0.1, 0.65),    # Bright red
}

const STATE_OUTLINE_COLORS := {
	"idle": Color(0.1, 0.6, 0.2, 0.9),         # Strong green
	"curious": Color(1.0, 0.65, 0.0, 0.95),    # Strong amber
	"suspicious": Color(1.0, 0.65, 0.0, 0.95), # Strong amber
	"alert": Color(1.0, 0.4, 0.0, 0.95),       # Strong orange
	"investigating": Color(1.0, 0.4, 0.0, 0.95), # Strong orange
	"chasing": Color(1.0, 0.1, 0.05, 1.0),     # Strong red
}

var _vision_mesh: MeshInstance3D
var _vision_outline: MeshInstance3D
var _hearing_mesh: MeshInstance3D
var _visible: bool = true


func _ready() -> void:
	_create_hearing_circle()
	_create_vision_cone()
	_create_vision_outline()
	_update_visibility()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		_visible = not _visible
		_update_visibility()


func _create_hearing_circle() -> void:
	_hearing_mesh = MeshInstance3D.new()
	
	var mesh = CylinderMesh.new()
	mesh.top_radius = hearing_range
	mesh.bottom_radius = hearing_range
	mesh.height = 0.02
	mesh.radial_segments = 64  # High count for smooth circle
	
	_hearing_mesh.mesh = mesh
	_hearing_mesh.position.y = 0.01
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = hearing_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hearing_mesh.material_override = mat
	
	add_child(_hearing_mesh)


func _create_vision_cone() -> void:
	_vision_mesh = MeshInstance3D.new()
	
	# Create cone/wedge using ImmediateMesh
	var mesh = ImmediateMesh.new()
	_vision_mesh.mesh = mesh
	_vision_mesh.position.y = 0.03
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = vision_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_vision_mesh.material_override = mat
	
	_update_vision_cone_mesh()
	add_child(_vision_mesh)


func _create_vision_outline() -> void:
	_vision_outline = MeshInstance3D.new()
	
	var mesh = ImmediateMesh.new()
	_vision_outline.mesh = mesh
	_vision_outline.position.y = 0.04
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = vision_outline_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_vision_outline.material_override = mat
	
	_update_vision_outline_mesh()
	add_child(_vision_outline)


func _update_vision_outline_mesh() -> void:
	var mesh = _vision_outline.mesh as ImmediateMesh
	if not mesh:
		return
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var half_angle = deg_to_rad(vision_angle / 2.0)
	var segments = 48  # High count for smooth arc
	
	# Calculate left/right edge points at start offset (1m ahead of feet)
	var left_start = Vector3(sin(-half_angle) * vision_start_offset, 0, cos(-half_angle) * vision_start_offset)
	var right_start = Vector3(sin(half_angle) * vision_start_offset, 0, cos(half_angle) * vision_start_offset)
	
	# Start at left edge of the offset start
	mesh.surface_add_vertex(left_start)
	
	# Arc edge at full range
	for i in range(segments + 1):
		var angle = -half_angle + (half_angle * 2.0 * i / segments)
		var p = Vector3(sin(angle) * vision_range, 0, cos(angle) * vision_range)
		mesh.surface_add_vertex(p)
	
	# Back to right edge of the offset start
	mesh.surface_add_vertex(right_start)
	
	# Close the gap - draw line across the start arc
	mesh.surface_add_vertex(left_start)
	
	mesh.surface_end()


func _update_vision_cone_mesh() -> void:
	var mesh = _vision_mesh.mesh as ImmediateMesh
	if not mesh:
		return
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_angle = deg_to_rad(vision_angle / 2.0)
	var segments = 32  # High count for smooth arc
	
	# Create truncated cone (starts 1m ahead)
	# Draw triangles between inner arc (at offset) and outer arc (at range)
	for i in range(segments):
		var angle1 = -half_angle + (half_angle * 2.0 * i / segments)
		var angle2 = -half_angle + (half_angle * 2.0 * (i + 1) / segments)
		
		# Inner arc points (at start offset)
		var inner1 = Vector3(sin(angle1) * vision_start_offset, 0, cos(angle1) * vision_start_offset)
		var inner2 = Vector3(sin(angle2) * vision_start_offset, 0, cos(angle2) * vision_start_offset)
		
		# Outer arc points (at full range)
		var outer1 = Vector3(sin(angle1) * vision_range, 0, cos(angle1) * vision_range)
		var outer2 = Vector3(sin(angle2) * vision_range, 0, cos(angle2) * vision_range)
		
		# Triangle 1: inner1 -> outer1 -> outer2
		mesh.surface_add_vertex(inner1)
		mesh.surface_add_vertex(outer1)
		mesh.surface_add_vertex(outer2)
		
		# Triangle 2: inner1 -> outer2 -> inner2
		mesh.surface_add_vertex(inner1)
		mesh.surface_add_vertex(outer2)
		mesh.surface_add_vertex(inner2)
	
	mesh.surface_end()


func _update_visibility() -> void:
	if _vision_mesh:
		_vision_mesh.visible = _visible
	if _vision_outline:
		_vision_outline.visible = _visible
	if _hearing_mesh:
		_hearing_mesh.visible = _visible and show_hearing


func set_ranges(vision: float, hearing: float, angle: float = 90.0) -> void:
	vision_range = vision
	hearing_range = hearing
	vision_angle = angle
	
	if _hearing_mesh and _hearing_mesh.mesh is CylinderMesh:
		_hearing_mesh.mesh.top_radius = hearing
		_hearing_mesh.mesh.bottom_radius = hearing
	
	if _vision_mesh:
		_update_vision_cone_mesh()
	if _vision_outline:
		_update_vision_outline_mesh()


func set_state(state: String) -> void:
	## Update vision cone color based on NPC state
	if not STATE_COLORS.has(state):
		return
	
	var fill_color = STATE_COLORS[state]
	var outline_color = STATE_OUTLINE_COLORS[state]
	
	# Update vision cone fill
	if _vision_mesh and _vision_mesh.material_override:
		_vision_mesh.material_override.albedo_color = fill_color
	
	# Update vision cone outline
	if _vision_outline and _vision_outline.material_override:
		_vision_outline.material_override.albedo_color = outline_color
