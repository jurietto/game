extends Node2D

# ---------------- CONSTANTS ----------------

const PLAYER_SPEED: float = 300.0
const FOCUS_SPEED: float = 130.0

const PLAYER_BULLET_SPEED: float = 700.0
const BOSS_BULLET_SPEED: float = 230.0

const PLAYER_SHOT_COOLDOWN: float = 0.09        # seconds between shots
const RING_INTERVAL: float = 0.8                # how often boss throws a bullet (slower = fewer)
const BULLETS_PER_RING: int = 48                # not used now, but kept

const MAX_ENEMY_BULLETS: int = 18               # cap enemy bullets on screen

# bullet life (kitty bullets only)
const PLAYER_BULLET_LIFE: float = 1.0

# HP values
const PLAYER_MAX_HP: int = 100
const BOSS_MAX_HP: int = 200

# health bar sizes
const HP_BAR_WIDTH: float = 260.0
const HP_BAR_HEIGHT: float = 16.0

# boss death animation
const BOSS_DIE_TIME: float = 1.0   # seconds of shake + flicker before disappearing

# kitty hurt flicker time
const PLAYER_HURT_TIME: float = 0.4

# shoot sound
const SHOOT_SOUND: AudioStream = preload("res://playerbullet.wav")
const POP_SOUND: AudioStream = preload("res://pop.wav")

# simple game state
enum GameState { CUTSCENE, PLAYING, STAGE_CLEAR, GAME_OVER }

# ---------------- STATE ----------------

var player: Node2D
var player_hitbox: Node2D
var boss: Node2D

var player_sprite: Sprite2D
var player_hurt_timer: float = 0.0

var player_bullets: Array[Node2D] = []
var boss_bullets: Array[Node2D] = []

var shoot_timer: float = 0.0
var ring_timer: float = 0.0

var score: int = 0
var score_label: Label

var shoot_audio: AudioStreamPlayer
var pop_audio: AudioStreamPlayer

var player_hp: int = PLAYER_MAX_HP
var boss_hp: int = BOSS_MAX_HP

var ui_layer: CanvasLayer
var player_hp_bar: ColorRect
var boss_hp_bar: ColorRect

var boss_base_position: Vector2 = Vector2.ZERO
var boss_sprite: Sprite2D
var boss_flicker: bool = false
var boss_flicker_phase: float = 0.0
var boss_dying: bool = false
var boss_die_timer: float = 0.0

var game_state: int = GameState.PLAYING

var end_panel: ColorRect
var end_title_label: Label
var end_stats_label: Label

var cutscene_panel: ColorRect
var cutscene_label: Label
var cutscene_skip_label: Label
var cutscene_timer: float = 0.0

const CUTSCENE_DURATION: float = 4.0


func _ready() -> void:
	_ensure_input_actions()
	randomize()
	_create_background()
	_create_player()
	_create_boss()
	_create_ui()

	game_state = GameState.CUTSCENE

	# audio for shooting
	shoot_audio = AudioStreamPlayer.new()
	shoot_audio.stream = SHOOT_SOUND
	add_child(shoot_audio)

	pop_audio = AudioStreamPlayer.new()
	pop_audio.stream = POP_SOUND
	add_child(pop_audio)

	set_process(true)

	_start_cutscene()


# --------- helper kept for later (circle bosses etc.) ---------

func _make_circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var ang: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(ang), sin(ang)) * radius)
	return pts


func _health_color(ratio: float) -> Color:
	# 1.0 = green, mid = yellow, low = red
	if ratio > 0.6:
		return Color(0.0, 1.0, 0.0)   # lime green
	elif ratio > 0.3:
		return Color(1.0, 1.0, 0.0)   # yellow
	else:
		return Color(1.0, 0.0, 0.0)   # red


# ------------- SETUP NODES --------------

