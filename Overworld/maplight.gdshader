shader_type canvas_item;

uniform float brightness_boost : hint_range(-1.0, 1.0) = 0.2; // Brightness adjustment factor

void fragment() {
    vec4 original_color = texture(TEXTURE, UV); // Sample the original color

    // Adjust brightness
    vec4 brightened_color = original_color * (1.0 + brightness_boost);

    // Clamp the color to ensure it stays within valid range
    COLOR = clamp(brightened_color, 0.0, 1.0);
}