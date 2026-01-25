shader_type spatial;
render_mode unshaded, depth_test_disabled;

// Post-process outline using depth and normal edge detection
// Cleaner than inverted hull - no gaps or artifacts

uniform vec4 outline_color : source_color = vec4(0.15, 0.1, 0.1, 1.0);
uniform float outline_thickness : hint_range(0.5, 3.0) = 1.0;
uniform float depth_threshold : hint_range(0.0, 1.0) = 0.1;
uniform float normal_threshold : hint_range(0.0, 1.0) = 0.3;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_linear_mipmap;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float get_depth(vec2 uv) {
	float depth = texture(depth_texture, uv).r;
	return depth;
}

vec3 get_normal(vec2 uv) {
	return texture(normal_texture, uv).rgb * 2.0 - 1.0;
}

void fragment() {
	vec2 pixel_size = 1.0 / VIEWPORT_SIZE * outline_thickness;
	
	// Sample center
	float depth_center = get_depth(SCREEN_UV);
	vec3 normal_center = get_normal(SCREEN_UV);
	
	// Sample neighbors (Roberts cross pattern for crisp edges)
	vec2 offsets[4] = {
		vec2(-1.0, -1.0),
		vec2(1.0, -1.0),
		vec2(-1.0, 1.0),
		vec2(1.0, 1.0)
	};
	
	float depth_diff = 0.0;
	float normal_diff = 0.0;
	
	for (int i = 0; i < 4; i++) {
		vec2 uv = SCREEN_UV + offsets[i] * pixel_size;
		
		// Depth edge detection
		float depth_sample = get_depth(uv);
		depth_diff = max(depth_diff, abs(depth_center - depth_sample));
		
		// Normal edge detection
		vec3 normal_sample = get_normal(uv);
		normal_diff = max(normal_diff, distance(normal_center, normal_sample));
	}
	
	// Threshold edges
	float depth_edge = step(depth_threshold * depth_center, depth_diff);
	float normal_edge = step(normal_threshold, normal_diff);
	
	// Combine edges
	float edge = max(depth_edge, normal_edge);
	
	// Get screen color and blend outline
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	ALBEDO = mix(screen_color, outline_color.rgb, edge * outline_color.a);
}
