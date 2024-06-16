shader_type canvas_item;

uniform sampler2D noise_texture : hint_default_black, filter_nearest, repeat_enable;

uniform vec2 cloud_speed = vec2(0.02, 0.01); // Speed of cloud movement
uniform float shadow_intensity = 1.1; // Intensity of the shadow effect
uniform vec2 cloud_scale = vec2(2.0, 2.0); // Scale of the cloud shadows
uniform float shadow_bias = 0.5; // Shadow intensity adjustment

void fragment() {
    // Compute the cloud movement offset based on time
    vec2 cloud_offset = UV * cloud_scale + TIME * cloud_speed;

    // Sample the noise texture to get cloud pattern
    float cloud_value = texture(noise_texture, cloud_offset).r;

    // Adjust the cloud value to create shadow/light effect
    cloud_value = cloud_value * shadow_intensity - shadow_bias;

    // Blend the shadow effect with the existing scene color
    COLOR = vec4(0.0, 0.0, 0.0, cloud_value); // Alpha channel controls shadow opacity
}