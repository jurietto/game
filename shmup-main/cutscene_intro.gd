extends Node2D

const NEXT_SCENE_PATH := "res://main.tscn"
const CUTSCENE_FONT_PATH := "res://DotGothic16-Regular.ttf"
const CUTSCENE_IMAGE_PATH := "res://cutscene kitty.png"

const KITTY_SCALE := 0.4
const KITTY_TOP_PADDING := 20.0
const TEXT_GAP := 100.0

const CutsceneKitty := preload("res://cutscene_kitty.gd")

func _ready() -> void:
    _ensure_input_actions()
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

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    ui_root.add_child(center)

    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", TEXT_GAP)
    stack.custom_minimum_size = Vector2(screen.x * 0.8, screen.y * 0.6)
    stack.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
    stack.size_flags_vertical   = Control.SIZE_FILL | Control.SIZE_EXPAND
    center.add_child(stack)

    var tex := load(CUTSCENE_IMAGE_PATH) as Texture2D
    if not tex:
        push_warning("Failed to load texture at " + CUTSCENE_IMAGE_PATH)
    var kitty_image := CutsceneKitty.new()
    kitty_image.texture = tex
    kitty_image.kitty_scale = KITTY_SCALE
    kitty_image.top_padding = KITTY_TOP_PADDING
    kitty_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if tex:
        kitty_image.custom_minimum_size = Vector2(tex.get_width() * KITTY_SCALE, tex.get_height() * KITTY_SCALE)
    kitty_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    kitty_image.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
    stack.add_child(kitty_image)

    var text_label := RichTextLabel.new()
    text_label.text = "kitty lives quietly indoors, and when she drifts into sleep her worries and triggers appear as small yarn balls rolling through her mind. the boss arrives, calm and wordless, adding more yarn and turning her thoughts into a challenge she must face. kitty moves through the chaos with soft determination, brushing aside what she can until the dream finally lets her wake..."
    text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    text_label.fit_content = true
    text_label.custom_minimum_size = Vector2(screen.x * 0.8, screen.y * 0.3)
    text_label.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
    text_label.size_flags_vertical   = Control.SIZE_FILL | Control.SIZE_EXPAND
    text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var font := load(CUTSCENE_FONT_PATH) as Font
    if font:
        text_label.add_theme_font_override("font", font)
        text_label.add_theme_font_size_override("font_size", 16) # using size 16 for DotGothic16-Regular
    else:
        push_warning("Failed to load font at " + CUTSCENE_FONT_PATH)

    stack.add_child(text_label)

func _ensure_input_actions() -> void:
    if not InputMap.has_action("ui_accept"):
        InputMap.add_action("ui_accept")

    for keycode in [ KEY_ENTER, KEY_KP_ENTER, KEY_SPACE ]:
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
