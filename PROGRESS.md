# Untitled Raccoon Game

## Current Focus
**Visual Polish** - UI, day/night, outlines

---

## Current State

- Player with WASD movement, jump, run, honk
- Shopkeeper NPC with wander + chase behavior
- Emotional state, perception, social systems
- Ghibli-style toon shading + outlines
- Day/night cycle (10 min, 4 periods)
- Game speed controls (1-4 keys)
- TOD clock widget (top-left, V to expand)
- NPC info panel (top-right, wildlife documentary style)

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Shift | Run |
| Space | Jump |
| E/Q | Honk |
| V | Toggle TOD widget expand |
| F3 | Debug overlay |
| 1-4 | Game speed |

## What's Working

| Feature | Status |
|---------|--------|
| Wander loop | ✅ Done |
| Chase + catch | ✅ Done |
| Perception (120° FOV, 8m) | ✅ Done |
| Emotional state system | ✅ Done |
| State icons (!, ?, !!) | ✅ Done |
| Ghibli outline shader | ✅ Done |
| Day/night cycle | ✅ Done |
| Vision indicator (ground glow) | ✅ Done |
| Game speed controls | ✅ Done |
| TOD clock widget | ✅ Done |
| NPC info panel | ✅ Done |
| Consistent UI style (dark translucent) | ✅ Done |

## Current Sprint: Visual Polish

| # | Task | Type | Notes |
|---|------|------|-------|
| 1 | UI look & feel | UI | Final polish pass |
| 2 | Day/night visuals | Visual | Time-based lighting/mood |
| 3 | Outline shader polish | Visual | Ghibli-style tweaks |

## Future: LLM Integration

| Feature | Notes |
|---------|-------|
| Narrator text generation | LLM picks contextual narrator lines |
| Dialogue text generation | LLM picks NPC dialogue based on state/mood |

*(Do visual polish first, then LLM integration)*

## Next Up (After Visual Polish)

| # | Feature | Type | Notes |
|---|---------|------|-------|
| 1 | LLM narrator/dialogue | AI/LLM | Dynamic text generation |
| 2 | Search behavior | BT | When player escapes LOS |
| 3 | Give up when exhausted | BT | Wire up will_give_up |
| 4 | Item stealing detection | BT | P2 |

## UI Style Guide

- **Background:** `rgba(15, 15, 20, 0.92)` - Dark translucent
- **Border:** `rgba(65, 65, 75, 0.9)` - Subtle gray
- **Text:** `#F5F5F0` - Cream white
- **Corners:** 10px radius (scaled)
- **Font:** JetBrains Mono
- **Scale:** 2.0x default for readability
