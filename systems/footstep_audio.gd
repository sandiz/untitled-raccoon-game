class_name FootstepAudio
extends Node
## Plays footstep sounds and spawns dust particles triggered by animation notifies.
## Call step() from animation method tracks at foot contact frames.

@export var enabled: bool = true
@export var volume_db: float = -10.0
@export var base_pitch: float = 1.0  ## Base pitch (higher = lighter footsteps)
@export var pitch_variation: float = 0.15  ## Random pitch variation (+/-)
@export_enum("grass", "concrete") var surface_type: String = "grass"

## Dust particle settings
@export var show_dust: bool = true
@export var dust_amount: int = 8
@export var dust_scale: float = 1.0
@export var dust_max_distance: float = 15.0  ## Only show dust within this distance from camera

var _audio_player: AudioStreamPlayer3D
var _footstep_sounds: Array[AudioStream] = []
var _dust_particles: CPUParticles3D
var _character: Node3D

# Surface colors (darker for visibility in daylight)
const DUST_COLORS := {
	"grass": Color(0.45, 0.35, 0.25, 0.9),  # Darker brown
	"concrete": Color(0.5, 0.48, 0.45, 0.85),  # Darker gray
}


func _ready() -> void:
	_character = get_parent() as Node3D
	_setup_audio_player()
	_setup_dust_particles()
	_load_sounds()


func _setup_audio_player() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.volume_db = volume_db
	_audio_player.max_distance = 20.0
	_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(_audio_player)


func _setup_dust_particles() -> void:
	_dust_particles = CPUParticles3D.new()
	_dust_particles.name = "DustParticles"
	_dust_particles.emitting = false
	_dust_particles.one_shot = true
	_dust_particles.explosiveness = 0.95
	_dust_particles.amount = dust_amount
	_dust_particles.lifetime = 0.5
	
	# Particle motion - soft puff outward and up
	_dust_particles.direction = Vector3(0, 1, 0)
	_dust_particles.spread = 70.0
	_dust_particles.initial_velocity_min = 0.8
	_dust_particles.initial_velocity_max = 1.5
	_dust_particles.gravity = Vector3(0, -1.0, 0)
	_dust_particles.damping_min = 3.0
	_dust_particles.damping_max = 5.0
	
	# Particle size - visible puffs
	_dust_particles.scale_amount_min = 0.18 * dust_scale
	_dust_particles.scale_amount_max = 0.28 * dust_scale
	
	# Fade out over lifetime
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0, 0.5))
	scale_curve.add_point(Vector2(0.3, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	_dust_particles.scale_amount_curve = scale_curve
	
	# Create simple sphere mesh for particles
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	_dust_particles.mesh = mesh
	
	# Material - unshaded for consistent look
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = DUST_COLORS.get(surface_type, DUST_COLORS["grass"])
	_dust_particles.material_override = mat
	
	# Color variation
	_update_dust_color()
	
	# Add as child - use local_coords=false so particles stay in world space
	_dust_particles.local_coords = false
	add_child(_dust_particles)


func _update_dust_color() -> void:
	if not _dust_particles:
		return
	
	var base_color: Color = DUST_COLORS.get(surface_type, DUST_COLORS["grass"])
	_dust_particles.color = base_color
	
	# Slight color variation
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, base_color)
	color_ramp.set_color(1, Color(base_color.r, base_color.g, base_color.b, 0))
	_dust_particles.color_ramp = color_ramp


func _load_sounds() -> void:
	set_surface(surface_type)


## Called by animation method tracks at foot contact frames
func step() -> void:
	if not enabled:
		return
	
	# Play sound
	if not _footstep_sounds.is_empty() and not _audio_player.playing:
		var sound = _footstep_sounds[randi() % _footstep_sounds.size()]
		_audio_player.stream = sound
		_audio_player.pitch_scale = base_pitch + randf_range(-pitch_variation, pitch_variation)
		_audio_player.play()
	
	# Spawn dust puff (only if close to camera)
	if show_dust and _dust_particles and _character:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var dist = _character.global_position.distance_to(camera.global_position)
			if dist > dust_max_distance:
				return
		
		var foot_offset = Vector3(
			randf_range(-0.2, 0.2),
			0.02,
			randf_range(-0.2, 0.2)
		)
		_dust_particles.global_position = _character.global_position + foot_offset
		_dust_particles.emitting = true
		_dust_particles.restart()


## Switch to different surface sounds and dust color
func set_surface(surface: String) -> void:
	surface_type = surface
	
	# Load sounds
	_footstep_sounds.clear()
	for i in range(5):
		var path = "res://assets/audio/footsteps/footstep_%s_00%d.ogg" % [surface, i]
		var sound = load(path)
		if sound:
			_footstep_sounds.append(sound)
	
	if _footstep_sounds.is_empty():
		push_warning("FootstepAudio: No footstep sounds found for surface: %s" % surface)
	
	# Update dust color
	_update_dust_color()
