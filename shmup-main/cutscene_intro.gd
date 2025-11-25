extends Node2D

# After the cutscene, go to the main game
const NEXT_SCENE_PATH := "res://main.tscn"

# Use DotGothic16-Regular font
const CUTSCENE_FONT_PATH := "res://DotGothic16-Regular.ttf"
const CUTSCENE_IMAGE_PATH := "res://cutscene kitty.png"

const KITTY_SCALE := 0.4
const KITTY_TOP_PADDING := 20.0
const TEXT_GAP := 100.0

const CutsceneKitty := preload("res://cutscene_kitty.gd")
const Dialogue := preload("res://dialogue.gd")

func _ready() -> void:
    _ensure_input_actions()
    var screen: Vector2 = get_viewport_rect().size

    # UI root
    var ui_root := Control.new()
    ui_root.anchor_left = 0.0
    ui_root.anchor_top = 0.0
    ui_root.anchor_right = 1.0
    ui_root.anchor_bottom = 1.0
    ui_root.offset_left = 0.0
    ui_root.offset_top = 0.0
    ui_root.offset_right = 0.0
    ui_root.offset_bottom = 0.0
    add_child(ui_root)

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
    bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui_root.add_child(bg_rect)

    # --- Kitty image: small, top-center, well above text ---
    var tex: Texture2D = load(CUTSCENE_IMAGE_PATH) as Texture2D
    var kitty_image: TextureRect = CutsceneKitty.new()
    kitty_image.texture = tex
    kitty_image.kitty_scale = KITTY_SCALE
    kitty_image.top_padding = KITTY_TOP_PADDING
    kitty_image.position = Vector2(screen.x * 0.5, KITTY_TOP_PADDING)
    ui_root.add_child(kitty_image)

    var kitty_height: float = tex.get_size().y * KITTY_SCALE
    var text_top: float = KITTY_TOP_PADDING + kitty_height + TEXT_GAP

    # --- Text block: centered, no overlap ---
    var dialogue_container: VBoxContainer = Dialogue.new()
    dialogue_container.anchor_left = 0.1
    dialogue_container.anchor_top = 0.0
    dialogue_container.anchor_right = 0.9
    dialogue_container.anchor_bottom = 0.0
    dialogue_container.offset_left = 0.0
    dialogue_container.offset_right = 0.0
    dialogue_container.offset_top = text_top
    var desired_height: float = min(screen.y * 0.35, max(screen.y - text_top - 20.0, 120.0))
    dialogue_container.offset_bottom = text_top + desired_height
    dialogue_container.add_theme_constant_override("separation", 20)

    var text_label := RichTextLabel.new()
    text_label.text = "kitty lives quietly indoors, and when she drifts into sleep her worries and triggers appear as small yarn balls rolling through her mind. the boss arrives, calm and wordless, adding more yarn and turning her thoughts into a challenge she must face. kitty moves through the chaos with soft determination, brushing aside what she can until the dream finally lets her wake..."
    text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    text_label.fit_content = true
    text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var font: Font = load(CUTSCENE_FONT_PATH) as Font
    if font:
        text_label.add_theme_font_override("font", font)
        text_label.add_theme_font_size_override("font_size", 18)

    dialogue_container.add_child(text_label)
    ui_root.add_child(dialogue_container)


func _ensure_input_actions() -> void:
    # Only needed if your Input Map is empty; harmless otherwise
    if not InputMap.has_action("ui_accept"):
        InputMap.add_action("ui_accept")

    var events := InputMap.action_get_events("ui_accept")
    var keycodes := [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]

    for keycode in keycodes:
        var exists := false
        for ev in events:
            if ev is InputEventKey and ev.keycode == keycode:
                exists = true
                break

        if not exists:
            var event := InputEventKey.new()
            event.keycode = keycode
            InputMap.action_add_event("ui_accept", event)


func _unhandled_input(event: InputEvent) -> void:
    # Press ENTER or ANY key to go to the main game
    if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed):
        get_tree().change_scene_to_file(NEXT_SCENE_PATH)