func _create_background() -> void:
	var texture: Texture2D = load("res://background.png") as Texture2D

	if texture:
		var screen: Vector2 = get_viewport_rect().size
		var bg_sprite: Sprite2D = Sprite2D.new()
		bg_sprite.texture = texture
		bg_sprite.centered = false
		bg_sprite.position = Vector2.ZERO

		var tex_size: Vector2 = texture.get_size()
		if tex_size.x != 0.0 and tex_size.y != 0.0:
			bg_sprite.scale = Vector2(screen.x / tex_size.x, screen.y / tex_size.y)

		bg_sprite.z_index = -10
		add_child(bg_sprite)
	else:
		var bg: ColorRect = ColorRect.new()
		bg.color = Color.BLACK
		bg.anchor_left = 0.0
		bg.anchor_top = 0.0
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.offset_left = 0.0
		bg.offset_top = 0.0
		bg.offset_right = 0.0
		bg.offset_bottom = 0.0
		bg.z_index = -10
		add_child(bg)


func _create_player() -> void:
	player = Node2D.new()
	add_child(player)

	var screen: Vector2 = get_viewport_rect().size
	player.position = Vector2(screen.x * 0.2, screen.y * 0.5)

	# --- kitty sprite ---
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://kitty.png") as Texture2D
	sprite.centered = true
	sprite.scale = Vector2(0.2, 0.2)
	player.add_child(sprite)

	player_sprite = sprite

	# tiny red hitbox (for focus mode)
	player_hitbox = Node2D.new()
	player.add_child(player_hitbox)
	var dot: ColorRect = ColorRect.new()
	dot.color = Color(1.0, 0.1, 0.3)
	dot.size = Vector2(4, 4)
	dot.position = Vector2(-2, -2)
	player_hitbox.add_child(dot)
	player_hitbox.visible = false


func _create_boss() -> void:
	boss = Node2D.new()
	add_child(boss)

	var screen: Vector2 = get_viewport_rect().size
	boss.position = Vector2(screen.x * 0.9, screen.y * 0.5)

	# --- boss.png sprite, bigger than kitty ---
	boss_sprite = Sprite2D.new()
	boss_sprite.texture = load("res://boss.png") as Texture2D
	boss_sprite.centered = true
	boss_sprite.scale = Vector2(0.26, 0.26)  # larger than kitty
	boss.add_child(boss_sprite)

	boss_base_position = boss.position


func _create_ui() -> void:
	# Make a UI layer so score/HP bars are always on top
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# Score label
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.position = Vector2(10, 10)

	# Use Dot Gothic 16 if available
	var font_res: Resource = load("res://DotGothic16-Regular.ttf")
	var font: Font = font_res as Font
	if font:
		score_label.add_theme_font_override("font", font)

	ui_layer.add_child(score_label)

	# HP bars
	var screen: Vector2 = get_viewport_rect().size

	player_hp_bar = ColorRect.new()
	player_hp_bar.position = Vector2(10, 40)
	player_hp_bar.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	ui_layer.add_child(player_hp_bar)

	boss_hp_bar = ColorRect.new()
	boss_hp_bar.position = Vector2(screen.x - HP_BAR_WIDTH - 10, 40)
	boss_hp_bar.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	ui_layer.add_child(boss_hp_bar)

	_update_health_bars()

	# End panel (hidden at first)
	end_panel = ColorRect.new()
	end_panel.color = Color(0, 0, 0, 0.8)
	end_panel.size = screen
	end_panel.visible = false
	ui_layer.add_child(end_panel)

	end_title_label = Label.new()
	end_title_label.position = Vector2(screen.x / 2 - 150, screen.y / 2 - 50)
	end_title_label.text = ""
	end_panel.add_child(end_title_label)

	end_stats_label = Label.new()
	end_stats_label.position = Vector2(screen.x / 2 - 150, screen.y / 2)
	end_stats_label.text = ""
	end_panel.add_child(end_stats_label)

	if font:
		end_title_label.add_theme_font_override("font", font)
		end_stats_label.add_theme_font_override("font", font)

	# Cutscene overlay
	cutscene_panel = ColorRect.new()
	cutscene_panel.color = Color(0, 0, 0, 0.7)
	cutscene_panel.size = screen
	cutscene_panel.visible = false
	ui_layer.add_child(cutscene_panel)

	cutscene_label = Label.new()
	cutscene_label.text = "Kitty drifts into a sweet dream...\nA cupcake duel is about to begin!"
	cutscene_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cutscene_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cutscene_label.position = Vector2.ZERO
	cutscene_label.size = screen
	cutscene_panel.add_child(cutscene_label)

	cutscene_skip_label = Label.new()
	cutscene_skip_label.text = "Press ENTER to skip"
	cutscene_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cutscene_skip_label.position = Vector2(0, screen.y * 0.7)
	cutscene_skip_label.size = Vector2(screen.x, 30.0)
	cutscene_panel.add_child(cutscene_skip_label)

	if font:
		cutscene_label.add_theme_font_override("font", font)
		cutscene_skip_label.add_theme_font_override("font", font)


