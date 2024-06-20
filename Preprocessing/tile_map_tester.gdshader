shader_type canvas_item;

// Function to convert RGB to HSV
vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs((q.z + (q.w - q.y) / (6.0 * d + e))), d / (q.x + e), q.x);
}

// Function to convert HSV to RGB
vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // Fetch the pixel's original color from the texture
    vec4 color = texture(TEXTURE, UV);

    // Convert RGB to HSV
    vec3 hsv = rgb_to_hsv(color.rgb);

    // Time-based switch to cycle through hue, saturation, and value
    //int mode = int(mod(TIME / 3.0, 3.0)); // Every 3 seconds, switch mode
	int mode = 0;
    // Determine display based on mode
    vec3 result_color;
    if (mode == 0) {
        // Display hue
        result_color = hsv_to_rgb(vec3(hsv.x, 1.0, 1.0));
    } else if (mode == 1) {
        // Display saturation (grayscale based on saturation value)
        result_color = vec3(hsv.y*1.0); // Saturation affects intensity of gray
    } else if (mode == 2) {
        // Display saturation (grayscale based on saturation value)
        result_color = vec3(hsv.z); // Value affects intensity of white
    } else {
        result_color = hsv_to_rgb(vec3(hsv.x, hsv.y, hsv.z));
    }

    // Set the output color of the shader
    COLOR = vec4(result_color, color.a);
	
}