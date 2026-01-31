class_name BaseNPC
extends CharacterBody3D
## Base class for all NPCs. Handles movement properly to prevent sliding.
##
## MOVEMENT RULES:
## - BT tasks set velocity (including zeroing it when stopped)
## - This class calls move_and_slide() ONCE per frame in _physics_process
## - Never call move_and_slide() from BT tasks - just set velocity
## - Gravity is applied automatically when not on floor

## How much force NPCs apply when pushing objects
@export var push_force: float = 0.8

## Override in subclass to add custom physics behavior
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Apply gravity when airborne
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	# Subclass processing (before move_and_slide)
	_npc_physics_process(delta)
	
	# Single move_and_slide call per frame - BT tasks just set velocity
	move_and_slide()
	
	# Push any RigidBody3D we collided with
	_push_rigidbodies()


## Apply impulse to any RigidBody3D we collided with
func _push_rigidbodies() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody3D:
			var push_dir = collision.get_normal() * -1
			push_dir.y = 0
			push_dir = push_dir.normalized()
			var contact_point = collision.get_position()
			collider.apply_impulse(push_dir * push_force, contact_point - collider.global_position)


## Override this in subclasses for custom physics behavior
## Called every physics frame BEFORE move_and_slide()
func _npc_physics_process(_delta: float) -> void:
	pass


## Helper to safely stop all movement
func stop_movement() -> void:
	velocity = Vector3.ZERO
