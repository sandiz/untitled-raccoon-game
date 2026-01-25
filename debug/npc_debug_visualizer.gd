extends Node3D
## 3D Debug Visualizer for NPC perception systems.
## Toggle with F3 (same as debug overlay).

# ═══════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════

@export var fov_color: Color = Color(0.2, 1.0, 0.2, 0.25)  # Green when idle
@export var fov_alert_color: Color = Color(1.0, 0.5, 0.0, 0.35)  # Orange when tracking
@export var sight_line_color: Color = Color(1.0, 0.0, 0.0, 0.8)
@export var hearing_ring_color: Color = Color(0.0, 0.8, 1.0, 0.15)

# ═══════════════════════════════════════
# INTERNAL STATE
# ═══════════════════════════════════════

var enabled: bool = true
var _parent_npc: Node3D = null
var _perception = null
var _social = null

# Mesh instances for visualization
var _fov_mesh: MeshInstance3D = null
var _hearing_mesh: MeshInstance3D = null
var _sight_lines: Array[Node3D] = []

# Materials
var _fov_material: StandardMaterial3D = null
var _fov_alert_material: StandardMaterial3D = null
var _sight_line_material: StandardMaterial3D = null
var _hearing_material: StandardMaterial3D = null

func _ready() -> void:
	# Get parent NPC and its systems
	_parent_npc = get_parent()
	_perception = _parent_npc.get("perception")
	_social = _parent_npc.get("social")
	
	# Create materials
	_create_materials()
	
	# Create visualization meshes
	_create_fov_mesh()
	_create_hearing_mesh()
	
	# Initially visible (debug on by default)
	visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		toggle()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle()

func _process(_delta: float) -> void:
	if not enabled or not _parent_npc:
		return
	
	_update_visualizations()

func toggle() -> void:
	enabled = not enabled
	visible = enabled

# ═══════════════════════════════════════
# MATERIAL CREATION
# ═══════════════════════════════════════

func _create_materials() -> void:
	# FOV cone material (green - idle)
	_fov_material = StandardMaterial3D.new()
	_fov_material.albedo_color = fov_color
	_fov_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fov_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fov_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# FOV alert material (orange - tracking)
	_fov_alert_material = StandardMaterial3D.new()
	_fov_alert_material.albedo_color = fov_alert_color
	_fov_alert_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fov_alert_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fov_alert_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Sight line material
	_sight_line_material = StandardMaterial3D.new()
	_sight_line_material.albedo_color = sight_line_color
	_sight_line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sight_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Hearing ring material
	_hearing_material = StandardMaterial3D.new()
	_hearing_material.albedo_color = hearing_ring_color
	_hearing_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hearing_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hearing_material.cull_mode = BaseMaterial3D.CULL_DISABLED

# ═══════════════════════════════════════
# MESH CREATION
# ═══════════════════════════════════════

func _create_fov_mesh() -> void:
	if not _perception:
		return
	
	_fov_mesh = MeshInstance3D.new()
	_fov_mesh.name = "FOVCone"
	add_child(_fov_mesh)
	
	# Create cone mesh
	var mesh = _create_cone_mesh(
		_perception.sight_range,
		_perception.fov_angle,
		20  # More segments for smoother cone
	)
	_fov_mesh.mesh = mesh
	_fov_mesh.material_override = _fov_material

func _create_hearing_mesh() -> void:
	if not _perception:
		return
	
	_hearing_mesh = MeshInstance3D.new()
	_hearing_mesh.name = "HearingRing"
	add_child(_hearing_mesh)
	
	# Create a ring/torus for hearing range
	var mesh = _create_ring_mesh(_perception.hearing_range, 0.1)
	_hearing_mesh.mesh = mesh
	_hearing_mesh.material_override = _hearing_material

