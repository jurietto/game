shader_type canvas_item;

// Infinite scrolling checkerboard floor with fake perspective.
// Works on any viewport size by relying on SCREEN_UV (0..1 regardless of resolution).
// Attach to a ColorRect or TextureRect that covers the viewport.

uniform vec3 color_a : source_color = vec3(0.92, 0.92, 0.92); // light tile
uniform vec3 color_b : source_color = vec3(0.15, 0.15, 0.18); // dark tile
uniform float horizon : hint_range(0.0, 0.9) = 0.28;          // fraction of the screen height where the horizon sits
uniform float perspective_strength : hint_range(0.1, 4.0) = 1.4; // higher = steeper depth curve
uniform float tile_density : hint_range(0.5, 20.0) = 8.0;     // how many tiles fit across the bottom edge
uniform float scroll_speed = 1.2;                             // world units per second moving left
uniform float horizon_fade : hint_range(0.0, 1.0) = 0.6;      // how much the floor fades into the horizon

void fragment() {
    // Normalized screen space (0..1) regardless of viewport size.
    vec2 uv = SCREEN_UV;

    // Everything above the horizon becomes the sky/fog color.
    if (uv.y < horizon) {
        float fog = 1.0 - (uv.y / horizon);
        vec3 sky = mix(color_a, color_b, fog * 0.4);
        COLOR = vec4(sky, 1.0);
        return;
    }

    // Convert screen Y into a perspective factor. As uv.y approaches the horizon,
    // the factor grows rapidly, squeezing tiles together and creating depth.
    float y_from_horizon = uv.y - horizon;
    float perspective = pow(y_from_horizon / max(1.0 - horizon, 0.001), perspective_strength);
    perspective = max(perspective, 0.0001);

    // Map screen coordinates onto the floor plane.
    // We center X around 0 so the vanishing point aligns with the screen center.
    vec2 plane;
    plane.x = (uv.x - 0.5) / perspective;
    plane.y = 1.0 / perspective;

    // Scale how many tiles appear near the camera.
    plane *= tile_density;

    // Scroll left over time (TIME is seconds); subtract to move the floor left.
    plane.x -= TIME * scroll_speed;

    // Checker pattern: alternate between the two colors in both axes.
    vec2 checker = floor(plane);
    float mask = mod(checker.x + checker.y, 2.0);
    vec3 base_color = mix(color_a, color_b, mask);

    // Fade into the horizon to avoid harsh aliasing at the vanishing line.
    float fade = clamp(y_from_horizon / max(horizon_fade, 0.001), 0.0, 1.0);
    vec3 final_color = mix(mix(color_a, color_b, 0.25), base_color, fade);

    COLOR = vec4(final_color, 1.0);
}
