shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

// Grid parameters
uniform float grid_size : hint_range(0.1, 10.0) = 1.0;
uniform float line_thickness : hint_range(0.001, 0.1) = 0.02;
uniform float line_softness : hint_range(0.0, 0.1) = 0.015;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.12);

// Distance fade (night values)
uniform float fade_start : hint_range(5.0, 100.0) = 15.0;
uniform float fade_end : hint_range(10.0, 200.0) = 40.0;

// Day fade distances (further out during bright conditions)
uniform float fade_start_day : hint_range(10.0, 150.0) = 25.0;
uniform float fade_end_day : hint_range(20.0, 300.0) = 80.0;

// Day/night brightness (0.0 = night, 1.0 = day)
uniform float day_factor : hint_range(0.0, 1.0) = 1.0;
uniform float night_brightness_boost : hint_range(1.0, 3.0) = 1.5;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Calculate grid lines using world position
	vec2 grid_uv = world_pos.xz / grid_size;
	
	// Distance to nearest grid line (in each axis)
	vec2 grid_fract = fract(grid_uv);
	vec2 dist_to_line = min(grid_fract, 1.0 - grid_fract) * grid_size;
	
	// Soft line with gradient edges
	float line_x = 1.0 - smoothstep(line_thickness - line_softness, line_thickness + line_softness, dist_to_line.x);
	float line_z = 1.0 - smoothstep(line_thickness - line_softness, line_thickness + line_softness, dist_to_line.y);
	float line_alpha = max(line_x, line_z);
	
	// Distance fade from camera (further during day, closer at night)
	float camera_dist = length(world_pos - CAMERA_POSITION_WORLD);
	float current_fade_start = mix(fade_start, fade_start_day, day_factor);
	float current_fade_end = mix(fade_end, fade_end_day, day_factor);
	float distance_fade = 1.0 - smoothstep(current_fade_start, current_fade_end, camera_dist);
	
	// Day/night brightness adjustment
	// At night (day_factor = 0), boost brightness slightly
	// At day (day_factor = 1), use normal brightness
	float brightness = mix(night_brightness_boost, 1.0, day_factor);
	
	// Final color
	ALBEDO = line_color.rgb * brightness;
	ALPHA = line_alpha * line_color.a * distance_fade;
}
