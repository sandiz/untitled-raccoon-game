class_name HeadLookAt
extends Node
## Makes NPC head turn toward a target. Attach to NPC with skeleton.

@export var skeleton_path: NodePath
@export var max_angle: float = 70.0  # Max head turn in degrees
@export var vision_cone_angle: float = 90.0  # Only track targets within this angle from forward
@export var turn_speed: float = 8.0  # How fast head turns
@export var show_debug_line: bool = true  # Toggle debug line visibility

var _skeleton: Skeleton3D
var _head_idx: int = -1
var _neck_idx: int = -1
var _debug_line: MeshInstance3D

var target: Node3D = null  # What to look at
var target_position: Vector3  # Or look at a position
var enabled: bool = true:
	set(value):
		enabled = value
		if not value:
			_clear_bone_override()

var _current_blend: float = 0.0  # 0 = default, 1 = looking at target


func _ready() -> void:
	# Run late so we apply rotation AFTER animation
	process_priority = 100
	call_deferred("_setup")
	
	# Create debug line
	if show_debug_line:
		_debug_line = MeshInstance3D.new()
		_debug_line.mesh = ImmediateMesh.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.0, 1.0)  # Bright orange for visibility
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.no_depth_test = true
		_debug_line.material_override = mat
		get_tree().root.call_deferred("add_child", _debug_line)


func _exit_tree() -> void:
	if _debug_line and is_instance_valid(_debug_line):
		_debug_line.queue_free()


func _setup() -> void:
	if skeleton_path:
		_skeleton = get_node_or_null(skeleton_path)
	
	if not _skeleton:
		var parent = get_parent()
		_skeleton = _find_skeleton(parent)
	
	if not _skeleton:
		push_warning("HeadLookAt: No skeleton found")
		return
	
	# Find bones - try common naming conventions
	_head_idx = _skeleton.find_bone("mixamorig_Head")
	if _head_idx == -1:
		_head_idx = _skeleton.find_bone("Head")
	
	_neck_idx = _skeleton.find_bone("mixamorig_Neck")
	if _neck_idx == -1:
		_neck_idx = _skeleton.find_bone("Neck")
	
	if _head_idx == -1:
		push_warning("HeadLookAt: Head bone not found")


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result:
			return result
	return null


func _process(delta: float) -> void:
	if not _skeleton or _head_idx == -1:
		return
	
	# Determine target position
	var look_pos := Vector3.ZERO
	var has_target := false
	
	if target and is_instance_valid(target):
		look_pos = target.global_position
		look_pos.y += 1.5  # Look at head height
		has_target = true
	elif target_position != Vector3.ZERO:
		look_pos = target_position
		has_target = true
	
	# Get head position in world space
	var head_bone_pose := _skeleton.get_bone_global_pose(_head_idx)
	var head_pos := _skeleton.to_global(head_bone_pose.origin)
	
	# Check if target is within vision cone (don't track targets behind NPC)
	var in_vision_cone := false
	var angle := 0.0
	var dir_to_target := Vector3.ZERO
	var parent_3d := get_parent() as Node3D
	if has_target:
		dir_to_target = (look_pos - head_pos).normalized()
		if parent_3d:
			var npc_forward := parent_3d.global_transform.basis.z.normalized()
			angle = rad_to_deg(npc_forward.angle_to(dir_to_target))
			in_vision_cone = angle <= vision_cone_angle / 2.0
	
	# Only track if within vision cone
	var should_track := enabled and has_target and in_vision_cone
	
	# Debug line uses body midpoints (not head height) so it doesn't float
	var npc_body_mid := parent_3d.global_position + Vector3(0, 0.9, 0) if parent_3d else head_pos
	var target_body_mid := Vector3.ZERO
	if target and is_instance_valid(target):
		target_body_mid = target.global_position + Vector3(0, 0.9, 0)
	elif target_position != Vector3.ZERO:
		target_body_mid = target_position
	
	# Only show debug line when tracking
	_update_debug_line(npc_body_mid, target_body_mid if should_track else Vector3.ZERO)
	
	# Blend toward target or back to neutral
	var target_blend := 1.0 if should_track else 0.0
	_current_blend = lerp(_current_blend, target_blend, delta * turn_speed)
	
	if _current_blend < 0.01:
		_current_blend = 0.0
		return
	
	if not should_track and _current_blend < 0.1:
		return
	
	if not has_target:
		return
	
	# Reduce effect if near max angle (smooth falloff at edges)
	var angle_factor := 1.0
	if angle > max_angle:
		angle_factor = clamp(1.0 - (angle - max_angle) / 30.0, 0.0, 1.0)
	var effective_blend := _current_blend * angle_factor
	
	if effective_blend < 0.01:
		return
	
	# Calculate look rotation in head's parent space
	var head_parent_transform := _skeleton.global_transform
	if _neck_idx != -1:
		head_parent_transform = head_parent_transform * _skeleton.get_bone_global_pose(_neck_idx)
	
	var local_dir := head_parent_transform.basis.inverse() * dir_to_target
	
	# Create rotation (yaw + pitch, no roll)
	# +Z is forward for this model
	var yaw := atan2(local_dir.x, local_dir.z)
	var pitch := atan2(-local_dir.y, Vector2(local_dir.x, local_dir.z).length())
	pitch = clamp(pitch, deg_to_rad(-30), deg_to_rad(30))
	
	var look_quat := Quaternion.from_euler(Vector3(pitch, yaw, 0))
	
	# Get current bone global pose and modify rotation
	var current_global_pose := _skeleton.get_bone_global_pose(_head_idx)
	var modified_pose := Transform3D(Basis(look_quat), current_global_pose.origin)
	
	# Use global pose override - this properly blends with animation
	_skeleton.set_bone_global_pose_override(_head_idx, modified_pose, effective_blend, true)


func _update_debug_line(from: Vector3, to: Vector3) -> void:
	if not _debug_line or not is_instance_valid(_debug_line):
		return
	
	var mesh := _debug_line.mesh as ImmediateMesh
	mesh.clear_surfaces()
	
	if to == Vector3.ZERO:
		return
	
	# Draw single line from NPC to target (at body height)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()


## Set a Node3D target to track
func look_at_node(node: Node3D) -> void:
	target = node
	target_position = Vector3.ZERO


## Set a world position to look at
func look_at_position(pos: Vector3) -> void:
	target = null
	target_position = pos


## Stop looking, return to default
func clear_target() -> void:
	target = null
	target_position = Vector3.ZERO
	_clear_bone_override()


## Clear the bone pose override to let animation take over
func _clear_bone_override() -> void:
	if _skeleton and _head_idx != -1:
		# Set override with 0 amount to clear it
		_skeleton.set_bone_global_pose_override(_head_idx, Transform3D.IDENTITY, 0.0, false)
		_current_blend = 0.0
