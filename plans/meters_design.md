# Meter System Design

## Core Gameplay Loops

The raccoon player wants to:
1. **Sneak** - Stay hidden, avoid detection
2. **Steal** - Grab items without getting caught  
3. **Escape** - Outrun/outmaneuver when spotted
4. **Manipulate** - Tire out, distract, trick the shopkeeper

Each meter should give the player a **lever to pull**.

---

## Option A: Three Meters (Recommended)

| Meter | Icon | Range | What it represents |
|-------|------|-------|-------------------|
| **Stamina** | ⚡ | 0-100 | Physical energy |
| **Suspicion** | 👀 | 0-100 | How much they're looking for you |
| **Temper** | 🔥 | 0-100 | How angry/aggressive they are |

### Stamina ⚡
**The "tire them out" lever**

| Increases | Decreases |
|-----------|-----------|
| Standing still (+2/sec) | Chasing (-5/sec) |
| Idle patrol (+1/sec) | Running (-3/sec) |
| | Searching (-1/sec) |

| Level | Effect |
|-------|--------|
| 80-100 | Full speed, long chase |
| 50-80 | Normal speed |
| 20-50 | Slower, shorter chase |
| 0-20 | **Exhausted** - gives up, must rest |

### Suspicion 👀
**The "stay hidden" lever**

| Increases | Decreases |
|-----------|-----------|
| Spotting player (+30) | Time passes (-3/sec) |
| Hearing sound (+15) | Nothing suspicious (-5/sec) |
| Item missing (+20) | Distraction (-10) |
| Lost sight of player (+10) | |

| Level | Effect |
|-------|--------|
| 80-100 | **Hunting** - Wide FOV (150°), fast reactions |
| 50-80 | **Alert** - Normal FOV (120°), searching |
| 20-50 | **Wary** - Narrow FOV (90°), slow reactions |
| 0-20 | **Oblivious** - Tiny FOV (60°), easily sneaked |

### Temper 🔥
**The "risk vs reward" lever**

| Increases | Decreases |
|-----------|-----------|
| Being tricked (+15) | Time passes (-1/sec) |
| Item stolen (+25) | Catching player (-50) |
| Long chase (+5/sec) | Resting (-2/sec) |
| Losing player (+10) | |

| Level | Effect |
|-------|--------|
| 80-100 | **Furious** - Fast chase, won't give up easily |
| 50-80 | **Annoyed** - Aggressive chase |
| 20-50 | **Calm** - Normal behavior |
| 0-20 | **Content** - Slow to react, forgiving |

---

## Emergent Behaviors

| Stamina | Suspicion | Temper | Behavior |
|---------|-----------|--------|----------|
| High | High | High | **DANGER** - Fast, alert, aggressive |
| High | Low | Low | **Easy mark** - Fresh but oblivious |
| Low | High | High | **Frustrated** - Knows you're there, can't chase |
| Low | Low | Low | **Nap time** - Exhausted, checked out |
| High | High | Low | **Professional** - Alert but calm, methodical |
| Low | High | Low | **Tired guard** - Watching but slow |

---

## State Machine (derived from meters)

```
EXHAUSTED:  stamina < 20
CHASING:    suspicion > 60 AND can_see_player AND stamina > 20
HUNTING:    suspicion > 70 AND NOT can_see_player
SEARCHING:  suspicion > 40 AND lost_player_recently
ALERT:      suspicion > 30
IDLE:       default
```

---

## Option B: Two Meters (Simpler)

| Meter | Combines |
|-------|----------|
| **Energy** ⚡ | Stamina + inverse of Temper |
| **Alertness** 👀 | Suspicion + Temper |

Simpler but less emergent gameplay.

---

## Option C: Four Meters (Current)

Keep Alertness, Annoyance, Exhaustion, Suspicion.

Issues:
- Alertness and Suspicion overlap
- Too many numbers to track
- Less clear player agency

---

## Recommendation

**Option A (Three Meters)** because:
1. Each meter = one clear player strategy
2. Combinations create 8+ distinct NPC behaviors
3. Easy to understand, hard to master
4. Visual indicators work well (3 bars or icons)

---

## Visual Display

```
┌─────────────────────┐
│ ⚡ ████████░░ 80%   │  Stamina
│ 👀 ███░░░░░░ 35%   │  Suspicion  
│ 🔥 █████░░░░ 55%   │  Temper
└─────────────────────┘
```

Or compact icons with fill:
```
⚡🔋 👀◐ 🔥◔
```
