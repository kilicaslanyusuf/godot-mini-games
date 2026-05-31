extends Node2D

var lane_positions = [360.0, 576.0, 792.0]
var current_lane := 1

var base_obstacle_speed := 260.0
var obstacle_speed := base_obstacle_speed

var score := 0
var best_score := 0
var save_path := "user://lane_dash_lite_save.save"
var game_active := false
var obstacle2_active := false

var lives := 3
var max_lives := 3

var shield_active := false
var shield_on_field := false
var invincible := false

var rng := RandomNumberGenerator.new()

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var best_score_label = $CanvasLayer/UIBox/BestScoreLabel
@onready var lives_label = $CanvasLayer/UIBox/LivesLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var player = $Player
@onready var obstacle = $Obstacle
@onready var obstacle2 = $Obstacle2
@onready var shield = $Shield
@onready var shield_sprite = $Shield/Sprite2D
@onready var player_sprite = $Player/Sprite2D
@onready var invincibility_timer = $InvincibilityTimer

func _ready():
	rng.randomize()
	load_best_score()
	shield_sprite.modulate = Color(0.3, 1.0, 0.3, 1.0)
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	show_start_screen()



func show_start_screen():
	invincible = false
	invincibility_timer.stop()
	player_sprite.modulate = Color(1, 1, 1, 1)
	score = 0
	game_active = false
	current_lane = 1
	obstacle_speed = base_obstacle_speed
	obstacle2_active = false
	shield_active = false
	shield_on_field = false
	lives = max_lives

	player.global_position = Vector2(lane_positions[current_lane], 560)
	obstacle.global_position = Vector2(lane_positions[1], -80)
	obstacle2.global_position = Vector2(lane_positions[0], -300)
	shield.global_position = Vector2(lane_positions[1], -500)

	obstacle2.visible = false
	shield.visible = false

	update_ui()
	status_label.text = "Enter ile başla"

func start_game():
	invincible = false
	invincibility_timer.stop()
	player_sprite.modulate = Color(1, 1, 1, 1)
	score = 0
	game_active = true
	current_lane = 1
	obstacle_speed = base_obstacle_speed
	obstacle2_active = false
	shield_active = false
	shield_on_field = false
	lives = max_lives

	player.global_position = Vector2(lane_positions[current_lane], 560)
	respawn_in_free_lane(obstacle, -80, [])
	obstacle2.global_position = Vector2(lane_positions[0], -300)
	obstacle2.visible = false

	shield.global_position = Vector2(lane_positions[1], -500)
	shield.visible = false

	update_ui()
	status_label.text = "Sağ/sol ile kaç"
	
func begin_invincibility():
	invincible = true
	invincibility_timer.start()
	player_sprite.modulate = Color(1, 1, 1, 0.45)	

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")
		return

	if not game_active:
		if Input.is_action_just_pressed("ui_accept"):
			start_game()
		return

	handle_lane_input()
	move_entities(delta)
	check_collision()

func handle_lane_input():
	if Input.is_action_just_pressed("ui_left"):
		current_lane = max(0, current_lane - 1)
		player.global_position.x = lane_positions[current_lane]

	if Input.is_action_just_pressed("ui_right"):
		current_lane = min(2, current_lane + 1)
		player.global_position.x = lane_positions[current_lane]

func move_entities(delta):
	obstacle.global_position.y += obstacle_speed * delta

	if obstacle.global_position.y > 720:
		register_dodge()
		var blocked_lanes = []
		if obstacle2_active:
			blocked_lanes.append(get_lane_index_for_node(obstacle2))
		if shield_on_field:
			blocked_lanes.append(get_lane_index_for_node(shield))
		respawn_in_free_lane(obstacle, -80, blocked_lanes)

	if obstacle2_active:
		obstacle2.global_position.y += obstacle_speed * 1.08 * delta

		if obstacle2.global_position.y > 720:
			register_dodge()
			var blocked_lanes = [get_lane_index_for_node(obstacle)]
			if shield_on_field:
				blocked_lanes.append(get_lane_index_for_node(shield))
			respawn_in_free_lane(obstacle2, -260, blocked_lanes)

	if shield_on_field:
		shield.global_position.y += obstacle_speed * 0.82 * delta

		if shield.global_position.y > 720:
			shield_on_field = false
			shield.visible = false

