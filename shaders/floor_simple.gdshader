shader_type spatial;

uniform vec4 day_color : source_color = vec4(0.55, 0.70, 0.48, 1.0);
uniform vec4 night_color : source_color = vec4(0.32, 0.42, 0.38, 1.0);
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    float t = clamp((brightness - 0.5) * 2.0, 0.0, 1.0);
    ALBEDO = mix(night_color.rgb, day_color.rgb, t);
    ROUGHNESS = 0.95;
    METALLIC = 0.0;
}
