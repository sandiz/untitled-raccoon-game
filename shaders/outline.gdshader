shader_type spatial;
render_mode unshaded, cull_front;

// Outline shader using inverted hull method
// Apply to a duplicate mesh or use next_pass on material

uniform vec4 outline_color : source_color = vec4(0.15, 0.1, 0.1, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Expand vertices along normals
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
