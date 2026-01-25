extends SceneTree
## Tests for NPCEmotionalState system
## Run: godot --headless -s tests/test_emotional_state.gd

const NPCEmotionalState = preload("res://systems/npc_emotional_state.gd")

var tests_passed := 0
var tests_failed := 0

func _init() -> void:
	print("\n=== NPCEmotionalState Tests ===\n")
	
	test_initial_values()
	test_clamping()
	test_decay()
	test_event_handlers()
	test_derived_properties()
	test_thresholds()
	
	print("\n--- Results: %d passed, %d failed ---\n" % [tests_passed, tests_failed])
	quit(tests_failed)

func test_initial_values() -> void:
	var state = NPCEmotionalState.new()
	
	assert_eq(state.alertness, 0.2, "alertness starts at 0.2")
	assert_eq(state.annoyance, 0.0, "annoyance starts at 0.0")
	assert_eq(state.exhaustion, 0.0, "exhaustion starts at 0.0")
	assert_eq(state.suspicion, 0.0, "suspicion starts at 0.0")

func test_clamping() -> void:
	var state = NPCEmotionalState.new()
	
	state.alertness = 5.0
	assert_eq(state.alertness, 1.0, "alertness clamps to 1.0")
	
	state.alertness = -1.0
	assert_eq(state.alertness, 0.0, "alertness clamps to 0.0")

func test_decay() -> void:
	var state = NPCEmotionalState.new()
	state.alertness = 1.0
	state.annoyance = 1.0
	
	# Simulate 1 second
	state.update(1.0)
	
	assert_lt(state.alertness, 1.0, "alertness decays")
	assert_lt(state.annoyance, 1.0, "annoyance decays")

func test_event_handlers() -> void:
	var state = NPCEmotionalState.new()
	var initial_alertness = state.alertness
	
	state.on_heard_honk()
	assert_gt(state.alertness, initial_alertness, "honk increases alertness")
	assert_gt(state.suspicion, 0.0, "honk increases suspicion")
	
	state.reset()
	state.on_saw_target()
	assert_gt(state.alertness, 0.5, "saw_target spikes alertness")
	
	state.reset()
	state.on_saw_stealing()
	assert_eq(state.alertness, 1.0, "stealing maxes alertness")

func test_derived_properties() -> void:
	var state = NPCEmotionalState.new()
	
	# will_chase: alertness >= 0.3 and exhaustion < 0.7
	state.alertness = 0.5
	state.exhaustion = 0.0
	assert_true(state.will_chase, "will chase when alert and not exhausted")
	
	state.exhaustion = 0.8
	assert_false(state.will_chase, "won't chase when exhausted")
	
	# will_give_up: exhaustion >= 0.7
	state.exhaustion = 0.7
	assert_true(state.will_give_up, "gives up when exhausted")
	
	# will_call_help: annoyance >= 0.8
	state.annoyance = 0.9
	assert_true(state.will_call_help, "calls help when very annoyed")

func test_thresholds() -> void:
	var state = NPCEmotionalState.new()
	
	# Test mood derivation
	state.alertness = 0.2
	state.annoyance = 0.0
	state.exhaustion = 0.0
	assert_eq(state.mood, "calm", "mood is calm at baseline")
	
	state.alertness = 0.8
	assert_eq(state.mood, "alarmed", "mood is alarmed at high alertness")
	
	state.alertness = 0.2
	state.annoyance = 0.8
	assert_eq(state.mood, "angry", "mood is angry at high annoyance")

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

func assert_gt(a: float, b: float, msg: String) -> void:
	if a > b:
		print("  ✓ %s" % msg)
		tests_passed += 1
	else:
		print("  ✗ %s (got %s, expected > %s)" % [msg, a, b])
		tests_failed += 1

func assert_lt(a: float, b: float, msg: String) -> void:
	if a < b:
		print("  ✓ %s" % msg)
		tests_passed += 1
	else:
		print("  ✗ %s (got %s, expected < %s)" % [msg, a, b])
		tests_failed += 1
