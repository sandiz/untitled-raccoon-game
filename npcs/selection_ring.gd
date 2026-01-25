class_name SelectionRing
extends Node3D
## Visual ring indicator for selected NPCs.

@export var ring_color: Color = Color(0.4, 0.9, 1.0, 0.8)
@export var ring_size: float = 2.0
@export var height_offset: float = 0.05

var _mesh: MeshInstance3D
var _material: ShaderMaterial
var _visible: bool = false
var _tween: Tween


func _ready() -> void:
	_setup_ring()
	hide_ring()


func _setup_ring() -> void:
	# Create plane mesh for the ring
	_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(ring_size, ring_size)
	_mesh.mesh = plane
	_mesh.position.y = height_offset
	_mesh.rotation_degrees.x = 0  # Flat on ground
	_mesh.visible = false  # Start hidden
	add_child(_mesh)
	
	# Load and apply shader
	var shader = load("res://shaders/selection_ring.gdshader")
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("ring_color", ring_color)
	_mesh.material_override = _material


func show_ring() -> void:
	if _visible:
		return
	_visible = true
	_mesh.visible = true
	
	# Fade in
	if _tween:
		_tween.kill()
	_material.set_shader_parameter("ring_color", Color(ring_color.r, ring_color.g, ring_color.b, 0.0))
	_tween = create_tween()
	_tween.tween_method(_set_alpha, 0.0, ring_color.a, 0.2)


func hide_ring() -> void:
	if not _visible:
		return
	_visible = false
	
	# Fade out
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_alpha, ring_color.a, 0.0, 0.15)
	_tween.tween_callback(func(): _mesh.visible = false)


func _set_alpha(alpha: float) -> void:
	var c = ring_color
	c.a = alpha
	_material.set_shader_parameter("ring_color", c)


func set_color(color: Color) -> void:
	ring_color = color
	if _material:
		_material.set_shader_parameter("ring_color", color)
