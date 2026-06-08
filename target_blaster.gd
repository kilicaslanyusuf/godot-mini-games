extends Node2D

var shots_fired := 0
var hits_landed := 0
var score := 0
var best_score := 0
var save_path := "user://target_blaster_save.save"

var time_left := 20
var game_active := false
var paused := false

var misses := 0
var max_misses := 3

var combo_count := 0

var bullet_active := false
var bullet_speed := 900.0
var rng := RandomNumberGenerator.new()

var base_target_speed := 220.0
var target_speed := base_target_speed
var speed_step := 20.0
var max_target_speed := 420.0
var target_direction := 1.0
var target_base_scale := Vector2(1.0, 1.0)
var target_min_scale := Vector2(0.45, 0.45)
var hit_tolerance := 70.0

var max_ammo := 6
var ammo := 6
var is_reloading := false

var game_timer_remaining := 0.0
var combo_timer_remaining := 0.0
var reload_timer_remaining := 0.0

var game_timer_default_wait := 0.0
var combo_timer_default_wait := 0.0
var reload_timer_default_wait := 0.0

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var best_score_label = $CanvasLayer/UIBox/BestScoreLabel
@onready var time_label = $CanvasLayer/UIBox/TimeLabel
@onready var miss_label = $CanvasLayer/UIBox/MissLabel
@onready var combo_label = $CanvasLayer/UIBox/ComboLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel
@onready var ammo_label = $CanvasLayer/UIBox/AmmoLabel

@onready var player = $Player
@onready var bullet = $Bullet
@onready var target = $Target

@onready var game_timer = $GameTimer
@onready var combo_timer = $ComboTimer
@onready var reload_timer = $ReloadTimer
@onready var shots_label = $CanvasLayer/UIBox/ShotsLabel
@onready var accuracy_label = $CanvasLayer/UIBox/AccuracyLabel

func _ready():
	rng.randomize()
	load_best_score()
	target_base_scale = target.scale

	reload_timer.timeout.connect(_on_reload_timer_timeout)

	game_timer_default_wait = game_timer.wait_time
	combo_timer_default_wait = combo_timer.wait_time
	reload_timer_default_wait = reload_timer.wait_time

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
	bullet_active = false
	misses = 0
	combo_count = 0
	shots_fired = 0
	hits_landed = 0
	ammo = max_ammo
	is_reloading = false

	game_timer_remaining = 0.0
	combo_timer_remaining = 0.0
	reload_timer_remaining = 0.0

	game_timer.stop()
	combo_timer.stop()
	reload_timer.stop()

	game_timer.wait_time = game_timer_default_wait
	combo_timer.wait_time = combo_timer_default_wait
	reload_timer.wait_time = reload_timer_default_wait

	player.visible = true
	target.visible = false
	bullet.visible = false

	set_player_control_enabled(false)

	update_ui()
	status_label.text = "Başlamak için Enter"

func start_game():
	score = 0
	time_left = 20
	game_active = true
	paused = false
	bullet_active = false
	misses = 0
	combo_count = 0
	shots_fired = 0
	hits_landed = 0
	ammo = max_ammo
	is_reloading = false
	target_speed = base_target_speed
	target.scale = target_base_scale
	hit_tolerance = 70.0

	game_timer_remaining = 0.0
	combo_timer_remaining = 0.0
	reload_timer_remaining = 0.0

	game_timer.stop()
	combo_timer.stop()
	reload_timer.stop()

	game_timer.wait_time = game_timer_default_wait
	combo_timer.wait_time = combo_timer_default_wait
	reload_timer.wait_time = reload_timer_default_wait

	player.visible = true
	target.visible = true
	bullet.visible = false

	set_player_control_enabled(true)

	update_ui()
	status_label.text = "Space ile ateş et"
	reset_bullet()
	move_target()
	game_timer.start()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://mini_games_hub.tscn")
		return

	if Input.is_action_just_pressed("pause_game") and game_active:
		toggle_pause()
		return

	if Input.is_action_just_pressed("ui_accept") and not game_active:
		start_game()

	if paused:
		return

	if not game_active:
		return

	move_target_sideways(delta)
	handle_shoot()
	move_bullet(delta)
	check_hit()

func toggle_pause():
	if not game_active:
		return

	paused = not paused

	if paused:
		game_timer_remaining = game_timer.time_left
		game_timer.stop()

		if combo_count > 0 and not combo_timer.is_stopped():
			combo_timer_remaining = combo_timer.time_left
			combo_timer.stop()
		else:
			combo_timer_remaining = 0.0

		if is_reloading and not reload_timer.is_stopped():
			reload_timer_remaining = reload_timer.time_left
			reload_timer.stop()
		else:
			reload_timer_remaining = 0.0

		set_player_control_enabled(false)
		status_label.text = "Duraklatıldı | P ile devam | ESC hub"
	else:
		if game_timer_remaining > 0.0:
			game_timer.start(game_timer_remaining)

		if combo_timer_remaining > 0.0:
			combo_timer.start(combo_timer_remaining)

		if is_reloading and reload_timer_remaining > 0.0:
			reload_timer.start(reload_timer_remaining)

		set_player_control_enabled(true)

		if is_reloading:
			status_label.text = "Şarjör dolduruluyor..."
		else:
			status_label.text = "Space ile ateş et"

