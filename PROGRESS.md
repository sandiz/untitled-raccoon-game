# Untitled Raccoon Game

## Current Focus
**Meter System Refactor** - Implementing 3-meter system (Stamina, Suspicion, Temper)

---

## Current State

- Player with WASD movement, jump, run, honk
- Shopkeeper NPC with wander + chase behavior
- Emotional state system (4 meters → refactoring to 3)
- Ghibli-style toon shading + outlines
- Day/night cycle (10 min, 4 periods) with distinct color palettes
- Game speed controls (1-4 keys)
- TOD clock widget (V to expand)
- NPC info panel (N to expand)
- Speech bubble above NPC (status emoji, dark theme)
- Vision cone + hearing circle visualization
- Head tracking (NPC looks at player when spotted)
- Smooth camera with target switching

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Shift | Run |
| Space | Jump |
| E/Q | Honk |
| V | Toggle TOD widget / perception viz |
| N | Toggle NPC info panel |
| 1-4 | Game speed |
| Scroll/Pinch | Camera zoom |
| Right-drag | Camera rotate |
| Click NPC | Select (camera follows) |

## What's Working

| Feature | Status |
|---------|--------|
| Wander loop | ✅ Done |
| Chase + catch | ✅ Done |
| Perception (120° FOV, 8m) | ✅ Done |
| Vision cone visualization | ✅ Done |
| Hearing circle visualization | ✅ Done |
| Head tracking | ✅ Done |
| State-based cone colors | ✅ Done |
| Emotional state system | ✅ Done (refactoring) |
| Ghibli outline shader | ✅ Done |
| Day/night cycle | ✅ Done |
| Morning/Afternoon distinction | ✅ Done |
| Game speed controls | ✅ Done |
| TOD clock widget | ✅ Done |
| NPC info panel | ✅ Done |
| Speech bubble | ✅ Done |
| Smooth camera follow | ✅ Done |
| Camera target switching | ✅ Done |
| Sleek notifications | ✅ Done |

## 3-Meter System (Decided)

Replacing 4 overlapping meters with 3 clear ones:

| Meter | Icon | Player Strategy | Effect |
|-------|------|-----------------|--------|
| **Stamina** | ⚡ | "Tire them out" | Low = gives up, must rest |
| **Suspicion** | 👀 | "Stay hidden" | High = wider FOV, faster reactions |
| **Temper** | 🔥 | "Don't push too hard" | High = faster, won't give up, remembers |

### Why 3 Meters
- Each meter = one clear player strategy
- No overlap (unlike Alert/Suspicion in old system)
- Creates emergent behavior combos
- ~2 hour refactor, not a rewrite

### Temper Value
Temper creates **consequences that persist across encounters**:
- First theft: calm chase, gives up easily
- Fifth theft: FURIOUS, faster, searches longer, harder to escape
- Enables "escalation" gameplay and viral "revenge chase" moments

See `plans/meters_design.md` and `plans/competitive_analysis.md` for full details.

## Competitive Position

| Metric | Current | With 3 Meters | Full Features |
|--------|---------|---------------|---------------|
| Emergent gameplay | 3/10 | 6/10 | 8/10 |
| Viral potential | 2/10 | 5/10 | 8/10 |
| Unique vs UGG | 3/10 | 6/10 | 8/10 |

Key differentiators vs Untitled Goose Game:
- Dynamic meter combinations (not static NPC states)
- Stamina-based chases (not boundary-based)
- Temper persists (NPCs remember)
- Gradual suspicion buildup (not binary detection)

## Next Up

| # | Feature | Type | Effort |
|---|---------|------|--------|
| 1 | **Implement 3-meter system** | Refactor | 2 hours |
| 2 | Expressive NPC reactions | Polish | Medium |
| 3 | Near-miss feedback | Polish | Low |
| 4 | Items to steal/throw | Gameplay | Medium |
| 5 | Search behavior (lost player) | BT | Medium |

## Future

| Feature | Notes |
|---------|-------|
| Multiple NPCs | Customer, pet with different detection |
| Environment manipulation | Lights, distractions, traps |
| Combo/style system | Reward chaining actions |
| LLM narrator/dialogue | AI-generated contextual text |

## Design Docs

- `plans/meters_design.md` - 3-meter system specification
- `plans/competitive_analysis.md` - UGG/Hitman comparison, virality factors
- `plans/emotional_system.md` - Original 4-meter system (deprecated)