func register_dodge():
	score += 1

	if score > best_score:
		best_score = score
		save_best_score()

	if score >= 8 and not obstacle2_active:
		activate_obstacle2()

	if score >= 6 and not shield_active and not shield_on_field and score % 6 == 0:
		spawn_shield()

	if score % 5 == 0:
		obstacle_speed += 35.0
		status_label.text = "Hız arttı!"
	else:
		if shield_active:
			status_label.text = "Kalkan hazır"
		else:
			status_label.text = "Sağ/sol ile kaç"

	update_ui()

func activate_obstacle2():
	obstacle2_active = true
	obstacle2.visible = true
	var blocked_lanes = [get_lane_index_for_node(obstacle)]
	respawn_in_free_lane(obstacle2, -260, blocked_lanes)
	status_label.text = "İkinci engel aktif!"

func spawn_shield():
	shield_on_field = true
	shield.visible = true

	var blocked_lanes = [get_lane_index_for_node(obstacle)]
	if obstacle2_active:
		blocked_lanes.append(get_lane_index_for_node(obstacle2))

	respawn_in_free_lane(shield, -220, blocked_lanes)
	status_label.text = "Kalkan geliyor!"

func respawn_in_free_lane(node: Node2D, y_value: float, forbidden_lanes: Array):
	var lane_index = rng.randi_range(0, 2)
	var tries = 0

	while lane_index in forbidden_lanes and tries < 20:
		lane_index = rng.randi_range(0, 2)
		tries += 1

	node.global_position = Vector2(lane_positions[lane_index], y_value)

func get_lane_index_for_node(node: Node2D) -> int:
	for i in range(lane_positions.size()):
		if abs(node.global_position.x - lane_positions[i]) < 5:
			return i
	return -1

func check_collision():
	if not invincible:
		if hit_with_node(obstacle):
			handle_obstacle_hit(obstacle, -80)
			return

		if obstacle2_active and hit_with_node(obstacle2):
			handle_obstacle_hit(obstacle2, -260)
			return

	if shield_on_field and hit_with_node(shield, 45):
		collect_shield()

func hit_with_node(node: Node2D, y_limit: float = 55.0) -> bool:
	var same_lane = abs(player.global_position.x - node.global_position.x) < 10
	var y_close = abs(player.global_position.y - node.global_position.y) < y_limit
	return same_lane and y_close

func handle_obstacle_hit(node: Node2D, y_value: float):
	var blocked_lanes = []
	if node != obstacle:
		blocked_lanes.append(get_lane_index_for_node(obstacle))
	if obstacle2_active and node != obstacle2:
		blocked_lanes.append(get_lane_index_for_node(obstacle2))
	if shield_on_field:
		blocked_lanes.append(get_lane_index_for_node(shield))

	if shield_active:
		shield_active = false
		begin_invincibility()
		status_label.text = "Kalkan kırıldı! Kısa süre güvendesin"
		respawn_in_free_lane(node, y_value, blocked_lanes)
		update_ui()
		return

	lives -= 1
	update_ui()

	if lives <= 0:
		finish_game()
		return

	begin_invincibility()
	status_label.text = "Can gitti! Kısa süre dokunulmazsın"
	respawn_in_free_lane(node, y_value, blocked_lanes)

func collect_shield():
	shield_active = true
	shield_on_field = false
	shield.visible = false
	status_label.text = "Kalkan alındı!"
	update_ui()

func _on_invincibility_timer_timeout():
	invincible = false
	player_sprite.modulate = Color(1, 1, 1, 1)

	if game_active:
		if shield_active:
			status_label.text = "Kalkan hazır"
		else:
			status_label.text = "Sağ/sol ile kaç"	

func finish_game():
	game_active = false
	status_label.text = "Can bitti! Skor: %d | En iyi: %d | Enter ile tekrar" % [score, best_score]

func update_ui():
	var shield_text = ""
	if shield_active:
		shield_text = " | Kalkan: Var"

	score_label.text = "Skor: %d%s" % [score, shield_text]
	best_score_label.text = "En iyi: %d" % best_score
	lives_label.text = "Can: %d" % lives

func save_best_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(best_score)

func load_best_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			best_score = int(file.get_var())
