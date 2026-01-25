shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Brightness controlled by DayNightCycle (multiplier on final output)
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform bool use_texture = false;

// Toon shading
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.3;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec4 tex_color = use_texture ? texture(albedo_texture, UV) : vec4(1.0);
	ALBEDO = base_color.rgb * tex_color.rgb;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float light_intensity = NdotL * 0.5 + 0.5;
	
	// Toon shading step
	float shade = smoothstep(shadow_threshold - 0.1, shadow_threshold + 0.1, light_intensity);
	float shadow = mix(1.0 - shadow_strength, 1.0, shade);
	
	// Apply light color, shadow, attenuation, and brightness
	vec3 final_color = ALBEDO * shadow * LIGHT_COLOR * ATTENUATION * brightness;
	DIFFUSE_LIGHT += final_color;
}
