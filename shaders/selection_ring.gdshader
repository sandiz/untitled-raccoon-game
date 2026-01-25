shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

// Crisp circle selection indicator
uniform vec4 ring_color : source_color = vec4(0.4, 0.9, 1.0, 0.8);
uniform float radius : hint_range(0.0, 1.0) = 0.85;
uniform float thickness : hint_range(0.001, 0.1) = 0.04;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	
	// Crisp circle outline
	float circle = abs(dist - radius);
	float ring = 1.0 - step(thickness, circle);
	
	ALBEDO = ring_color.rgb;
	ALPHA = ring * ring_color.a;
}
