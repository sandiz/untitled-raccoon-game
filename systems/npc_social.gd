class_name NPCSocial
extends RefCounted
## NPC Social system - handles communication between NPCs.
## Allows NPCs to warn each other, share information, and coordinate.

# ═══════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════

signal alert_received(from_npc: Node3D, alert_type: String, target_position: Vector3)
signal help_requested(from_npc: Node3D, reason: String)
signal gossip_received(from_npc: Node3D, info: Dictionary)

# ═══════════════════════════════════════
# STATIC SOCIAL NETWORK
# ═══════════════════════════════════════

## Global alert channel - all NPCs can subscribe
static var _alert_listeners: Array[Callable] = []

## Register to receive alerts
static func register_listener(callback: Callable) -> void:
	if callback not in _alert_listeners:
		_alert_listeners.append(callback)

## Unregister from alerts
static func unregister_listener(callback: Callable) -> void:
	_alert_listeners.erase(callback)

## Broadcast an alert to all NPCs in range
static func broadcast_alert(from_npc: Node3D, alert_type: String, target_position: Vector3, broadcast_range: float = 30.0) -> void:
	for callback in _alert_listeners:
		if callback.is_valid():
			callback.call(from_npc, alert_type, target_position, broadcast_range)

# ═══════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════

## How far this NPC can call for help
@export var call_range: float = 25.0

## How far this NPC can hear calls
@export var listen_range: float = 30.0

## Cooldown between sending alerts (seconds)
@export var alert_cooldown: float = 5.0

# ═══════════════════════════════════════
# STATE
# ═══════════════════════════════════════

## Owner NPC reference
var owner_npc: Node3D = null

## Last alert sent time
var _last_alert_time: float = 0.0

## Received alerts (for decision making)
var received_alerts: Array[Dictionary] = []  # [{from, type, position, time}]

## Trust level with other NPCs (could be expanded)
var trust_levels: Dictionary = {}  # NPC -> float (0-1)

# ═══════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════

func setup(npc: Node3D) -> void:
	owner_npc = npc
	NPCSocial.register_listener(_on_alert_received)

func cleanup() -> void:
	NPCSocial.unregister_listener(_on_alert_received)

func update(delta: float) -> void:
	_decay_alerts(delta)

# ═══════════════════════════════════════
# ALERT SYSTEM
# ═══════════════════════════════════════

## Alert types with their priorities
enum AlertType {
	SUSPICIOUS = 0,   # "I saw something odd"
	THIEF_SPOTTED = 1, # "Someone took something!"
	HELP_NEEDED = 2,   # "Come help me!"
	ALL_CLEAR = 3,     # "False alarm, never mind"
}

## Send an alert to nearby NPCs
func send_alert(alert_type: String, target_position: Vector3) -> bool:
	if not owner_npc:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	if current_time - _last_alert_time < alert_cooldown:
		return false  # On cooldown
	
	_last_alert_time = current_time
	NPCSocial.broadcast_alert(owner_npc, alert_type, target_position, call_range)
	return true

## Request help specifically
func call_for_help(_reason: String, target_position: Vector3) -> bool:
	if send_alert("help_needed", target_position):
		# Could trigger special behavior in nearby NPCs
		return true
	return false

## Signal all clear to nearby NPCs
func signal_all_clear() -> bool:
	if not owner_npc:
		return false
	return send_alert("all_clear", owner_npc.global_position)

# ═══════════════════════════════════════
# ALERT RESPONSES
# ═══════════════════════════════════════

## Check if we've received recent alerts
func has_recent_alerts(max_age: float = 10.0) -> bool:
	var current_time = Time.get_unix_time_from_system()
	for alert in received_alerts:
		if current_time - alert.time < max_age and alert.type != "all_clear":
			return true
	return false

## Get the most urgent recent alert
func get_most_urgent_alert(max_age: float = 10.0) -> Dictionary:
	var current_time = Time.get_unix_time_from_system()
	var priority_order = ["help_needed", "thief_spotted", "suspicious"]
	
	for alert_type in priority_order:
		for alert in received_alerts:
			if alert.type == alert_type and current_time - alert.time < max_age:
				return alert
	
	return {}

## Get position to investigate based on alerts
func get_alert_investigate_position() -> Vector3:
	var alert = get_most_urgent_alert()
	if alert:
		return alert.position
	return Vector3.ZERO

## Clear old alerts (e.g., after investigating)
func clear_alerts() -> void:
	received_alerts.clear()

# ═══════════════════════════════════════
# DEBUG INFO
# ═══════════════════════════════════════

func get_debug_info() -> Dictionary:
	var alert_info: Array[Dictionary] = []
	var current_time = Time.get_unix_time_from_system()
	
	for alert in received_alerts:
		alert_info.append({
			type = alert.type,
			from = alert.from.name if is_instance_valid(alert.from) else "unknown",
			age = current_time - alert.time
		})
	
	return {
		alerts_received = alert_info,
		cooldown_remaining = maxf(0, alert_cooldown - (current_time - _last_alert_time)),
		can_send_alert = current_time - _last_alert_time >= alert_cooldown
	}

# ═══════════════════════════════════════
# PRIVATE HELPERS
# ═══════════════════════════════════════

func _on_alert_received(from_npc: Node3D, alert_type: String, target_position: Vector3, _broadcast_range: float) -> void:
	if not owner_npc or from_npc == owner_npc:
		return  # Ignore own alerts
	
	# Check if we're in range
	var distance = owner_npc.global_position.distance_to(from_npc.global_position)
	if distance > listen_range:
		return
	
	# Store the alert
	received_alerts.append({
		from = from_npc,
		type = alert_type,
		position = target_position,
		time = Time.get_unix_time_from_system()
	})
	
	# Limit stored alerts
	while received_alerts.size() > 20:
		received_alerts.pop_front()
	
	# Emit signal for behavior tree / NPC script to handle
	alert_received.emit(from_npc, alert_type, target_position)
	
	if alert_type == "help_needed":
		help_requested.emit(from_npc, "help")

func _decay_alerts(_delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	# Remove alerts older than 30 seconds
	received_alerts = received_alerts.filter(func(a): return current_time - a.time < 30.0)

# ═══════════════════════════════════════
# GOSSIP SYSTEM (Future expansion)
# ═══════════════════════════════════════

## Share information with another NPC
func share_info(other_npc_social: NPCSocial, info: Dictionary) -> void:
	if other_npc_social:
		other_npc_social._receive_gossip(owner_npc, info)

func _receive_gossip(from_npc: Node3D, info: Dictionary) -> void:
	# Could store gossip, affect trust, etc.
	gossip_received.emit(from_npc, info)
