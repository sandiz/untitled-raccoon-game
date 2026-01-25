class_name GhibliShaderApplier
extends Node
## Utility to apply Ghibli-style toon shading and outlines to character meshes.
## Attach to any parent node containing MeshInstance3D children.

@export var apply_toon_shader: bool = true
@export var apply_outline: bool = true
@export var outline_color: Color = Color(0.15, 0.1, 0.1, 1.0)
@export var outline_width: float = 0.025
@export var enable_rim_light: bool = true

var _outline_shader: Shader
var _toon_shader: Shader

func _ready() -> void:
	# Load shaders
	_outline_shader = load("res://shaders/outline.gdshader")
	_toon_shader = load("res://shaders/toon.gdshader")
	
	# Apply to all mesh instances in parent
	var parent = get_parent()
	if parent:
		_apply_to_node_recursive(parent)


func _apply_to_node_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_shaders_to_mesh(node)
	
	for child in node.get_children():
		_apply_to_node_recursive(child)


func _apply_shaders_to_mesh(mesh_instance: MeshInstance3D) -> void:
	var mesh = mesh_instance.mesh
	if not mesh:
		return
	
	var surface_count = mesh.get_surface_count()
	
	for i in range(surface_count):
		var original_material = mesh_instance.get_surface_override_material(i)
		if not original_material:
			original_material = mesh.surface_get_material(i)
		
		if apply_toon_shader:
			# Create toon material based on original
			var toon_mat = _create_toon_material(original_material)
			
			if apply_outline:
				# Add outline as next_pass
				toon_mat.next_pass = _create_outline_material()
			
			mesh_instance.set_surface_override_material(i, toon_mat)
		elif apply_outline:
			# Just add outline to existing material
			var mat = original_material.duplicate() if original_material else StandardMaterial3D.new()
			mat.next_pass = _create_outline_material()
			mesh_instance.set_surface_override_material(i, mat)


func _create_toon_material(original: Material) -> ShaderMaterial:
	var toon_mat = ShaderMaterial.new()
	toon_mat.shader = _toon_shader
	
	# Extract color from original material if possible
	var base_color = Color.WHITE
	if original is StandardMaterial3D:
		base_color = original.albedo_color
		if original.albedo_texture:
			toon_mat.set_shader_parameter("albedo_texture", original.albedo_texture)
			toon_mat.set_shader_parameter("use_texture", true)
	
	toon_mat.set_shader_parameter("base_color", base_color)
	toon_mat.set_shader_parameter("shadow_threshold", 0.3)
	toon_mat.set_shader_parameter("light_threshold", 0.7)
	toon_mat.set_shader_parameter("shadow_color", Color(0.6, 0.5, 0.6, 1.0))
	toon_mat.set_shader_parameter("highlight_color", Color(1.0, 1.0, 0.95, 1.0))
	toon_mat.set_shader_parameter("enable_rim", enable_rim_light)
	toon_mat.set_shader_parameter("rim_color", Color(1.0, 0.95, 0.9, 1.0))
	toon_mat.set_shader_parameter("rim_power", 3.0)
	toon_mat.set_shader_parameter("rim_intensity", 0.3)
	
	return toon_mat


func _create_outline_material() -> ShaderMaterial:
	var outline_mat = ShaderMaterial.new()
	outline_mat.shader = _outline_shader
	outline_mat.render_priority = -1
	outline_mat.set_shader_parameter("outline_color", outline_color)
	outline_mat.set_shader_parameter("outline_width", outline_width)
	return outline_mat
