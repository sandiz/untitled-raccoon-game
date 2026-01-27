extends SceneTree
## Tests for GameTime system
## Run: godot --headless -s tests/test_game_time.gd

const GameTimeScript = preload("res://systems/game_time.gd")
var game_time: Node

var tests_passed := 0
var tests_failed := 0

func _init() -> void:
	print("\n=== GameTime Tests ===\n")
	
	# Create GameTime instance (simulating singleton for tests)
	game_time = Node.new()
	game_time.set_script(GameTimeScript)
	# Manually initialize since we're not in scene tree
	game_time.game_time = 8 * 3600.0  # 8:00 AM
	
	test_initial_state()
	test_time_progression()
	test_time_periods()
	test_helper_functions()
	
	game_time.free()
	
	print("\n--- Results: %d passed, %d failed ---\n" % [tests_passed, tests_failed])
	quit(tests_failed)

func test_initial_state() -> void:
	game_time.game_time = 8 * 3600.0  # 8:00 AM
	assert_eq(game_time.game_hour, 8, "starts at hour 8")
	assert_eq(game_time.game_minute, 0, "starts at minute 0")
	assert_eq(game_time.time_scale, 60.0, "time scale is 60x")

func test_time_progression() -> void:
	game_time.game_time = 10 * 3600.0 + 30 * 60.0  # 10:30
	
	# Simulate 1 real second = 1 game minute (time_scale=60)
	game_time._process(1.0)
	
	assert_eq(game_time.game_minute, 31, "minute advances by 1")
	
	# Test hour rollover
	game_time.game_time = 10 * 3600.0 + 59 * 60.0  # 10:59
	game_time._process(1.0)
	assert_eq(game_time.game_minute, 0, "minute wraps to 0")
	assert_eq(game_time.game_hour, 11, "hour advances on wrap")

func test_time_periods() -> void:
	game_time.game_time = 7 * 3600.0  # 7:00
	assert_eq(game_time.time_of_day, "morning", "7am is morning")
	
	game_time.game_time = 14 * 3600.0  # 14:00
	assert_eq(game_time.time_of_day, "afternoon", "2pm is afternoon")
	
	game_time.game_time = 19 * 3600.0  # 19:00
	assert_eq(game_time.time_of_day, "evening", "7pm is evening")
	
	game_time.game_time = 23 * 3600.0  # 23:00
	assert_eq(game_time.time_of_day, "evening", "11pm is evening")
	
	game_time.game_time = 3 * 3600.0  # 3:00
	assert_eq(game_time.time_of_day, "night", "3am is night")

func test_helper_functions() -> void:
	game_time.game_time = 9 * 3600.0  # 9:00
	assert_true(game_time.is_morning(), "9am is morning")
	assert_true(game_time.is_work_hours(), "9am is work hours")
	
	game_time.game_time = 15 * 3600.0  # 15:00
	assert_true(game_time.is_afternoon(), "3pm is afternoon")
	assert_true(game_time.is_work_hours(), "3pm is work hours")
	
	game_time.game_time = 20 * 3600.0  # 20:00
	assert_true(game_time.is_evening(), "8pm is evening")
	assert_false(game_time.is_work_hours(), "8pm is not work hours")
	
	game_time.game_time = 2 * 3600.0  # 2:00
	assert_true(game_time.is_night(), "2am is night")

# === Assertion Helpers ===

func assert_eq(a, b, msg: String) -> void:
	if a == b:
		print("  ✓ %s" % msg)
		tests_passed += 1
	else:
		print("  ✗ %s (got %s, expected %s)" % [msg, a, b])
		tests_failed += 1

func assert_true(val: bool, msg: String) -> void:
	assert_eq(val, true, msg)

func assert_false(val: bool, msg: String) -> void:
	assert_eq(val, false, msg)
