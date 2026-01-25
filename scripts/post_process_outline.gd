class_name PostProcessOutline
extends MeshInstance3D
## Post-process outline effect using depth/normal edge detection.
## Add as child of Camera3D.

@export var outline_color: Color = Color(0.15, 0.1, 0.1, 1.0)
@export var outline_thickness: float = 1.0
@export var depth_threshold: float = 0.1
@export var normal_threshold: float = 0.3

var _material: ShaderMaterial


func _ready() -> void:
	_setup_quad()


func _setup_quad() -> void:
	# Create fullscreen quad
	var quad = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	quad.flip_faces = true
	mesh = quad
	
	# Position in front of camera (clip space coords)
	position = Vector3(0, 0, -1)
	
	# Extra cull margin to prevent culling
	extra_cull_margin = 16384
	
	# Load shader and create material
	var shader = load("res://shaders/post_outline.gdshader")
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("outline_color", outline_color)
	_material.set_shader_parameter("outline_thickness", outline_thickness)
	_material.set_shader_parameter("depth_threshold", depth_threshold)
	_material.set_shader_parameter("normal_threshold", normal_threshold)
	
	material_override = _material


func set_outline_color(color: Color) -> void:
	outline_color = color
	if _material:
		_material.set_shader_parameter("outline_color", color)


func set_thickness(thickness: float) -> void:
	outline_thickness = thickness
	if _material:
		_material.set_shader_parameter("outline_thickness", thickness)
