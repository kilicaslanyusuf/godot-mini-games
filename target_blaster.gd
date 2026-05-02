extends Node2D

var score := 0
var time_left := 20
var game_active := false

var bullet_active := false
var bullet_speed := 900.0
var rng := RandomNumberGenerator.new()

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var time_label = $CanvasLayer/UIBox/TimeLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var player = $Player
@onready var bullet = $Bullet
@onready var target = $Target
@onready var game_timer = $GameTimer

func _ready():
	rng.randomize()
	show_start_screen()

func show_start_screen():
	score = 0
	time_left = 20
	game_active = false
	bullet_active = false

	player.visible = true
	target.visible = false
	bullet.visible = false

	update_ui()
	status_label.text = "Başlamak için Enter"

func start_game():
	score = 0
	time_left = 20
	game_active = true
	bullet_active = false

	player.visible = true
	target.visible = true
	bullet.visible = false

	update_ui()
	status_label.text = "Space ile ateş et"
	reset_bullet()
	move_target()
	game_timer.start()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept") and not game_active:
		start_game()

	if not game_active:
		return

	handle_shoot()
	move_bullet(delta)
	check_hit()

func handle_shoot():
	if Input.is_action_just_pressed("shoot") and not bullet_active:
		bullet_active = true
		bullet.visible = true
		bullet.global_position = player.global_position + Vector2(0, -60)
		status_label.text = "Ateş ettin"

func move_bullet(delta):
	if not bullet_active:
		return

	bullet.global_position.y -= bullet_speed * delta

	if bullet.global_position.y < -50:
		reset_bullet()
		status_label.text = "Kaçırdın"

func check_hit():
	if not bullet_active:
		return

	var x_hit = abs(bullet.global_position.x - target.global_position.x) <= 70
	var y_hit = abs(bullet.global_position.y - target.global_position.y) <= 70

	if x_hit and y_hit:
		score += 1
		update_ui()
		status_label.text = "Vurdun!"
		reset_bullet()
		move_target()

func move_target():
	var size = get_viewport_rect().size
	target.visible = true
	target.global_position = Vector2(
		rng.randi_range(220, int(size.x) - 220),
		120
	)

func reset_bullet():
	bullet_active = false
	bullet.visible = false
	bullet.global_position = player.global_position + Vector2(0, -60)

func update_ui():
	score_label.text = "Skor: %d" % score
	time_label.text = "Süre: %d" % time_left

func _on_game_timer_timeout():
	if not game_active:
		return

	time_left -= 1
	update_ui()

	if time_left <= 0:
		finish_game()

func finish_game():
	game_active = false
	game_timer.stop()
	bullet_active = false
	bullet.visible = false
	target.visible = false
	status_label.text = "Süre bitti! Skor: %d | Enter ile tekrar başla" % score
