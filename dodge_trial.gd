extends Node2D

var best_survival_time := 0
var survived_time := 0
var save_path := "user://dodge_trial_save.save"

var rng := RandomNumberGenerator.new()
var time_left := 15
var game_active := false

var base_enemy_speed := 180.0
var base_enemy2_speed := 220.0

var enemy_speed := base_enemy_speed
var enemy2_speed := base_enemy2_speed
var enemy2_active := false

var slow_active := false
var slow_multiplier := 0.5

@onready var time_label = $CanvasLayer/UIBox/TimeLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var player = $Player
@onready var enemy = $Enemy
@onready var enemy2 = $Enemy2
@onready var game_timer = $GameTimer
@onready var best_time_label = $CanvasLayer/UIBox/BestTimeLabel
@onready var slow_bonus = $SlowBonus
@onready var slow_bonus_sprite = $SlowBonus/Sprite2D
@onready var slow_timer = $SlowTimer

func _ready():
	rng.randomize()
	load_best_survival_time()
	slow_bonus_sprite.modulate = Color(0.3, 1.0, 0.3, 1.0)
	slow_timer.timeout.connect(_on_slow_timer_timeout)
	show_start_screen()

func show_start_screen():
	time_left = 15
	survived_time = 0
	game_active = false
	enemy2_active = false
	slow_active = false

	enemy_speed = base_enemy_speed
	enemy2_speed = base_enemy2_speed

	game_timer.stop()
	slow_timer.stop()

	player.visible = false
	enemy.visible = false
	enemy2.visible = false
	slow_bonus.visible = false

	update_ui()
	status_label.text = "Başlamak için Enter"

func start_game():
	time_left = 15
	game_active = true
	enemy2_active = false
	survived_time = 0
	slow_active = false

	enemy_speed = base_enemy_speed
	enemy2_speed = base_enemy2_speed

	player.visible = true
	enemy.visible = true
	enemy2.visible = false
	slow_bonus.visible = false

	slow_timer.stop()

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

func get_safe_random_position(excluded_positions: Array, min_distance: float) -> Vector2:
	var size = get_viewport_rect().size

	for i in range(200):
		var candidate = Vector2(
			rng.randi_range(80, int(size.x) - 80),
			rng.randi_range(80, int(size.y) - 80)
		)

		var valid = true

		for pos in excluded_positions:
			if candidate.distance_to(pos) < min_distance:
				valid = false
				break

		if valid:
			return candidate

	return Vector2(200, 200)

func spawn_slow_bonus():
	var excluded_positions = [player.global_position, enemy.global_position]

	if enemy2_active:
		excluded_positions.append(enemy2.global_position)

	slow_bonus.global_position = get_safe_random_position(excluded_positions, 120.0)
	slow_bonus.visible = true
	status_label.text = "Yavaşlatma bonusu çıktı!"

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")
		return

	if Input.is_action_just_pressed("ui_accept") and not game_active:
		start_game()

	if game_active:
		move_enemy(delta)

		if enemy2_active:
			move_enemy2(delta)

		check_enemy_collision()
		check_slow_bonus()

func move_enemy(delta):
	var current_speed = enemy_speed
	if slow_active:
		current_speed *= slow_multiplier

	var direction = (player.global_position - enemy.global_position).normalized()
	enemy.global_position += direction * current_speed * delta

func move_enemy2(delta):
	var current_speed = enemy2_speed
	if slow_active:
		current_speed *= slow_multiplier

	var direction = (player.global_position - enemy2.global_position).normalized()
	enemy2.global_position += direction * current_speed * delta

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

func check_slow_bonus():
	if slow_bonus.visible and player.global_position.distance_to(slow_bonus.global_position) < 25:
		slow_bonus.visible = false
		slow_active = true
		slow_timer.start()
		status_label.text = "Yavaşlatma aktif!"

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

	if time_left == 11 or time_left == 5:
		if game_active:
			spawn_slow_bonus()

	if time_left <= 0:
		finish_game(true)

func _on_slow_timer_timeout():
	slow_active = false

	if game_active:
		status_label.text = "Kaç!"

func finish_game(won: bool):
	game_active = false
	game_timer.stop()
	slow_timer.stop()
	slow_active = false
	slow_bonus.visible = false

	player.visible = true
	enemy.visible = true
	enemy2.visible = enemy2_active

	if survived_time > best_survival_time:
		best_survival_time = survived_time
		save_best_survival_time()

	update_ui()

	if won:
		status_label.text = "Kazandın! Süre: %d | En iyi: %d | Enter ile tekrar başla" % [survived_time, best_survival_time]
	else:
		status_label.text = "Yakalandın! Süre: %d | En iyi: %d | Enter ile tekrar başla" % [survived_time, best_survival_time]

func save_best_survival_time():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(best_survival_time)

func load_best_survival_time():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			best_survival_time = int(file.get_var())
