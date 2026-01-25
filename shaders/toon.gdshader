shader_type spatial;

// Toon/Cel shader with soft shadows
// Responds to scene DirectionalLight3D for proper TOD support

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform bool use_texture = false;

// Shading - shadow_strength controls how dark shadows get (0 = no shadow, 1 = full dark)
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.25;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.4;

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
	// Get base color from texture or uniform
	vec4 tex_color = use_texture ? texture(albedo_texture, UV) : vec4(1.0);
	vec3 color = base_color.rgb * tex_color.rgb;
	
	// Pass to light function via ALBEDO
	ALBEDO = color;
	
	// Rim lighting (view-dependent, calculated here)
	if (enable_rim) {
		vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_vertex);
		float rim = 1.0 - max(dot(normalize(world_normal), view_dir), 0.0);
		rim = pow(rim, rim_power) * rim_intensity;
		EMISSION = rim_color.rgb * rim;
	}
}

void light() {
	// Get light intensity from actual scene light
	float NdotL = dot(NORMAL, LIGHT);
	float light_intensity = NdotL * 0.5 + 0.5; // Remap to 0-1
	
	// Simple cel shading: step between shadow and lit
	float shade = smoothstep(shadow_threshold - 0.1, shadow_threshold + 0.1, light_intensity);
	
	// Shadow is just a subtle darkening, not black
	float brightness = mix(1.0 - shadow_strength, 1.0, shade);
	
	vec3 final_color = ALBEDO * brightness * LIGHT_COLOR;
	
	// Apply light attenuation
	DIFFUSE_LIGHT += final_color * ATTENUATION;
}
