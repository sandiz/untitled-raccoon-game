class_name GameTime
extends Node
## Game Time System - uses static singleton pattern (no autoload)
## Manages day/night cycle with compressed game time.
## 1 real second = 1 game minute (adjustable via time_scale)
##
## Usage: GameTime.get_instance().game_hour

# Static instance (lazy initialized)
static var _instance: GameTime = null

signal time_changed(hour: int, minute: int)
signal period_changed(period: String)

# Time scale: game seconds per real second
var time_scale: float = 60.0
# Starting hour (0-23)
var start_hour: int = 8

# Internal time tracking (seconds since midnight)
var game_time: float = 0.0
var paused: bool = false

# Cached values
var _last_hour: int = -1
var _last_period: String = ""

# Session tracking - detect game restarts
var _session_frame: int = -1


static func get_instance() -> GameTime:
	if _instance == null:
		_instance = GameTime.new()
		_instance._session_frame = Engine.get_process_frames()
		_instance._initialize()
		# Add to tree so _process runs
		if Engine.get_main_loop():
			var root = Engine.get_main_loop().root
			if root:
				root.call_deferred("add_child", _instance)
	else:
		# Check if this is a new game session
		var current_frame = Engine.get_process_frames()
		if current_frame < _instance._session_frame or _instance._session_frame < 0:
			print("[GameTime] New session detected, resetting")
			_instance.reset()
			_instance._session_frame = current_frame
	return _instance


func _initialize() -> void:
	game_time = start_hour * 3600.0
	_last_hour = game_hour
	_last_period = time_of_day


func reset() -> void:
	game_time = start_hour * 3600.0
	paused = false
	_last_hour = game_hour
	_last_period = time_of_day


# ═══════════════════════════════════════
# COMPUTED PROPERTIES
# ═══════════════════════════════════════

var game_hour: int:
	get: return int(game_time / 3600.0) % 24

var game_minute: int:
	get: return int(game_time / 60.0) % 60

var game_time_string: String:
	get: return "%02d:%02d" % [game_hour, game_minute]

var time_of_day: String:
	get:
		if game_hour < 6: return "night"
		if game_hour < 12: return "morning"
		if game_hour < 18: return "afternoon"
		return "evening"

var day_progress: float:
	get: return game_time / 86400.0  # 0.0 to 1.0 over full day

# ═══════════════════════════════════════
# TIME PERIOD HELPERS
# ═══════════════════════════════════════

func is_between(start_h: int, end_h: int) -> bool:
	if start_h <= end_h:
		return game_hour >= start_h and game_hour < end_h
	else:  # Wraps around midnight
		return game_hour >= start_h or game_hour < end_h

func is_morning() -> bool:
	return is_between(6, 12)

func is_afternoon() -> bool:
	return is_between(12, 18)

func is_evening() -> bool:
	return is_between(18, 22)

func is_night() -> bool:
	return is_between(22, 6)

func is_work_hours() -> bool:
	return is_between(9, 18)

func is_lunch_time() -> bool:
	return is_between(12, 14)

# ═══════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════

func _process(delta: float) -> void:
	if paused:
		return
	
	game_time += delta * time_scale
	
	# Wrap around at midnight
	if game_time >= 86400.0:
		game_time -= 86400.0
	
	# Emit signals on changes
	if game_hour != _last_hour:
		_last_hour = game_hour
		time_changed.emit(game_hour, game_minute)
	
	if time_of_day != _last_period:
		_last_period = time_of_day
		period_changed.emit(time_of_day)

# ═══════════════════════════════════════
# CONTROL
# ═══════════════════════════════════════

func set_time(hour: int, minute: int = 0) -> void:
	game_time = hour * 3600.0 + minute * 60.0
	_last_hour = game_hour
	_last_period = time_of_day

func pause_time() -> void:
	paused = true

func resume_time() -> void:
	paused = false

func set_time_scale(scale: float) -> void:
	time_scale = scale
