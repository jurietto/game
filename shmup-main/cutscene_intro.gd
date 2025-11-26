extends Node2D

const NEXT_SCENE_PATH := "res://main.tscn"
const CUTSCENE_FONT_PATH := "res://DotGothic16-Regular.ttf"
const CUTSCENE_FONT_SIZE := 24
const CUTSCENE_IMAGE_PATH := "res://cutscene kitty.png"

# Base desired kitty scale (we'll clamp this so it doesn't overlap the text)
const KITTY_BASE_SCALE := 1.0
const KITTY_TOP_PADDING := 20.0

# Text layout (bottom band of the screen)
const TEXT_ANCHOR_LEFT := 0.1
const TEXT_ANCHOR_RIGHT := 0.9
const TEXT_ANCHOR_TOP := 0.65
const TEXT_ANCHOR_BOTTOM := 0.98

# IMPORTANT: must match what Godot shows in FileSystem → right-click → Copy Path
const CUTSCENE_SOUND_PATH := "res://kitty cutscene.mp3"

const CutsceneKitty := preload("res://cutscene_kitty.gd")

var cutscene_sound_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_input_actions()

	# --- PLAY CUTSCENE SOUND ONCE ---
	cutscene_sound_player = AudioStreamPlayer.new()
	add_child(cutscene_sound_player)

	var stream := load(CUTSCENE_SOUND_PATH)
	if stream == null:
		push_error("Failed to load cutscene sound at: " + CUTSCENE_SOUND_PATH)
	else:
		cutscene_sound_player.stream = stream
		cutscene_sound_player.volume_db = 0.0  # tweak as needed
		cutscene_sound_player.play()
		print("Playing cutscene sound:", CUTSCENE_SOUND_PATH)

	var screen: Vector2 = get_viewport_rect().size
	print("Screen size: ", screen)

	var layer := CanvasLayer.new()
	add_child(layer)

	var ui_root := Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui_root)

	var bg_rect := ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 1)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(bg_rect)

	# ---------------- KITTY IMAGE (TOP / CENTER) ----------------
	var tex := load(CUTSCENE_IMAGE_PATH) as Texture2D
	if not tex:
		push_warning("Failed to load texture at " + CUTSCENE_IMAGE_PATH)

	var kitty_image := CutsceneKitty.new()
	kitty_image.texture = tex
	kitty_image.top_padding = KITTY_TOP_PADDING
	kitty_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Anchor kitty around the top-middle of the screen
	kitty_image.anchor_left = 0.5
	kitty_image.anchor_right = 0.5
	kitty_image.anchor_top = 0.0
	kitty_image.anchor_bottom = 0.0

	if tex:
		var tex_size := Vector2(tex.get_width(), tex.get_height())

		# Space from top padding down to the start of the text band
		var available_height: float = (screen.y * TEXT_ANCHOR_TOP) - KITTY_TOP_PADDING * 2.0
		var max_scale_h: float = available_height / max(float(tex_size.y), 1.0)
		var kitty_scale: float = min(KITTY_BASE_SCALE, max_scale_h)

		kitty_image.kitty_scale = kitty_scale

		var kitty_size := tex_size * kitty_scale
		kitty_image.custom_minimum_size = kitty_size
		# Centered horizontally, padded down a bit from the top
		kitty_image.position = Vector2(screen.x * 0.5, KITTY_TOP_PADDING + kitty_size.y * 0.5)
	else:
		kitty_image.kitty_scale = KITTY_BASE_SCALE

	ui_root.add_child(kitty_image)

	# ---------------- TEXT (BOTTOM AREA, NEVER CUT) ----------------
	var text_label := RichTextLabel.new()
	text_label.text = "kitty lives quietly indoors, and when she drifts into sleep her worries and triggers appear as small yarn balls rolling through her mind. the boss arrives, calm and wordless, adding more yarn and turning her thoughts into a challenge she must face. kitty moves through the chaos with soft determination, brushing aside what she can until the dream finally lets her wake..."
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.fit_content = false
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Pin the label to the bottom portion of the screen with margins
	text_label.anchor_left = TEXT_ANCHOR_LEFT
	text_label.anchor_right = TEXT_ANCHOR_RIGHT
	text_label.anchor_top = TEXT_ANCHOR_TOP
	text_label.anchor_bottom = TEXT_ANCHOR_BOTTOM
	text_label.offset_left = 0.0
	text_label.offset_right = 0.0
	text_label.offset_top = 0.0
	text_label.offset_bottom = 0.0

	var font := load(CUTSCENE_FONT_PATH) as Font
	if font:
		text_label.add_theme_font_override("font", font)
		text_label.add_theme_font_size_override("font_size", CUTSCENE_FONT_SIZE)
	else:
		push_warning("Failed to load font at " + CUTSCENE_FONT_PATH)

	ui_root.add_child(text_label)


func _ensure_input_actions() -> void:
	if not InputMap.has_action("ui_accept"):
		InputMap.add_action("ui_accept")

	for keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		var exists := false
		for ev in InputMap.action_get_events("ui_accept"):
			if ev is InputEventKey and ev.keycode == keycode:
				exists = true
				break
		if not exists:
			var event := InputEventKey.new()
			event.keycode = keycode
			InputMap.action_add_event("ui_accept", event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed):
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
