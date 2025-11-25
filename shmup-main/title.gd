extends Node2D

enum MenuState { MAIN, INSTRUCTIONS }

var state: int = MenuState.MAIN
var menu_index: int = 0  # 0 = Start, 1 = Instructions

var ui_layer: CanvasLayer
var bg_rect: ColorRect

var title_label: Label
var start_label: Label
var instructions_label: Label
var cursor_label: Label

var instructions_panel: ColorRect
var instructions_text: Label
var back_label: Label

# Go to the kitty cutscene first
const GAME_SCENE_PATH := "res://cutscene_intro.tscn"

# Use DotGothic16-Regular everywhere
const MENU_FONT_PATH := "res://DotGothic16-Regular.ttf"


func _ready() -> void:
	randomize()
	_create_background()
	_create_main_menu()
	_create_instructions_screen()
	_set_state(MenuState.MAIN)


# ---------------- UI SETUP ----------------

func _create_background() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# Full black background (no transparency)
	bg_rect = ColorRect.new()
	bg_rect.color = Color(0, 0, 0, 1)  # pure black
	bg_rect.anchor_left = 0.0
	bg_rect.anchor_top = 0.0
	bg_rect.anchor_right = 1.0
	bg_rect.anchor_bottom = 1.0
	bg_rect.offset_left = 0.0
	bg_rect.offset_top = 0.0
	bg_rect.offset_right = 0.0
	bg_rect.offset_bottom = 0.0
	ui_layer.add_child(bg_rect)


func _get_menu_font() -> Font:
	var font_res: Resource = load(MENU_FONT_PATH)
	var f: Font = font_res as Font
	return f


func _create_main_menu() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var font: Font = _get_menu_font()

	# Title (centered)
	title_label = Label.new()
	title_label.text = "KITTY PANIC ☆"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, screen.y * 0.18)
	title_label.size = Vector2(screen.x, 40)
	if font:
		title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 32)
	ui_layer.add_child(title_label)

	# Left margin for menu items
	var menu_margin_left: float = screen.x * 0.15

	# Start Game – LEFT aligned
	start_label = Label.new()
	start_label.text = "Start Game"
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	start_label.position = Vector2(menu_margin_left, screen.y * 0.35)
	start_label.size = Vector2(screen.x - menu_margin_left * 2.0, 30)
	if font:
		start_label.add_theme_font_override("font", font)
	start_label.add_theme_font_size_override("font_size", 22)
	ui_layer.add_child(start_label)

	# Instructions – LEFT aligned
	instructions_label = Label.new()
	instructions_label.text = "Instructions"
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	instructions_label.position = Vector2(menu_margin_left, screen.y * 0.42)
	instructions_label.size = Vector2(screen.x - menu_margin_left * 2.0, 30)
	if font:
		instructions_label.add_theme_font_override("font", font)
	instructions_label.add_theme_font_size_override("font_size", 22)
	ui_layer.add_child(instructions_label)

	# Cursor just to the left of the menu text
	cursor_label = Label.new()
	cursor_label.text = "▶"
	if font:
		cursor_label.add_theme_font_override("font", font)
	cursor_label.add_theme_font_size_override("font_size", 22)
	ui_layer.add_child(cursor_label)

	_update_cursor_position()


func _create_instructions_screen() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var font: Font = _get_menu_font()

	instructions_panel = ColorRect.new()
	# Full black, no transparency
	instructions_panel.color = Color(0, 0, 0, 1)
	instructions_panel.anchor_left = 0.0
	instructions_panel.anchor_top = 0.0
	instructions_panel.anchor_right = 1.0
	instructions_panel.anchor_bottom = 1.0
	instructions_panel.offset_left = 0.0
	instructions_panel.offset_top = 0.0
	instructions_panel.offset_right = 0.0
	instructions_panel.offset_bottom = 0.0
	ui_layer.add_child(instructions_panel)

	instructions_text = Label.new()
	instructions_text.text = (
		"Move : Arrow Keys\n" +
		"Shoot : ENTER or SPACE\n" +
		"Focus (slow + show hitbox) : SHIFT\n\n" +
		"Shoot cupcakes at the boss and at bullets\n" +
        "to gain points and survive!"
	)
	instructions_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions_text.position = Vector2(0, screen.y * 0.2)
	instructions_text.size = Vector2(screen.x, screen.y * 0.5)
	if font:
		instructions_text.add_theme_font_override("font", font)
	instructions_text.add_theme_font_size_override("font_size", 20)
	instructions_panel.add_child(instructions_text)

	back_label = Label.new()
	back_label.text = "Press ENTER to go back"
	back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_label.position = Vector2(0, screen.y * 0.75)
	back_label.size = Vector2(screen.x, 30)
	if font:
		back_label.add_theme_font_override("font", font)
	back_label.add_theme_font_size_override("font_size", 18)
	instructions_panel.add_child(back_label)

	instructions_panel.visible = false


# ---------------- STATE HANDLING ----------------

func _set_state(new_state: int) -> void:
	state = new_state
	match state:
		MenuState.MAIN:
			title_label.visible = true
			start_label.visible = true
			instructions_label.visible = true
			cursor_label.visible = true
			instructions_panel.visible = false
		MenuState.INSTRUCTIONS:
			title_label.visible = false
			start_label.visible = false
			instructions_label.visible = false
			cursor_label.visible = false
			instructions_panel.visible = true


# ---------------- INPUT (RAW KEYS) ----------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var e := event as InputEventKey
	if not e.pressed or e.echo:
		return

	# MAIN MENU
	if state == MenuState.MAIN:
		# Up
		if e.keycode == KEY_UP or e.keycode == KEY_W:
			menu_index = (menu_index + 1) % 2
			_update_cursor_position()
		# Down
		elif e.keycode == KEY_DOWN or e.keycode == KEY_S:
			menu_index = (menu_index + 1) % 2
			_update_cursor_position()
		# Confirm
		elif e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER or e.keycode == KEY_SPACE:
			if menu_index == 0:
				_start_game()
			elif menu_index == 1:
				_set_state(MenuState.INSTRUCTIONS)

	# INSTRUCTIONS SCREEN
	elif state == MenuState.INSTRUCTIONS:
		# ENTER or ESC to go back
		if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER or e.keycode == KEY_ESCAPE:
			_set_state(MenuState.MAIN)


func _update_cursor_position() -> void:
	var target_label: Label = start_label if menu_index == 0 else instructions_label
	var offset_x: float = -40.0  # cursor to the left of the text
	cursor_label.position = Vector2(
		target_label.position.x + offset_x,
		target_label.position.y
	)


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
