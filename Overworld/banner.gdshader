shader_type canvas_item;

// Transparency level for target color
uniform float red_alpha : hint_range(0.0, 1.0) = 0.9; 

// Target color to be made translucent
uniform vec3 target_color = vec3(0.2235, 0.0784, 0.0627); // rgb(57, 20, 16) in normalized 0-1 range

// Threshold for color proximity
uniform float color_threshold = 0.2;

// Base color to apply to translucent areas
uniform vec3 base_color = vec3(1.0, 0.0, 0.0); // Default to red

// Parameters for whorling noise effect
uniform float noise_scale = 10; // Scale of noise
uniform float noise_intensity = 1.5; // Intensity of the noise effect
uniform float swirl_speed = 1.5; // Speed of the swirling effect

// Parameters for metallic sheen effect
uniform vec3 sheen_color = vec3(0.8, 0.8, 0.8); // Color of the metallic sheen
uniform float sheen_intensity = 0.1; // Intensity of the sheen effect

// Saturation boost
uniform float saturation_boost = 3; // Boost for the saturation

// Compression factor
uniform float compression_factor = 1.5; // Factor for compression (2/3)

vec2 random(vec2 pos) {
    return fract(sin(vec2(dot(pos, vec2(12.9898, 78.233)), dot(pos, vec2(43.9479, 77.6453)))) * 43758.5453);
}

float value_noise(vec2 pos) {
    vec2 p = floor(pos);
    vec2 f = fract(pos);

    float v00 = random(p + vec2(0.0, 0.0)).x;
    float v10 = random(p + vec2(1.0, 0.0)).x;
    float v01 = random(p + vec2(0.0, 1.0)).x;
    float v11 = random(p + vec2(1.0, 1.0)).x;

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(v00, v10, u.x), mix(v01, v11, u.x), u.y);
}

float noise_tex(vec2 p) {
    return (
        value_noise(p * 0.984864) * 0.5 +
        value_noise(p * 2.543) * 0.25 +
        value_noise(p * 9.543543) * 0.125 +
        value_noise(p * 21.65436) * 0.0625 +
        value_noise(p * 42.0) * 0.03125
    );
}

vec3 boost_saturation(vec3 color, float factor) {
    float intensity = dot(color, vec3(0.2126, 0.7152, 0.0722)); // Luminance
    return mix(vec3(intensity), color, factor);
}

vec2 adjust_uv(vec2 uv) {
    // Compress the middle of the UV coordinates
    float middle_x = (uv.x - 0.5) * compression_factor + 0.5;
    return vec2(middle_x, uv.y);
}

void fragment() {
    vec2 adjusted_uv = adjust_uv(UV);
    vec4 color = texture(TEXTURE, adjusted_uv);
    vec3 color_diff = abs(color.rgb - target_color);

    if (color_diff.r < color_threshold && color_diff.g < color_threshold && color_diff.b < color_threshold) {
        // First, set the translucent area to white
        color.rgb = vec3(1.0);

        // Apply the whorling noise pattern to the white areas
        float noise_value = noise_tex(adjusted_uv * noise_scale + TIME * swirl_speed);
        vec3 highlighted_color = mix(color.rgb, base_color, noise_value * noise_intensity);

        // Apply metallic sheen based on noise value
        vec3 sheen = mix(highlighted_color, sheen_color, noise_value * sheen_intensity);

        // Boost saturation of the final color
        color.rgb = boost_saturation(sheen, saturation_boost);
        color.a *= red_alpha;
    }

    COLOR = color;
}