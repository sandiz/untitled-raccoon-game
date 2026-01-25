# Shopkeeper AI

## Current Focus
**Search Behavior:** When player breaks LOS during chase, search at last known position

---

## AI Loop (Priority Order)

```
BTRepeat (forever)
└── BTSelector
    ├── [1] Chase       ← will_chase AND can_see_player
    ├── [2] Search      ← has_last_known AND lost sight ← IN PROGRESS
    ├── [3] Give Up     ← exhausted
    └── [4] Wander      ← fallback
```

---

## Status

| Behavior | Status | File |
|----------|--------|------|
| Wander | ✅ Done | `select_random_position.gd`, `move_to_position.gd` |
| Chase | ✅ Done | `chase_player.gd` (catches at 1.5m) |
| Search | 🔨 WIP | `search_for_player.gd` (exists, not wired) |
| Give Up | ⚠️ Partial | Logic exists, needs BT wiring |

---

## Search Behavior Spec

**Trigger:** Player breaks line of sight during chase

**Flow:**
1. Chase fails (can't see player for X seconds)
2. Go to `last_known_position`
3. Look around (rotate, play animation)
4. Check 2-3 nearby points
5. If found → resume chase
6. If not found → give up, return to wander

**Variables:**
- `last_known_position` - Updated while chasing
- `search_time` - Accumulated search duration
- `max_search_time` - Give up threshold (10-15s)

---

## Emotional Thresholds

| Emotion | Threshold | Effect |
|---------|-----------|--------|
| will_chase | alertness ≥ 0.3 + (annoyance ≥ 0.1 OR suspicion ≥ 0.3) | Start chase |
| will_give_up | exhaustion ≥ 0.7 | Stop chase/search |

---

## States & Icons

| State | Icon | Animation |
|-------|------|-----------|
| idle | ♪ | Idle |
| alert | ! | Idle |
| investigating | ? | Walk |
| chasing | !! | Sprint |
| searching | ? | Walk + LookAround |
| frustrated | zzz | Idle_Tired |
