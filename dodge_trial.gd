extends Node2D

var time_left := 15
var game_active := false

var base_enemy_speed := 180.0
var base_enemy2_speed := 220.0

var enemy_speed := base_enemy_speed
var enemy2_speed := base_enemy2_speed
var enemy2_active := false

@onready var time_label = $CanvasLayer/UIBox/TimeLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var player = $Player
@onready var enemy = $Enemy
@onready var enemy2 = $Enemy2
@onready var game_timer = $GameTimer

func _ready():
	show_start_screen()

func show_start_screen():
	time_left = 15
	game_active = false
	enemy2_active = false
	game_timer.stop()

	player.visible = false
	enemy.visible = false
	enemy2.visible = false

	update_ui()
	status_label.text = "Başlamak için Enter"

func start_game():
	time_left = 15
	game_active = true
	enemy2_active = false
	
	enemy_speed = base_enemy_speed
	enemy2_speed = base_enemy2_speed

	player.visible = true
	enemy.visible = true
	enemy2.visible = false

	player.global_position = Vector2(200, 200)
	enemy.global_position = Vector2(900, 500)
	enemy2.global_position = Vector2(150, 500)

	update_ui()
	status_label.text = "Kaç!"
	game_timer.start()

func update_ui():
	time_label.text = "Süre: %d" % time_left

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept") and not game_active:
		start_game()

	if game_active:
		move_enemy(delta)

		if enemy2_active:
			move_enemy2(delta)

		check_enemy_collision()

func move_enemy(delta):
	var direction = (player.global_position - enemy.global_position).normalized()
	enemy.global_position += direction * enemy_speed * delta

func move_enemy2(delta):
	var direction = (player.global_position - enemy2.global_position).normalized()
	enemy2.global_position += direction * enemy2_speed * delta
	

func increase_difficulty():
	enemy_speed += 20.0

	if enemy2_active:
		enemy2_speed += 25.0	

func check_enemy_collision():
	if player.global_position.distance_to(enemy.global_position) < 30:
		finish_game(false)
		return

	if enemy2_active and player.global_position.distance_to(enemy2.global_position) < 30:
		finish_game(false)

func activate_enemy2():
	enemy2_active = true
	enemy2.visible = true
	enemy2.global_position = Vector2(150, 500)
	status_label.text = "İkinci düşman geldi!"

func _on_game_timer_timeout():
	if not game_active:
		return

	time_left -= 1
	update_ui()
	
	if time_left == 12 or time_left == 9 or time_left == 6 or time_left == 3:
		increase_difficulty()

	if time_left == 8 and not enemy2_active:
		activate_enemy2()

	if time_left <= 0:
		finish_game(true)

func finish_game(won: bool):
	game_active = false
	game_timer.stop()

	player.visible = true
	enemy.visible = true
	enemy2.visible = enemy2_active

	if won:
		status_label.text = "Kazandın! Enter ile tekrar başla"
	else:
		status_label.text = "Yakalandın! Enter ile tekrar başla"
