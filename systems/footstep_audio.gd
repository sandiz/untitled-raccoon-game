class_name FootstepAudio
extends Node
## Plays footstep sounds based on character movement.
## Attach to any CharacterBody3D with a velocity property.

@export var enabled: bool = true
@export var step_interval: float = 0.35  ## Seconds between steps when walking
@export var run_interval: float = 0.25  ## Seconds between steps when running
@export var run_speed_threshold: float = 5.0  ## Speed above this = running
@export var volume_db: float = -10.0
@export var base_pitch: float = 1.0  ## Base pitch (higher = lighter footsteps)
@export var pitch_variation: float = 0.15  ## Random pitch variation (+/-)
@export_enum("grass", "concrete") var surface_type: String = "grass"

var _audio_player: AudioStreamPlayer3D
var _footstep_sounds: Array[AudioStream] = []
var _step_timer: float = 0.0
var _character: CharacterBody3D


func _ready() -> void:
	_character = get_parent() as CharacterBody3D
	if not _character:
		push_warning("FootstepAudio: Parent must be CharacterBody3D")
		return
	
	_setup_audio_player()
	_load_sounds()


func _setup_audio_player() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.volume_db = volume_db
	_audio_player.max_distance = 20.0
	_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(_audio_player)


func _load_sounds() -> void:
	set_surface(surface_type)


func _process(delta: float) -> void:
	if not enabled or not _character or _footstep_sounds.is_empty():
		return
	
	# Get horizontal velocity (ignore Y)
	var velocity_xz = Vector2(_character.velocity.x, _character.velocity.z)
	var speed = velocity_xz.length()
	
	# Only play footsteps if moving and on floor
	if speed < 0.5 or not _character.is_on_floor():
		_step_timer = 0.0
		return
	
	# Determine interval based on speed
	var interval = run_interval if speed > run_speed_threshold else step_interval
	
	_step_timer += delta
	if _step_timer >= interval:
		_step_timer = 0.0
		_play_footstep()


func _play_footstep() -> void:
	if _audio_player.playing:
		return
	
	# Random sound from pool
	var sound = _footstep_sounds[randi() % _footstep_sounds.size()]
	_audio_player.stream = sound
	
	# Random pitch around base_pitch for variety
	_audio_player.pitch_scale = base_pitch + randf_range(-pitch_variation, pitch_variation)
	
	_audio_player.play()


## Switch to different surface sounds
func set_surface(surface: String) -> void:
	_footstep_sounds.clear()
	for i in range(5):
		var path = "res://assets/audio/footsteps/footstep_%s_00%d.ogg" % [surface, i]
		var sound = load(path)
		if sound:
			_footstep_sounds.append(sound)
	
	if _footstep_sounds.is_empty():
		push_warning("FootstepAudio: No footstep sounds found for surface: %s" % surface)
