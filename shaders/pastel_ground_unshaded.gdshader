shader_type spatial;
render_mode unshaded, cull_back;

// Brightness controlled by DayNightCycle
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

// Base grass color (soft Ghibli green)
uniform vec4 color_grass : source_color = vec4(0.55, 0.70, 0.48, 1.0);

// Night tint color (blueish)
uniform vec4 night_tint : source_color = vec4(0.4, 0.5, 0.65, 1.0);

void fragment() {
    // Simple day/night transition - no noise, no warping
    vec3 day_color = color_grass.rgb;
    vec3 night_color = color_grass.rgb * night_tint.rgb * 0.5;
    
    // Remap brightness: 0.5-1.0 -> 0.0-1.0
    float day_amount = clamp((brightness - 0.5) * 2.0, 0.0, 1.0);
    
    ALBEDO = mix(night_color, day_color, day_amount);
}
