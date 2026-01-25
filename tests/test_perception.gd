extends SceneTree
## Tests for NPCPerception system
## Run: godot --headless -s tests/test_perception.gd

const NPCPerception = preload("res://systems/npc_perception.gd")

var tests_passed := 0
var tests_failed := 0

func _init() -> void:
	print("\n=== NPCPerception Tests ===\n")
	
	test_initial_config()
	test_hearing()
	test_awareness_tracking()
	test_sound_decay()
	
	print("\n--- Results: %d passed, %d failed ---\n" % [tests_passed, tests_failed])
	quit(tests_failed)

func test_initial_config() -> void:
	var perception = NPCPerception.new()
	
	assert_eq(perception.fov_angle, 120.0, "FOV is 120 degrees")
	assert_eq(perception.sight_range, 8.0, "sight range is 8m")
	assert_eq(perception.peripheral_range, 12.0, "peripheral range is 12m")
	assert_eq(perception.hearing_range, 10.0, "hearing range is 10m")
	assert_eq(perception.loud_hearing_range, 20.0, "loud hearing range is 20m")
	assert_eq(perception.notice_time, 0.8, "notice time is 0.8s")
	assert_eq(perception.memory_duration, 5.0, "memory duration is 5s")

func test_hearing() -> void:
	var perception = NPCPerception.new()
	
	# Mock owner at origin
	var mock_npc = Node3D.new()
	mock_npc.global_position = Vector3.ZERO
	perception.owner_npc = mock_npc
	
	# Hear sound within range
	perception.hear_sound(Vector3(10, 0, 0), "honk", 1.0)
	assert_eq(perception.recent_sounds.size(), 1, "sound registered")
	assert_eq(perception.recent_sounds[0].type, "honk", "sound type is honk")
	
	# Get loudest sound
	var loudest = perception.get_loudest_recent_sound()
	assert_eq(loudest.type, "honk", "loudest sound is honk")
	
	mock_npc.free()

func test_awareness_tracking() -> void:
	var perception = NPCPerception.new()
	
	# No targets initially
	assert_false(perception.has_any_awareness(), "no awareness initially")
	assert_eq(perception.get_primary_target(), null, "no primary target")
	
	# Mock target tracking
	var mock_target = Node3D.new()
	perception.tracked_targets[mock_target] = {
		awareness = 0.5,
		last_position = Vector3(5, 0, 0),
		last_seen = Time.get_unix_time_from_system()
	}
	
	assert_true(perception.has_any_awareness(), "has awareness after tracking")
	assert_eq(perception.get_awareness(mock_target), 0.5, "awareness is 0.5")
	assert_eq(perception.get_primary_target(), mock_target, "primary target set")
	
	mock_target.free()

func test_sound_decay() -> void:
	var perception = NPCPerception.new()
	
	# Add old sound (fake timestamp)
	perception.recent_sounds.append({
		position = Vector3.ZERO,
		type = "old",
		loudness = 1.0,
		time = Time.get_unix_time_from_system() - 10.0  # 10 seconds ago
	})
	
	# Decay removes old sounds (>5s)
	perception._decay_sounds(0.1)
	assert_eq(perception.recent_sounds.size(), 0, "old sounds removed")

func test_debug_info() -> void:
	var perception = NPCPerception.new()
	var info = perception.get_debug_info()
	
	assert_eq(info.fov_angle, 120.0, "debug info has fov")
	assert_eq(info.tracked_count, 0, "debug info has tracked count")

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
