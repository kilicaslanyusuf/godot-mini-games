extends Node2D

var base_ball_speed := 420.0
var ball_speed := base_ball_speed
var ball_velocity := Vector2.ZERO
var ball_launched := false

var score := 0
var level := 1
var lives := 3
var max_lives := 3
var game_over_state := false
var paused := false

var base_paddle_scale_x := 0.55
var min_paddle_scale_x := 0.35
var base_paddle_collision_width := 140.0
var min_paddle_collision_width := 80.0

var best_score := 0
var best_level := 1
var save_path := "user://brick_break_save.save"

var rng := RandomNumberGenerator.new()
var brick_hp := {}
var brick_type := {}
var level_patterns = [
	[2,2,3,2,2, 1,1,1,1,1],
	[2,0,2,0,2, 1,3,1,3,1],
	[2,2,0,2,2, 0,1,3,1,0],
	[0,2,3,2,0, 1,1,0,1,1]
]

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var lives_label = $CanvasLayer/UIBox/LivesLabel
@onready var level_label = $CanvasLayer/UIBox/LevelLabel
@onready var best_label = $CanvasLayer/UIBox/BestLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel

@onready var paddle = $Paddle
@onready var paddle_sprite = $Paddle/Sprite2D
@onready var paddle_collision = $Paddle/CollisionShape2D
@onready var ball = $Ball

@onready var bricks = [
	$Bricks/Brick1,
	$Bricks/Brick2,
	$Bricks/Brick3,
	$Bricks/Brick4,
	$Bricks/Brick5,
	$Bricks/Brick6,
	$Bricks/Brick7,
	$Bricks/Brick8,
	$Bricks/Brick9,
	$Bricks/Brick10
]

func _ready():
	rng.randomize()
	load_progress()
	start_new_game()

func start_new_game():
	score = 0
	level = 1
	lives = max_lives
	ball_speed = base_ball_speed
	game_over_state = false
	paused = false
	reset_paddle_size()

	reset_bricks()
	show_start_state("Space ile topu başlat")
	update_ui()

func toggle_pause():
	if game_over_state:
		return

	paused = not paused

	if paused:
		status_label.text = "Duraklatıldı | P ile devam | ESC hub"
	else:
		if ball_launched:
			status_label.text = "Devam"
		else:
			status_label.text = "Space ile topu başlat"

func show_start_state(message: String = "Space ile topu başlat"):
	paused = false
	ball_launched = false
	ball_velocity = Vector2.ZERO
	status_label.text = message
	reset_ball_on_paddle()

func reset_ball_on_paddle():
	ball.global_position = paddle.global_position + Vector2(0, -45)

func _physics_process(delta):
	if game_over_state:
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().change_scene_to_file("res://mini_games_hub.tscn")
			return

		if Input.is_action_just_pressed("ui_accept"):
			start_new_game()
		return

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")
		return

	if Input.is_action_just_pressed("pause_game"):
		toggle_pause()
		return

	if paused:
		return

	if not ball_launched:
		reset_ball_on_paddle()

		if Input.is_action_just_pressed("shoot"):
			launch_ball()

		return

	move_ball(delta)
	check_paddle_bounce()
	check_brick_collision()

func launch_ball():
	ball_launched = true
	ball_velocity = Vector2(0.25, -1).normalized() * ball_speed
	status_label.text = "Devam"

func move_ball(delta):
	ball.global_position += ball_velocity * delta

	var size = get_viewport_rect().size
	var radius = 10.0

	if ball.global_position.x <= radius:
		ball.global_position.x = radius
		ball_velocity.x *= -1
	elif ball.global_position.x >= size.x - radius:
		ball.global_position.x = size.x - radius
		ball_velocity.x *= -1

	if ball.global_position.y <= radius:
		ball.global_position.y = radius
		ball_velocity.y *= -1

	if ball.global_position.y >= size.y + 30:
		lives -= 1
		update_ui()

		if lives <= 0:
			game_over()
		else:
			show_start_state("Can gitti! Space ile devam")

func check_paddle_bounce():
	var half_width = paddle_collision.shape.size.x / 2.0
	var x_close = abs(ball.global_position.x - paddle.global_position.x) <= half_width
	var y_close = abs(ball.global_position.y - paddle.global_position.y) <= 25

	if x_close and y_close and ball_velocity.y > 0:
		var offset = (ball.global_position.x - paddle.global_position.x) / half_width
		ball_velocity = Vector2(offset, -1).normalized() * ball_speed

