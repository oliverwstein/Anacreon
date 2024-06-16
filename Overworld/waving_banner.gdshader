shader_type canvas_item;

uniform float wave_amplitude : hint_range(0.0, 20.0) = 5.0; // height of the wave
uniform float wave_frequency : hint_range(0.0, 10.0) = 1.0; // number of waves
uniform float wave_speed : hint_range(0.0, 10.0) = 1.0; // speed of wave movement

void vertex() {
    // apply a wave effect based on the vertex's x position and time
    VERTEX.y += sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
}

void fragment() {
    // just sample the texture normally
    COLOR = texture(TEXTURE, UV);
}