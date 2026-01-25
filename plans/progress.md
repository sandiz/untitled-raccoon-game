# Progress

## Day/Night Cycle

### What Works ✅
- 4 TOD periods: Morning, Afternoon, Evening, Night
- Skybox switching (day/night) during TOD transitions
- Fog color changes per TOD period
- Moonlit blue lighting at night
- TODSettings resource for tweakable values
- Smooth transitions between periods
- Sleek TOD clock widget (expandable)

### Fixed Issues ✅
- **Floor warping**: Enabled debanding in project settings
- **TOD transition bug**: Removed duplicate blending at period boundaries
- **Floor edge visible**: Light exponential fog (0.005) + camera far clip (60m) + large floor (2000x2000)

## Environment
- Floor: 2000x2000 (edge at 1000m, invisible)
- Fog: Light exponential (density 0.005), matches sky color
- Camera: Far clip 60m
- Skyboxes: goose_sky.png (day), night_moonlit_sky.png (night)

## Gameplay
- Mouse-based: click to possess/influence NPCs
- Raccoon is passive avatar with `possess(npc)` / `release()` API
- No WASD movement

## UI
- NPC speech bubbles with padding and outline
- Sleek TOD clock widget (icon + time + expand)

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
