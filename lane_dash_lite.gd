extends Node2D

var lane_positions = [360.0, 576.0, 792.0]
var current_lane := 1

var base_obstacle_speed := 260.0
var obstacle_speed := base_obstacle_speed

var score := 0
var best_score := 0
var save_path := "user://lane_dash_lite_save.save"
var game_active := false

var rng := RandomNumberGenerator.new()

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var best_score_label = $CanvasLayer/UIBox/BestScoreLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var player = $Player
@onready var obstacle = $Obstacle

func _ready():
	rng.randomize()
	load_best_score()
	show_start_screen()

func show_start_screen():
	score = 0
	game_active = false
	current_lane = 1
	obstacle_speed = base_obstacle_speed

	player.global_position = Vector2(lane_positions[current_lane], 560)
	obstacle.global_position = Vector2(lane_positions[1], -80)

	update_ui()
	status_label.text = "Enter ile başla"

func start_game():
	score = 0
	game_active = true
	current_lane = 1
	obstacle_speed = base_obstacle_speed

	player.global_position = Vector2(lane_positions[current_lane], 560)
	respawn_obstacle()

	update_ui()
	status_label.text = "Sağ/sol ile kaç"

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")
		return

	if not game_active:
		if Input.is_action_just_pressed("ui_accept"):
			start_game()
		return

	handle_lane_input()
	move_obstacle(delta)
	check_collision()

func handle_lane_input():
	if Input.is_action_just_pressed("ui_left"):
		current_lane = max(0, current_lane - 1)
		player.global_position.x = lane_positions[current_lane]

	if Input.is_action_just_pressed("ui_right"):
		current_lane = min(2, current_lane + 1)
		player.global_position.x = lane_positions[current_lane]

func move_obstacle(delta):
	obstacle.global_position.y += obstacle_speed * delta

	if obstacle.global_position.y > 720:
		score += 1

		if score > best_score:
			best_score = score
			save_best_score()

		if score % 5 == 0:
			obstacle_speed += 35.0
			status_label.text = "Hız arttı!"
		else:
			status_label.text = "Sağ/sol ile kaç"

		update_ui()
		respawn_obstacle()

func respawn_obstacle():
	var lane_index = rng.randi_range(0, 2)
	obstacle.global_position = Vector2(lane_positions[lane_index], -80)

func check_collision():
	var same_lane = abs(player.global_position.x - obstacle.global_position.x) < 10
	var y_close = abs(player.global_position.y - obstacle.global_position.y) < 55

	if same_lane and y_close:
		finish_game()

func finish_game():
	game_active = false
	status_label.text = "Çarptın! Skor: %d | En iyi: %d | Enter ile tekrar" % [score, best_score]

func update_ui():
	score_label.text = "Skor: %d" % score
	best_score_label.text = "En iyi: %d" % best_score

func save_best_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(best_score)

func load_best_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			best_score = int(file.get_var())
