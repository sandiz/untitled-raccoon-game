# Progress

## Day/Night Cycle

### What Works ✅
- 4 TOD periods: Morning, Afternoon, Evening, Night
- Night skybox (`assets/skybox/night_moonlit_sky.png`)
- Moonlit blue lighting at night
- TODSettings resource for tweakable values (`systems/default_tod_settings.tres`)
- Floor color transitions with TOD (500x500 size)
- Shadows on characters
- Sleek TOD clock widget (expandable with period jump + speed controls)
- Smooth transitions between periods (fixed 5am sunny → 6am dark bug)

### Fixed: Floor Warping ✅
**Problem:** Circular warping artifacts on floor during TOD transitions

**Solution:** Enable debanding in Project Settings
```
[rendering]
anti_aliasing/quality/use_debanding=true
```

### Fixed: TOD Transition Bug ✅
**Problem:** Scene became sunny at 5am then dark again at 6am

**Solution:** Removed duplicate blending at start-of-period (only blend at end-of-period now)

## Gameplay

### Player Control
- Removed WASD movement from raccoon
- Game is mouse-based: click to possess/influence NPCs
- Raccoon is passive avatar with `possess(npc)` / `release()` API

## UI
- NPC speech bubbles with proper padding and outline
- Sleek TOD clock widget (icon + time + expand button)

### Current Floor Setup
- 100x100 PlaneMesh
- StandardMaterial3D (green grass color)
- Scene lighting handles TOD (no custom shader)
- Single shadow cascade, bias 0.15

## Files Added/Modified
- `systems/tod_settings.gd` - TODSettings resource class
- `systems/default_tod_settings.tres` - Default TOD values
- `systems/day_night_cycle.gd` - Updated with settings support
- `assets/skybox/night_moonlit_sky.png` - Night skybox
- `shaders/floor_simple.gdshader` - Simple floor shader (not currently used)
- Removed: `shaders/vision_cone.gdshader`, `npcs/vision_indicator.gd`
