class_name PerceptionRange
extends Node3D
## Shows NPC vision/hearing range as ground indicators.
## Vision = cone in front, Hearing = full circle.
## Fades in on selection, fades out on deselection. Toggle with V key.

@export var npc_id: String = ""  # Set by parent to identify which NPC this belongs to
@export var vision_range: float = 10.0
@export var vision_angle: float = 90.0  # Degrees, total arc
@export var hearing_range: float = 10.0  # Same as vision
@export var vision_start_offset: float = 1.0  # Start cone 1m ahead of feet
@export var vision_color: Color = Color(0.2, 0.75, 0.3, 0.5)  # Vivid green (idle)
@export var vision_outline_color: Color = Color(0.1, 0.6, 0.2, 0.9)  # Strong green outline
@export var hearing_color: Color = Color(0.6, 0.2, 0.7, 0.5)  # Vivid violet - contrasts with green
@export var show_hearing: bool = true
@export var fade_duration: float = 0.25  # How long fade takes

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
var _visible: bool = true  # V key toggle
var _is_selected: bool = false
var _fade_tween: Tween
var _current_alpha: float = 0.0  # Start hidden

# Store target alphas for each material
var _vision_target_alpha: float = 0.5
var _outline_target_alpha: float = 0.9
var _hearing_target_alpha: float = 0.4  # Increased for visibility


func _ready() -> void:
	if show_hearing:
		_create_hearing_circle()
	_create_vision_cone()
	_create_vision_outline()
	
	# Start fully transparent
	_set_alpha(0.0)
	
	# Connect to selection changes
	var data_store = NPCDataStore.get_instance()
	if data_store:
		data_store.selection_changed.connect(_on_selection_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		_visible = not _visible
		_update_visibility()


func _create_hearing_circle() -> void:
	_hearing_mesh = MeshInstance3D.new()
	
	# Use ImmediateMesh like vision cone for consistency
	var mesh = ImmediateMesh.new()
	_hearing_mesh.mesh = mesh
	_hearing_mesh.position.y = 0.01  # Below vision cone
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = hearing_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.render_priority = -1  # Render BEFORE vision cone (behind)
	_hearing_mesh.material_override = mat
	
	_update_hearing_circle_mesh()
	add_child(_hearing_mesh)


func _update_hearing_circle_mesh() -> void:
	var mesh = _hearing_mesh.mesh as ImmediateMesh
	if not mesh:
		return
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var segments = 64  # Smooth circle
	var center = Vector3.ZERO
	
	# Fan triangles from center to edge (CCW = faces up)
	for i in range(segments):
		var angle1 = TAU * i / segments
		var angle2 = TAU * (i + 1) / segments
		
		var edge1 = Vector3(cos(angle1) * hearing_range, 0, sin(angle1) * hearing_range)
		var edge2 = Vector3(cos(angle2) * hearing_range, 0, sin(angle2) * hearing_range)
		
		# CCW winding: center -> edge1 -> edge2 (faces up)
		mesh.surface_add_vertex(center)
		mesh.surface_add_vertex(edge1)
		mesh.surface_add_vertex(edge2)
	
	mesh.surface_end()


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
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.render_priority = 0  # Render AFTER hearing (on top)
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
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.render_priority = 1  # Render last (outline on very top)
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
		
		# Triangle 1: inner1 -> outer2 -> outer1 (CCW from above = faces up)
		mesh.surface_add_vertex(inner1)
		mesh.surface_add_vertex(outer2)
		mesh.surface_add_vertex(outer1)
		
		# Triangle 2: inner1 -> inner2 -> outer2 (CCW from above = faces up)
		mesh.surface_add_vertex(inner1)
		mesh.surface_add_vertex(inner2)
		mesh.surface_add_vertex(outer2)
	
	mesh.surface_end()


func _update_visibility() -> void:
	if _vision_mesh:
		_vision_mesh.visible = _visible and _is_selected
	if _vision_outline:
		_vision_outline.visible = _visible and _is_selected
	if _hearing_mesh:
		_hearing_mesh.visible = _visible and show_hearing and _is_selected


func _set_alpha(alpha: float) -> void:
	_current_alpha = alpha
	
	if _vision_mesh and _vision_mesh.material_override:
		var color = _vision_mesh.material_override.albedo_color
		color.a = _vision_target_alpha * alpha
		_vision_mesh.material_override.albedo_color = color
	
	if _vision_outline and _vision_outline.material_override:
		var color = _vision_outline.material_override.albedo_color
		color.a = _outline_target_alpha * alpha
		_vision_outline.material_override.albedo_color = color
	
	if _hearing_mesh and _hearing_mesh.material_override:
		var color = _hearing_mesh.material_override.albedo_color
		color.a = _hearing_target_alpha * alpha
		_hearing_mesh.material_override.albedo_color = color


func _fade_to(target_alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_alpha, _current_alpha, target_alpha, fade_duration)


func _on_selection_changed(selected_ids: Array) -> void:
	var was_selected = _is_selected
	_is_selected = npc_id in selected_ids
	
	if _is_selected and not was_selected:
		# Just selected - fade in
		_update_visibility()
		_fade_to(1.0)
	elif not _is_selected and was_selected:
		# Just deselected - fade out
		_fade_to(0.0)


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
	
	# Store target alphas from the state colors
	_vision_target_alpha = fill_color.a
	_outline_target_alpha = outline_color.a
	
	# Apply colors (alpha will be modulated by _current_alpha)
	if _vision_mesh and _vision_mesh.material_override:
		fill_color.a = _vision_target_alpha * _current_alpha
		_vision_mesh.material_override.albedo_color = fill_color
	
	if _vision_outline and _vision_outline.material_override:
		outline_color.a = _outline_target_alpha * _current_alpha
		_vision_outline.material_override.albedo_color = outline_color
