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
		var tex_size := texture.get_size() * kitty_scale
		offset_left = -tex_size.x * 0.5
		offset_right = tex_size.x * 0.5
		offset_bottom = top_padding + tex_size.y
	else:
		offset_left = 0.0
		offset_right = 0.0
		offset_bottom = top_padding

	offset_top = top_padding
	mouse_filter = MOUSE_FILTER_IGNORE

func get_bottom_y() -> float:
	if texture:
		return offset_top + (texture.get_size().y * kitty_scale)
	return offset_top
