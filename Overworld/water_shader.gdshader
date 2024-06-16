shader_type canvas_item;

uniform sampler2D noise_texture : filter_nearest, repeat_enable;

// Parameters for the base noise layer
uniform float noise_scale = 1.0; // Scale of noise for randomness
uniform vec2 desync_factor = vec2(-2000.0, -1000.0); // Desynchronization factor
uniform float flash_chance = 0.27; // Chance of flashing white for near blue pixels
uniform float blue_threshold = 0.4; // Threshold for what counts as predominantly blue
uniform float flash_speed = 0.1; // Speed of flashing effect

// Parameters for the second noise layer
uniform float noise_scale2 = 0.5; // Scale of the second noise for additional randomness
uniform vec2 desync_factor2 = vec2(500.0, 2500.0); // Second desynchronization factor

// Parameters for frequent flashing layer
uniform float frequent_flash_speed = 0.4; // Speed of frequent flashing effect
uniform float frequent_flash_chance = 0.6; // Chance of frequent flashing for near blue pixels

// Light blue color for flashing effect
uniform vec4 light_blue_color = vec4(0.6, 0.8, 1.0, 1.0); // Define light blue
uniform vec4 flash_color = vec4(0.2, 0.5, 1.0, 0.5); // White color for flashing

// Function to determine if a pixel is predominantly blue
bool is_loosely_blue(vec4 color) {
    return color.b > blue_threshold && color.b > (color.r + color.g) * 0.7;
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV); // Sample the original color

    // Determine if the current pixel is predominantly blue
    bool is_blue = is_loosely_blue(original_color);

    // Initialize the final color with the original color
    vec4 final_color = original_color;

    // Offset UV by desynchronization factors for two noise layers
    vec2 desynced_uv1 = UV * noise_scale + FRAGCOORD.xy / desync_factor;
    vec2 desynced_uv2 = UV * noise_scale2 + FRAGCOORD.xy / desync_factor2;
    
    // Sample noise textures for both layers
    float noise_value1 = texture(noise_texture, desynced_uv1 + TIME * flash_speed).r;
    float noise_value2 = texture(noise_texture, desynced_uv2 + TIME * flash_speed).r;

    // Combine the two noise values
    float combined_noise_value = (noise_value1 + noise_value2) * 0.5;

    if (is_blue) {
        // Dynamic effect: brighten and darken the blue area
        float brightness_adjustment = 1.0 + (combined_noise_value - 0.5);
        final_color.rgb = original_color.rgb * brightness_adjustment;
        final_color = clamp(final_color, 0.0, 1.0);

        // Occasionally flash light blue
        if (combined_noise_value < flash_chance) {
            final_color = mix(final_color, light_blue_color, step(0.5, fract(combined_noise_value + TIME)));
        }

    } else {
        // For non-blue regions, check if they should flash white based on proximity to blue
        vec2 offsets[8] = vec2[](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
                                 vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0));
        bool is_adjacent_to_blue = false;
        for (int i = 0; i < 8; ++i) {
            vec2 neighbor_uv = UV + offsets[i] / vec2(textureSize(TEXTURE, 0));
            vec4 neighbor_color = texture(TEXTURE, neighbor_uv);

            if (is_loosely_blue(neighbor_color)) {
                // Frequently flash white for non-blue pixels
                float neighbor_noise = texture(noise_texture, neighbor_uv * noise_scale + TIME * frequent_flash_speed).r;
                if (neighbor_noise < frequent_flash_chance) {
                    final_color = mix(original_color, flash_color, step(0.5, fract(neighbor_noise + TIME)));
                }
                is_adjacent_to_blue = true;
            }
        }
    }

    // Set the final color
    COLOR = final_color;
}