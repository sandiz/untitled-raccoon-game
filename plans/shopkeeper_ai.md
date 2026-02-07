# Shopkeeper AI

## BT Loop (Priority Order)

```
BTRepeat (forever)
└── BTSelector
    ├── [1] Chase       ← will_chase AND can_see_player
    ├── [2] Search      ← has_last_known AND lost sight (WIP)
    ├── [3] Give Up     ← stamina < 10
    └── [4] Wander      ← fallback
```

## Status

| Behavior | Status | File |
|----------|--------|------|
| Wander | ✅ | `select_random_position.gd`, `move_to_position.gd` |
| Chase | ✅ | `chase_player.gd` (catches at 1.5m) |
| Search | 🔨 WIP | `search_for_player.gd` |
| Give Up | ✅ | Wired via stamina threshold |

## Chase Trigger

```gdscript
will_chase = witnessed_theft AND stamina > 20
```

- `witnessed_theft` set when NPC sees player holding stolen item
- Resets after catch or give up

## Search Behavior (WIP)

**Trigger:** Player breaks LOS during chase

1. Go to `last_known_position`
2. Look around (rotate, animation)
3. Check 2-3 nearby points
4. Found → resume chase / Not found → give up

## States & Icons

| State | Emoji | Animation |
|-------|-------|-----------|
| idle | 😌 | Idle |
| alert | 👀 | Idle |
| chasing | 😠 | Sprint |
| searching | ❓ | Walk |
| tired | 😮‍💨 | Idle_Tired |
| caught | 😤 | Idle |
