class_name ClickIndicator
extends Node3D
## Cute animated click-to-move indicator
## Shows a ring on ground with bouncing arrow pointing down

const RING_SEGMENTS := 32
const RING_INNER_RADIUS := 0.4  # Match visual size of raccoon's selection ring
const RING_OUTER_RADIUS := 0.48

## Animation settings
@export var duration := 0.4  # Fade out duration

## Arrow bounce settings
@export var arrow_bounce_height := 0.5
@export var arrow_bounce_speed := 4.0
@export var arrow_base_height := 1.0

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _arrow: Node3D
var _arrow_material: StandardMaterial3D
var _tween: Tween
var _time := 0.0


func _ready() -> void:
	_create_ring_mesh()
	_create_arrow()


func _process(delta: float) -> void:
	if not visible:
		return
	
	# Bounce the arrow
	_time += delta
	if _arrow:
		var bounce := sin(_time * arrow_bounce_speed) * arrow_bounce_height
		_arrow.position.y = arrow_base_height + bounce
		# Debug every 60 frames
		if Engine.get_process_frames() % 60 == 0:
			print("[ClickIndicator] _time=", snapped(_time, 0.01), " bounce=", snapped(bounce, 0.01), " arrow.y=", snapped(_arrow.position.y, 0.01))


func _create_ring_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "RingMesh"
	
	# Create flat ring using ImmediateMesh for precise control
	var mesh := ImmediateMesh.new()
	_mesh_instance.mesh = mesh
	
	# Create unshaded material with transparency
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(1.0, 1.0, 1.0, 0.9)  # White - visible in all lighting
	_material.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = _material
	
	_build_ring(mesh)
	
	_mesh_instance.position.y = 0.02
	_mesh_instance.rotation_degrees.x = -90
	
	add_child(_mesh_instance)
	visible = false


func _build_ring(mesh: ImmediateMesh) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for i in range(RING_SEGMENTS + 1):
		var angle := float(i) / RING_SEGMENTS * TAU
		var cos_a := cos(angle)
		var sin_a := sin(angle)
		
		var outer_color := Color(1.0, 1.0, 1.0, 0.9)
		mesh.surface_set_color(outer_color)
		mesh.surface_add_vertex(Vector3(cos_a * RING_OUTER_RADIUS, sin_a * RING_OUTER_RADIUS, 0))
		
		var inner_color := Color(1.0, 1.0, 1.0, 0.3)
		mesh.surface_set_color(inner_color)
		mesh.surface_add_vertex(Vector3(cos_a * RING_INNER_RADIUS, sin_a * RING_INNER_RADIUS, 0))
	
	mesh.surface_end()


func _create_arrow() -> void:
	_arrow = Node3D.new()
	_arrow.name = "Arrow"
	
	# Arrow material - same golden color
	_arrow_material = StandardMaterial3D.new()
	_arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arrow_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # White
	
	# Arrow head (cone pointing down)
	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.2
	cone.height = 0.4
	cone.radial_segments = 8
	head.mesh = cone
	head.material_override = _arrow_material
	head.rotation_degrees.x = 180  # Point downward
	head.position.y = -0.2
	_arrow.add_child(head)
	
	# Arrow shaft (thin cylinder)
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.06
	cyl.height = 0.35
	cyl.radial_segments = 6
	shaft.mesh = cyl
	shaft.material_override = _arrow_material
	shaft.position.y = 0.17
	_arrow.add_child(shaft)
	
	_arrow.position.y = arrow_base_height
	add_child(_arrow)


func show_at(pos: Vector3) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	global_position = pos
	# Don't reset _time - preserve bounce phase across clicks
	
	# Immediately update arrow position to current bounce phase
	if _arrow:
		var bounce := sin(_time * arrow_bounce_speed) * arrow_bounce_height
		_arrow.position.y = arrow_base_height + bounce
		print("[ClickIndicator] show_at: _time=", snapped(_time, 0.01), " immediate bounce=", snapped(bounce, 0.01))
	
	visible = true
	scale = Vector3.ONE
	
	# Start transparent
	_material.albedo_color.a = 0.0
	_arrow_material.albedo_color.a = 0.0
	
	# Fade in animation
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	
	_tween.tween_property(_material, "albedo_color:a", 0.9, duration)
	_tween.tween_property(_arrow_material, "albedo_color:a", 1.0, duration)


func hide_indicator() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	# Fade out animation
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	
	_tween.tween_property(_material, "albedo_color:a", 0.0, duration)
	_tween.tween_property(_arrow_material, "albedo_color:a", 0.0, duration)
	
	_tween.chain().tween_callback(func(): visible = false)
