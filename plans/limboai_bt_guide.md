# LimboAI Behavior Tree Best Practices

Lessons learned from debugging BT issues in this project. Follow these guidelines to avoid common pitfalls.

---

## 1. Blackboard Variables Must Be Declared

**Problem:** Runtime error "Variable X not found" when using `blackboard.get_var()`.

**Solution:** Always declare variables in the `BlackboardPlan` in your `.tres` BT file:

```
[sub_resource type="BlackboardPlan" id="BlackboardPlan_1"]
var/chase_on_cooldown/name = &"chase_on_cooldown"
var/chase_on_cooldown/type = 1  # bool
var/chase_on_cooldown/value = false
var/chase_cooldown_timer/name = &"chase_cooldown_timer"
var/chase_cooldown_timer/type = 3  # float
var/chase_cooldown_timer/value = 0.0
```

**Type IDs:**
- 1 = bool
- 2 = int
- 3 = float
- 4 = String
- 9 = Vector3

---

## 2. Prevent Double-Triggering of One-Shot Actions

**Problem:** Celebration/catch animation plays multiple times.

**Root Cause:** BT flow:
1. Task catches player → calls `on_chase_ended()` → plays celebration
2. Task waits for celebration_time → returns SUCCESS
3. BTRepeat restarts → BTSelector tries chase again
4. If player still nearby and no cooldown → catches again immediately!

**Solution:** Use BOTH a cooldown AND a guard flag:

```gdscript
# In BT task - set cooldown IMMEDIATELY when catching
if distance < stop_distance:
    blackboard.set_var(&"chase_on_cooldown", true)  # Prevent re-entry
    blackboard.set_var(&"chase_cooldown_timer", 5.0)
    _caught_player = true
    _on_caught_player(player)
    return RUNNING

# Check cooldown at start of _tick()
func _tick(delta: float) -> Status:
    if blackboard.get_var(&"chase_on_cooldown", false):
        return FAILURE  # Skip chase while on cooldown
```

```gdscript
# In NPC script - guard flag for callbacks
var _chase_end_handled: bool = false

func on_chase_ended(success: bool) -> void:
    if _chase_end_handled:
        return
    _chase_end_handled = true
    # ... do stuff ...
    _chase_end_handled = false
```

---

## 3. Always Call move_and_slide() When Stopping

**Problem:** NPC slides/drifts when stopping movement.

**Root Cause:** Setting `velocity = Vector3.ZERO` doesn't apply to physics until `move_and_slide()` is called.

**Solution:** Always pair velocity changes with move_and_slide():

```gdscript
# WRONG - causes sliding
agent.velocity = Vector3.ZERO
return SUCCESS

# CORRECT - stops immediately
agent.velocity = Vector3.ZERO
agent.move_and_slide()
return SUCCESS
```

**Apply in ALL stopping scenarios:**
- Celebration/caught state
- Idle state
- Wait state
- Any task that stops movement

---

## 4. Avoid Async Await in BT Callbacks

**Problem:** State becomes inconsistent, animations play at wrong times.

**Root Cause:** `await` in a callback creates a parallel execution path that races with BT timing.

```gdscript
# PROBLEMATIC - races with BT
func on_chase_ended(success: bool) -> void:
    play_celebration()
    await get_tree().create_timer(2.0).timeout  # BT continues while waiting!
    set_state("idle")  # May conflict with BT state
```

**Solution:** Let BT handle all timing. Callbacks should be instant:

```gdscript
# CORRECT - BT handles timing
func on_chase_ended(success: bool) -> void:
    play_celebration()
    set_state("caught")
    # BT task waits for celebration_time, then sets idle state
```

---

## 5. Sync Visual Indicators with Actual Values

**Problem:** Visual perception cone doesn't match actual detection range.

**Solution:** Keep values synchronized:

| Setting | npc_perception.gd | perception_range.gd (visual) |
|---------|-------------------|------------------------------|
| Range   | sight_range: 10.0 | vision_range: 10.0          |
| FOV     | fov_angle: 90.0   | vision_angle: 90.0          |

---

## 6. State Transitions in BT Tasks

**Problem:** UI shows wrong state after BT transitions.

**Solution:** Set state in BT tasks when transitioning:

```gdscript
# In select_random_position.gd (start of wander)
func _tick(_delta: float) -> Status:
    if agent.has_method("set_current_state"):
        var current = agent.get("current_state")
        if current != "idle":
            agent.set_current_state("idle")
    # ... rest of logic
```

---

## 7. BTSelector Re-evaluation Limitation

**Problem:** BTSelector doesn't re-evaluate higher priority tasks while a lower task returns RUNNING.

**Solution:** Add abort checks inside long-running tasks:

```gdscript
# In interruptible_wait.gd
func _tick(delta: float) -> Status:
    # Manual check for higher priority condition
    if blackboard.has_var(&"emotional_state"):
        var emo = blackboard.get_var(&"emotional_state")
        if emo and emo.will_chase:
            return FAILURE  # Abort wait, let selector try chase
    
    # ... normal wait logic
```

---

## 8. Minimum Distance for Wander Positions

**Problem:** NPC stands in place because wander target is too close.

**Solution:** Ensure minimum distance in position selection:

```gdscript
@export var min_distance: float = 3.0  # At least 3 meters away

func _tick(_delta: float) -> Status:
    var random_pos = home + direction * randf_range(min_distance, radius)
```

---

## 9. Save Manager - Only Save Safe States

**Problem:** Game loads with NPC in "chasing" or "caught" state.

**Solution:** Only autosave when all NPCs are idle:

```gdscript
func _any_npc_active() -> bool:
    var npcs = get_tree().get_nodes_in_group("npc")
    const SAFE_STATES := ["idle", ""]
    for npc in npcs:
        var state = npc.get("current_state") if npc.get("current_state") else "idle"
        if state.to_lower() not in SAFE_STATES:
            return true
    return false

func save_simulation(slot: String) -> bool:
    if _any_npc_active():
        return false  # Don't save during action
    # ... save logic
```

---

## Common BT Structure

```
BTRepeat (forever)
└── BTSelector
    ├── ChasePlayer (high priority, returns FAILURE when no target/on cooldown)
    └── BTSequence (wander - low priority fallback)
        ├── SelectRandomPosition
        ├── MoveToPosition
        ├── PlayIdle
        └── InterruptibleWait
```

**Key Points:**
- Chase returns FAILURE when not chasing → selector falls through to wander
- Chase returns RUNNING while chasing → stays in chase
- Chase returns SUCCESS after catch → selector succeeds → repeat restarts
- Cooldown prevents immediate re-chase after SUCCESS