func check_brick_collision():
	for brick in bricks:
		if not brick.visible:
			continue

		var x_close = abs(ball.global_position.x - brick.global_position.x) <= 75
		var y_close = abs(ball.global_position.y - brick.global_position.y) <= 30

		if x_close and y_close:
			hit_brick(brick)

			if ball_velocity.y < 0:
				ball_velocity.y = abs(ball_velocity.y)
			else:
				ball_velocity.y = -abs(ball_velocity.y)

			break

func hit_brick(brick):
	if brick_hp[brick.name] <= 0:
		return

	var key = brick.name
	brick_hp[key] -= 1

	if brick_hp[key] <= 0:
		var type_value = brick_type[key]

		brick.visible = false
		brick.get_node("Sprite2D").visible = false

		if type_value == 3:
			score += 3
			lives = min(max_lives, lives + 1)
			status_label.text = "Bonus tuğla! +3 skor, +1 can"
		else:
			score += 1

			if all_bricks_broken():
				status_label.text = "Bölüm temizlendi!"
			else:
				status_label.text = "Tuğla kırıldı!"

		check_records()
		update_ui()

		if all_bricks_broken():
			next_level()
	else:
		set_brick_visual(brick)
		status_label.text = "Sert tuğla çatladı!"

func all_bricks_broken() -> bool:
	for brick in bricks:
		if brick.visible:
			return false
	return true

func reset_paddle_size():
	paddle_sprite.scale = Vector2(base_paddle_scale_x, paddle_sprite.scale.y)
	paddle_collision.shape.size.x = base_paddle_collision_width

func update_paddle_difficulty():
	var new_scale_x = max(min_paddle_scale_x, base_paddle_scale_x - (level - 1) * 0.04)
	var new_collision_width = max(min_paddle_collision_width, base_paddle_collision_width - (level - 1) * 10.0)

	paddle_sprite.scale = Vector2(new_scale_x, paddle_sprite.scale.y)
	paddle_collision.shape.size.x = new_collision_width

func get_current_pattern():
	return level_patterns[(level - 1) % level_patterns.size()]

func reset_bricks():
	var size = get_viewport_rect().size
	var gap_x = 150.0
	var gap_y = 70.0
	var cols = 5

	var total_width = (cols - 1) * gap_x
	var start_x = rng.randi_range(160, int(size.x - 160 - total_width))
	var start_y = rng.randi_range(110, 170)

	var pattern = get_current_pattern()

	for i in range(bricks.size()):
		var brick = bricks[i]
		var row = i / cols
		var col = i % cols
		var type_value = pattern[i]

		brick.global_position = Vector2(
			start_x + col * gap_x,
			start_y + row * gap_y
		)

		brick_type[brick.name] = type_value

		if type_value == 0:
			brick.visible = false
			brick.get_node("Sprite2D").visible = false
			brick_hp[brick.name] = 0
		else:
			brick.visible = true
			brick.get_node("Sprite2D").visible = true

			if type_value == 2:
				brick_hp[brick.name] = 2
			else:
				brick_hp[brick.name] = 1

			set_brick_visual(brick)

func set_brick_visual(brick):
	var sprite = brick.get_node("Sprite2D")
	var type_value = brick_type[brick.name]
	var hp_value = brick_hp[brick.name]

	if type_value == 3:
		sprite.modulate = Color(0.3, 1.0, 0.3, 1.0)
	elif hp_value >= 2:
		sprite.modulate = Color(1.0, 0.6, 0.2, 1.0)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func check_records():
	var changed := false

	if score > best_score:
		best_score = score
		changed = true

	if level > best_level:
		best_level = level
		changed = true

	if changed:
		save_progress()

func next_level():
	level += 1
	ball_speed += 40.0
	update_paddle_difficulty()
	check_records()
	reset_bricks()
	show_start_state("Seviye %d! Top hızlandı, paddle küçüldü" % level)
	update_ui()

func game_over():
	paused = false
	game_over_state = true
	ball_launched = false
	ball_velocity = Vector2.ZERO
	reset_ball_on_paddle()
	status_label.text = "Oyun bitti! Skor: %d | Seviye: %d | Enter ile yeni oyun" % [score, level]

func save_progress():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var({
			"best_score": best_score,
			"best_level": best_level
		})

func load_progress():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				best_score = int(data.get("best_score", 0))
				best_level = int(data.get("best_level", 1))

func update_ui():
	score_label.text = "Skor: %d" % score
	lives_label.text = "Can: %d" % lives
	level_label.text = "Seviye: %d" % level
	best_label.text = "Rekor: %d | En iyi seviye: %d" % [best_score, best_level]
