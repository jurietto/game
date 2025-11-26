# Infinite checkerboard floor for Godot 4.5+

This shader draws an infinite, horizontally scrolling checkerboard floor with a simple fake perspective. It is resolution-independent because it uses `SCREEN_UV` (0..1 normalized screen coordinates) rather than hard-coded pixel sizes.

## Files
- `checkerboard_floor.gdshader` – the canvas item shader. Attach it to a `ShaderMaterial` on any 2D node that fills the viewport (e.g., `ColorRect` or `TextureRect`).

## Quick setup
1. **Add a full-viewport node**: Create a `ColorRect` in your scene, anchor it to all sides so it fills the viewport.
2. **Create the material**: In the inspector, add a `ShaderMaterial` and load `checkerboard_floor.gdshader` as its shader.
3. **Tune uniforms** (defaults work well):
   - `horizon` – height of the vanishing line (0 = top, 1 = bottom). Move it down for a lower camera, up for a higher one.
   - `perspective_strength` – steeper values tighten tiles near the horizon.
   - `tile_density` – how many tiles are visible near the bottom of the screen.
   - `scroll_speed` – world units per second; negative values move right, positive values move left.
   - `horizon_fade` – softens the aliasing at the horizon.
   - `color_a`, `color_b` – tile colors.
4. **Play**: The floor scrolls automatically using `TIME`, so no script is required.

## Why it works
- `SCREEN_UV` provides normalized screen coordinates, so resizing the window keeps the pattern consistent.
- The Y distance from the horizon is remapped into a perspective factor (`1 / y^power`) to squash tiles as they approach the vanishing line.
- We center X around the middle of the screen so the grid converges toward the center; multiplying by `tile_density` controls how many tiles appear at the front.
- Horizontal scrolling is just an offset of the projected X coordinate over time; because the checker pattern is procedural, it never runs out of tiles.

## Optional: match the horizon to other layers
If you have a parallax background or sky, align your horizon by matching this shader's `horizon` uniform to the visual horizon line in your scene. You can also animate `horizon` or `scroll_speed` from a script if you need to sync with gameplay.
