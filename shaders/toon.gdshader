shader_type spatial;

// Toon/Cel shader with color banding
// Gives that Ghibli-style soft shading look

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform bool use_texture = false;

// Shading bands
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float light_threshold : hint_range(0.0, 1.0) = 0.7;
uniform vec4 shadow_color : source_color = vec4(0.6, 0.5, 0.6, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);

// Rim light (optional Ghibli touch)
uniform bool enable_rim = true;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.9, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_normal;
varying vec3 world_vertex;

void vertex() {
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Get base color
	vec4 tex_color = use_texture ? texture(albedo_texture, UV) : vec4(1.0);
	vec3 color = base_color.rgb * tex_color.rgb;
	
	// Calculate diffuse lighting (simplified)
	vec3 light_dir = normalize(vec3(0.5, 1.0, 0.3)); // Approximate sun direction
	float NdotL = dot(normalize(world_normal), light_dir);
	float light_intensity = NdotL * 0.5 + 0.5; // Remap to 0-1
	
	// Apply color banding (cel shading)
	vec3 final_color;
	if (light_intensity < shadow_threshold) {
		// Shadow band
		final_color = color * shadow_color.rgb;
	} else if (light_intensity < light_threshold) {
		// Mid tone (base color)
		final_color = color;
	} else {
		// Highlight band
		final_color = color * highlight_color.rgb;
	}
	
	// Rim lighting
	if (enable_rim) {
		vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_vertex);
		float rim = 1.0 - max(dot(normalize(world_normal), view_dir), 0.0);
		rim = pow(rim, rim_power) * rim_intensity;
		final_color += rim_color.rgb * rim;
	}
	
	ALBEDO = final_color;
}
