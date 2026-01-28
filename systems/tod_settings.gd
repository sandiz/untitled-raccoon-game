class_name TODSettings
extends Resource
## Time of Day settings resource - tweak in editor without touching code.

@export_group("Cycle")
@export var cycle_duration: float = 600.0  ## Full day in seconds (default 10 min)
@export var transition_duration: float = 30.0  ## Blend time between periods

@export_group("Morning (6am-12pm)")
@export var morning_light_color: Color = Color(1.0, 0.88, 0.7)  # Warm golden-pink
@export var morning_light_intensity: float = 0.9
@export var morning_ambient_color: Color = Color(0.85, 0.75, 0.65)  # Warm shadow
@export var morning_ambient_energy: float = 0.25
@export var morning_brightness: float = 1.0
@export var morning_fog_color: Color = Color(0.95, 0.85, 0.65)  # Golden haze
@export var morning_fog_density: float = 0.006

@export_group("Afternoon (12pm-6pm)")
@export var afternoon_light_color: Color = Color(1.0, 0.98, 0.95)  # Neutral white
@export var afternoon_light_intensity: float = 1.0
@export var afternoon_ambient_color: Color = Color(0.8, 0.82, 0.85)  # Cool neutral
@export var afternoon_ambient_energy: float = 0.3
@export var afternoon_brightness: float = 1.1
@export var afternoon_fog_color: Color = Color(0.9, 0.92, 0.95)  # Clear/minimal
@export var afternoon_fog_density: float = 0.002

@export_group("Evening (6pm-12am)")
@export var evening_light_color: Color = Color(1.0, 0.65, 0.5)  # Deep coral/orange
@export var evening_light_intensity: float = 0.6
@export var evening_ambient_color: Color = Color(0.7, 0.5, 0.45)  # Warm shadow
@export var evening_ambient_energy: float = 0.25
@export var evening_brightness: float = 0.75
@export var evening_fog_color: Color = Color(0.75, 0.55, 0.5)  # Warm coral
@export var evening_fog_density: float = 0.008

@export_group("Night (12am-6am)")
@export var night_light_color: Color = Color(0.5, 0.6, 0.85)  # Cool blue moonlight
@export var night_light_intensity: float = 0.35
@export var night_ambient_color: Color = Color(0.2, 0.25, 0.4)  # Deep blue shadow
@export var night_ambient_energy: float = 0.15
@export var night_brightness: float = 0.5
@export var night_fog_color: Color = Color(0.25, 0.3, 0.4)  # Cool blue
@export var night_fog_density: float = 0.01
