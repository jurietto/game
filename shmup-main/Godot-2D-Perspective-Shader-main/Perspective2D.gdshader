shader_type canvas_item;

// Base tile size in pixels (at bottom of screen)
uniform float base_square_size : hint_range(8.0, 200.0) = 80.0;
// Checker-colors
uniform vec4 color_even : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_odd  : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Where on the screen the floor begins (0 = top, 1 = bottom)
uniform float floor_start : hint_range(0.0, 1.0) = 0.6;

// How “strong” the perspective distortion is (bigger = more foreshortening)
uniform float perspective_strength : hint_range(0.5, 4.0) = 2.0;

void fragment() {
    // Normalized screen coordinates, (0,0) = top-left, (1,1) = bottom-right
    vec2 uv = SCREEN_UV;
    // If above floor_start → give black sky (or background)
    if (uv.y < floor_start) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // t: 0 at floor_start, 1 at bottom → how far into floor we are
    float t = (uv.y - floor_start) / (1.0 - floor_start);
    t = clamp(t, 0.0, 1.0);

    // Compute a scale factor for tiles as we move toward horizon
    float size_factor = mix(0.3, 1.0, t);
    float square_size = base_square_size * size_factor;

    // Convert to pixel coords
    vec2 p = FRAGCOORD.xy;

    // Apply perspective “squeeze” horizontally depending on t
    float px = p.x - 0.5 * VIEWPORT_SIZE.x;
    px *= mix(0.3, 1.0, t * perspective_strength);
    p.x = px + 0.5 * VIEWPORT_SIZE.x;

    // Decide which tile we are in
    vec2 tile = p / square_size;
    float sum = floor(tile.x) + floor(tile.y);
    float mask = mod(sum, 2.0);

    // Checkerboard: even vs odd color
    COLOR = mix(color_even, color_odd, mask);
}
