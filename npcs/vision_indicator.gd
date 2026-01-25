class_name VisionIndicator
extends Node3D
## Visual indicator showing NPC's awareness state on the ground.
## Changes color/visibility based on idle/suspicious/chasing states.

@export_group("Colors")
@export var idle_color: Color = Color(0.0, 0.0, 0.0, 0.0)  # Invisible
@export var suspicious_color: Color = Color(1.0, 0.7, 0.0, 0.2)  # Amber #FFB300 @ 20%
@export var chasing_color: Color = Color(1.0, 0.4, 0.0, 0.4)  # Orange #FF6600 @ 40%

@export_group("Settings")
@export var range_scale: float = 8.0  # Matches perception sight_range
@export var cone_angle: float = 60.0  # Half-angle in degrees
@export var transition_speed: float = 3.0

var _mesh: MeshInstance3D
var _material: ShaderMaterial
var _current_color: Color = Color.TRANSPARENT
var _target_color: Color = Color.TRANSPARENT
var _parent_npc: Node3D


func _ready() -> void:
	_parent_npc = get_parent()
	_create_indicator_mesh()
	
	# Start invisible
	_current_color = idle_color
	_target_color = idle_color
	_update_material_color()


func _process(delta: float) -> void:
	# Smoothly transition color
	if _current_color != _target_color:
		_current_color = _current_color.lerp(_target_color, delta * transition_speed)
		_update_material_color()
	
	# Face same direction as parent NPC
	if _parent_npc:
		rotation.y = _parent_npc.rotation.y


func _create_indicator_mesh() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "VisionMesh"
	add_child(_mesh)
	
	# Create a flat disc mesh
	var plane = PlaneMesh.new()
	plane.size = Vector2(range_scale * 2, range_scale * 2)
	_mesh.mesh = plane
	
	# Position at ground level, slightly above to avoid z-fighting
	_mesh.position.y = 0.02
	
	# Create shader material
	var shader = load("res://shaders/vision_cone.gdshader")
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("cone_color", _current_color)
	_material.set_shader_parameter("intensity", 0.5)
	_material.set_shader_parameter("cone_angle", cone_angle)
	_material.set_shader_parameter("pulse_speed", 1.5)
	_material.set_shader_parameter("pulse_amount", 0.1)
	_material.set_shader_parameter("fade_edge", 0.3)
	
	_mesh.material_override = _material


func _update_material_color() -> void:
	if _material:
		_material.set_shader_parameter("cone_color", _current_color)
		_material.set_shader_parameter("intensity", _current_color.a * 2.0)  # Boost for visibility
		_mesh.visible = _current_color.a > 0.01


# Public API - called by NPC state system

func set_state_idle() -> void:
	_target_color = idle_color
	# Immediately hide mesh when going idle
	if _mesh:
		_mesh.visible = false


func set_state_suspicious() -> void:
	_target_color = suspicious_color
	# Slower pulse for investigation
	if _material:
		_material.set_shader_parameter("pulse_speed", 1.0)


func set_state_chasing() -> void:
	_target_color = chasing_color
	# Faster pulse for chase
	if _material:
		_material.set_shader_parameter("pulse_speed", 3.0)


func set_range(new_range: float) -> void:
	range_scale = new_range
	if _mesh and _mesh.mesh is PlaneMesh:
		_mesh.mesh.size = Vector2(range_scale * 2, range_scale * 2)


func set_cone_angle_degrees(angle: float) -> void:
	cone_angle = angle
	if _material:
		_material.set_shader_parameter("cone_angle", cone_angle)
