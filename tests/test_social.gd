extends SceneTree
## Tests for NPCSocial system
## Run: godot --headless -s tests/test_social.gd

const NPCSocial = preload("res://systems/npc_social.gd")

var tests_passed := 0
var tests_failed := 0

func _init() -> void:
	print("\n=== NPCSocial Tests ===\n")
	
	test_initial_config()
	test_alert_cooldown()
	test_alert_storage()
	test_alert_decay()
	test_debug_info()
	
	print("\n--- Results: %d passed, %d failed ---\n" % [tests_passed, tests_failed])
	quit(tests_failed)

func test_initial_config() -> void:
	var social = NPCSocial.new()
	
	assert_eq(social.call_range, 25.0, "call range is 25m")
	assert_eq(social.listen_range, 30.0, "listen range is 30m")
	assert_eq(social.alert_cooldown, 5.0, "alert cooldown is 5s")

func test_alert_cooldown() -> void:
	var social = NPCSocial.new()
	var mock_npc = Node3D.new()
	social.owner_npc = mock_npc
	
	# First alert should succeed
	social._last_alert_time = 0.0
	var success = social.send_alert("suspicious", Vector3.ZERO)
	assert_true(success, "first alert succeeds")
	
	# Immediate second alert should fail (cooldown)
	success = social.send_alert("suspicious", Vector3.ZERO)
	assert_false(success, "second alert blocked by cooldown")
	
	mock_npc.free()

func test_alert_storage() -> void:
	var social = NPCSocial.new()
	
	assert_false(social.has_recent_alerts(), "no alerts initially")
	
	# Manually add alert
	social.received_alerts.append({
		from = null,
		type = "thief_spotted",
		position = Vector3(10, 0, 0),
		time = Time.get_unix_time_from_system()
	})
	
	assert_true(social.has_recent_alerts(), "has alerts after receiving")
	
	var urgent = social.get_most_urgent_alert()
	assert_eq(urgent.type, "thief_spotted", "most urgent is thief_spotted")

func test_alert_decay() -> void:
	var social = NPCSocial.new()
	
	# Add old alert
	social.received_alerts.append({
		from = null,
		type = "old_alert",
		position = Vector3.ZERO,
		time = Time.get_unix_time_from_system() - 60.0  # 60 seconds ago
	})
	
	social._decay_alerts(0.1)
	assert_eq(social.received_alerts.size(), 0, "old alerts removed")

func test_debug_info() -> void:
	var social = NPCSocial.new()
	social._last_alert_time = 0.0
	
	var info = social.get_debug_info()
	assert_true(info.can_send_alert, "can send alert when off cooldown")

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
