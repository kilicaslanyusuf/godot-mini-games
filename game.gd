extends Node2D

var max_time := 30
var new_record_this_run := false
var score := 0
var best_score := 0
var save_path := "user://collector_rush_save.save"
var time_left := 20
var game_active := false
var paused := false

var streak_count := 0

var game_timer_remaining := 0.0
var message_timer_remaining := 0.0
var streak_timer_remaining := 0.0

var game_timer_default_wait := 0.0
var message_timer_default_wait := 0.0
var streak_timer_default_wait := 0.0

var paused_status_backup := ""

var rng := RandomNumberGenerator.new()

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var best_score_label = $CanvasLayer/UIBox/BestScoreLabel
@onready var time_label = $CanvasLayer/UIBox/TimeLabel
@onready var streak_label = $CanvasLayer/UIBox/StreakLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel

@onready var player = $Player
@onready var collectible = $Collectible
@onready var hazard = $Hazard
@onready var bonus = $Bonus

@onready var game_timer = $GameTimer
@onready var message_timer = $MessageTimer
@onready var streak_timer = $StreakTimer

func _ready():
	rng.randomize()
	load_best_score()
	game_timer_default_wait = game_timer.wait_time
	message_timer_default_wait = message_timer.wait_time
	streak_timer_default_wait = streak_timer.wait_time
	streak_timer.timeout.connect(_on_streak_timer_timeout)
	show_start_screen()

func set_player_control_enabled(enabled: bool):
	player.set_process(enabled)
	player.set_physics_process(enabled)
	player.set_process_input(enabled)

func show_start_screen():
	score = 0
	time_left = 20
	game_active = false
	paused = false
	new_record_this_run = false
	streak_count = 0

	game_timer_remaining = 0.0
	message_timer_remaining = 0.0
	streak_timer_remaining = 0.0
	paused_status_backup = ""

	game_timer.stop()
	message_timer.stop()
	streak_timer.stop()

	game_timer.wait_time = game_timer_default_wait
	message_timer.wait_time = message_timer_default_wait
	streak_timer.wait_time = streak_timer_default_wait

	set_world_visible(false)
	set_player_control_enabled(false)
	update_ui()
	status_label.text = "Collector Rush\nBaşlamak için Enter"

func start_new_game():
	score = 0
	time_left = 20
	game_active = true
	paused = false
	new_record_this_run = false
	streak_count = 0

	game_timer_remaining = 0.0
	message_timer_remaining = 0.0
	streak_timer_remaining = 0.0
	paused_status_backup = ""

	game_timer.stop()
	message_timer.stop()
	streak_timer.stop()

	game_timer.wait_time = game_timer_default_wait
	message_timer.wait_time = message_timer_default_wait
	streak_timer.wait_time = streak_timer_default_wait

	set_world_visible(true)
	set_player_control_enabled(true)

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
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")
		return

	if Input.is_action_just_pressed("pause_game") and game_active:
		toggle_pause()
		return

	if paused:
		return

	if game_active:
		check_collect()
		check_hazard()
		check_bonus()

	if Input.is_action_just_pressed("ui_accept") and not game_active:
		start_new_game()

func toggle_pause():
	if not game_active:
		return

	paused = not paused

	if paused:
		paused_status_backup = status_label.text

		game_timer_remaining = game_timer.time_left
		game_timer.stop()

		if not message_timer.is_stopped():
			message_timer_remaining = message_timer.time_left
			message_timer.stop()
		else:
			message_timer_remaining = 0.0

		if not streak_timer.is_stopped():
			streak_timer_remaining = streak_timer.time_left
			streak_timer.stop()
		else:
			streak_timer_remaining = 0.0

		set_player_control_enabled(false)
		status_label.text = "Duraklatıldı | P ile devam | ESC hub"
	else:
		if game_timer_remaining > 0.0:
			game_timer.start(game_timer_remaining)

		if message_timer_remaining > 0.0:
			message_timer.start(message_timer_remaining)

		if streak_timer_remaining > 0.0:
			streak_timer.start(streak_timer_remaining)

		set_player_control_enabled(true)

		if paused_status_backup != "":
			status_label.text = paused_status_backup
		else:
			set_default_status()

func update_ui():
	score_label.text = "Skor: %d" % score
	best_score_label.text = "En iyi skor: %d" % best_score
	time_label.text = "Süre: %d" % time_left
	streak_label.text = "Streak: x%d" % streak_count

func set_default_status():
	if game_active:
		status_label.text = "Topla, kaçın, bonusu kap!"

func show_temp_status(text: String):
	status_label.text = text
	message_timer.stop()
	message_timer.wait_time = message_timer_default_wait
	message_timer.start()

func _on_message_timer_timeout():
	message_timer.wait_time = message_timer_default_wait
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
		streak_count += 1
		var gained_points = streak_count
		score += gained_points

		if score > best_score:
			best_score = score
			save_best_score()
			new_record_this_run = true

		streak_timer.stop()
		streak_timer.wait_time = streak_timer_default_wait
		streak_timer.start()

		update_ui()
		show_temp_status("Topladın! +%d | Streak x%d" % [gained_points, streak_count])
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

func _on_streak_timer_timeout():
	streak_timer.wait_time = streak_timer_default_wait
	streak_count = 0
	update_ui()

	if game_active and not paused:
		status_label.text = "Streak bitti"

func _on_game_timer_timeout():
	if not game_active or paused:
		return

	game_timer.wait_time = game_timer_default_wait

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
	paused = false
	streak_count = 0

	game_timer_remaining = 0.0
	message_timer_remaining = 0.0
	streak_timer_remaining = 0.0
	paused_status_backup = ""

	game_timer.stop()
	message_timer.stop()
	streak_timer.stop()

	game_timer.wait_time = game_timer_default_wait
	message_timer.wait_time = message_timer_default_wait
	streak_timer.wait_time = streak_timer_default_wait

	set_player_control_enabled(false)
	set_world_visible(true)
	update_ui()

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
