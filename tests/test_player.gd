extends SceneTree
## Tests for Player Controller
## Run: godot --headless -s tests/test_player.gd

var tests_passed := 0
var tests_failed := 0

func _init() -> void:
	print("\n=== Player Controller Tests ===\n")
	
	test_player_scene_loads()
	test_player_groups()
	test_player_exports()
	
	print("\n--- Results: %d passed, %d failed ---\n" % [tests_passed, tests_failed])
	quit(tests_failed)

func test_player_scene_loads() -> void:
	var scene = load("res://player/player.tscn")
	assert_not_null(scene, "player.tscn loads")
	
	var player = scene.instantiate()
	assert_not_null(player, "player instantiates")
	assert_true(player is CharacterBody3D, "player is CharacterBody3D")
	
	player.free()

func test_player_groups() -> void:
	var scene = load("res://player/player.tscn")
	var player = scene.instantiate()
	
	assert_true(player.is_in_group("player"), "player in 'player' group")
	
	player.free()

func test_player_exports() -> void:
	var scene = load("res://player/player.tscn")
	var player = scene.instantiate()
	
	# Check exported variables exist and have sensible defaults
	assert_gt(player.walk_speed, 0, "walk_speed > 0")
	assert_gt(player.run_speed, player.walk_speed, "run_speed > walk_speed")
	assert_gt(player.jump_velocity, 0, "jump_velocity > 0")
	assert_gt(player.rotation_speed, 0, "rotation_speed > 0")
	
	player.free()

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

func assert_not_null(val, msg: String) -> void:
	if val != null:
		print("  ✓ %s" % msg)
		tests_passed += 1
	else:
		print("  ✗ %s (got null)" % msg)
		tests_failed += 1

func assert_gt(a: float, b: float, msg: String) -> void:
	if a > b:
		print("  ✓ %s" % msg)
		tests_passed += 1
	else:
		print("  ✗ %s (got %s, expected > %s)" % [msg, a, b])
		tests_failed += 1
