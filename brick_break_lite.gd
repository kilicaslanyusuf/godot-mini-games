extends Node2D

var rng := RandomNumberGenerator.new()
var ball_speed := 420.0
var ball_velocity := Vector2.ZERO
var ball_launched := false
var score := 0

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel

@onready var paddle = $Paddle
@onready var ball = $Ball

@onready var bricks = [
	$Bricks/Brick1,
	$Bricks/Brick2,
	$Bricks/Brick3,
	$Bricks/Brick4,
	$Bricks/Brick5
]

func _ready():
	rng.randomize()
	start_new_round()

func start_new_round():
	score = 0
	reset_bricks()
	show_start_state()
	update_ui()

func show_start_state():
	ball_launched = false
	ball_velocity = Vector2.ZERO
	status_label.text = "Space ile topu başlat"
	reset_ball_on_paddle()

func reset_ball_on_paddle():
	ball.global_position = paddle.global_position + Vector2(0, -45)

func _physics_process(delta):
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
		status_label.text = "Kaçtı! Yeni tur başlıyor"
		start_new_round()

func check_paddle_bounce():
	var x_close = abs(ball.global_position.x - paddle.global_position.x) <= 85
	var y_close = abs(ball.global_position.y - paddle.global_position.y) <= 25

	if x_close and y_close and ball_velocity.y > 0:
		var offset = (ball.global_position.x - paddle.global_position.x) / 85.0
		ball_velocity = Vector2(offset, -1).normalized() * ball_speed

func check_brick_collision():
	for brick in bricks:
		if not brick.visible:
			continue

		var x_close = abs(ball.global_position.x - brick.global_position.x) <= 75
		var y_close = abs(ball.global_position.y - brick.global_position.y) <= 30

		if x_close and y_close:
			brick.visible = false
			brick.get_node("Sprite2D").visible = false

			if ball_velocity.y < 0:
				ball_velocity.y = abs(ball_velocity.y)
			else:
				ball_velocity.y = -abs(ball_velocity.y)

			score += 1
			update_ui()
			status_label.text = "Tuğla kırıldı!"

			if all_bricks_broken():
				status_label.text = "Satır temizlendi!"
				reset_bricks()

			break

func all_bricks_broken() -> bool:
	for brick in bricks:
		if brick.visible:
			return false
	return true

func reset_bricks():
	var size = get_viewport_rect().size
	var gap = 150.0
	var total_width = (bricks.size() - 1) * gap
	var start_x = rng.randi_range(160, int(size.x - 160 - total_width))
	var row_y = rng.randi_range(120, 200)

	for i in range(bricks.size()):
		var brick = bricks[i]
		brick.visible = true
		brick.get_node("Sprite2D").visible = true
		brick.global_position = Vector2(start_x + i * gap, row_y)

func update_ui():
	score_label.text = "Skor: %d" % score
