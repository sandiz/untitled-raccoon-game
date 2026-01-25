shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Brightness controlled by DayNightCycle
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

// === BASE COLORS (soft pastels) ===
uniform vec4 color_grass_main : source_color = vec4(0.58, 0.72, 0.52, 1.0);
uniform vec4 color_grass_light : source_color = vec4(0.65, 0.78, 0.58, 1.0);
uniform vec4 color_grass_warm : source_color = vec4(0.62, 0.70, 0.50, 1.0);
uniform vec4 color_patch_cream : source_color = vec4(0.75, 0.72, 0.62, 1.0);

// === NOISE SETTINGS ===
uniform float noise_scale : hint_range(0.001, 0.1) = 0.015;
uniform float color_variation : hint_range(0.0, 1.0) = 0.5;
uniform float patch_threshold : hint_range(0.0, 1.0) = 0.7;

// === SHADING ===
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.15;

// Simplex noise functions
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289_2(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 1.0) * x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289_2(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                     + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy),
                            dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * snoise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv_world = world_pos.xz;
    
    float large_noise = fbm(uv_world * noise_scale, 3) * 0.5 + 0.5;
    float medium_noise = fbm(uv_world * noise_scale * 2.5, 2) * 0.5 + 0.5;
    
    vec3 grass_color = mix(color_grass_main.rgb, color_grass_light.rgb, large_noise * color_variation);
    grass_color = mix(grass_color, color_grass_warm.rgb, medium_noise * 0.4);
    
    float patch_factor = smoothstep(patch_threshold, patch_threshold + 0.15, medium_noise);
    grass_color = mix(grass_color, color_patch_cream.rgb, patch_factor * 0.4);
    
    ALBEDO = grass_color;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float light_intensity = NdotL * 0.5 + 0.5;
    
    float shade = smoothstep(0.3, 0.6, light_intensity);
    float shadow = mix(1.0 - shadow_strength, 1.0, shade);
    
    // Apply light with brightness control
    vec3 final_color = ALBEDO * shadow * LIGHT_COLOR * ATTENUATION * brightness;
    DIFFUSE_LIGHT += final_color;
}
