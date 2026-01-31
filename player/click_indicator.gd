class_name ClickIndicator
extends Node3D
## Cute animated click-to-move indicator
## Shows a shrinking ring with fade-out effect when player clicks to move

const RING_SEGMENTS := 32
const RING_INNER_RADIUS := 0.3
const RING_OUTER_RADIUS := 0.4

## Animation settings
@export var duration := 0.8  # How long the animation lasts
@export var start_scale := 1.5  # Initial scale
@export var end_scale := 0.3  # Final scale (shrinks down)

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _tween: Tween


func _ready() -> void:
	_create_ring_mesh()


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
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides
	_material.albedo_color = Color(1.0, 0.85, 0.5, 0.9)  # Warm golden yellow
	_material.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = _material
	
	# Build the ring geometry
	_build_ring(mesh)
	
	# Position flat on ground, slightly above to avoid z-fighting
	_mesh_instance.position.y = 0.02
	_mesh_instance.rotation_degrees.x = -90  # Flat on XZ plane
	
	add_child(_mesh_instance)
	visible = false


func _build_ring(mesh: ImmediateMesh) -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	# Create ring with gradient alpha (brighter at outer edge)
	for i in range(RING_SEGMENTS + 1):
		var angle := float(i) / RING_SEGMENTS * TAU
		var cos_a := cos(angle)
		var sin_a := sin(angle)
		
		# Outer vertex (brighter)
		var outer_color := Color(1.0, 0.9, 0.55, 0.95)
		mesh.surface_set_color(outer_color)
		mesh.surface_add_vertex(Vector3(cos_a * RING_OUTER_RADIUS, sin_a * RING_OUTER_RADIUS, 0))
		
		# Inner vertex (more transparent for soft edge)
		var inner_color := Color(1.0, 0.75, 0.3, 0.4)
		mesh.surface_set_color(inner_color)
		mesh.surface_add_vertex(Vector3(cos_a * RING_INNER_RADIUS, sin_a * RING_INNER_RADIUS, 0))
	
	mesh.surface_end()


## Show the indicator at the given world position with animation
func show_at(pos: Vector3) -> void:
	# Kill any existing animation
	if _tween and _tween.is_valid():
		_tween.kill()
	
	# Position at click location
	global_position = pos
	
	# Reset state
	visible = true
	scale = Vector3.ONE * start_scale
	_material.albedo_color.a = 1.0
	
	# Create shrink + fade animation
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	
	# Shrink down
	_tween.tween_property(self, "scale", Vector3.ONE * end_scale, duration)
	
	# Fade out (slightly delayed start for better feel)
	_tween.tween_property(_material, "albedo_color:a", 0.0, duration * 0.7).set_delay(duration * 0.3)
	
	# Hide when done
	_tween.chain().tween_callback(func(): visible = false)


## Immediately hide the indicator
func hide_indicator() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	visible = false
