extends Node2D

var best_survival_time := 0
var survived_time := 0

var rng := RandomNumberGenerator.new()
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
@onready var best_time_label = $CanvasLayer/UIBox/BestTimeLabel

func _ready():
	rng.randomize()
	show_start_screen()

func show_start_screen():
	time_left = 15
	survived_time = 0
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
	survived_time = 0
	
	enemy_speed = base_enemy_speed
	enemy2_speed = base_enemy2_speed

	player.visible = true
	enemy.visible = true
	enemy2.visible = false

	var size = get_viewport_rect().size
	
	player.global_position = size / 2
	enemy.global_position = get_random_edge_position()
	enemy2.global_position = get_random_edge_position()

	update_ui()
	status_label.text = "Kaç!"
	game_timer.start()

func update_ui():
	time_label.text = "Süre: %d" % time_left
	best_time_label.text = "En iyi: %d" % best_survival_time
	
func get_random_edge_position() -> Vector2:
	var size = get_viewport_rect().size
	var margin = 40.0
	var side = rng.randi_range(0, 3)

	match side:
		0:
			return Vector2(rng.randi_range(int(margin), int(size.x - margin)), margin)
		1:
			return Vector2(size.x - margin, rng.randi_range(int(margin), int(size.y - margin)))
		2:
			return Vector2(rng.randi_range(int(margin), int(size.x - margin)), size.y - margin)
		_:
			return Vector2(margin, rng.randi_range(int(margin), int(size.y - margin)))

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
	enemy2.global_position = get_random_edge_position()
	status_label.text = "İkinci düşman geldi!"

func _on_game_timer_timeout():
	if not game_active:
		return

	time_left -= 1
	survived_time += 1
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

	if survived_time > best_survival_time:
		best_survival_time = survived_time

	update_ui()

	if won:
		status_label.text = "Kazandın! Süre: %d | En iyi: %d | Enter ile tekrar başla" % [survived_time, best_survival_time]
	else:
		status_label.text = "Yakalandın! Süre: %d | En iyi: %d | Enter ile tekrar başla" % [survived_time, best_survival_time]
