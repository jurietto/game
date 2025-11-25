extends TextureRect

@export var top_padding := 20.0
@export var kitty_scale := 0.4

func _ready():
    scale = Vector2(kitty_scale, kitty_scale)
    anchor_left = 0.5
    anchor_right = 0.5
    anchor_top = 0.0
    anchor_bottom = 0.0

    if texture:
        var tex_width := texture.get_size().x * kitty_scale
        offset_left = -tex_width * 0.5
    else:
        offset_left = 0.0

    offset_top = top_padding
    mouse_filter = MOUSE_FILTER_IGNORE

func get_bottom_y() -> float:
    if texture:
        return offset_top + (texture.get_size().y * kitty_scale)
    return offset_top
