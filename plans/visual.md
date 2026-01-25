# Visual Design

## Style: "Cozy Mischief"
Mischief sim + Studio Ghibli = warm, hand-crafted stealth comedy

### Core Look
- **Outlines**: Soft dark outlines on characters (toon shader)
- **Shading**: Cel/toon, 2-3 color bands
- **Colors**: Warm, slightly desaturated, nostalgic
- **Skies**: Painterly gradients, brushstroke clouds
- **Shadows**: Soft, diffused

### References
Sly Cooper (stealth) + Untitled Goose Game (mischief) + Ghibli (warmth)

---

## Color Palette

| Element | Hex | Use |
|---------|-----|-----|
| Grass | #8BC34A | Environment |
| Path | #D7CCC8 | Ground |
| Wood | #BCAAA4 | Props |
| Walls | #FFF8E1 | Buildings |
| Accent | #1565C0 | Doors, details |

---

## Day/Night Cycle

**Duration:** 10 min total (2.5 min each period)
**Transitions:** 30 sec gradual blend
**Pauses:** Menus + dialogue

| Time | Light Color | Intensity | Sky | Mood |
|------|-------------|-----------|-----|------|
| Morning | #FFD700 gold | 0.7 | Pink→orange→blue | Fresh, misty |
| Afternoon | #FFFEF0 white | 1.0 | Clear blue | Bright, alert |
| Evening | #FF7F50 amber | 0.6 | Orange→purple | Golden hour |
| Night | #6495ED blue | 0.25 | Navy, stars | Sneaky |

**TOD Change Cue:** Subtle UI + soft chime + brief text ("Evening...")

---

## NPC Vision Indicators

| State | Ground Effect | Target Marker |
|-------|---------------|---------------|
| Idle | None | None |
| Suspicious | Amber glow #FFB300 @20% | Yellow ring |
| Chasing | Orange cone #FF6600 @40% | Red ring |

---

## NPC Floating Icons

| State | Symbol | Color |
|-------|--------|-------|
| Alert | ! | #FFCC00 |
| Suspicious | ? | #4D9EFF |
| Chasing | !! | #FF3333 |
| Tired | zzz | #999999 |
| Calm | ♪ | #66CC66 |

Pop-in animation, gentle bob, billboard to camera.

---

## Player Creature

**Status:** TBD, swappable

| Trait | Value |
|-------|-------|
| Type | Fantasy/Ghibli creature (raccoon valid) |
| Size | Small, knee-height |
| Shape | Round, chubby, Totoro-like |
| Carrying | Backpack (items poke out) |

---

## Tech Implementation

### Shaders (DONE)
- `shaders/outline.gdshader` - Inverted hull outline (cull_front, vertex expansion)
- `shaders/toon.gdshader` - Soft cel shading (25% shadow darkening, not harsh black)
- `shaders/selection_ring.gdshader` - Crisp cyan circle for selected NPCs
- `scripts/ghibli_shader_applier.gd` - Auto-applies to MeshInstance3D children

**Toon Shader Settings:**
- `shadow_strength = 0.25` - Shadows only 25% darker than lit areas
- `shadow_threshold = 0.4` - Where shadow edge falls
- Soft, readable shadows while maintaining cel-shaded look

**Scene-Wide Application:**
- `SceneShaderApplier` node in main.tscn with `scene_wide = true`
- `watch_for_new = true` - Auto-applies to newly generated meshes
- Excludes: floor, ground, terrain, selection, vision, water, particles

**Usage:** Add `GhibliShaderApplier` node as child of mesh container, or use scene-wide.

### Day/Night Cycle (DONE)
- `systems/day_night_cycle.gd` - 10 min cycle, 4 periods, 30s transitions
- `ui/tod_notification.gd` - Subtle "Morning..." fade text on period change
- `ui/tod_clock_widget.gd` - Bottom-left widget with period buttons + auto toggle
- Pauses via `DayNightCycle.pause()` / `resume()`

### Vision Indicator (DONE)
- `shaders/vision_cone.gdshader` - Radial cone glow with pulse
- `npcs/vision_indicator.gd` - State-driven (idle/suspicious/chasing)
- Amber @20% suspicious, Orange @40% chasing

### Remaining
- **Target ring** - Player-lock ring indicator
