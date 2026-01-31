class_name ShopItem
extends RigidBody3D
## A stealable/interactable item in the shop.
## Can be picked up by player, knocked over, and returned by NPC.

enum ItemSize { SMALL, MEDIUM, LARGE }
enum ItemState { IN_PLACE, HELD_BY_PLAYER, HELD_BY_NPC, DISPLACED, KNOCKED_OVER }

@export var item_name: String = "Item"
@export var size: ItemSize = ItemSize.SMALL
@export var value: int = 1  ## How much NPC cares (1-5 scale)

## Where this item "belongs" - set on ready or in editor
@export var home_position: Vector3
@export var use_current_as_home: bool = true  ## Auto-set home_position on _ready

var state: ItemState = ItemState.IN_PLACE
var holder: Node3D = null  ## Who's holding it (player or NPC)
var time_displaced: float = 0.0  ## When it was displaced (for priority sorting)

signal state_changed(item: ShopItem, old_state: ItemState, new_state: ItemState)
signal picked_up(item: ShopItem, by: Node3D)
signal dropped(item: ShopItem, at: Vector3)
signal knocked_over(item: ShopItem)

## Computed property: is item currently held? (for player pickup system compatibility)
var is_held: bool:
	get: return state == ItemState.HELD_BY_PLAYER or state == ItemState.HELD_BY_NPC


func _ready() -> void:
	add_to_group("stealable_items")
	if use_current_as_home:
		home_position = global_position
	
	# Items start unfrozen so they can be pushed
	freeze = false
	
	# Set up collision
	collision_layer = 8  # Layer 4 (items)
	collision_mask = 15  # Collide with environment (1), NPCs (2), player (4), and other items (8)


func _process(_delta: float) -> void:
	# Visual feedback based on state
	pass


## Player pickup system compatibility - wrapper for pickup_by_player
func pickup(new_holder: Node3D) -> void:
	pickup_by_player(new_holder)


## Check if item is at its home position
func is_at_home() -> bool:
	return global_position.distance_to(home_position) < 0.5


## Check if item can be picked up by player
func can_be_picked_up() -> bool:
	return size == ItemSize.SMALL and state in [ItemState.IN_PLACE, ItemState.DISPLACED, ItemState.KNOCKED_OVER]


## Check if item can be pushed
func can_be_pushed() -> bool:
	return size in [ItemSize.SMALL, ItemSize.MEDIUM]


## Called when player picks up this item
func pickup_by_player(player: Node3D) -> void:
	if not can_be_picked_up():
		return
	
	var old_state = state
	state = ItemState.HELD_BY_PLAYER
	holder = player
	freeze = true
	
	# Disable collision while held
	collision_layer = 0
	collision_mask = 0
	
	state_changed.emit(self, old_state, state)
	picked_up.emit(self, player)


## Called when NPC picks up this item
func pickup_by_npc(npc: Node3D) -> void:
	var old_state = state
	state = ItemState.HELD_BY_NPC
	holder = npc
	freeze = true
	
	collision_layer = 0
	collision_mask = 0
	
	state_changed.emit(self, old_state, state)
	picked_up.emit(self, npc)


## Called when holder drops this item
func drop(drop_position: Vector3) -> void:
	var old_state = state
	holder = null
	
	# Determine new state based on position
	if drop_position.distance_to(home_position) < 0.5:
		state = ItemState.IN_PLACE
		global_position = home_position
		freeze = true
	else:
		state = ItemState.DISPLACED
		global_position = drop_position
		time_displaced = Time.get_ticks_msec() / 1000.0
		freeze = false  # Let physics take over
	
	# Re-enable collision
	collision_layer = 8
	collision_mask = 1
	
	state_changed.emit(self, old_state, state)
	dropped.emit(self, drop_position)


## Called when item is placed at home by NPC
func place_at_home() -> void:
	var old_state = state
	state = ItemState.IN_PLACE
	holder = null
	global_position = home_position
	freeze = true
	
	collision_layer = 8
	collision_mask = 1
	
	state_changed.emit(self, old_state, state)


## Called when item is knocked over
func knock_over(impulse: Vector3 = Vector3.ZERO) -> void:
	if state == ItemState.HELD_BY_PLAYER or state == ItemState.HELD_BY_NPC:
		return
	
	var old_state = state
	state = ItemState.KNOCKED_OVER
	time_displaced = Time.get_ticks_msec() / 1000.0
	freeze = false
	
	if impulse != Vector3.ZERO:
		apply_central_impulse(impulse)
	
	state_changed.emit(self, old_state, state)
	knocked_over.emit(self)


## Get state as string for debugging
func get_state_string() -> String:
	match state:
		ItemState.IN_PLACE: return "in_place"
		ItemState.HELD_BY_PLAYER: return "held_player"
		ItemState.HELD_BY_NPC: return "held_npc"
		ItemState.DISPLACED: return "displaced"
		ItemState.KNOCKED_OVER: return "knocked"
	return "unknown"


## Get size as string for debugging
func get_size_string() -> String:
	match size:
		ItemSize.SMALL: return "small"
		ItemSize.MEDIUM: return "medium"
		ItemSize.LARGE: return "large"
	return "unknown"