func _create_cone_mesh(length: float, angle_deg: float, segments: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Cap angle for visualization (avoid tan explosion)
	var half_angle = deg_to_rad(min(angle_deg, 120.0) / 2.0)
	
	# Apex at eye level (matches perception system)
	var apex = Vector3(0, 1.2, 0)
	verts.append(apex)
	
	# Create a flat horizontal wedge (pizza slice shape)
	# Only spreads left/right, stays at eye level
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = lerp(-half_angle, half_angle, t)
		var x = sin(angle) * length
		var z = cos(angle) * length
		verts.append(Vector3(x, 1.2, z))
	
	# Create triangles (fan from apex)
	for i in range(segments):
		indices.append(0)
		indices.append(i + 1)
		indices.append(i + 2)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _create_ring_mesh(radius: float, thickness: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var segments = 32
	
	# Create outer and inner circle at ground level
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		var outer_x = cos(angle) * radius
		var outer_z = sin(angle) * radius
		var inner_x = cos(angle) * (radius - thickness)
		var inner_z = sin(angle) * (radius - thickness)
		
		verts.append(Vector3(outer_x, 0.05, outer_z))
		verts.append(Vector3(inner_x, 0.05, inner_z))
	
	# Create quad strip
	for i in range(segments):
		var base = i * 2
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

# ═══════════════════════════════════════
# VISUALIZATION UPDATES
# ═══════════════════════════════════════

func _update_visualizations() -> void:
	# Update FOV cone color based on tracking state
	_update_fov_color()
	
	# Update sight lines to tracked targets
	_update_sight_lines()
	
	# Pulse hearing ring based on recent sounds
	_update_hearing_ring()

func _update_fov_color() -> void:
	if not _perception:
		return
	
	# Check visibility for all players
	var is_seeing_target = false
	var is_investigating = false
	var players = get_tree().get_nodes_in_group("player")
	
	for player in players:
		if is_instance_valid(player):
			var visibility = _perception.check_target_visibility(player)
			if visibility.visible:
				is_seeing_target = true
	
	# Check if investigating (heard recent sounds or has elevated alertness)
	if _perception.recent_sounds.size() > 0:
		is_investigating = true
	
	# Also check emotional state for alertness (must be clearly elevated)
	var emotional_state = _parent_npc.get("emotional_state")
	if emotional_state and emotional_state.alertness > 0.5:
		is_investigating = true
	
	# Update main FOV cone color: green (idle) -> orange (seeing/investigating)
	if _fov_mesh:
		if is_seeing_target or is_investigating:
			_fov_mesh.material_override = _fov_alert_material
		else:
			_fov_mesh.material_override = _fov_material

func _update_sight_lines() -> void:
	# Clear old lines
	for line in _sight_lines:
		line.queue_free()
	_sight_lines.clear()
	
	if not _perception:
		return
	
	# Draw lines to tracked targets if currently visible
	var debug_info = _perception.get_debug_info()
	for target_info in debug_info.tracked_targets:
		if target_info.awareness > 0.1:
			# Find the actual target node
			var targets = get_tree().get_nodes_in_group("player")
			for target in targets:
				if is_instance_valid(target) and target.name == target_info.name:
					var visibility = _perception.check_target_visibility(target)
					if visibility.visible:
						var target_top = target.global_position + Vector3(0, 1.2, 0)
						_draw_sight_line(target_top, target_info.awareness)
					break

func _draw_sight_line(target_pos: Vector3, awareness: float) -> void:
	var eye_pos = Vector3(0, 1.2, 0)  # Local eye position
	var local_target = _parent_npc.to_local(target_pos)
	
	# Create thick beam using cylinder
	var line = MeshInstance3D.new()
	line.name = "SightLine"
	add_child(line)
	_sight_lines.append(line)
	
	# Thin line thickness
	var thickness = 0.01 + awareness * 0.02  # 0.01 to 0.03
	var mesh = _create_beam_mesh(eye_pos, local_target, thickness)
	line.mesh = mesh
	
	# Color based on awareness - yellow to orange to red
	var mat = _sight_line_material.duplicate()
	if awareness < 0.5:
		mat.albedo_color = Color(1.0, 1.0, 0.0, 0.6)  # Yellow - glimpse
	elif awareness < 1.0:
		mat.albedo_color = Color(1.0, 0.5, 0.0, 0.8)  # Orange - noticing
	else:
		mat.albedo_color = Color(1.0, 0.0, 0.0, 1.0)  # Bright red - LOCKED ON
	line.material_override = mat
	
	# Add "LOCKED" indicator when fully aware
	if awareness >= 1.0:
		_add_locked_indicator(local_target)

func _create_line_mesh(from: Vector3, to: Vector3) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	verts.append(from)
	verts.append(to)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func _create_beam_mesh(from: Vector3, to: Vector3, thickness: float) -> ArrayMesh:
	# Create a cylinder beam between two points
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var direction = (to - from).normalized()
	var _length = from.distance_to(to)
	
	# Find perpendicular vectors for cylinder
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.9:
		up = Vector3.RIGHT
	var right = direction.cross(up).normalized() * thickness
	var forward = direction.cross(right).normalized() * thickness
	
	var segments = 6
	# Create cylinder vertices
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		var offset = right * cos(angle) + forward * sin(angle)
		verts.append(from + offset)
		verts.append(to + offset)
	
	# Create triangles
	for i in range(segments):
		var curr = i * 2
		var next = ((i + 1) % segments) * 2
		# Two triangles per segment
		indices.append(curr)
		indices.append(curr + 1)
		indices.append(next)
		
		indices.append(next)
		indices.append(curr + 1)
		indices.append(next + 1)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _add_locked_indicator(_target_local: Vector3) -> void:
	# Floating "!" alert above NPC's head
	var label = Label3D.new()
	label.name = "LockedIndicator"
	add_child(label)
	_sight_lines.append(label)  # Reuse array for cleanup
	
	label.text = "!"
	label.font_size = 128
	label.position = Vector3(0, 2.3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	label.outline_modulate = Color(0.3, 0, 0, 1.0)
	label.outline_size = 12
	
	# Add a small background panel effect with another label
	var bg = Label3D.new()
	bg.name = "LockedBG"
	add_child(bg)
	_sight_lines.append(bg)
	
	bg.text = "●"
	bg.font_size = 200
	bg.position = Vector3(0, 2.3, 0.01)
	bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bg.no_depth_test = true
	bg.modulate = Color(1.0, 0.9, 0.0, 0.9)  # Yellow background

func _update_hearing_ring() -> void:
	if not _hearing_mesh or not _perception:
		return
	
	# Pulse based on recent sounds
	var debug_info = _perception.get_debug_info()
	if debug_info.recent_sounds > 0:
		_hearing_material.albedo_color.a = 0.3
	else:
		_hearing_material.albedo_color.a = 0.1
