extends Node2D

var ball_speed := 420.0
var ball_velocity := Vector2.ZERO
var ball_launched := false

@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var paddle = $Paddle
@onready var ball = $Ball

func _ready():
	show_start_state()

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

func launch_ball():
	ball_launched = true
	ball_velocity = Vector2(1, -1).normalized() * ball_speed
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
		show_start_state()

func check_paddle_bounce():
	var x_close = abs(ball.global_position.x - paddle.global_position.x) <= 85
	var y_close = abs(ball.global_position.y - paddle.global_position.y) <= 25

	if x_close and y_close and ball_velocity.y > 0:
		var offset = (ball.global_position.x - paddle.global_position.x) / 85.0
		ball_velocity = Vector2(offset, -1).normalized() * ball_speed
