# Progress

## Day/Night Cycle

### What Works
- 4 TOD periods: Morning, Afternoon, Evening, Night
- Night skybox (`assets/skybox/night_moonlit_sky.png`)
- Moonlit blue lighting at night
- TODSettings resource for tweakable values (`systems/default_tod_settings.tres`)
- Floor color transitions with TOD
- Shadows on characters
- TOD clock widget + notifications

### Known Issue: Floor Warping
**Problem:** Slight circular warping artifacts on floor during TOD transitions

**What we tried:**
- Custom shader with brightness uniform → warping
- Unshaded shader → no warping but no shadows
- Large floor (4000x4000) → severe warping
- Smaller floor (100x100) → less warping but still present
- StandardMaterial3D with scene lighting → still warps
- Shadow bias adjustments → didn't help
- Single shadow cascade mode → didn't help

**Root cause (suspected):**
- Godot's lighting interpolation on flat surfaces causes precision artifacts
- Not specific to our shader - happens with StandardMaterial3D too

**To research:**
- How other games handle day/night on terrain (vertex colors, baked lighting, post-process color grading)
- Godot terrain plugins approach
- Tiled floor chunks instead of single large plane

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
