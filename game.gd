extends Node2D

var max_time := 30
var new_record_this_run := false
var score := 0
var best_score := 0
var save_path := "user://collector_rush_save.save"
var time_left := 20
var game_active := false

var rng := RandomNumberGenerator.new()

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var best_score_label = $CanvasLayer/UIBox/BestScoreLabel
@onready var time_label = $CanvasLayer/UIBox/TimeLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var player = $Player
@onready var collectible = $Collectible
@onready var hazard = $Hazard
@onready var bonus = $Bonus
@onready var game_timer = $GameTimer
@onready var message_timer = $MessageTimer

func _ready():
	rng.randomize()
	load_best_score()
	show_start_screen()

func show_start_screen():
	score = 0
	time_left = 20
	game_active = false
	game_timer.stop()
	message_timer.stop()
	set_world_visible(false)
	update_ui()
	status_label.text = "Collector Rush\nBaşlamak için Enter"

func start_new_game():
	score = 0
	time_left = 20
	game_active = true
	new_record_this_run = false
	set_world_visible(true)

	move_collectible([])
	move_hazard([collectible.global_position])
	move_bonus([collectible.global_position, hazard.global_position])

	update_ui()
	set_default_status()
	game_timer.start()

func set_world_visible(is_visible: bool):
	player.visible = is_visible
	collectible.visible = is_visible
	hazard.visible = is_visible
	bonus.visible = is_visible

func _physics_process(_delta):
	if game_active:
		check_collect()
		check_hazard()
		check_bonus()

	if Input.is_action_just_pressed("ui_accept") and not game_active:
		start_new_game()

func update_ui():
	score_label.text = "Skor: %d" % score
	best_score_label.text = "En iyi skor: %d" % best_score
	time_label.text = "Süre: %d" % time_left

func set_default_status():
	if game_active:
		status_label.text = "Topla, kaçın, bonusu kap!"

func show_temp_status(text: String):
	status_label.text = text
	message_timer.start()

func _on_message_timer_timeout():
	set_default_status()

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

func move_collectible(excluded_positions: Array = []):
	collectible.global_position = get_safe_random_position(excluded_positions, 140.0)

func move_hazard(excluded_positions: Array = []):
	hazard.global_position = get_safe_random_position(excluded_positions, 140.0)

func move_bonus(excluded_positions: Array = []):
	bonus.global_position = get_safe_random_position(excluded_positions, 140.0)

func check_collect():
	if player.global_position.distance_to(collectible.global_position) < 25:
		score += 1

		if score > best_score:
			best_score = score
			save_best_score()
			new_record_this_run = true

		update_ui()
		show_temp_status("Topladın!")
		move_collectible([hazard.global_position, bonus.global_position])

func check_hazard():
	if player.global_position.distance_to(hazard.global_position) < 28:
		time_left -= 3

		if time_left < 0:
			time_left = 0

		update_ui()
		show_temp_status("Çarptın! -3 saniye")
		move_hazard([collectible.global_position, bonus.global_position])

		if time_left <= 0:
			finish_game()

func check_bonus():
	if player.global_position.distance_to(bonus.global_position) < 25:
		var old_time = time_left
		time_left = min(time_left + 2, max_time)

		if time_left > old_time:
			show_temp_status("Bonus! +2 saniye")
		else:
			show_temp_status("Süre maksimumda")

		update_ui()
		move_bonus([collectible.global_position, hazard.global_position])

func _on_game_timer_timeout():
	if not game_active:
		return

	time_left -= 1
	update_ui()

	if time_left <= 0:
		finish_game()
		
func get_grade_text() -> String:
	if score <= 4:
		return "Zayıf"
	elif score <= 9:
		return "İdare eder"
	elif score <= 14:
		return "İyi"
	else:
		return "Çok iyi"		

func finish_game():
	game_active = false
	game_timer.stop()
	message_timer.stop()
	set_world_visible(true)

	var result_text = "Bitti. Skor: %d | En iyi: %d | Derece: %s" % [score, best_score, get_grade_text()]

	if new_record_this_run:
		result_text += " | Yeni rekor!"

	result_text += " | Enter ile tekrar dene."
	status_label.text = result_text

func save_best_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(best_score)

func load_best_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			best_score = int(file.get_var())
