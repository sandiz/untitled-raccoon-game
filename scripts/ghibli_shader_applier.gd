class_name GhibliShaderApplier
extends Node
## Utility to apply Ghibli-style toon shading to meshes.
## Can apply to parent's children or entire scene tree.
## Outlines are handled separately via post-process.

@export var apply_toon_shader: bool = true
@export var enable_rim_light: bool = true
@export var scene_wide: bool = false  ## Apply to entire scene tree instead of just parent
@export var watch_for_new: bool = true  ## Auto-apply to new meshes added to scene

## Mesh names to exclude (contains check)
var _exclude_names: Array[String] = [
	"floor", "ground", "terrain", "plane",
	"selection", "vision", "indicator", "ring",
	"sky", "water", "particle"
]

var _toon_shader: Shader


func _ready() -> void:
	_toon_shader = load("res://shaders/toon.gdshader")
	
	if scene_wide:
		call_deferred("_apply_scene_wide")
		
		if watch_for_new and not Engine.is_editor_hint():
			get_tree().node_added.connect(_on_node_added)
	else:
		var parent = get_parent()
		if parent:
			_apply_to_node_recursive(parent)


func _apply_scene_wide() -> void:
	var root = get_tree().current_scene
	if root:
		_apply_to_node_recursive(root)


func _on_node_added(node: Node) -> void:
	if node is MeshInstance3D:
		call_deferred("_try_apply_to_mesh", node)


func _try_apply_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if is_instance_valid(mesh_instance) and not _should_exclude(mesh_instance):
		_apply_shaders_to_mesh(mesh_instance)


func _apply_to_node_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		if not _should_exclude(node):
			_apply_shaders_to_mesh(node)
	
	for child in node.get_children():
		_apply_to_node_recursive(child)


func _should_exclude(mesh_instance: MeshInstance3D) -> bool:
	var name_lower = mesh_instance.name.to_lower()
	for exclude in _exclude_names:
		if exclude in name_lower:
			return true
	
	var mat = mesh_instance.get_surface_override_material(0)
	if mat is ShaderMaterial and mat.shader == _toon_shader:
		return true
	
	return false


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
			var toon_mat = _create_toon_material(original_material)
			mesh_instance.set_surface_override_material(i, toon_mat)


func _create_toon_material(original: Material) -> ShaderMaterial:
	var toon_mat = ShaderMaterial.new()
	toon_mat.shader = _toon_shader
	
	var base_color = Color.WHITE
	if original is StandardMaterial3D:
		base_color = original.albedo_color
		if original.albedo_texture:
			toon_mat.set_shader_parameter("albedo_texture", original.albedo_texture)
			toon_mat.set_shader_parameter("use_texture", true)
	
	toon_mat.set_shader_parameter("base_color", base_color)
	toon_mat.set_shader_parameter("shadow_strength", 0.25)
	toon_mat.set_shader_parameter("shadow_threshold", 0.4)
	toon_mat.set_shader_parameter("enable_rim", enable_rim_light)
	toon_mat.set_shader_parameter("rim_color", Color(1.0, 0.95, 0.9, 1.0))
	toon_mat.set_shader_parameter("rim_power", 3.0)
	toon_mat.set_shader_parameter("rim_intensity", 0.3)
	
	return toon_mat