func handle_shoot():
	if not Input.is_action_just_pressed("shoot"):
		return

	if is_reloading:
		status_label.text = "Şarjör dolduruluyor..."
		return

	if bullet_active:
		return

	if ammo <= 0:
		begin_reload()
		return

	bullet_active = true
	bullet.visible = true
	bullet.global_position = player.global_position + Vector2(0, -60)

	shots_fired += 1
	ammo -= 1
	update_ui()

	if ammo <= 0:
		begin_reload()
	else:
		status_label.text = "Ateş ettin"

func begin_reload():
	if is_reloading:
		return

	is_reloading = true
	reload_timer.start()
	update_ui()
	status_label.text = "Şarjör dolduruluyor..."

func move_bullet(delta):
	if not bullet_active:
		return

	bullet.global_position.y -= bullet_speed * delta

	if bullet.global_position.y < -50:
		reset_bullet()
		misses += 1

		if combo_count > 0:
			combo_count = 0
			combo_timer.stop()
			combo_timer.wait_time = combo_timer_default_wait
			status_label.text = "Kaçırdın! Combo bozuldu"
		else:
			status_label.text = "Kaçırdın!"

		update_ui()

		if misses >= max_misses:
			finish_game(false)

func check_hit():
	if not bullet_active:
		return

	var x_hit = abs(bullet.global_position.x - target.global_position.x) <= hit_tolerance
	var y_hit = abs(bullet.global_position.y - target.global_position.y) <= hit_tolerance

	if x_hit and y_hit:
		combo_count += 1
		var gained_points = combo_count

		score += gained_points
		hits_landed += 1
		target_speed = min(target_speed + speed_step, max_target_speed)
		update_target_difficulty()

		if score > best_score:
			best_score = score
			save_best_score()

		update_ui()
		status_label.text = "Vurdun! +%d | Combo x%d" % [gained_points, combo_count]

		combo_timer.stop()
		combo_timer.wait_time = combo_timer_default_wait
		combo_timer.start()

		reset_bullet()
		move_target()

func update_target_difficulty():
	var shrink_steps = int(score / 5)

	var new_scale_x = max(target_min_scale.x, target_base_scale.x - shrink_steps * 0.08)
	var new_scale_y = max(target_min_scale.y, target_base_scale.y - shrink_steps * 0.08)

	target.scale = Vector2(new_scale_x, new_scale_y)
	hit_tolerance = max(35.0, 70.0 - shrink_steps * 5.0)

func move_target():
	var size = get_viewport_rect().size
	target.visible = true
	target.global_position = Vector2(
		rng.randi_range(220, int(size.x) - 220),
		120
	)

	if rng.randi_range(0, 1) == 0:
		target_direction = -1.0
	else:
		target_direction = 1.0

func move_target_sideways(delta):
	var size = get_viewport_rect().size

	target.global_position.x += target_direction * target_speed * delta

	if target.global_position.x <= 220:
		target.global_position.x = 220
		target_direction = 1.0
	elif target.global_position.x >= size.x - 220:
		target.global_position.x = size.x - 220
		target_direction = -1.0

func reset_bullet():
	bullet_active = false
	bullet.visible = false
	bullet.global_position = player.global_position + Vector2(0, -60)

func update_ui():
	score_label.text = "Skor: %d" % score
	best_score_label.text = "En iyi: %d" % best_score
	time_label.text = "Süre: %d" % time_left
	miss_label.text = "Kaçırma: %d/%d" % [misses, max_misses]
	shots_label.text = "Atış: %d" % shots_fired

	var accuracy := 0
	if shots_fired > 0:
		accuracy = int((float(hits_landed) / float(shots_fired)) * 100.0)

	accuracy_label.text = "İsabet: %%%d" % accuracy
	combo_label.text = "Combo: x%d" % combo_count

	if is_reloading:
		ammo_label.text = "Mermi: Reload..."
	else:
		ammo_label.text = "Mermi: %d/%d" % [ammo, max_ammo]

func _on_game_timer_timeout():
	if not game_active or paused:
		return

	game_timer.wait_time = game_timer_default_wait

	time_left -= 1
	update_ui()

	if time_left <= 0:
		finish_game(true)

func _on_combo_timer_timeout():
	combo_timer.wait_time = combo_timer_default_wait
	combo_count = 0
	update_ui()

	if game_active and not paused:
		status_label.text = "Combo bitti"

func _on_reload_timer_timeout():
	reload_timer.wait_time = reload_timer_default_wait
	ammo = max_ammo
	is_reloading = false
	update_ui()

	if game_active and not paused:
		if bullet_active:
			status_label.text = "Şarjör doldu"
		else:
			status_label.text = "Tekrar ateş edebilirsin"

func finish_game(won: bool):
	game_active = false
	paused = false
	bullet_active = false
	is_reloading = false

	game_timer_remaining = 0.0
	combo_timer_remaining = 0.0
	reload_timer_remaining = 0.0

	game_timer.stop()
	combo_timer.stop()
	reload_timer.stop()

	game_timer.wait_time = game_timer_default_wait
	combo_timer.wait_time = combo_timer_default_wait
	reload_timer.wait_time = reload_timer_default_wait

	bullet.visible = false
	target.visible = false

	set_player_control_enabled(false)

	var accuracy := 0
	if shots_fired > 0:
		accuracy = int((float(hits_landed) / float(shots_fired)) * 100.0)

	update_ui()

	if won:
		status_label.text = "Süre bitti! Skor: %d | İsabet: %%%d | Enter ile tekrar başla" % [score, accuracy]
	else:
		status_label.text = "Kaybettin! Skor: %d | İsabet: %%%d | Enter ile tekrar başla" % [score, accuracy]

func save_best_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(best_score)

func load_best_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			best_score = int(file.get_var())