func _start_cutscene() -> void:
	cutscene_timer = CUTSCENE_DURATION
	if cutscene_panel:
		cutscene_panel.visible = true


func _ensure_input_actions() -> void:
	# Provide default controls in case the Input Map is empty.
	_ensure_action_keys("ui_accept", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_ensure_action_keys("ui_up", [KEY_UP, KEY_W])
	_ensure_action_keys("ui_down", [KEY_DOWN, KEY_S])
	_ensure_action_keys("ui_left", [KEY_LEFT, KEY_A])
	_ensure_action_keys("ui_right", [KEY_RIGHT, KEY_D])


func _ensure_action_keys(action: String, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	for keycode in keycodes:
		var exists := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and ev.keycode == keycode:
				exists = true
				break

			if not exists:
				var event := InputEventKey.new()
				event.keycode = keycode
				InputMap.action_add_event(action, event)


func _begin_gameplay() -> void:
	game_state = GameState.PLAYING
	ring_timer = RING_INTERVAL
	_spawn_boss_bullet()
	if cutscene_panel:
		cutscene_panel.visible = false


func _update_score_label() -> void:
	if score_label:
		score_label.text = "Score: %d" % score

	# When score reaches 500, boss starts flickering (enraged)
	if score >= 500 and not boss_flicker and not boss_dying and boss != null:
		boss_flicker = true
		boss_flicker_phase = 0.0


func _update_health_bars() -> void:
	var screen: Vector2 = get_viewport_rect().size

	var p_ratio: float = clamp(float(player_hp) / float(PLAYER_MAX_HP), 0.0, 1.0)
	var b_ratio: float = clamp(float(boss_hp) / float(BOSS_MAX_HP), 0.0, 1.0)

	player_hp_bar.size.x = HP_BAR_WIDTH * p_ratio
	player_hp_bar.color = _health_color(p_ratio)

	# Boss bar shrinks from right to left
	boss_hp_bar.size.x = HP_BAR_WIDTH * b_ratio
	boss_hp_bar.color = _health_color(b_ratio)
	boss_hp_bar.position.x = screen.x - 10.0 - HP_BAR_WIDTH + (HP_BAR_WIDTH - boss_hp_bar.size.x)


func _show_end_screen(title: String, is_clear: bool) -> void:
	game_state = GameState.STAGE_CLEAR if is_clear else GameState.GAME_OVER

	end_title_label.text = title
	end_stats_label.text = "Score: %d\nKitty HP: %d" % [score, max(player_hp, 0)]
	end_panel.visible = true


# ------------ SPAWN FUNCTIONS ------------

func _spawn_player_bullet() -> void:
	var b: Node2D = Node2D.new()
	add_child(b)
	b.position = player.position + Vector2(20, 0)

	# --- cupcake bullets for kitty ---
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://cupcake.png") as Texture2D
	sprite.centered = true
	sprite.scale = Vector2(0.08, 0.08)      # tweak if too big/small
	b.add_child(sprite)

	b.set_meta("vel", Vector2(1, 0) * PLAYER_BULLET_SPEED)
	b.set_meta("rot_speed", 4.0)
	b.set_meta("life", 0.0)
	b.set_meta("max_life", PLAYER_BULLET_LIFE)

	player_bullets.append(b)

	# play shoot sound
	if shoot_audio:
		shoot_audio.play()


# Boss throws ONE big bouncing bullet
func _spawn_boss_bullet() -> void:
	if boss == null:
		return

	# Don't spawn if too many enemy bullets already on screen
	if boss_bullets.size() >= MAX_ENEMY_BULLETS:
		return

	var b: Node2D = Node2D.new()
	add_child(b)
	b.position = boss.position

	# big boss bullet using bullet.png
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://bullet.png") as Texture2D
	sprite.centered = true
	sprite.scale = Vector2(0.18, 0.18)      # larger enemy bullets
	b.add_child(sprite)

	# random direction
	var ang: float = randf() * TAU
	var dir: Vector2 = Vector2(cos(ang), sin(ang))

	b.set_meta("vel", dir * BOSS_BULLET_SPEED)
	b.set_meta("rot_speed", 6.0)

	boss_bullets.append(b)


# ---------------- MAIN LOOP ----------------

func _process(delta: float) -> void:
	# On end screen: wait for Enter/Space to go to title
	if game_state == GameState.STAGE_CLEAR or game_state == GameState.GAME_OVER:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene_to_file("res://title.tscn")
			return
		return

	if game_state == GameState.CUTSCENE:
		cutscene_timer -= delta
		if Input.is_action_just_pressed("ui_accept"):
			cutscene_timer = 0.0

		if cutscene_timer <= 0.0:
			_begin_gameplay()
		return

	_update_player(delta)
	_update_player_shooting(delta)

	_update_player_bullets(delta)
	_update_boss_bullets(delta)
	_update_boss_pattern(delta)

	_update_boss_visual(delta)
	_update_player_hurt(delta)
	_update_health_bars()

	_check_collisions()


# --------------- PLAYER -----------------

func _update_player(delta: float) -> void:
	if player == null:
		return

	var dir: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		dir.x += 1.0
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1.0

	var speed: float = PLAYER_SPEED

	# focus mode with Shift: slower + show hitbox
	if Input.is_key_pressed(KEY_SHIFT):
		speed = FOCUS_SPEED
		player_hitbox.visible = true
	else:
		player_hitbox.visible = false

	if dir != Vector2.ZERO:
		dir = dir.normalized()

	player.position += dir * speed * delta

	# OPTIONAL: clamp kitty to stay on screen
	# var screen := get_viewport_rect().size
	# player.position.x = clamp(player.position.x, 0.0, screen.x)
	# player.position.y = clamp(player.position.y, 0.0, screen.y)


func _update_player_shooting(delta: float) -> void:
	shoot_timer -= delta
	if shoot_timer < 0.0:
		shoot_timer = 0.0

	# hold Space / Enter (ui_accept) to shoot
	if Input.is_action_pressed("ui_accept") and shoot_timer == 0.0 and player != null:
		_spawn_player_bullet()
		shoot_timer = PLAYER_SHOT_COOLDOWN


func _update_player_hurt(delta: float) -> void:
	if player_sprite == null:
		return

	if player_hurt_timer > 0.0:
		player_hurt_timer -= delta
		# fast flicker
		var on: bool = int(player_hurt_timer * 40.0) % 2 == 0
		player_sprite.visible = on
	else:
		# ensure visible when not hurt
		player_sprite.visible = true


# --------------- BULLET UPDATES ---------------

func _update_player_bullets(delta: float) -> void:
	var screen_x: float = get_viewport_rect().size.x

	for i in range(player_bullets.size() - 1, -1, -1):
		var b: Node2D = player_bullets[i]
		if not is_instance_valid(b):
			player_bullets.remove_at(i)
			continue

		var vel: Vector2 = b.get_meta("vel", Vector2.ZERO)
		var rot_speed: float = b.get_meta("rot_speed", 0.0)
		var life: float = b.get_meta("life", 0.0)
		var max_life: float = b.get_meta("max_life", PLAYER_BULLET_LIFE)

		life += delta
		b.set_meta("life", life)

		b.position += vel * delta

		if rot_speed != 0.0:
			for child in b.get_children():
				if child is Sprite2D:
					child.rotation += rot_speed * delta

		# disappear after lifetime OR far off-screen
		if life >= max_life or b.position.x > screen_x + 200.0:
			b.queue_free()
			player_bullets.remove_at(i)


func _update_boss_bullets(delta: float) -> void:
	var screen: Vector2 = get_viewport_rect().size

	for i in range(boss_bullets.size() - 1, -1, -1):
		var b: Node2D = boss_bullets[i]
		if not is_instance_valid(b):
			boss_bullets.remove_at(i)
			continue

		var vel: Vector2 = b.get_meta("vel", Vector2.ZERO)
		var rot_speed: float = b.get_meta("rot_speed", 0.0)

		var pos: Vector2 = b.position
		pos += vel * delta

		# bounce off edges
		if pos.x < 0.0:
			pos.x = 0.0
			vel.x = -vel.x
		elif pos.x > screen.x:
			pos.x = screen.x
			vel.x = -vel.x

		if pos.y < 0.0:
			pos.y = 0.0
			vel.y = -vel.y
		elif pos.y > screen.y:
			pos.y = screen.y
			vel.y = -vel.y

		b.position = pos
		b.set_meta("vel", vel)

		if rot_speed != 0.0:
			for child in b.get_children():
				if child is Sprite2D:
					child.rotation += rot_speed * delta

		# boss bullets stay in play forever unless shot or hitting kitty


# --------------- BOSS PATTERN & VISUALS ---------------

func _update_boss_pattern(delta: float) -> void:
	ring_timer -= delta
	if ring_timer <= 0.0:
		ring_timer = RING_INTERVAL
		_spawn_boss_bullet()


func _update_boss_visual(delta: float) -> void:
	if boss == null or boss_sprite == null:
		return

	if boss_dying:
		boss_die_timer -= delta
		var t: float = boss_die_timer

		# strong flicker + shake
		var on: bool = int(t * 30.0) % 2 == 0
		boss_sprite.visible = on

		var shake_amp: float = 10.0
		boss.position = boss_base_position + Vector2(
			randf_range(-shake_amp, shake_amp),
			randf_range(-shake_amp, shake_amp)
		)

		if boss_die_timer <= 0.0:
			boss.queue_free()
			boss = null
			_show_end_screen("STAGE CLEAR!", true)
			return
	elif boss_flicker:
		# gentle flicker, no shake
		boss_flicker_phase += delta
		var on2: bool = int(boss_flicker_phase * 10.0) % 2 == 0
		boss_sprite.visible = on2
		boss.position = boss_base_position
	else:
		# normal
		boss_sprite.visible = true
		boss.position = boss_base_position


# --------------- COLLISIONS ---------------

func _check_collisions() -> void:
	if player == null:
		return

	# 1) cupcake bullets hitting boss (damage boss)
	if boss != null and not boss_dying:
		for i in range(player_bullets.size() - 1, -1, -1):
			var b: Node2D = player_bullets[i]
			if b.position.distance_to(boss.position) < 50.0:
				score += 10
				_update_score_label()
				boss_hp = max(boss_hp - 5, 0)
				b.queue_free()
				player_bullets.remove_at(i)

				if boss_hp <= 0 and not boss_dying:
					boss_dying = true
					boss_die_timer = BOSS_DIE_TIME
					boss_base_position = boss.position
				continue

	# 2) cupcake bullets shooting enemy bullets (both disappear, +points)
	for pi in range(player_bullets.size() - 1, -1, -1):
		var pb: Node2D = player_bullets[pi]
		var removed_pb: bool = false

		for bi in range(boss_bullets.size() - 1, -1, -1):
			var bb: Node2D = boss_bullets[bi]
			if pb.position.distance_to(bb.position) < 40.0:
				# gain points for shooting bullets
				score += 2
				_update_score_label()

				# remove both instantly
				bb.queue_free()
				boss_bullets.remove_at(bi)

				pb.queue_free()
				player_bullets.remove_at(pi)
				if pop_audio:
					pop_audio.play()
				removed_pb = true
				break

		if removed_pb:
			continue

	# 3) boss bullets hitting kitty hitbox (damage player)
	var hitbox_pos: Vector2 = player.global_position
	for i in range(boss_bullets.size() - 1, -1, -1):
		var b2: Node2D = boss_bullets[i]
		if b2.position.distance_to(hitbox_pos) < 8.0:
			player_hp = max(player_hp - 10, 0)
			print("Kitty hit! HP =", player_hp)
			b2.queue_free()
			boss_bullets.remove_at(i)

			# start hurt flicker
			player_hurt_timer = PLAYER_HURT_TIME

			if player_hp <= 0 and game_state == GameState.PLAYING:
				print("Kitty died!")
				player.hide()
				_show_end_screen("GAME OVER", false)
