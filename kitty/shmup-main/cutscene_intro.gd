extends Node2D

# After the cutscene, go to the main game
const NEXT_SCENE_PATH := "res://main.tscn"

# Use DotGothic16-Regular font
const CUTSCENE_FONT_PATH := "res://DotGothic16-Regular.ttf"
const CUTSCENE_IMAGE_PATH := "res://cutscene kitty.png"

func _ready() -> void:
	var screen: Vector2 = get_viewport_rect().size

	# --- Background (pure black) ---
	var bg_rect := ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 1)
	bg_rect.anchor_left = 0.0
	bg_rect.anchor_top = 0.0
	bg_rect.anchor_right = 1.0
	bg_rect.anchor_bottom = 1.0
	bg_rect.offset_left = 0.0
	bg_rect.offset_top = 0.0
	bg_rect.offset_right = 0.0
	bg_rect.offset_bottom = 0.0
	add_child(bg_rect)

	# --- Kitty image: toward top center, a bit smaller ---
	var tex: Texture2D = load(CUTSCENE_IMAGE_PATH) as Texture2D
	var kitty_image := TextureRect.new()
	kitty_image.texture = tex
	kitty_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kitty_image.set_anchors_preset(Control.PRESET_CENTER_TOP)
	kitty_image.position = Vector2(screen.x * 0.5, screen.y * 0.2)
	kitty_image.custom_minimum_size = Vector2(screen.x * 0.45, screen.y * 0.2)
	add_child(kitty_image)

	# --- Text block: left-aligned under kitty ---
	var text_label := Label.new()
	text_label.text = "kitty lives quietly indoors, and when she drifts into sleep her worries and triggers appear as small yarn balls rolling through her mind. the boss arrives, calm and wordless, adding more yarn and turning her thoughts into a challenge she must face. kitty moves through the chaos with soft determination, brushing aside what she can until the dream finally lets her wake..."
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	var margin_left := screen.x * 0.1
	var text_width := screen.x * 0.8
	var text_height := screen.y * 0.25
	text_label.position = Vector2(margin_left, screen.y * 0.6)
	text_label.size = Vector2(text_width, text_height)

	var font: Font = load(CUTSCENE_FONT_PATH) as Font
	if font:
		text_label.add_theme_font_override("font", font)
		text_label.add_theme_font_size_override("font_size", 18)

	add_child(text_label)


func _unhandled_input(event: InputEvent) -> void:
	# Press ENTER or any key to go to the main game
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed):
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
