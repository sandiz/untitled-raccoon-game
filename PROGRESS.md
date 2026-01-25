# Untitled Raccoon Game

## Current Focus
**Visual Polish** - UI, day/night, outlines

---

## Current State

- Player with WASD movement, jump, run, honk
- Shopkeeper NPC with wander + chase behavior
- Emotional state system (4 meters - considering simplifying to 3)
- Ghibli-style toon shading + outlines
- Day/night cycle (10 min, 4 periods)
- Game speed controls (1-4 keys)
- TOD clock widget (top-left, V to expand, shows speed/ratio in collapsed view)
- NPC info panel (top-right, N to expand, starts collapsed, typewriter effect)
- Speech bubble above NPC (status emoji, dark theme, synced via data store)
- Shared widget architecture (BaseWidget base class, NPCDataStore for sync)

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Shift | Run |
| Space | Jump |
| E/Q | Honk |
| V | Toggle TOD widget expand |
| N | Toggle NPC info panel expand |
| 1-4 | Game speed |
| Scroll/Pinch | Camera zoom (max 1.8x) |

## What's Working

| Feature | Status |
|---------|--------|
| Wander loop | ✅ Done |
| Chase + catch | ✅ Done |
| Perception (120° FOV, 8m) | ✅ Done |
| Emotional state system | ✅ Done |
| Ghibli outline shader | ✅ Done |
| Day/night cycle | ✅ Done |
| Vision indicator (ground glow) | ✅ Done |
| Game speed controls | ✅ Done |
| TOD clock widget | ✅ Done |
| NPC info panel (fold/expand) | ✅ Done |
| NPC portrait (rounded corners) | ✅ Done |
| Pause functionality | ✅ Done |
| Speech bubble (status emoji, dark) | ✅ Done |
| Button focus release (all widgets) | ✅ Done |
| Widget sync via NPCDataStore | ✅ Done |
| BaseWidget shared styling | ✅ Done |
| Speed options below 1x | ✅ Done |

## Speech Bubble Features

- Dark translucent style (matches other widgets)
- Status-based emoji (😌 idle, 👀 alert, 😠 chasing, etc.)
- Tail flush with bubble body (no bottom border, renders behind)
- Pop-in animation (TRANS_BACK bounce)
- Typewriter text effect
- Subtle bob animation
- **Synced with NPC info panel** via NPCDataStore (single source of truth)
- **Message priority system** ✅ High-prio messages (chasing, caught) stay on screen longer

## Speed Options

Array-based speeds: `[0.1, 0.25, 0.5, 1.0, 2.0, 4.0]`
Labels: `["⅒x", "¼x", "½x", "1x", "2x", "4x"]`

## Pending Decisions

### Emotional Meters
Current 4 meters (Alert, Annoyed, Tired, Suspicious) have overlap.

**Proposed 3-meter system:**
| Meter | Drives | Player manipulates by |
|-------|--------|----------------------|
| ⚡ Energy | Chase duration, give up | Making them run |
| 🔥 Agitation | Aggression, detection | Mischief, being spotted |
| 👀 Awareness | FOV, reaction time | Distractions, hiding |

## Future: LLM Integration

| Feature | Notes |
|---------|-------|
| Narrator text generation | LLM picks contextual narrator lines |
| Dialogue text generation | LLM picks NPC dialogue based on state/mood |

## Next Up (After Visual Polish)

| # | Feature | Type |
|---|---------|------|
| 1 | Finalize meter system | Design |
| 2 | LLM narrator/dialogue | AI/LLM |
| 3 | Search behavior | BT |
| 4 | Give up when exhausted | BT |
| 5 | Item stealing detection | BT |

## UI Style Guide

- **Background:** `rgba(15, 15, 20, 0.92)` - Dark translucent
- **Border:** `rgba(65, 65, 75, 0.9)` - Subtle gray
- **Text:** `#F5F5F0` - Cream white
- **Corners:** 10px radius (scaled)
- **Font:** JetBrains Mono
- **Scale:** 2.0x default for readability
