shader_type canvas_item;

// Noise texture for variation and subtle movement
uniform sampler2D noise_texture;

// Scale of the color variation noise
uniform float color_noise_scale = 0.5;

// Scale of the movement impression noise
uniform float movement_noise_scale = 10.0;

// Intensity of color variation
uniform float color_variation_intensity = 0.25;

// Intensity of movement impression (brightness modulation)
uniform float movement_intensity = 0.05;

void fragment() {
// Base color from the sprite texture
vec4 base_color = texture(TEXTURE, UV);

// Sample noise texture for color variation
float color_noise = texture(noise_texture, UV * color_noise_scale).r;

// Adjust the color by noise to simulate color variation in foliage
base_color.rgb *= mix(1.0 - color_variation_intensity, 1.0 + color_variation_intensity, color_noise);

// Sample noise texture for subtle movement impression
float movement_noise = texture(noise_texture, UV * movement_noise_scale + vec2(TIME * 0.1, 0)).r;

// Modulate the brightness slightly to give an impression of movement
base_color.rgb *= mix(1.0 - movement_intensity, 1.0 + movement_intensity, movement_noise);

COLOR = base_color;
}