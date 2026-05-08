extends Node2D

var score := 0
var best_score := 0
var save_path := "user://target_blaster_save.save"

var time_left := 20
var game_active := false

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

@onready var score_label = $CanvasLayer/UIBox/ScoreLabel
@onready var best_score_label = $CanvasLayer/UIBox/BestScoreLabel
@onready var time_label = $CanvasLayer/UIBox/TimeLabel
@onready var miss_label = $CanvasLayer/UIBox/MissLabel
@onready var combo_label = $CanvasLayer/UIBox/ComboLabel
@onready var status_label = $CanvasLayer/UIBox/StatusLabel

@onready var player = $Player
@onready var bullet = $Bullet
@onready var target = $Target

@onready var game_timer = $GameTimer
@onready var combo_timer = $ComboTimer

func _ready():
	rng.randomize()
	load_best_score()
	show_start_screen()

func show_start_screen():
	score = 0
	time_left = 20
	game_active = false
	bullet_active = false
	misses = 0
	combo_count = 0

	game_timer.stop()
	combo_timer.stop()

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
	misses = 0
	combo_count = 0
	target_speed = base_target_speed

	game_timer.stop()
	combo_timer.stop()

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

	move_target_sideways(delta)
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
		misses += 1

		if combo_count > 0:
			combo_count = 0
			combo_timer.stop()
			status_label.text = "Kaçırdın! Combo bozuldu"
		else:
			status_label.text = "Kaçırdın!"

		update_ui()

		if misses >= max_misses:
			finish_game(false)

func check_hit():
	if not bullet_active:
		return

	var x_hit = abs(bullet.global_position.x - target.global_position.x) <= 70
	var y_hit = abs(bullet.global_position.y - target.global_position.y) <= 70

	if x_hit and y_hit:
		combo_count += 1
		var gained_points = combo_count

		score += gained_points
		target_speed = min(target_speed + speed_step, max_target_speed)

		if score > best_score:
			best_score = score
			save_best_score()

		update_ui()
		status_label.text = "Vurdun! +%d | Combo x%d" % [gained_points, combo_count]

		combo_timer.stop()
		combo_timer.start()

		reset_bullet()
		move_target()

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
	combo_label.text = "Combo: x%d" % combo_count

func _on_game_timer_timeout():
	if not game_active:
		return

	time_left -= 1
	update_ui()

	if time_left <= 0:
		finish_game(true)

func _on_combo_timer_timeout():
	combo_count = 0
	update_ui()

	if game_active:
		status_label.text = "Combo bitti"

func finish_game(won: bool):
	game_active = false
	game_timer.stop()
	combo_timer.stop()
	bullet_active = false
	bullet.visible = false
	target.visible = false

	if won:
		status_label.text = "Süre bitti! Skor: %d | En iyi: %d | Enter ile tekrar başla" % [score, best_score]
	else:
		status_label.text = "Kaybettin! Skor: %d | En iyi: %d | Enter ile tekrar başla" % [score, best_score]

func save_best_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(best_score)

func load_best_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			best_score = int(file.get_var())
