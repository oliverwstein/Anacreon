shader_type canvas_item;

// Assuming each tile is 16x16 pixels
uniform vec2 tile_size = vec2(16, 16);

void fragment() {
    // Calculate the position of the current pixel within its tile
    vec2 tile_position = mod(FRAGCOORD.xy, tile_size);

    // Define the thickness of the border
    float border_thickness = 1.0;

    // Check if the current pixel is within the border thickness
    bool on_border = tile_position.x < border_thickness || tile_position.x > tile_size.x - border_thickness ||
                     tile_position.y < border_thickness || tile_position.y > tile_size.y - border_thickness;

    // Color the border black, and use the original texture color otherwise
    if (on_border) {
        COLOR = vec4(0, 0, 0, 1); // Black for borders
    } else {
        COLOR = texture(TEXTURE, UV); // Default texture color
    }
}