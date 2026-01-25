shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_disabled;

// Vision cone/glow shader for NPC awareness indicator
// Projects onto ground as a soft radial gradient

uniform vec4 cone_color : source_color = vec4(1.0, 0.7, 0.0, 0.3);
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.15;
uniform float cone_angle : hint_range(0.0, 180.0) = 60.0;  // Half-angle in degrees
uniform float fade_edge : hint_range(0.0, 0.5) = 0.2;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// Calculate distance from center (normalized)
	vec2 uv_centered = local_pos.xz;
	float dist = length(uv_centered);
	
	// Radial fade (soft edge)
	float radial_alpha = 1.0 - smoothstep(1.0 - fade_edge, 1.0, dist);
	
	// Cone angle mask (using forward direction as -Z)
	float angle = atan(uv_centered.x, -uv_centered.y);  // Angle from forward
	float angle_deg = abs(degrees(angle));
	float cone_half = cone_angle;
	float angle_alpha = 1.0 - smoothstep(cone_half - 10.0, cone_half, angle_deg);
	
	// Pulse effect
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	
	// Combine
	float alpha = radial_alpha * angle_alpha * intensity * pulse;
	
	ALBEDO = cone_color.rgb;
	ALPHA = alpha * cone_color.a;
}
