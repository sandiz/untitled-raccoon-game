class_name StealableItem
extends Area3D
## An item that can be picked up by the player and triggers shopkeeper suspicion.

signal picked_up(item: StealableItem)
signal dropped(item: StealableItem)

@export var item_name: String = "Shiny Object"
@export var value: int = 10
@export var hold_offset: Vector3 = Vector3(0.3, 0.5, -0.3)  # Offset when held

var is_held: bool = false
var holder: Node3D = null
var _original_parent: Node = null
var _original_transform: Transform3D


func _ready() -> void:
	add_to_group("stealable_items")
	_original_parent = get_parent()
	_original_transform = global_transform
	
	# Connect body entered for player detection (handled by player's pickup area)
	

func pickup(new_holder: Node3D) -> void:
	if is_held:
		return
	
	is_held = true
	holder = new_holder
	_original_transform = global_transform
	
	# Reparent to holder
	reparent(new_holder)
	position = hold_offset
	rotation = Vector3.ZERO
	
	# Disable collision while held
	monitoring = false
	monitorable = false
	
	picked_up.emit(self)


func drop(drop_position: Vector3) -> void:
	if not is_held:
		return
	
	is_held = false
	holder = null
	
	# Reparent back to original parent (or scene root)
	var target_parent = _original_parent if is_instance_valid(_original_parent) else get_tree().current_scene
	reparent(target_parent)
	global_position = drop_position + Vector3(0, 0.3, 0)
	rotation = Vector3.ZERO
	
	# Re-enable collision
	monitoring = true
	monitorable = true
	
	dropped.emit(self)


func return_to_origin() -> void:
	if is_held and holder:
		reparent(_original_parent if is_instance_valid(_original_parent) else get_tree().current_scene)
	
	is_held = false
	holder = null
	global_transform = _original_transform
	monitoring = true
	monitorable = true
