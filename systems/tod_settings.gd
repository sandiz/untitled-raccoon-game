class_name TODSettings
extends Resource
## Time of Day settings resource - tweak in editor without touching code.

@export_group("Cycle")
@export var cycle_duration: float = 600.0  ## Full day in seconds (default 10 min)
@export var transition_duration: float = 30.0  ## Blend time between periods

@export_group("Morning (6am-12pm)")
@export var morning_light_color: Color = Color(1.0, 0.95, 0.85)
@export var morning_light_intensity: float = 1.0
@export var morning_ambient_color: Color = Color(0.9, 0.88, 0.82)
@export var morning_ambient_energy: float = 0.3
@export var morning_brightness: float = 1.0  ## Global shader brightness

@export_group("Afternoon (12pm-6pm)")
@export var afternoon_light_color: Color = Color("#FFF8E7")
@export var afternoon_light_intensity: float = 0.9
@export var afternoon_ambient_color: Color = Color(0.95, 0.94, 0.9)
@export var afternoon_ambient_energy: float = 0.4
@export var afternoon_brightness: float = 1.0  ## Global shader brightness

@export_group("Evening (6pm-12am)")
@export var evening_light_color: Color = Color("#FFB5A7")
@export var evening_light_intensity: float = 0.55
@export var evening_ambient_color: Color = Color(0.9, 0.78, 0.75)
@export var evening_ambient_energy: float = 0.3
@export var evening_brightness: float = 0.7  ## Global shader brightness

@export_group("Night (12am-6am)")
@export var night_light_color: Color = Color("#B8C5D6")
@export var night_light_intensity: float = 0.3
@export var night_ambient_color: Color = Color(0.55, 0.58, 0.7)
@export var night_ambient_energy: float = 0.2
@export var night_brightness: float = 0.0  ## Global shader brightness (0 = pitch black)
