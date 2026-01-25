extends CharacterBody3D
## Raccoon - player's avatar. No direct control.
## Player influences NPCs through possession/clicking.

signal possessed_npc(npc: Node3D)
signal released_npc(npc: Node3D)

var _current_possessed: Node3D = null


func _ready() -> void:
	add_to_group("player")


func is_possessing() -> bool:
	return _current_possessed != null


func get_possessed() -> Node3D:
	return _current_possessed


func possess(npc: Node3D) -> void:
	if _current_possessed:
		release()
	_current_possessed = npc
	possessed_npc.emit(npc)


func release() -> void:
	if _current_possessed:
		var old = _current_possessed
		_current_possessed = null
		released_npc.emit(old)
